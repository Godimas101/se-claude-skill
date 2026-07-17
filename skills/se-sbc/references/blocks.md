# SBC Blocks Reference — Space Engineers

Block definitions, categories, variant groups, and the type reference table. For SBC rules and DefinitionBase fields that apply everywhere, see [SBC_RULES.md](SBC_RULES.md).

> For blueprints, production tabs, and progression locks: see [SBC_PRODUCTION.md](SBC_PRODUCTION.md).
> For LCD registration, localization, loot, and prefabs: see [SBC_MISC.md](SBC_MISC.md).

---

## Block Category (G-menu filter tab)

The XML wrapper is `<CategoryClasses>`. Identity key is `<Name>` (NOT SubtypeId).

**Additive behavior:** If a `<Name>` already exists, your entry **appends** its `<ItemIds>` to it. All other fields on the duplicate are ignored. This is how mods add blocks to vanilla tabs without overriding them.

### Extend an existing vanilla category

Only include `<Name>` and `<ItemIds>` — other fields are ignored when appending. Do NOT re-include items that are already in the category.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <CategoryClasses>
    <Category xsi:type="MyObjectBuilder_GuiBlockCategoryDefinition">
      <Id>
        <TypeId>GuiBlockCategoryDefinition</TypeId>
        <SubtypeId/>
      </Id>
      <Name>Section1_Position3_Weapons</Name>
      <ItemIds>
        <string>LargeMissileTurret/MY_TURRET_SUBTYPE</string>
        <string>SmallMissileLauncher/MY_LAUNCHER_SUBTYPE</string>
      </ItemIds>
    </Category>
  </CategoryClasses>
</Definitions>
```

> `ItemIds` format is `TypeId/SubtypeId` — bare TypeId, NOT `MyObjectBuilder_TypeId/SubtypeId`. For empty SubtypeId, use `TypeId/` or `TypeId/(null)`.

> **Do NOT use short names** like `Weapons` or `LargeBlocks` — those create a NEW separate tab instead of merging with vanilla.

### Vanilla category Names

| G-menu tab | `<Name>` |
|-----------|----------|
| All large grid | `Section1_Position1_LargeBlocks` |
| All small grid | `Section1_Position1_SmallBlocks` |
| Weapons | `Section1_Position3_Weapons` |
| Decorative | `Section1_Position3_Decorative` |
| Propulsion | `Section1_Position3_Propulsion` |
| Power | `Section1_Position3_Power` |
| Production | `Section1_Position3_Production` |
| Mechanical | `Section1_Position3_Mechanical` |

### Create a new custom category tab

Use a unique Name so it doesn't collide with vanilla or other mods. Include `<DisplayName>` here since this is the initial definition.

```xml
<Category xsi:type="MyObjectBuilder_GuiBlockCategoryDefinition">
  <Id>
    <TypeId>GuiBlockCategoryDefinition</TypeId>
    <SubtypeId/>
  </Id>
  <DisplayName>My Mod Blocks</DisplayName>
  <Name>MyMod_UniqueTabName</Name>
  <ItemIds>
    <string>CubeBlock/MY_BLOCK_ID_1</string>
    <string>CubeBlock/MY_BLOCK_ID_2</string>
  </ItemIds>
