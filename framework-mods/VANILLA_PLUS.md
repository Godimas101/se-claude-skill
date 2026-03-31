# Vanilla+ Framework

**Workshop ID:** 2915780227
**Author:** Nerd e1
**Example mod:** Workshop ID `3014670447` — copy from local workshop cache (unlisted)
**Discord (primary docs):** https://discord.gg/dxfxcnvXeh

Vanilla+ Framework (VPF) is a server-side scripting framework that adds advanced projectile and weapon behaviors to vanilla Space Engineers weapons without overwriting any vanilla SBC definitions. It works by reading C# definition objects registered by child mods at session load, then intercepting vanilla missile and turret events at runtime to apply additional logic.

> **Key insight:** VPF does nothing on its own — it is purely infrastructure. Child mods register `VPFAmmoDefinition`, `VPFTurretDefinition`, or `VPFVisualEffectsDefinition` objects via the SE message API, and the framework attaches those behaviors to matching ammo/block subtypes. No new SBC blocks are needed unless you want new visual assets.

> ⚠️ **INCOMPATIBLE WITH WEAPONCORE** — Never load both in the same world. They conflict at a fundamental level.

> ⚠️ **Server-side scripted** — Does not work on console or Mod.io. Requires client-side scripting access.

> **Note:** The Vanilla+ Framework Workshop listing has been removed from public view. It remains functional for existing subscribers. Access docs via the local workshop files or Discord.

**Primary documentation:** The `.cs` definition files themselves contain extensive XML doc comments on every field — read them. The Discord server is the main support channel.

---

## How Vanilla+ Child Mods Are Structured

```
MyVanillaPlusMod/
├── Data/
│   └── Scripts/
│       └── MyMod/
│           ├── VPFModAPI.cs                         ← Copy verbatim from framework
│           ├── Definitions/
│           │   ├── AmmoDefinitionDefinitions.cs     ← Copy verbatim — DO NOT MODIFY
│           │   ├── TurretDefinitionDefinitions.cs   ← Copy verbatim — DO NOT MODIFY
│           │   ├── FXDefinitionDefinitions.cs       ← Copy verbatim — DO NOT MODIFY
│           │   └── DefinitionTools.cs               ← Copy verbatim — DO NOT MODIFY
│           └── MyModDefinitions.cs                  ← Your definitions (session component)
└── metadata.mod
```

The four files in `Definitions/` and `VPFModAPI.cs` are boilerplate copies from the framework source. Get them from the framework mod's workshop folder:
`[Workshop]\content\244850\2915780227\Data\Scripts\VanillaPlusFrameworkScripts\`

---

## Registration Pattern (Session Component)

VPF uses SE's `SendModMessage` to pass definitions to the framework. The message channel ID is `2915780228L` (Workshop ID + 1).

```csharp
using Sandbox.ModAPI;
using VRage.Game.Components;
using VanillaPlusFramework.TemplateClasses;

namespace MyMod
{
    [MySessionComponentDescriptor(MyUpdateOrder.NoUpdate)]
    public class MyModSession : MySessionComponentBase
    {
        public override void LoadData()
        {
            VPFModAPI.Load();  // Must call before registering definitions
        }

        public override void BeforeStart()
        {
            if (!VPFModAPI.IsReady) return;  // Framework not loaded — bail

            // Register ammo definition
            var ammoDef = new VPFAmmoDefinition
            {
                subtypeName = "Missile200mm",  // Vanilla Ammo.sbc SubtypeId
                VPF_MissileHitpoints = 2,
                GL_Stats = new GuidanceLock_Logic { /* ... */ },
                EMP_Stats = null,
            };

            MyAPIGateway.Utilities.SendModMessage(
                DefinitionTools.ModMessageID,
                MyAPIGateway.Utilities.SerializeToBinary(ammoDef)
            );
        }

