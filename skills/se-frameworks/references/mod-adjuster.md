# Mod Adjuster

**Workshop ID:** 3017795356
**Author:** Ash Like Snow
**Workshop:** [Mod Adjuster V2](https://steamcommunity.com/sharedfiles/filedetails?id=3017795356)
**GitHub:** [Ash-LikeSnow/ModAdjusterV2](https://github.com/Ash-LikeSnow/ModAdjusterV2)

Mod Adjuster is a session component that lets your mod patch other mods' and vanilla game definitions **at runtime** — without SBC file conflicts or load-order problems. It is the preferred approach for balance overrides and cross-mod compatibility.

> For compiled C# mods, text surface scripts, PB scripts, and all other SE modding, use `/space-engineers`.

---

## How Mod Adjuster Works

1. Mod Adjuster's session component (`LoadData`) iterates all loaded mods
2. For each mod, it checks for `Data\ModAdjuster\ModAdjusterFiles.txt`
3. If found, it reads each listed XML filename from `Data\ModAdjuster\`
4. It deserializes those XML files into definition objects
5. It calls `Load()` on each definition, which patches the **live** in-memory game definition

**Key point:** only fields present in your XML are changed. Everything else stays as-is. This is a true merge, not a replace.

---

## Your Mod's File Structure

```
YourMod/
├── Data/
│   └── ModAdjuster/
│       ├── ModAdjusterFiles.txt   ← lists XML filenames to load (one per line)
│       ├── blocks.xml             ← your block patches
│       ├── weapons.xml            ← your weapon patches
│       └── components.xml         ← your component patches
├── metadata.mod
└── thumb.png
```

### ModAdjusterFiles.txt

Plain text, one filename per line (no path, just the name):

```
blocks.xml
weapons.xml
components.xml
```

---

## XML File Format

### Root Structure

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <CubeBlocks>
    <!-- block patches here -->
  </CubeBlocks>
  <Weapons>
    <!-- weapon patches here -->
  </Weapons>
  <Components>
    <!-- component patches here -->
  </Components>
</Definitions>
```

### CRITICAL: xsi:type Prefix Rule

Mod Adjuster **strips `MyObjectBuilder_` from `xsi:type` values** when parsing. Use the short form:

| Vanilla SBC | Mod Adjuster XML |
|-------------|-----------------|
| `xsi:type="MyObjectBuilder_ReactorDefinition"` | `xsi:type="ReactorDefinition"` |
| `xsi:type="MyObjectBuilder_ThrustDefinition"` | `xsi:type="ThrustDefinition"` |
| `xsi:type="MyObjectBuilder_CubeBlockDefinition"` | `xsi:type="CubeBlockDefinition"` |

**Type and Subtype IDs in `<Id>` tags use the same values as vanilla SBC** — no stripping needed there.

---

## Supported Definition Types and Their XML Tags

| XML Array Tag | xsi:type to use | What it patches |
|--------------|-----------------|-----------------|
| `<CubeBlocks>` / `<Definition>` | `CubeBlockDefinition` + subclass | Any block |
| `<Weapons>` / `<Weapon>` | `WeaponDefinition` | Weapon definitions |
| `<Ammos>` / `<Ammo>` | `AmmoDefinition` | Ammo definitions |
| `<AmmoMagazines>` / `<AmmoMagazine>` | `AmmoMagazineDefinition` | Ammo magazines |
| `<Components>` / `<Component>` | `ComponentDefinition` | Components |
| `<PhysicalItems>` / `<PhysicalItem>` | `PhysicalItemDefinition` | Physical items/ores |
| `<Blueprints>` / `<Blueprint>` | `BlueprintDefinition` | Crafting recipes |
| `<BlueprintClasses>` / `<Class>` | `BlueprintClassDefinition` | Blueprint classes |
| `<BlueprintClassEntries>` / `<Entry>` | *(no xsi:type)* | Add/remove blueprints from classes |
| `<Characters>` / `<Character>` | `CharacterDefinition` | Character definitions |
| `<VoxelMaterials>` / `<VoxelMaterial>` | `VoxelMaterialDefinition` | Voxel/ore materials |
| `<Prefabs>` / `<Prefab>` | `PrefabDefinition` | Prefab definitions |

---

## Common Patch Examples

### Change Block PCU

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <CubeBlocks>
    <Definition xsi:type="CubeBlockDefinition">
      <Id Type="MyObjectBuilder_CubeBlock" Subtype="LargeBlockArmorBlock" />
      <PCU>1</PCU>
    </Definition>
  </CubeBlocks>
</Definitions>
```

### Change Block Component Cost

```xml
<Definition xsi:type="CubeBlockDefinition">
  <Id Type="MyObjectBuilder_CubeBlock" Subtype="LargeBlockArmorBlock" />
  <Components>
    <Component Subtype="SteelPlate" Count="25" />
    <Component Subtype="SteelPlate" Count="5" />
  </Components>
  <CriticalComponent Subtype="SteelPlate" Index="1" />
</Definition>
```

> ⚠️ When you change Components, MA recalculates MaxIntegrity, mass, CriticalIntegrityRatio, and OwnershipIntegrityRatio automatically. You don't need to set these manually.

### Change Reactor Power Output

```xml
<Definition xsi:type="ReactorDefinition">
  <Id Type="MyObjectBuilder_Reactor" Subtype="LargeBlockLargeGenerator" />
  <MaxPowerOutput>500</MaxPowerOutput>
</Definition>
```

### Change Thruster Force

```xml
<Definition xsi:type="ThrustDefinition">
  <Id Type="MyObjectBuilder_Thrust" Subtype="LargeBlockLargeThrust" />
  <ForceMagnitude>5400000</ForceMagnitude>
  <MaxPowerConsumption>3.36</MaxPowerConsumption>
</Definition>
```

### Change Weapon Damage and Range

```xml
<Weapons>
  <Weapon>
    <Id Type="MyObjectBuilder_WeaponDefinition" Subtype="AutomaticRifleGun_Mag_20rd" />
    <DamageMultiplier>1.5</DamageMultiplier>
    <RangeMultiplier>1.2</RangeMultiplier>
    <ReloadTime>2000</ReloadTime>
  </Weapon>
</Weapons>
```

### Change Jump Drive Power and Distance

```xml
<Definition xsi:type="JumpDriveDefinition">
  <Id Type="MyObjectBuilder_JumpDrive" Subtype="LargeJumpDrive" />
  <RequiredPowerInput>10</RequiredPowerInput>
  <MaxJumpDistance>50000</MaxJumpDistance>
</Definition>
```

### Change Cargo Container Volume

```xml
<Definition xsi:type="CargoContainerDefinition">
  <Id Type="MyObjectBuilder_CargoContainer" Subtype="LargeBlockLargeContainer" />
  <InventorySize>
    <X>2.5</X><Y>2.5</Y><Z>2.5</Z>
  </InventorySize>
</Definition>
```

### Hide a Block from G-Menu (GuiVisible)

```xml
<Definition xsi:type="CubeBlockDefinition">
  <Id Type="MyObjectBuilder_CubeBlock" Subtype="SomeBlockSubtype" />
  <GuiVisible>false</GuiVisible>
</Definition>
```

### Change Display Name

```xml
<Definition xsi:type="CubeBlockDefinition">
  <Id Type="MyObjectBuilder_CubeBlock" Subtype="SomeBlockSubtype" />
  <DisplayName>My New Name</DisplayName>
</Definition>
```

### Remove Block from Survival (SBC-only blocks)

```xml
<Definition xsi:type="CubeBlockDefinition">
  <Id Type="MyObjectBuilder_CubeBlock" Subtype="SomeBlockSubtype" />
  <AvailableInSurvival>false</AvailableInSurvival>
</Definition>
```

### Add Blueprint to Assembler Class

```xml
<BlueprintClassEntries>
  <Entry>
    <Class>LargeBlocks</Class>
    <BlueprintSubtypeId>MyBlueprintSubtype</BlueprintSubtypeId>
  </Entry>
</BlueprintClassEntries>
```

> ⚠️ The first entry that changes a class **clears all existing entries** for that class first. Every entry after that adds to the cleared list. So if you want to add one blueprint while keeping all existing ones, you must list ALL existing blueprints plus your new one.

---

## CubeBlock xsi:type Reference

Use the most specific type for the block you're patching:

| Block Type | xsi:type |
|------------|----------|
| Generic / Armor | `CubeBlockDefinition` |
| Thruster | `ThrustDefinition` |
| Reactor | `ReactorDefinition` |
| Battery | `BatteryBlockDefinition` |
| Jump Drive | `JumpDriveDefinition` |
| Refinery | `RefineryDefinition` |
| Assembler | `AssemblerDefinition` |
| Cargo Container | `CargoContainerDefinition` |
| Connector | `ShipConnectorDefinition` |
| Gyroscope | `GyroDefinition` |
| Turret (gatling) | `LargeGatlingTurretDefinition` |
| Turret (missile) | `LargeMissileTurretDefinition` |
| Fixed gun | `WeaponBlockDefinition` |
| Warhead | `WarheadDefinition` |
| Door | `DoorDefinition` |
| Air Vent | `AirVentDefinition` |
| Med Bay | `MedicalRoomDefinition` |
| Beacon | `BeaconDefinition` |
| Antenna | `RadioAntennaDefinition` |
| Camera | `CameraBlockDefinition` |
| Sensor | `SensorBlockDefinition` |
| Timer | `TimerBlockDefinition` |
| Programmable Block | `ProgrammableBlockDefinition` |
| Projector | `ProjectorDefinition` |
| Upgrade Module | `UpgradeModuleDefinition` |
| Solar Panel | `SolarPanelDefinition` |
| Wind Turbine | `WindTurbineDefinition` |
| O2/H2 Generator | `OxygenGeneratorDefinition` |
| Gas Tank | `GasTankDefinition` |
| Piston | `PistonBaseDefinition` |
| Rotor | `MotorAdvancedStatorDefinition` |
| Hinge | `MotorAdvancedStatorDefinition` |
| Merge Block | `MergeBlockDefinition` |
| Landing Gear | `LandingGearDefinition` |
| Sorter | `ConveyorSorterDefinition` |

---

## Fields Available on All Definitions

These come from the base `Definition` class — available on every definition type:

| Field | Type | Notes |
|-------|------|-------|
| `DisplayName` | string | Display name in game |
| `Description` | string | Tooltip description |
| `Icon` | string[] | Icon texture path(s) |
| `Public` | bool? | Whether block appears in G-menu |
| `Enabled` | bool? | Whether the definition is active |
| `AvailableInSurvival` | bool? | Whether buildable in Survival |

---

## Fields Available on CubeBlock Definitions

The most-used fields from `CubeBlockDefinition`:

| Field | Type | Notes |
|-------|------|-------|
| `PCU` | int? | PCU cost (regular sessions) |
| `PCUConsole` | int? | PCU cost (console PCU mode) |
| `Components` | array | Full component list — replaces entirely |
| `CriticalComponent` | element | Which component is the critical one |
| `BuildTimeSeconds` | float? | Build time |
| `DisassembleRatio` | float? | Ratio of components returned on grind |
| `MaxIntegrity` | int? | Override max HP (normally auto-calculated from components) |
| `DeformationRatio` | float? | How much the block deforms on impact |
| `GeneralDamageMultiplier` | float? | Multiplier on all incoming damage |
| `GuiVisible` | bool? | Show in G-menu toolbar |
| `IsAirTight` | bool? | Whether block seals atmosphere |
| `MountPoints` | array | Block attachment faces |
| `PrimarySound` | string | Running/active sound |
| `DamagedSound` | string | Sound when damaged |

---

## Known Limitations

1. **Some fields are commented out / not implemented.** The Mod Adjuster source explicitly skips some fields (MirroringX/Y/Z, Rotation, Direction, CompoundEnabled, SubBlockDefinitions). Check the source at `[Steam]\steamapps\workshop\content\244850\3017795356\Data\Scripts\Adjuster\Definitions\Blocks\CubeBlock.cs` before trying to patch those.

2. **BlueprintClassEntries clears the class on first write.** If you add entries to a class, list ALL blueprints you want — not just the new one.

3. **Icons get the mod path prepended.** MA prepends the mod folder path to icon paths, so use relative paths like `Textures\GUI\Icons\MyIcon.dds`.

4. **Mod Adjuster v2 only.** This is the v2 API (Workshop ID 3017795356). Not compatible with older MA v1 mods.

5. **Requires Mod Adjuster to be loaded.** Players must have the Mod Adjuster mod enabled. Make it a required dependency in your mod's Workshop page.

---

## Debugging

Mod Adjuster writes a log. Failed patches show as:
```
Failed to find definition for MyObjectBuilder_CubeBlock/BadSubtype
```

Log location: `%AppData%\SpaceEngineers\SpaceEngineers.log`

Search for `ModAdjuster` to find all MA log lines.

---

## References

### External
- [Workshop Page](https://steamcommunity.com/sharedfiles/filedetails?id=3017795356)
- [GitHub Repository](https://github.com/Ash-LikeSnow/ModAdjusterV2)

### Internal
- [../sbc/SBC_RULES.md](../sbc/SBC_RULES.md) — SBC override/additive rules and load order
- [../sbc/SBC_BLOCKS.md](../sbc/SBC_BLOCKS.md) — block and item definition templates for what to patch

### Local

Search the user's `MOD_CATALOGUE.md` for Workshop ID `3017795356` (listed under the **Mod Adjuster** category). If installed, the source layout is always:

| What | Path within mod folder |
|------|------------------------|
| All definition classes | `Data\Scripts\Adjuster\Definitions\` |
| CubeBlock fields | `Data\Scripts\Adjuster\Definitions\Blocks\CubeBlock.cs` |
| All functional block types | `Data\Scripts\Adjuster\Definitions\Blocks\FunctionalBlocks.cs` |
| Weapon definition fields | `Data\Scripts\Adjuster\Definitions\Weapons.cs` |
| Session component (loader) | `Data\Scripts\Adjuster\Session\ModAdjuster.cs` |

Vanilla block SBCs (always present if SE is installed): `[Steam]\steamapps\common\SpaceEngineers\Content\Data\`
