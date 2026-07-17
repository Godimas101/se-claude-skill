# Scope Framework

**Workshop ID:** 2754014019
**Author:** klime

Scope Framework is a modder's utility framework that provides a complete scoped-weapon system for hand weapons in Space Engineers. It is not a standalone weapon mod — it is infrastructure that other hand weapon mods depend on to add realistic scope/zoom behaviour without writing their own camera and control logic.

> **Key insight:** Scope Framework child mods require no C# code at all. Integration is entirely data-driven: drop a `ScopeConfig.txt` in your mod's `Data/` folder and map your weapon's SubtypeId to a camera block. The framework handles all runtime logic — camera switching, sway, stabilization, iron sights, and zoom input.

---

## End-User Features (Delivered Through Child Weapon Mods)

- Right-click to zoom into scope view, with configurable entry delay
- Player can still move (WASD, jetpack) while scoped
- Scope sway simulates weapon shake; hold **Shift** to stabilize
- Hold **Ctrl** + right-click for iron sights mode instead of scope view
- Adjust zoom level while scoped with **Q** and **E**
- Full multiplayer and dedicated server support

---

## How Scope Framework Child Mods Are Structured

```
MyHandWeaponMod/
├── Data/
│   ├── ScopeConfig.txt              ← INI config; one section per scoped weapon
│   └── CubeBlocks_ScopeCamera.sbc  ← Camera block SBC (required — see below)
└── metadata.mod
```

The `Data/ScopeConfig.txt` path is required. The camera block SBC is necessary because each scoped weapon needs a physical camera subpart embedded in the weapon model.

---

## ScopeConfig.txt Format

```ini
[WeaponPhysicalItemSubtypeId]
CameraSubtype=MyScopeCamera
DelayInFrames=18
XOffset=0.0
YOffset=0.0
ZOffset=0.0
Sway=0.1
```

Each INI section header (`[...]`) is the SubtypeId of the hand weapon's **`PhysicalGunObject`** SBC definition. You can have multiple sections for multiple weapons.

### Config Keys

| Key | Type | Description |
|-----|------|-------------|
| `CameraSubtype` | string | SubtypeId of the camera block used as the scope's viewport. Must be a camera subpart embedded in the weapon model. |
| `DelayInFrames` | int | Frames to wait after right-clicking before entering scope view. `18` ≈ 0.3s at 60fps. |
| `XOffset` | float | Horizontal camera offset in meters. `0.0` = centered. |
| `YOffset` | float | Vertical camera offset in meters. `0.0` = centered. |
| `ZOffset` | float | Forward/back camera offset in meters. `0.0` = at camera position. |
| `Sway` | float | Sway intensity. `0` = none, `0.1` = default. Higher = more shake. |

---

## Camera Block SBC Requirements

The scope view is rendered through a real camera block defined in your mod's SBC. It must be configured as a minimal, invisible block:

```xml
<Definition xsi:type="MyObjectBuilder_CameraBlockDefinition">
  <Id>
    <TypeId>CameraBlock</TypeId>
    <SubtypeId>MyScopeCamera</SubtypeId>
  </Id>
  <DisplayName></DisplayName>       <!-- Empty — must not appear in terminal -->
  <Size subTypeSize="Small">
    <X>1</X><Y>1</Y><Z>1</Z>
  </Size>
  <StandaloneCamera>true</StandaloneCamera>
  <HasPhysics>true</HasPhysics>
  <RequiredPowerInput>0</RequiredPowerInput>
</Definition>
```

Key requirements:
- **Small 1x1x1 block** — must fit as a subpart in a hand weapon model
- **`StandaloneCamera = true`** — allows it to function without a grid
- **`HasPhysics = true`** — required for attachment to a hand weapon entity
- **Empty `DisplayName`** — must not show up as a placeable block in-game
- **`RequiredPowerInput = 0`** — no power requirement

The camera SubtypeId here must exactly match `CameraSubtype` in your `ScopeConfig.txt`.

---

## Real-World Example (Binoculars)

From Workshop ID `2777644246`:

**`Data/ScopeConfig.txt`:**
```ini
[BinocularsItem]
CameraSubtype=BinoScopeCamera
DelayInFrames=10
XOffset=0.0
YOffset=0.0
ZOffset=0.0
Sway=0.02
```

The binoculars hand weapon has SubtypeId `BinocularsItem`. When the player right-clicks, Scope Framework switches to the `BinoScopeCamera` with subtle sway.

---

## Critical Rules

1. **Section name = `PhysicalGunObject` SubtypeId** — The INI section header matches the hand weapon's SubtypeId, not a turret or a magazine. Scope Framework is for hand weapons only.

2. **Camera block must exist in your mod's SBC** — The framework reads `CameraSubtype` and looks up that camera block definition. If the block isn't defined, the scope won't work.

3. **No C# required** — Scope Framework child mods are config + SBC only. Never write a session component for this framework.

4. **File location is fixed** — Must be `Data/ScopeConfig.txt` exactly. The framework scans this path in all loaded mods.

5. **Framework must be loaded before the child mod** — Players need Scope Framework (ID: 2754014019) subscribed and loaded. Your weapon mod depends on it but does not bundle it.

---

## Finding Examples

Check the user's **MOD_CATALOGUE.md** for all mods with category **Scope Framework** — these are the child mods they have installed. Use them as local reference examples when configuring `ScopeConfig.txt`.

Any mod with a `Data/ScopeConfig.txt` file is a Scope Framework child mod.

---

## Known Issues

- **Black/empty scope:** Can occur with "Better Performance" plugin active — load order conflict.
- **No external docs:** All documentation is the Workshop page description. No GitHub or wiki.
- **Last updated November 2022** — may have minor compatibility issues with newer SE updates.

---

## Finding More Examples

Any mod with a `Data/ScopeConfig.txt` file is a Scope Framework child mod. Check MOD_CATALOGUE.md for the **Scope Framework** category.

Full documentation is on the Scope Framework Workshop page (ID: 2754014019).

---

## References

### External
- [Workshop Page](https://steamcommunity.com/sharedfiles/filedetails?id=2754014019) — only documentation available
- Binoculars (example child mod) — Workshop ID `2777644246`

### Internal
- [../sbc/SBC_MISC.md](../sbc/SBC_MISC.md) — camera block SBC definition (required for each scoped weapon)
- [../ASSETS.md](../ASSETS.md) — hand weapon model with embedded camera subpart

### Local

Search the user's `MOD_CATALOGUE.md` for entries in the **Scope Framework** category. Any listed mod is a locally installed Scope Framework child mod and is valid implementation reference.

**Workshop IDs — check MOD_CATALOGUE for local paths:**
| Workshop ID | Mod Name | Category | Notes |
|-------------|----------|----------|-------|
| 2754014019 | Scope Framework | Framework Mod | Framework source |
| 2777644246 | Binoculars | Scope Framework | Example child mod |

> No external docs exist — the Workshop page description is the full documentation. Read the local source and any installed Scope Framework child mods for implementation guidance.