</Category>
```

### Category-specific fields

| Field | Default | Notes |
|-------|---------|-------|
| `<StrictSearch>` | `false` | If false, BVG members auto-appear in all categories containing their group's first block. Set true to prevent this. |
| `<SearchBlocks>` | `true` | Whether contents appear in G-menu search results |
| `<ShowInCreative>` | `true` | Visibility in creative mode |
| `<IsBlockCategory>` | `true` | Marks as a placeable block category |
| `<IsToolCategory>` | `false` | Marks as equippable item category |
| `<IsShipCategory>` | `false` | Controls visibility in ship toolbars (cockpit, seat, RC) |
| `<IsAnimationCategory>` | `false` | Marks for character emotes |

### Category positioning via Name

The `<Name>` value controls ordering in the G-menu. Appending a suffix after an existing name sorts after it:

```
Section1_Position2_Armorblocks           ← vanilla
Section1_Position2_Armorblocks_Fancy     ← your mod's sub-category, appears after
```

Sub-categories can be visually indented by prefixing `DisplayName` with three spaces:
```xml
<DisplayName>   My Sub-Category</DisplayName>
```

`<IsToolCategory>true</IsToolCategory>` is required for weapons and hand tools to appear on the character hotbar. Without it, they only show in the G-menu.

If a small grid block and a large grid block share the same `BlockPairName` and both are in the same `BlockCategory`, **only the large grid block** displays in the category. The small grid variant is accessible via grid-size swap (R key) but won't show as a separate entry.

---

## Block Variant Group (hotbar scroll group)

Groups multiple blocks into one G-menu slot; mouse wheel scrolls through variants.

### ⚠️ Critical Rules

1. **Non-additive — you MUST include all vanilla blocks.** Your definition completely replaces the vanilla one. Omitting any vanilla block removes it from the group for all players loading your mod.
2. **`<DisplayName>` MUST use the vanilla localization key** (starting with `DisplayName_`) for any group that appears in `RadialMenu.sbc`. Plain text or missing DisplayName → null `DisplayNameEnum` → `NullReferenceException` in `MyRadialMenuItemCubeBlock.Init` → session load aborted.
3. **A block cannot appear in more than one BVG.**
4. **Blocks paired by the same `BlockPairName` must both be in the same group.**
5. **List large grid blocks first** to avoid ordering bugs.
6. **DLC block as first entry = DLC wall** — players without that DLC cannot access the entire group.

### Extend an existing vanilla variant group

Copy the exact vanilla `<Icon>`, `<DisplayName>`, and `<Description>`. Include ALL vanilla `<Block>` entries first, then append yours.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlockVariantGroups>
    <BlockVariantGroup>
      <Id Type="MyObjectBuilder_BlockVariantGroup" Subtype="TurretGroup" />
      <Icon>Textures\GUI\Icons\Cubes\gatling_turret.dds</Icon>
      <DisplayName>DisplayName_BlockGroup_TurretGroup</DisplayName>
      <Description>Description_BlockGroup_TurretGroup</Description>
      <Blocks>
        <!-- ALL vanilla blocks first — omitting any removes it from the group -->
        <Block Type="MyObjectBuilder_LargeGatlingTurret" Subtype="" />
        <Block Type="MyObjectBuilder_LargeGatlingTurret" Subtype="SmallGatlingTurret" />
        <Block Type="MyObjectBuilder_LargeGatlingTurret" Subtype="LargeGatlingTurretReskin" />
        <Block Type="MyObjectBuilder_LargeGatlingTurret" Subtype="SmallGatlingTurretReskin" />
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="" />
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="SmallMissileTurret" />
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="LargeMissileTurretReskin" />
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="SmallMissileTurretReskin" />
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="LargeCalibreTurret" />
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="LargeBlockMediumCalibreTurret" />
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="SmallBlockMediumCalibreTurret" />
        <Block Type="MyObjectBuilder_InteriorTurret" Subtype="LargeInteriorTurret" />
        <Block Type="MyObjectBuilder_LargeGatlingTurret" Subtype="AutoCannonTurret" />
        <!-- Modded blocks appended at the end -->
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="MY_TURRET_SUBTYPE" />
      </Blocks>
    </BlockVariantGroup>
  </BlockVariantGroups>
</Definitions>
```

> `Block Type` uses the `MyObjectBuilder_` prefix. This is different from `ItemIds` in categories which use the bare TypeId.

> Always get the full vanilla block list from `[Steam]\steamapps\common\SpaceEngineers\Content\Data\BlockVariantGroups.sbc` before writing your override — the vanilla list changes between game patches.

### Vanilla DisplayName keys and Icons for common groups

