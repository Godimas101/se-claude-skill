# WeaponCore

**Workshop ID:** 3154371364
**Authors:** BDCarrillo (primary), Ash Like Snow (contributor/wiki)
**Required dependency:** Camera Panning — Workshop ID `806331071`

WeaponCore (internally "CoreSystems") is the dominant weapon framework for Space Engineers modding. It completely replaces SE's native combat system — all vanilla weapons are swapped for WC-managed equivalents, and any incompatible third-party weapon blocks are removed from the world at session start (unless the server enables "UnsupportedMode"). WeaponCore itself adds no weapons; it is purely infrastructure that weapon mod authors build on top of.

> **Key insight:** WeaponCore weapon mods consist of `.cs` configuration files (not SBC weapon stats) placed in `Data/Scripts/CoreParts/`, paired with standard SBC block definitions. The framework compiles and reads these files at startup. You never edit the framework; you only provide definition files.

**Authoritative documentation:** [GitHub Wiki — Ash-LikeSnow/WeaponCore](https://github.com/Ash-LikeSnow/WeaponCore/wiki)
**Example CoreParts repo:** [Ash-LikeSnow/CoreParts](https://github.com/Ash-LikeSnow/CoreParts)

---

## How WeaponCore Child Mods Are Structured

```
MyWeaponMod/
├── Data/
│   ├── Scripts/CoreParts/
│   │   ├── MasterConfig.cs          ← Required: lists all WeaponDefinitions
│   │   ├── PartCompile.cs           ← Required: mandatory framework file (copy from CoreParts repo)
│   │   ├── Slave.cs                 ← Required: mandatory framework file (copy from CoreParts repo)
│   │   ├── Structure.cs             ← Required: mandatory framework file (copy from CoreParts repo)
│   │   ├── MyWeaponPart.cs          ← Your weapon definition(s)
│   │   └── MyWeaponAmmo.cs          ← Your ammo definition(s)
│   ├── CubeBlocks_MyWeapon.sbc      ← Block grid placement definition
│   └── Energy_Ammo.sbc              ← Optional: energy ammo magazines
└── metadata.mod
```

**Three files — `PartCompile.cs`, `Slave.cs`, `Structure.cs` — are mandatory framework boilerplate.** Copy them verbatim from the [CoreParts example repo](https://github.com/Ash-LikeSnow/CoreParts). Never modify them.

---

## SBC Block Type

The **recommended block type for WeaponCore weapons is `ConveyorSorter`** — it has performance advantages and supports angled turrets:

```xml
<Definition xsi:type="MyObjectBuilder_ConveyorSorterDefinition">
  <Id>
    <TypeId>ConveyorSorter</TypeId>
    <SubtypeId>MyTurretBlock</SubtypeId>   <!-- Must match MountPointDef.SubtypeId in C# -->
  </Id>
  <DisplayName>My Custom Turret</DisplayName>
  <Model>Models\Cubes\Large\MyTurret.mwm</Model>
  <!-- WeaponCore handles targeting/ammo/damage — don't define weapon stats here -->
</Definition>
```

Other supported types: `LargeMissileTurret` (add `<AiEnabled>false</AiEnabled>` to suppress vanilla AI), `GatlingTurret`, `InteriorTurret`, `RocketLauncher`, `SmallGatlingGun`, `SmallMissileLauncher`. Prefer `ConveyorSorter`.

---

## WeaponDefinition File Structure

### Part File (`{Name}Part.cs`)

```csharp
using static Scripts.Structure;
using static Scripts.Structure.WeaponDefinition;
using static Scripts.Structure.WeaponDefinition.ModelAssignmentsDef;
using static Scripts.Structure.WeaponDefinition.HardPointDef;
using static Scripts.Structure.WeaponDefinition.HardPointDef.Prediction;
using static Scripts.Structure.WeaponDefinition.TargetingDef.BlockTypes;
using static Scripts.Structure.WeaponDefinition.TargetingDef.Threat;
using static Scripts.Structure.WeaponDefinition.TargetingDef;
using static Scripts.Structure.WeaponDefinition.HardPointDef.HardwareDef;
using static Scripts.Structure.WeaponDefinition.HardPointDef.HardwareDef.HardwareType;

namespace Scripts {
    partial class Parts {
        // Don't edit above this line
        WeaponDefinition MyTurretWeapon => new WeaponDefinition
        {
            Assignments = new ModelAssignmentsDef
            {
                MountPoints = new[] {
                    new MountPointDef {
                        SubtypeId = "MyTurretBlock",          // Must match CubeBlocks SBC SubtypeId
                        MuzzlePartId = "ElevationSubpart",    // Subpart containing muzzle empties
                        AzimuthPartId = "AzimuthSubpart",     // Horizontal rotation subpart
                        ElevationPartId = "ElevationSubpart", // Vertical rotation subpart
                        DurabilityMod = 0.25f,                // Damage multiplier (0.25 = 25% damage taken)
                    },
                },
                Muzzles = new[] {
                    "muzzle_01", "muzzle_02",                 // Muzzle empty names — use numbers, not letters
                },
            },
            Targeting = new TargetingDef
            {
                Threats = new[] { Grids, Projectiles },       // Meteors, Grids, Characters, Projectiles, Neutrals
                SubSystems = new[] { Offense, Utility, Power, Any },
                MaxTargetDistance = 0,                        // 0 = unlimited
                MinTargetDistance = 0,
                TopTargets = 24,                              // Max targets to randomize between
                CycleTargets = 4,
                TopBlocks = 24,
                CycleBlocks = 4,
            },
            HardPoint = new HardPointDef
            {
                PartName = "My Turret",                       // Terminal display name
                DeviateShotAngle = 0.25f,                     // Accuracy spread in degrees
                AimingTolerance = 5f,                         // How far off-center it can still fire
                AimLeadingPrediction = Accurate,              // Off, Basic, Accurate, Advanced
                Ai = new AiDef
                {
                    TrackTargets = true,
                    TurretAttached = true,
                    TurretController = true,
                },
                Loading = new LoadingDef
                {
                    RateOfFire = 600,                         // Rounds per minute
                    ReloadTime = 0,                           // Ticks (60 = 1 second)
                    BarrelsPerShot = 1,
                    TrajectilesPerBarrel = 1,
                },
                HardWare = new HardwareDef
                {
                    RotateRate = 0.02f,
                    ElevateRate = 0.02f,
                    Type = Phantom,                           // Phantom = no recoil block needed
                },
            },
            Ammos = new[] { MyAmmoRound },                    // References ammo C# property name
        };
    }
}
```

### Ammo File (`{Name}Ammo.cs`)

```csharp
using static Scripts.Structure.WeaponDefinition;
using static Scripts.Structure.WeaponDefinition.AmmoDef;
using static Scripts.Structure.WeaponDefinition.AmmoDef.TrajectoryDef;
using static Scripts.Structure.WeaponDefinition.AmmoDef.TrajectoryDef.GuidanceType;
// ... (many additional static using imports for ammo sub-types)

namespace Scripts {
    partial class Parts {
        private AmmoDef MyAmmoRound => new AmmoDef
        {
            AmmoMagazine = "MyAmmoMagazine",  // SubtypeId of magazine, or "Energy" for energy weapons
            AmmoRound = "My Cannon Round",    // Terminal display name (unique per weapon)
            BaseDamage = 1000f,               // Direct damage; 100 = one steel plate
            Mass = 50f,                       // Projectile mass in kg (impulse on impact)
            Health = 0,                       // 0 = untargetable projectile
            EnergyCost = 0f,                  // Energy per shot (0 for physical ammo)
            EnergyMagazineSize = 0,           // For energy weapons: shots before reload

            Trajectory = new TrajectoryDef
            {
                Guidance = None,              // None, Smart, TravelTo, Remote, DetectSmart, etc.
                DesiredSpeed = 400f,          // m/s
                MaxTrajectory = 1800f,        // Max range in meters
                AccelPerSec = 0f,             // 0 = constant speed
                GravityMultiplier = 0f,       // 0 = not affected by gravity
            },
            // ... Shape, DamageScale, AreaEffect (AoE/EMP), Graphics, Audio, Fragments
        };
    }
}
```

---

## MasterConfig.cs

Every WeaponCore child mod needs a `MasterConfig.cs` that declares all weapon definitions:

```csharp
using static Scripts.Structure;

namespace Scripts {
    partial class Parts {
        // All weapon definition properties listed here
        // WeaponCore scans this to discover what's in the mod
    }
}
```

In practice the MasterConfig calls `PartDefinitions(...)` to register all weapons — copy the structure from the [CoreParts example repo](https://github.com/Ash-LikeSnow/CoreParts).

---

## Critical Rules

1. **Copy the three mandatory files** — `PartCompile.cs`, `Slave.cs`, `Structure.cs` must be present in `CoreParts/`. Get them from [Ash-LikeSnow/CoreParts](https://github.com/Ash-LikeSnow/CoreParts). Without them the mod won't compile.

2. **`partial class Parts` is mandatory** — All weapon and ammo definitions must be properties of `partial class Parts` in namespace `Scripts`. The class is partial so multiple files combine into one.

3. **Weapon references ammo by property name** — `Ammos = new[] { MyAmmoRound }` must match the C# property name in the ammo file (same namespace/class).

4. **Muzzle empties use numbers** — Vanilla SE uses letters (A, B, C) but WeaponCore expects numbers (`muzzle_01`, `muzzle_02`). Don't copy vanilla naming.

5. **SubtypeId links block to weapon** — `MountPointDef.SubtypeId` must exactly match the `<SubtypeId>` in your SBC block definition. This is how WeaponCore discovers which blocks to control.

6. **Camera Panning is a required dependency** — Players must have Workshop ID `806331071` loaded alongside WeaponCore.

7. **ConveyorSorter is preferred** — Use `ConveyorSorter` as your SBC block type unless you have a specific reason not to.

---

## Programmable Block API

WeaponCore exposes a PB scripting API via the `WcPbApi` class. Key method categories:

| Category | Methods |
|----------|---------|
| Weapon discovery | `GetAllCoreWeapons`, `GetAllCoreTurrets`, `GetAllCoreStaticLaunchers` |
| Targeting | `GetAiFocus`, `SetAiFocus`, `GetWeaponTarget`, `SetWeaponTarget`, `GetSortedThreats` |
| Fire control | `FireWeaponOnce`, `ToggleWeaponFire`, `IsWeaponReadyToFire` |
| Aim queries | `IsTargetAligned`, `CanShootTarget`, `GetPredictedTargetPosition` |
| Status | `GetHeatLevel`, `GetCurrentPower`, `GetActiveAmmo`, `SetActiveAmmo` |
| Advanced | `GetWeaponAzimuthMatrix`, `GetWeaponElevationMatrix`, `GetWeaponScope` |

Full PB API guide: Workshop ID `2178802013` (by Sigmund Froid).

---

## Finding Examples

Check the user's **MOD_CATALOGUE.md** for all mods with category **WeaponCore** — these are the child mods they have installed. Use them as local reference examples when building new weapon definitions.

Any mod with `Data/Scripts/CoreParts/*.cs` files is a WeaponCore child mod. The official compatible mod list (79+ mods) is on the [GitHub wiki](https://github.com/Ash-LikeSnow/WeaponCore/wiki/Current-WeaponCore-ModList).