        protected override void UnloadData()
        {
            VPFModAPI.Unload();
        }
    }
}
```

---

## Ammo Logic Types (`VPFAmmoDefinition`)

Each definition is keyed to a vanilla `AmmoDefinition` subtype ID. Attach any combination of the following logic types.

### Common Fields

| Field | Description |
|-------|-------------|
| `subtypeName` | SubtypeId from vanilla `Ammo.sbc` (e.g. `"Missile200mm"`) |
| `VPF_MissileHitpoints` | HP pool — allows point-defense to shoot this missile down. `0` = untargetable |
| `NeedsAPHEFix` | Enable APHE penetration damage fix |

### Guidance Lock (GL_Stats)

Guided missile logic with piecewise polynomial homing curves:

```csharp
GL_Stats = new GuidanceLock_Logic
{
    // Homing strength: piecewise polynomial (time in seconds → degrees/second of turn)
    // Each row: [startTime, const, x¹, x², ...]
    GL_HomingPiecewisePolynomialFunction = DefinitionTools.ConvertToDoubleArrayList(
        new double[,] {
            { 0,   0,   0, 0 },   // 0–0.2s: no guidance (burn phase)
            { 0.2, 160, 0, 0 },   // 0.2–1.2s: 160 deg/s
            { 1.2, 20,  0, 0 },   // 1.2s+: 20 deg/s (cruise)
        }
    ),
    // Optional: flare resistance, decoy spawning, preferred target block type
},
```

### Proximity Detonation (PD_Stats)

Flak-style detonation:

```csharp
PD_Stats = new ProximityDetonation_Logic
{
    PD_DetectionRadius = 15f,  // Meters — triggers within this range of target
},
```

### EMP (EMP_Stats)

```csharp
EMP_Stats = new EMP_Logic
{
    EMP_Radius   = 50f,   // Meters
    EMP_Duration = 300,   // Ticks (60 = 1 second)
},
```

### Jump Drive Inhibitor (JDI_Stats)

```csharp
JDI_Stats = new JumpDriveInhibitor_Logic
{
    JDI_DrainWatts = 500000f,  // Watts to drain from jump drive charge
},
```

### Shrapnel (SPL_Stats)

Spawns secondary hitscan beams or projectiles on missile death:

```csharp
SPL_Stats = new Shrapnel_Logic
{
    // Cone direction: Projectile, Gravity, CollisionNormal, ReflectionVector
    // Spawn conditions: OnCollide, OnNoCollide, OnArmed, etc.
},
```

### Beam Weapon Type (BWT_Stats)

Turns the missile into a server-side hitscan beam:

```csharp
BWT_Stats = new BeamWeaponType_Logic
{
    BWT_PenetrationDamage = 5000f,
    BWT_ExplosiveDamage   = 0f,
    BWT_RicochetChance    = 0.3f,
},
```

---

## Turret Logic Types (`VPFTurretDefinition`)

Each definition is keyed to a `CubeBlocks.sbc` SubtypeId (or TypeId for vanilla turrets with empty subtypes).

### Turret AI Override (TAI_Stats)

```csharp
TAI_Stats = new TurretAI_Logic
{
    TAI_MinRange = 50f,        // Minimum firing distance (won't fire closer)
    TAI_ForceTargetLargeShips  = true,
    TAI_ForceTargetSmallShips  = true,
    TAI_ForceTargetMissiles    = true,
    // Force-enable or force-disable any vanilla targeting flag
},
```

### Ammo Generation (AG_Stats)

Automatically regenerates ammo using power/hydrogen/oxygen:

```csharp
AG_Stats = new AmmoGeneration_Logic
{
    AG_Resource    = IdType.POWER,   // POWER, HYDROGEN, OXYGEN
    AG_Amount      = 1f,             // Resource cost per batch
    AG_Time        = 120,            // Ticks per batch
    AG_BatchCount  = 1,              // Magazines per batch
    AG_Capacitor   = false,          // true = charge once, fire, wait
},
```

### Fake Beam FX (FB_Stats)

Visual beam drawn every tick, decoupled from damage frequency:

```csharp
FB_Stats = new FakeBeam_Logic
{
    FB_MuzzleDummy = "muzzle_01",    // Empty name on the turret model
    FB_Length      = 200f,           // Visual beam length in meters
},
```

### Recoil Fix

```csharp
RecoilFix = true,  // Corrects vanilla bug where missile turrets produce no recoil
```

---

## Visual Effects (`VPFVisualEffectsDefinition`)

Bypasses the SE engine's 1024 particle emitter limit by drawing custom line/sphere/trail objects attached to missiles:

```csharp
var fxDef = new VPFVisualEffectsDefinition
{
    subtypeName = "Missile200mm",
    // Color, thickness, blend type, fade, rotation, velocity inheritance, etc.
};
```

---

## Critical Rules

1. **Copy the 5 boilerplate files verbatim** — `VPFModAPI.cs` + the four `Definitions/*.cs` files. Never modify them.

2. **Unique namespaces** — Every definition class must use a unique namespace. Never use `VanillaPlusFramework` as your namespace.

3. **Never combine with WeaponCore** — These two frameworks are fundamentally incompatible. Warn the user if they try.

4. **`GL_Stats = null` if not used** — Explicitly null out unused logic types. Unset values may throw runtime errors.

5. **`subtypeName` = Ammo.sbc SubtypeId** — For ammo definitions, this is the ammo's SubtypeId (e.g. `"Missile200mm"`), not the magazine SubtypeId.

6. **Server-side only** — Will not function on console clients or Mod.io.

7. **Call `VPFModAPI.Load()` in `LoadData()`** — Then check `VPFModAPI.IsReady` in `BeforeStart()` before registering.

---

## Finding Examples

Check the user's **MOD_CATALOGUE.md** for all mods with category **Vanilla+ Framework** — these are the child mods they have installed. Use them as local reference examples when building new definitions.

Any mod with `Definitions/AmmoDefinitionDefinitions.cs` inside its `Data/Scripts/` tree is a Vanilla+ child mod. The most useful reference is the **Example Mod** (ID `3014670447`) — if the user has it installed, it's the authoritative implementation reference.