| `Subtype` | `<DisplayName>` | `<Icon>` |
|-----------|-----------------|----------|
| `TurretGroup` | `DisplayName_BlockGroup_TurretGroup` | `Textures\GUI\Icons\Cubes\gatling_turret.dds` |
| `ShipWeaponStaticGroup` | `DisplayName_BlockGroup_ShipWeaponStaticGroup` | `Textures\GUI\Icons\Cubes\missile_launcher.dds` |
| `BatteryGroup` | `DisplayName_Block_Battery` | `Textures\GUI\Icons\Cubes\Battery.dds` |
| `SolarGroup` | `DisplayName_BlockGroup_EnergyRenewableGroup` | `Textures\GUI\Icons\Cubes\SolarPanel.dds` |
| `WindTurbineGroup` | `DisplayName_Block_WindTurbine` | `Textures\GUI\Icons\Cubes\WindTurbine.dds` |
| `RotorGroup` | `DisplayName_Block_Rotor` | `Textures\GUI\Icons\Cubes\motor.dds` |
| `HingeGroup` | `DisplayName_Block_Hinge` | `Textures\GUI\Icons\Cubes\Hinge.dds` |
| `StorageShelves` | `DisplayName_BlockGroup_StorageShelves` | `Textures\GUI\Icons\Cubes\Shelf_1.dds` |
| `TurretControlGroup` | `DisplayName_BlockGroup_TurretControlGroup` | *(check vanilla)* |

### Create a new custom variant group

```xml
<BlockVariantGroup>
  <Id Type="MyObjectBuilder_BlockVariantGroup" Subtype="MyMod_UniqueGroupName" />
  <Icon>Textures\GUI\Icons\Cubes\MyIcon.dds</Icon>
  <DisplayName>My Block Group</DisplayName>
  <Description>Scroll to cycle through variants</Description>
  <Blocks>
    <Block Type="MyObjectBuilder_CubeBlock" Subtype="MY_VARIANT_A" />
    <Block Type="MyObjectBuilder_CubeBlock" Subtype="MY_VARIANT_B" />
  </Blocks>
</BlockVariantGroup>
```

---

## Full Block Definition (Large Grid, Simple Block)

Key gotchas before copy-pasting:
- **`xsi:type`** on the `<Definition>` element is required. Wrong or missing → generic NullReferenceException on Init.
- **`<Icon>`** is required for any block that appears in menus — missing Icon → `ArgumentNullException` at `PostprocessRadialMenus`.
- **`<BlockPairName>`** is critical to change when copying vanilla blocks. Controls R-key grid size swap and server block limits.
- **`<BlockTopology>`** must be declared. `TriangleMesh` for normal blocks, `Cube` for deformable armor.
- **`<Public>false</Public>`** on BOTH grid sizes → `NullReferenceException` in `MyGuiControlBlockGroupInfo.RecreateDetail`.
- **`<BuildProgressModels>`** entries must be in ascending `BuildPercentUpperBound` order.
- **`Computer` component** in the component list grants ownership tracking. Omit for non-owned blocks.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <CubeBlocks>
    <Definition xsi:type="MyObjectBuilder_CubeBlockDefinition">
      <Id Type="MyObjectBuilder_CubeBlock" Subtype="MY_BLOCK_ID" />
      <DisplayName>My Block Name</DisplayName>
      <Description>What this block does</Description>
      <Icon>Textures\GUI\Icons\Cubes\MyBlock.dds</Icon>
      <CubeSize>Large</CubeSize>
      <BlockTopology>TriangleMesh</BlockTopology>
      <Size x="1" y="1" z="1" />
      <ModelOffset x="0" y="0" z="0" />
      <Model>Models\Cubes\Large\MyBlock.mwm</Model>
      <Components>
        <Component Subtype="SteelPlate" Count="20" />
        <Component Subtype="Construction" Count="10" />
        <Component Subtype="Motor" Count="2" />
        <Component Subtype="Computer" Count="1" />   <!-- grants ownership -->
        <Component Subtype="SteelPlate" Count="5" /> <!-- final stage -->
      </Components>
      <CriticalComponent Subtype="Computer" Index="0" />
      <BuildProgressModels>
        <!-- Must be ascending order -->
        <Model BuildPercentUpperBound="0.33" File="Models\Cubes\Large\MyBlock_BS1.mwm" />
        <Model BuildPercentUpperBound="0.67" File="Models\Cubes\Large\MyBlock_BS2.mwm" />
        <Model BuildPercentUpperBound="1.00" File="Models\Cubes\Large\MyBlock_BS3.mwm" />
      </BuildProgressModels>
      <MountPoints>
        <MountPoint Side="Bottom" StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Top"    StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Left"   StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Right"  StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Front"  StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Back"   StartX="0" StartY="0" EndX="1" EndY="1" />
      </MountPoints>
      <BlockPairName>MY_BLOCK_ID</BlockPairName>  <!-- change this from any vanilla source -->
      <EdgeType>Light</EdgeType>
      <PCU>25</PCU>
      <IsAirTight>false</IsAirTight>
    </Definition>
  </CubeBlocks>
</Definitions>
```

---

## Mod Adjuster Patch (Minimal Override)

Only include the fields you're changing. Mod Adjuster merges at runtime, not replaces.

### Reactor Power Override
```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <CubeBlocks>
    <Definition xsi:type="MyObjectBuilder_ReactorDefinition">
      <Id Type="MyObjectBuilder_Reactor" Subtype="TARGET_SUBTYPE" />
      <MaxPowerOutput>500</MaxPowerOutput>
    </Definition>
  </CubeBlocks>
</Definitions>
```

### Component Cost Override
```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <CubeBlocks>
    <Definition xsi:type="MyObjectBuilder_CubeBlockDefinition">
      <Id Type="MyObjectBuilder_CubeBlock" Subtype="TARGET_SUBTYPE" />
      <Components>
        <Component Subtype="SteelPlate" Count="5" />
        <Component Subtype="Construction" Count="3" />
        <Component Subtype="SteelPlate" Count="1" />
      </Components>
      <CriticalComponent Subtype="Construction" Index="0" />
    </Definition>
  </CubeBlocks>
</Definitions>
```

### Refinery Speed / Efficiency Override
```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <CubeBlocks>
    <Definition xsi:type="MyObjectBuilder_RefineryDefinition">
      <Id Type="MyObjectBuilder_Refinery" Subtype="TARGET_SUBTYPE" />
      <RefineSpeed>1.0</RefineSpeed>
      <MaterialEfficiency>0.8</MaterialEfficiency>
    </Definition>
  </CubeBlocks>
</Definitions>
```

---

## Physical Item Definition

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <PhysicalItems>
    <PhysicalItem xsi:type="MyObjectBuilder_PhysicalItemDefinition">
      <Id Type="MyObjectBuilder_Ore" Subtype="MY_ORE" />
      <DisplayName>My Ore</DisplayName>
      <Description>Description of this ore</Description>
      <Icon>Textures\GUI\Icons\component\MY_ORE.dds</Icon>
      <Size><X>0.07</X><Y>0.07</Y><Z>0.07</Z></Size>
      <Mass>1</Mass>
      <Volume>0.037</Volume>
      <Model>Models\Ores\MY_ORE.mwm</Model>
      <PhysicalMaterial>Rock</PhysicalMaterial>
      <MaxStackAmount>1000000</MaxStackAmount>
      <CanSpawnFromScreen>false</CanSpawnFromScreen>
      <CanBeDropped>true</CanBeDropped>
    </PhysicalItem>
  </PhysicalItems>
</Definitions>
```

---

## Common Crash Causes — Quick Reference

| Error | Cause | Fix |
|-------|-------|-----|
| `NullReferenceException / MyRadialMenuItemCubeBlock.Init` | BVG `<DisplayName>` missing or doesn't start with `DisplayName_` | Copy exact vanilla localization key |
| `NullReferenceException / MyBlockVariantGroup.ResolveBlocks` | BVG has no `<Blocks>` element | Add `<Blocks>` list |
| `ArgumentNullException / PostprocessRadialMenus` | Block definition has no `<Icon>` | Add Icon to block definition |
| `NullReferenceException / (AnyBlockClass).Init` | Wrong or missing `xsi:type` on `<Definition>` | Copy correct xsi:type from vanilla counterpart |
| `NullReferenceException / MyGuiControlBlockGroupInfo.RecreateDetail` | `<Public>false</Public>` on both grid sizes | Remove or set `<Public>true</Public>` |
| `MOD_CRITICAL_ERROR / Phase 4` | Invalid component SubtypeId or missing `<CriticalComponent>` | Verify component SubtypeIds exist |
| `KeyNotFoundException / MyWeaponDefinition.Init` | Ammo magazine points to non-existent ammo subtype | Check ammo SubtypeId spelling |
| `FormatException / MyBlueprintDefinitionBase.ToString` | `{` or `}` in blueprint `<DisplayName>` | Escape as `{{` and `}}` |
| `NullReferenceException / MyBlockBuilderBase.AddFastBuildModelWithSubparts` | `<MirroringBlock>` SubtypeId doesn't exist | Verify mirror block SubtypeId |
| `KeyNotFoundException / MyResourceDistributorComponent.GetTypeIndex` | Oxygen disabled + GasGenerator lacks oxygen | Enable oxygen or fix generator |

> **Always restart the game after any error that sends you to the main menu.** Not doing so causes cascading errors from corrupted game state.

---

## Block Type Reference — TypeId → xsi:type

Every `<Definition>` in a `<CubeBlocks>` file needs `xsi:type` on the element if the block is NOT a plain decorative CubeBlock. The xsi:type is formed by removing spaces from the type name and prepending `MyObjectBuilder_`.

**Key rule:** `xsi:type` is for XML deserialization only — never use it as an ID reference. `TypeId` and `xsi:type` serve different purposes and are sometimes both needed.

### Common Block Types

| TypeId | xsi:type | Conveyor | LCD Support |
|--------|----------|----------|-------------|
| `CubeBlock` | *(none needed)* | EntityComp | — |
| `BatteryBlock` | `MyObjectBuilder_BatteryBlockDefinition` | EntityComp | LCD ModFix |
| `Reactor` | `MyObjectBuilder_ReactorDefinition` | Inherent | LCD ModFix |
| `SolarPanel` | `MyObjectBuilder_SolarPanelDefinition` | EntityComp | LCD ModFix (broken) |
| `WindTurbine` | `MyObjectBuilder_WindTurbineDefinition` | EntityComp | LCD ModFix+Caution |
| `HydrogenEngine` | `MyObjectBuilder_HydrogenEngineDefinition` | Inherent | LCD ModFix+Caution |
| `OxygenGenerator` | `MyObjectBuilder_OxygenGeneratorDefinition` | Inherent | LCD ModFix |
| `OxygenTank` / Hydrogen tank | `MyObjectBuilder_GasTankDefinition` | Inherent | LCD ModFix |
| `Thrust` | `MyObjectBuilder_ThrustDefinition` | Inherent | LCD ModFix+Caution |
| `Gyro` | `MyObjectBuilder_GyroDefinition` | EntityComp | LCD ModFix |
| `CargoContainer` | `MyObjectBuilder_CargoContainerDefinition` | Inherent | — |
| `ConveyorSorter` | `MyObjectBuilder_ConveyorSorterDefinition` | Inherent | LCD ModFix |
| `Refinery` | `MyObjectBuilder_RefineryDefinition` | Inherent | LCDs |
| `Assembler` | `MyObjectBuilder_AssemblerDefinition` | Inherent | LCDs |
| `SurvivalKit` | `MyObjectBuilder_SurvivalKitDefinition` | Inherent | LCDs |
| `MedicalRoom` | `MyObjectBuilder_MedicalRoomDefinition` | Inherent | LCDs |
| `LargeGatlingTurret` | `MyObjectBuilder_LargeTurretBaseDefinition` | Inherent | LCD ModFix+Caution |
| `LargeMissileTurret` | `MyObjectBuilder_LargeTurretBaseDefinition` | Inherent | LCD ModFix |
| `InteriorTurret` | `MyObjectBuilder_LargeTurretBaseDefinition` | EntityComp | LCD ModFix+Caution |
| `SmallGatlingGun` | `MyObjectBuilder_WeaponBlockDefinition` | Inherent | LCD ModFix+Caution |
| `SmallMissileLauncher` | `MyObjectBuilder_WeaponBlockDefinition` | Inherent | LCD ModFix |
| `SmallMissileLauncherReload` | `MyObjectBuilder_WeaponBlockDefinition` | Inherent | LCD ModFix |
| `TurretControlBlock` | `MyObjectBuilder_TurretControlBlockDefinition` | EntityComp | LCDs |
| `TextPanel` | `MyObjectBuilder_TextPanelDefinition` | EntityComp | LCDs |
| `Cockpit` | `MyObjectBuilder_CockpitDefinition` | Inherent | LCDs |
| `MyProgrammableBlock` | `MyObjectBuilder_ProgrammableBlockDefinition` | EntityComp | LCDs |
| `MotorStator` | `MyObjectBuilder_MotorStatorDefinition` | Inherent | LCD ModFix |
| `MotorAdvancedStator` | `MyObjectBuilder_MotorAdvancedStatorDefinition` | Inherent | LCD ModFix |
| `MotorRotor` | *(none needed)* | EntityComp | — |
| `MotorAdvancedRotor` | *(none needed)* | Inherent | — |
| `ExtendedPistonBase` | `MyObjectBuilder_ExtendedPistonBaseDefinition` | Inherent | LCD ModFix |
| `LandingGear` | `MyObjectBuilder_LandingGearDefinition` | EntityComp | LCD ModFix |
| `Door` | `MyObjectBuilder_DoorDefinition` | EntityComp | LCD ModFix |
| `AdvancedDoor` | `MyObjectBuilder_AdvancedDoorDefinition` | EntityComp | LCD ModFix |
| `OreDetector` | `MyObjectBuilder_OreDetectorDefinition` | EntityComp | LCD ModFix |
| `Searchlight` | `MyObjectBuilder_SearchlightDefinition` | EntityComp | LCD ModFix+Caution |
| `InteriorLight` | `MyObjectBuilder_LightingBlockDefinition` | EntityComp | LCD ModFix+Caution |
| `Beacon` | `MyObjectBuilder_BeaconDefinition` | EntityComp | LCD ModFix |
| `RadioAntenna` | `MyObjectBuilder_RadioAntennaDefinition` | EntityComp | LCD ModFix |
| `GravityGenerator` | `MyObjectBuilder_GravityGeneratorDefinition` | EntityComp | LCD ModFix |
| `JumpDrive` | `MyObjectBuilder_JumpDriveDefinition` | EntityComp | LCD ModFix (broken) |
| `Projector` | `MyObjectBuilder_ProjectorDefinition` | EntityComp | LCDs |
| `Warhead` | `MyObjectBuilder_WarheadDefinition` | EntityComp | — |
| `UpgradeModule` | `MyObjectBuilder_UpgradeModuleDefinition` | EntityComp | LCD ModFix |
| `FunctionalBlock` | `MyObjectBuilder_FunctionalBlockDefinition` | EntityComp | LCD ModFix |
| `SafeZoneBlock` | `MyObjectBuilder_SafeZoneBlockDefinition` | Inherent | LCDs |
| `StoreBlock` | `MyObjectBuilder_StoreBlockDefinition` | Inherent | LCDs |

**LCD Support legend:**
- **LCDs** — native `<ScreenAreas>` support
- **LCD ModFix** — requires the "Fix LCD" workshop mod
- **LCD ModFix+Caution** — mod compatible but may break block functionality
- **LCD ModFix (broken)** — mod present but LCD doesn't work properly
- **EntityComp** — can get conveyor access via `EntityContainers.sbc` `ConveyorEndpointComponent`
- **Inherent** — conveyor connectivity built into the block type (model still needs conveyor port dummies)

> Full table at `[Steam]\steamapps\common\SpaceEngineers\Content\Data\CubeBlocks\` — copy the right file for the block type you're creating.

---

## EntityComponents — Granting Conveyor Access

Some block types need an `EntityContainers.sbc` entry to get conveyor network access (shown as "EntityComp" in the type table above).

> ⚠️ If you copy vanilla `EntityContainers.sbc` or `EntityComponents.sbc` into your mod, keep ONLY the entries you need — you'll fully overwrite vanilla defaults otherwise.
> ⚠️ Adding/removing components requires the entity to be respawned — changes don't apply to existing placed blocks.
> ⚠️ TextPanel blocks require `LcdSurfaceComponent` — if you write a custom EntityContainer for a TextPanel, include it or LCDs won't work.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <EntityContainers>
    <EntityContainer>
      <Id Type="MyObjectBuilder_CubeBlock" Subtype="MY_BLOCK_SUBTYPE" />
      <DefaultComponents>
        <Component Type="MyObjectBuilder_ConveyorEndpointComponent" />
      </DefaultComponents>
    </EntityContainer>
  </EntityContainers>
</Definitions>
```

**Key component types:**

| Component TypeId | Purpose |
|-----------------|---------|
| `MyObjectBuilder_ConveyorEndpointComponent` | Grants conveyor network access |
| `MyObjectBuilder_LcdSurfaceComponent` | Required for TextPanel LCD blocks |
| `MyObjectBuilder_InventorySpawnComponent` | Inventory that spawns items |
| `MyObjectBuilder_ModStorageComponent` | Persistent mod script data storage |
| `MyObjectBuilder_RotatingSubpartComponent` | Spins named subparts |

---

## Built-in LCD Script Names

These are the internal names for the game's built-in LCD apps. Use in `<ScreenArea Script="...">` to set a default app:

| Internal Name | Display Name |
|---------------|-------------|
| `TSS_Jukebox` | Jukebox GUI |
| `TSS_ClockAnalog` | Analog Clock |
| `TSS_ClockDigital` | Digital Clock |
| `TSS_ArtificialHorizon` | Artificial Horizon |
| `TSS_EnergyHydrogen` | Energy and Hydrogen |
| `TSS_FactionIcon` | Faction Icon |
| `TSS_Gravity` | Gravity |
| `TSS_TargetingInfo` | Targeting Info |
| `TSS_Velocity` | Velocity |
| `TSS_VendingMachine` | Vending Machine GUI |
| `TSS_Weather` | Weather |

> Setting a `Script` default does not prevent players from selecting a different app.

---

## Vanilla Component SubtypeIds

| SubtypeId | Display Name |
|-----------|-------------|
| `SteelPlate` | Steel Plate |
| `Construction` | Construction Component |
| `MetalGrid` | Metal Grid |
| `InteriorPlate` | Interior Plate |
| `SmallTube` | Small Tube |
| `LargeTube` | Large Tube |
| `Motor` | Motor |
| `Display` | Display |
| `BulletproofGlass` | Bulletproof Glass |
| `Girder` | Girder |
| `SolarCell` | Solar Cell |
| `PowerCell` | Power Cell |
| `Superconductor` | Superconductor |
| `Computer` | Computer |
| `Reactor` | Reactor Component |
| `Thrust` | Thruster Component |
| `GravityGenerator` | Gravity Component |
| `Medical` | Medical Component |
| `RadioCommunication` | Radio Component |
| `Detector` | Detector Component |
| `Explosives` | Explosives |
| `ZoneChip` | Zone Chip |

> Cross-reference `[Steam]\steamapps\common\SpaceEngineers\Content\Data\Components.sbc` for definitive list including mass/volume values.

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/SBC](https://spaceengineers.wiki.gg/wiki/Modding/Reference/SBC) — official SBC modding reference

### Internal
- [SBC_RULES.md](SBC_RULES.md) — universal SBC rules, DefinitionBase fields, override/additive behavior
- [SBC_PRODUCTION.md](SBC_PRODUCTION.md) — blueprints and production tabs for new block recipes
- [SBC_MISC.md](SBC_MISC.md) — LCD screen setup for blocks with displays

### Local
- Vanilla block SBCs: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\CubeBlocks\`
- All component definitions: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\Components.sbc`
