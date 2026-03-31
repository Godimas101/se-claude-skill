# SBC Templates & Reference — Space Engineers

Copy-paste XML templates and field references for common modding patterns. Always cross-reference vanilla SBCs at `[Steam]\steamapps\common\SpaceEngineers\Content\Data\` for exact schema.

---

## Universal SBC Rules

These apply to ALL `.sbc` files without exception:

- **File extension must be lowercase** — `.sbc` only. `.SBC` or `.Sbc` will not load.
- **Never edit vanilla game files.** Copy the target vanilla SBC into your mod's `Data/` folder, strip what you don't need, and edit your copy.
- **All `.sbc` files in `Data/` and all subfolders are loaded automatically.** File naming is irrelevant — only the XML content matters.
- **TypeId cannot be invented.** You can only use TypeIds that exist in the game engine. SubtypeId can be anything.
- **`MyObjectBuilder_` prefix is optional** in most places — the game accepts `CubeBlock` and `MyObjectBuilder_CubeBlock` interchangeably.
- **Wiki default values come from game code, not vanilla SBC files.** Vanilla SBCs may not declare a field even when it equals the default.
- **Binary cache files (`.sbcB5` / `.sbsB5`)** store pre-parsed versions of SBCs. If you change an SBC that has a cache, delete the cache or the change won't apply.

### Override vs Additive Behavior

| Behavior | Definition Types |
|----------|-----------------|
| **Override** — last-loaded mod wins, same Type+Subtype | Most definitions (CubeBlocks, BlockVariantGroups, etc.) |
| **Additive** — new entries appended to existing | BlockCategories (by `<Name>`), BlueprintClassEntries, MaterialProperties, AnimationController |
| **Merged** | Environment Definition |
| **No Override** | Decal, EmissiveColor, EmissiveColorStatePreset |

### Mod Load Order

Mods load **bottom-to-top** in the in-game mod list. The mod **highest in the list** is loaded last and wins any definition conflicts. To override another mod's definition, your mod must be higher in the list than theirs.

### Definitions That Cannot Be Modded

| File | Issue |
|------|-------|
| `RadialMenu.sbc` | Not moddable — Keen ticket #47915 |
| `GuiTextures.sbc` | Mod textures silently fail |
| `ControllerSchemes.sbc` | New entries don't appear in GUI |
| `WheelModels.sbc` | Code using it is disabled |
| `DLCs.sbc` | No modding support |
| `AssetModifiers.sbc` | Broken support |

---

## Cross-Mod Asset References

You can reference models, textures, icons, and sounds from **another Workshop mod** without copying their files — using the `..\\` path syntax.

### How It Works

Workshop mods all live in the same parent folder:
```
[Steam]\steamapps\workshop\content\244850\
  12345678\     ← mod with Workshop ID 12345678
  99887766\     ← your mod with Workshop ID 99887766
```

The `..\\` prefix navigates up one level from your mod's root to the `244850\` folder, then into the target mod by its ID:

```xml
<!-- Standard path (your own mod's assets) -->
<Icon>Textures\GUI\Icons\MyBlock.dds</Icon>
<Model>Models\Cubes\Large\MyBlock.mwm</Model>

<!-- Cross-mod reference (assets owned by Workshop mod 12345678) -->
<Icon>..\\12345678\\Textures\\GUI\\Icons\\FancyBlock.dds</Icon>
<Model>..\\12345678\\Models\\Cubes\\Large\\FancyBlock.mwm</Model>
```

Use `\\` (double backslash) — standard SE XML path separator.

Works for: `<Icon>`, `<Model>`, `<BuildProgressModel>`, `<LOD>` entries, `<ColorMetalTexture>` and other material paths, and audio `<File>` references in AudioDefinition SBCs. Confirmed to work for LOD model paths too.

### Local Testing Without Uploading

Cross-mod paths resolve relative to the **folder the mod lives in**. Workshop mods live in `244850\`. Local mods live in `%AppData%\SpaceEngineers\Mods\`.

To test locally, mirror the Workshop folder structure:

1. Copy the target mod's folder to `%AppData%\SpaceEngineers\Mods\`
2. Rename the copied folder to the Workshop ID (e.g., `12345678`)
3. Your local mod's `..\\12345678\\...` paths now resolve correctly

### Permissions and Restrictions

- Referencing assets = no copy, no permission needed
- Copying asset files into your mod = **requires express permission** from the original author
- Script (`.cs`) files cannot be referenced or patched — no method exists short of full permission
- If you use any DLC asset, you must add `<DLC>DLCName</DLC>` to your block definition

### Workshop Dependencies vs Load Order

Do **not** use the formal Workshop "Required Items" dependency system if you also need to override a definition from the target mod. The dependency is forced to load before your mod, which is usually correct for override purposes — but the system has known quirks. The safe approach:
- For **definition overrides**: link the original mod in your description, ask users to place it lower in their mod list
- For **asset references only**: load order doesn't matter; either approach works

---

## File Header

Required on all SBC files:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <!-- content here -->
</Definitions>
```

---

## DefinitionBase — Shared Fields

Every SBC definition type inherits these fields. They work the same everywhere.

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `<Id>` | | Yes | | Composite identifier — TypeId + SubtypeId |
| `<Id><TypeId>` or `Type=` attr | string | Yes | | Use element OR attribute, never both |
| `<Id><SubtypeId>` or `Subtype=` attr | string | No | `""` | Use element OR attribute, never both |
| `<DisplayName>` | string | Conditional | null | Required if object appears in menus. See format rules below. |
| `<Description>` | string | No | null | Shown in tooltips. Supports localization keys and `{0}` bind placeholders. |
| `<DescriptionArgs>` | string | No | null | Comma-separated control IDs for `{0}`, `{1}` substitution in Description |
| `<Icon>` | string | No | null | Path to `.dds` or `.png`. Declare multiple times to stack icons. |
| `<DLC>` | string | No | null | Required DLC SubtypeId(s). Declare multiple times for multiple requirements. |
| `<AvailableInSurvival>` | bool | No | `true` | Controls accessibility in survival mode |
| `<Public>` | bool | No | `true` | Controls menu visibility. Block is still buildable via blueprints/projectors when false. |
| `Enabled` (attribute) | bool | No | `true` | Set `<Definition Enabled="false">` to remove a definition after loading |

### DisplayName / Description Format Rules

- **Contains `DisplayName_`** → game looks it up in `.resx` localization files (localized string)
- **Contains `Description_`** → same localization lookup
- **Plain text** → displayed as-is, not localized
- **`{0}`, `{1}` in Description** → replaced by player's current keybind for the control IDs in `<DescriptionArgs>`
- **`{` or `}` in blueprint DisplayName** → must be escaped as `{{` and `}}` or the game throws a FormatException (bug #43912)
- **For mod-provided localized strings:** use `{LOC:DisplayName_MyKey}` syntax with a `Data/Localization/MyTexts.resx` file

### Id Shorthand vs Element Form

```xml
<!-- Element form -->
<Id>
  <TypeId>CubeBlock</TypeId>
  <SubtypeId>MyBlock</SubtypeId>
</Id>

<!-- Attribute shorthand — equivalent, preferred for compact definitions -->
<Id Type="CubeBlock" Subtype="MyBlock" />
```

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

## Blueprint (Crafting Recipe)

> ⚠️ Do not use `{` or `}` in `<DisplayName>` — escape them as `{{` and `}}` or the game throws a FormatException.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Blueprints>
    <Blueprint>
      <Id Type="MyObjectBuilder_BlueprintDefinition" Subtype="MY_RECIPE" />
      <DisplayName>My Recipe Name</DisplayName>
      <Icon>Textures\GUI\Icons\component\MY_COMPONENT.dds</Icon>
      <Prerequisites>
        <Item Amount="10" TypeId="Ore" SubtypeId="Iron" />
        <Item Amount="2" TypeId="Ore" SubtypeId="Nickel" />
      </Prerequisites>
      <Result Amount="1" TypeId="Component" SubtypeId="MY_COMPONENT" />
      <BaseProductionTimeInSeconds>5</BaseProductionTimeInSeconds>
    </Blueprint>
  </Blueprints>
</Definitions>
```

---

## Text Surface Script Registration

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <LCDScripts>
    <LCDScript>
      <Id Type="MyObjectBuilder_LCDScript" Subtype="SCRIPT_SUBTYPE_ID" />
      <DisplayName>Script Display Name</DisplayName>
      <Description>What this screen shows</Description>
    </LCDScript>
  </LCDScripts>
</Definitions>
```

The `Subtype` must exactly match the first argument of `[MyTextSurfaceScript("SCRIPT_SUBTYPE_ID", "...")]` in C#.

---

## LCD Texture Definition (Static Image on LCD)

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <LCDTextures>
    <LCDTextureDefinition>
      <Id>
        <TypeId>LCDTextureDefinition</TypeId>
        <SubtypeId>MyTexture_UniqueId</SubtypeId>
      </Id>
      <LocalizationId>My Texture Display Name</LocalizationId>
      <TexturePath>Textures\Models\MyTexture.dds</TexturePath>
      <SpritePath>Textures\Sprites\MyTexture.dds</SpritePath>
      <Selectable>true</Selectable>
    </LCDTextureDefinition>
  </LCDTextures>
</Definitions>
```

> Both `TexturePath` and `SpritePath` are required. If `SpritePath` is omitted the texture may not render correctly in scripts.

---

## Custom LCD Block (TextPanelDefinition)

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <CubeBlocks>
    <Definition xsi:type="MyObjectBuilder_TextPanelDefinition">
      <Id>
        <TypeId>TextPanel</TypeId>
        <SubtypeId>MY_LCD_BLOCK_ID</SubtypeId>
      </Id>
      <DisplayName>My LCD Block</DisplayName>
      <Description>A custom LCD panel block.</Description>
      <Icon>Textures\GUI\Icons\Cubes\MyLCDBlock.dds</Icon>
      <CubeSize>Large</CubeSize>
      <BlockTopology>TriangleMesh</BlockTopology>
      <Size x="1" y="1" z="1"/>
      <Model>Models\Cubes\large\MyLCDBlock.mwm</Model>
      <Components>
        <Component Subtype="InteriorPlate" Count="4"/>
        <Component Subtype="Construction" Count="8"/>
        <Component Subtype="Computer" Count="4"/>
        <Component Subtype="Display" Count="10"/>
        <Component Subtype="BulletproofGlass" Count="4"/>
      </Components>
      <CriticalComponent Subtype="Display" Index="0"/>
      <ScreenWidth>1</ScreenWidth>
      <ScreenHeight>1</ScreenHeight>
      <TextureResolution>512</TextureResolution>
      <ScreenAreas>
        <!-- Each ScreenArea = one IMyTextSurface surface (index 0, 1, 2...) -->
        <ScreenArea Name="ScreenArea" DisplayName="Main Screen"
                    TextureResolution="512" ScreenWidth="1" ScreenHeight="1"/>
      </ScreenAreas>
      <PanelMaterialName>ScreenArea</PanelMaterialName>
      <MaxScreenRenderDistance>100</MaxScreenRenderDistance>
      <ResourceSinkGroup>Utility</ResourceSinkGroup>
      <RequiredPowerInput>0.0001</RequiredPowerInput>
      <IsAirTight>false</IsAirTight>
      <PCU>25</PCU>
    </Definition>
  </CubeBlocks>
</Definitions>
```

> Multiple `ScreenArea` entries create a multi-surface block. Each is addressable via `IMyTextSurfaceProvider.GetSurface(index)`.

---

## Localization File (MyTexts.resx)

Place at `Data/Localization/MyTexts.resx`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<root>
  <xsd:schema id="root" xmlns="" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
              xmlns:msdata="urn:schemas-microsoft-com:xml-msdata">
    <xsd:element name="root" msdata:IsDataSet="true"/>
  </xsd:schema>
  <resheader name="resmimetype"><value>text/microsoft-resx</value></resheader>
  <resheader name="version"><value>2.0</value></resheader>
  <resheader name="reader">
    <value>System.Resources.ResXResourceReader, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>
  <resheader name="writer">
    <value>System.Resources.ResXResourceWriter, System.Windows.Forms, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089</value>
  </resheader>

  <data name="DisplayName_MyMod_BlockName" xml:space="preserve">
    <value>My Block Display Name</value>
    <comment/>
  </data>
  <data name="Description_MyMod_BlockName" xml:space="preserve">
    <value>What this block does.</value>
    <comment/>
  </data>
</root>
```

Then in your mod SBC, use the explicit `{LOC:}` wrap — mods require it:
```xml
<DisplayName>{LOC:DisplayName_MyMod_BlockName}</DisplayName>
<Description>{LOC:Description_MyMod_BlockName}</Description>
```

> **Mods vs vanilla difference:** Vanilla SBCs trigger localization lookup automatically if the string *contains* `DisplayName_` (no wrap needed). Mods **must** use `{LOC:Key}` syntax. Without it, the raw key string shows in-game instead of the translated text.

> **Known bug:** If a modded block is on the toolbar when a save is reloaded, its localization key shows instead of the translated name. This is an engine bug with no mod-side fix.

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

## BlueprintClassEntries — Non-destructive Recipe Adding

Add items to production tabs without overriding any block definitions. **Additive** — safe to use alongside other mods.

### Add a new item to an existing production tab

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlueprintClassEntries>
    <Entry Class="LargeBlocks" BlueprintSubtypeId="MY_RECIPE_SUBTYPE" />
  </BlueprintClassEntries>
</Definitions>
```

### Remove an item from a production tab

Self-closing `/>` tags cannot have children — use full open/close tags:

```xml
<BlueprintClassEntries>
  <Entry Class="SmallBlocks" BlueprintSubtypeId="SomeBlock">
    <Enabled>false</Enabled>
  </Entry>
</BlueprintClassEntries>
```

> Find the class name by checking `<BlueprintClasses>` on the target production block in `Content\Data\CubeBlocks\CubeBlocks_Production.sbc`.
> Blocks auto-generate blueprints using `TypeId/SubtypeId` — no manual blueprint needed for block recipes.

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

## SBC Definition Chains

How the main game systems link together. Knowing the chain helps you find what file to copy and modify.

| System | Chain |
|--------|-------|
| Blocks | `CubeBlock → Components → BlueprintClassEntries → BlockCategories → BlockVariantGroups` |
| Weapons | `CubeBlock → WeaponDefinition → AmmoMagazine → Ammo` |
| Production | `CubeBlock → BlueprintClass → BlueprintClassEntries → Blueprints` |
| Hand tools | `HandItems → PhysicalItems → AnimationControllers → Blueprints` |
| Loot | `ContainerTypes → ContainerType node in prefab` |

---

## Files That Cannot Be Modded

Attempting to override these causes crashes or silent failures:

| File | Status |
|------|--------|
| `RadialMenu.sbc` | **Not moddable** — Keen confirmed in support ticket #47915. Overriding it crashes the game. |
| `GuiTextures.sbc` | Broken — mod textures silently fail |
| `ControllerSchemes.sbc` | Singleplayer only; new selections don't appear in GUI |
| `WheelModels.sbc` | Code that uses it is disabled |
| `Game/DLCs.sbc` | Informational only |
| `Screens/*.gsc` | Only loads from game folder with exact filenames |

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

## BlueprintClass Definition (New Production Tab)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/BlueprintClasses -->

Creates a new tab in a production block's UI. You must also link a production block to this class via its SBC definition, and add blueprint entries to populate it.

**The three-layer system:**
1. `BlueprintClass` — defines the tab (icon, name, hover text)
2. `BlueprintClassEntries` — links blueprints to a class (additive, safe for mods)
3. `Blueprint` — defines what goes in → what comes out

### New BlueprintClass (production tab)

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlueprintClasses>
    <Class>
      <Id>
        <TypeId>BlueprintClassDefinition</TypeId>
        <SubtypeId>MyMod_CustomTab</SubtypeId>
      </Id>
      <DisplayName>My Custom Tab</DisplayName>
      <Description>Hover text shown on the tab</Description>
      <!-- All icon fields are optional but recommended -->
      <Icon>Textures\\GUI\\Icons\\SomeFile.dds</Icon>
      <HighlightIcon>Textures\\GUI\\Icons\\SomeFile.dds</HighlightIcon>
      <FocusIcon>Textures\\GUI\\Icons\\SomeFile_Focused.dds</FocusIcon>
      <InputConstraintIcon>Textures\\GUI\\Icons\\filter_ore.dds</InputConstraintIcon>
      <OutputConstraintIcon>Textures\\GUI\\Icons\\FilterComponent.dds</OutputConstraintIcon>
    </Class>
  </BlueprintClasses>
</Definitions>
```

### Add blueprint to existing class (preferred mod approach)

`BlueprintClassEntries` is **additive** — multiple mods can safely use it without conflicts.

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlueprintClassEntries>
    <!-- Add to an existing class by name -->
    <Entry Class="SimpleComponents" BlueprintSubtypeId="MY_RECIPE_SUBTYPE" />
    <!-- Block auto-generates a blueprint using TypeId/SubtypeId format -->
    <Entry Class="LargeBlocks" BlueprintSubtypeId="CubeBlock/MY_BLOCK_SUBTYPE" />
    <!-- Null subtype blocks use (null) after the slash -->
    <Entry Class="LargeBlocks" BlueprintSubtypeId="JumpDrive/(null)" />
  </BlueprintClassEntries>
</Definitions>
```

### Remove a blueprint from a class

Self-closing `<Entry />` cannot have children — use full open/close tags:

```xml
<BlueprintClassEntries>
  <Entry Class="SimpleComponents" BlueprintSubtypeId="MedicalComponent">
    <Enabled>false</Enabled>
  </Entry>
</BlueprintClassEntries>
```

### Blueprint definition (recipe)

```xml
<Blueprints>
  <Blueprint>
    <Id Type="MyObjectBuilder_BlueprintDefinition" Subtype="MY_RECIPE_SUBTYPE" />
    <DisplayName>My Recipe Name</DisplayName>
    <Icon>Textures\\GUI\\Icons\\component\\MyComponent.dds</Icon>
    <Prerequisites>
      <Item Amount="10" TypeId="Ore" SubtypeId="Iron" />
      <Item Amount="2"  TypeId="Ore" SubtypeId="Nickel" />
    </Prerequisites>
    <Results>
      <Item Amount="1" TypeId="Component" SubtypeId="MY_COMPONENT" />
    </Results>
    <BaseProductionTimeInSeconds>5</BaseProductionTimeInSeconds>
    <!-- IsPrimary=true means this recipe is used for disassembly reverse lookup -->
    <IsPrimary>false</IsPrimary>
  </Blueprint>
</Blueprints>
```

### Gotchas

- **Do NOT copy block SBC files** just to add blueprints — use `BlueprintClassEntries` only.
- **Same item in Prerequisites and Results** — crashes if that item's `<MinimalPricePerUnit>` equals `-1`.
- **Handitem definitions are not valid physical items** in blueprints — use `PhysicalItem` TypeIds.
- **Find the class name** for a production block in `Content\Data\CubeBlocks\CubeBlocks_Production.sbc` — look for `<BlueprintClasses>` on the block definition.

---

## Progression / Research Lock

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Progression -->

Locks blocks behind research. Players must build a "trigger" block to unlock a group; any member of the group unlocks it.

### Lock a block behind a research group

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ResearchBlocks>
    <!-- The block that gets locked -->
    <ResearchBlock xsi:type="ResearchBlock">
      <Id Type="CubeBlock" Subtype="MY_BLOCK_SUBTYPE" />
      <UnlockedByGroups>
        <!-- Must build any block in this group to unlock -->
        <GroupSubtype>MY_RESEARCH_GROUP</GroupSubtype>
      </UnlockedByGroups>
    </ResearchBlock>
  </ResearchBlocks>

  <ResearchGroups>
    <!-- The group — building ANY member unlocks it -->
    <ResearchGroup xsi:type="ResearchGroup">
      <Id Type="MyObjectBuilder_ResearchGroupDefinition" Subtype="MY_RESEARCH_GROUP" />
      <Members>
        <BlockId Type="CubeBlock" Subtype="TRIGGER_BLOCK_SUBTYPE" />
        <!-- Add more trigger blocks here if desired -->
      </Members>
    </ResearchGroup>
  </ResearchGroups>
</Definitions>
```

### Gotchas

- **`MyObjectBuilder_` prefix is optional** in `<Id Type>` and `<BlockId Type>` — both forms accepted.
- **Any member unlocks the group** — you cannot require ALL members, only ANY one.
- Both `<ResearchBlocks>` and `<ResearchGroups>` can be in the same `.sbc` file.
- The `xsi:type="ResearchBlock"` and `xsi:type="ResearchGroup"` are short forms (no `MyObjectBuilder_` prefix needed here).

---

## Screens / LCDs on Blocks (ScreenAreas)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Screens -->

Adds text surface(s) to a block. Each `<ScreenArea>` entry creates one `IMyTextSurface` surface, accessible via `IMyTextSurfaceProvider.GetSurface(index)` in scripts.

### ScreenArea field reference

| Attribute | Type | Required | Default | Notes |
|-----------|------|----------|---------|-------|
| `Name` | string | Yes | — | Must match a material name inside the `.mwm` model. ColorMetal texture of that material is replaced with the rendered screen. |
| `DisplayName` | string | Yes | — | Label shown in terminal UI. Can be plain text or a localization key. |
| `ScreenWidth` | int | No | 1 | Used with ScreenHeight for aspect ratio. Measure UV width directly. |
| `ScreenHeight` | int | No | 1 | Measure UV height directly from model. |
| `TextureResolution` | int | No | 512 | Suggested resolution — actual render can be larger on one axis due to aspect ratio rounding. |
| `Script` | string | No | — | Internal name of built-in LCD app to run by default (e.g. `TSS_ClockDigital`). |

### XML example

```xml
<ScreenAreas>
  <!-- Surface 0 — index used in GetSurface(0) -->
  <ScreenArea Name="ScreenMaterialName"
              DisplayName="Main Display"
              ScreenWidth="2"
              ScreenHeight="1"
              TextureResolution="512"
              Script="" />
  <!-- Surface 1 -->
  <ScreenArea Name="SideScreenMaterial"
              DisplayName="Side Panel"
              ScreenWidth="1"
              ScreenHeight="1"
              TextureResolution="256" />
</ScreenAreas>
```

### Model setup requirements (3D artist notes)

- **UV must be centered** and touch the edges on at least one axis — off-center UVs won't render correctly.
- **Add a plane behind the LCD plane** — when the block is on but the screen is blank, the screen material becomes invisible, revealing whatever is behind it.
- `_ng` and `_add` textures can reference the game's own screen material textures.

---

## Cargo Loot (ContainerTypes)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Cargo_Loot -->

Three ways to assign a loot table to inventory blocks. The loot table SubtypeId must reference a `ContainerType` definition.

### Method 1 — CargoContainer block (simplest)

Only works for blocks with `TypeId=CargoContainer`. Add directly to the prefab/grid definition:

```xml
<MyObjectBuilder_CubeBlock xsi:type="MyObjectBuilder_CargoContainer">
  <!-- other block properties -->
  <ContainerType>MY_LOOT_TABLE_SUBTYPE</ContainerType>
</MyObjectBuilder_CubeBlock>
```

### Method 2 — Any inventory block (via ComponentContainer in prefab)

Used in prefab `.sbc` files for non-CargoContainer blocks. Insert inside the block's `<ComponentContainer>`:

```xml
<ComponentContainer>
  <Components>
    <!-- preserve existing components here -->
    <ComponentData>
      <TypeId>MyRandomCargoEntityComponent</TypeId>
      <Component xsi:type="MyObjectBuilder_RandomCargoEntityComponent">
        <ContainerType>MY_LOOT_TABLE_SUBTYPE</ContainerType>
      </Component>
    </ComponentData>
  </Components>
</ComponentContainer>
```

### Method 3 — Global block-type loot (EntityContainers)

Applies loot to ALL blocks of a given TypeId. Uses two linked definitions:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">

  <!-- Step 1: Register the component on the block type -->
  <EntityContainers>
    <Container>
      <Id>
        <TypeId>OxygenTank</TypeId>
        <!-- No SubtypeId = applies to ALL OxygenTank subtypes -->
      </Id>
      <DefaultComponents>
        <Component BuilderType="MyObjectBuilder_RandomCargoEntityComponent"
                   SubtypeId="MY_LOOT_COMP_SUBTYPE"
                   ForceCreate="true" />
      </DefaultComponents>
    </Container>
  </EntityContainers>

  <!-- Step 2: Define the component pointing to the loot table -->
  <EntityComponents>
    <EntityComponent xsi:type="MyObjectBuilder_RandomCargoEntityComponentDefinition">
      <Id>
        <TypeId>RandomCargoEntityComponent</TypeId>
        <SubtypeId>MY_LOOT_COMP_SUBTYPE</SubtypeId>
      </Id>
      <ContainerType>MY_LOOT_TABLE_SUBTYPE</ContainerType>
    </EntityComponent>
  </EntityComponents>

</Definitions>
```

### Gotchas

- **Delete `.sbcB5` cache files** when testing loot changes — the binary cache shadows your edits.
- **Ensure `.sbcB5` exists before publishing** — generate it by loading the game with your mod active.
- **`OxygenTank` TypeId includes hydrogen tanks** — applying globally to `OxygenTank` affects both.
- **Don't override existing loot tables via SBC** — non-additive and goes stale with updates. Use C# mod scripts for complex loot.
- **Method 2 warning:** Do not accidentally remove existing `<ComponentData>` entries when inserting yours.
- Method 1's `<ContainerType>` is ignored if the block also has `MyRandomCargoEntityComponent` in `<ComponentContainer>` — they don't stack.

---

## Prefab vs ShipBlueprint Conversion

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Convert_between_Prefab_and_ShipBlueprint -->

Prefabs (spawnable encounters/NPC ships) and ship blueprints (player save files) use nearly identical XML but live in different lists. They cannot be used interchangeably without conversion.

### Prefab format (mod-distributed ship)

Place in `Data\Prefabs\` in your mod folder:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <Prefabs>
    <Prefab xsi:type="MyObjectBuilder_PrefabDefinition">
      <Id Type="MyObjectBuilder_PrefabDefinition" Subtype="MY_UNIQUE_PREFAB_NAME" />
      <!-- ShipBlueprint ship data goes here -->
    </Prefab>
  </Prefabs>
</Definitions>
```

### ShipBlueprint format (player blueprint)

File **must be named `bp.sbc`**. Place in `%AppData%\SpaceEngineers\Blueprints\Local\<FolderName>\bp.sbc`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ShipBlueprints>
    <ShipBlueprint xsi:type="MyObjectBuilder_ShipBlueprintDefinition">
      <!-- Prefab ship data goes here -->
    </ShipBlueprint>
  </ShipBlueprints>
</Definitions>
```

### Conversion steps

**ShipBlueprint → Prefab (for mod distribution):**
1. Change `<ShipBlueprints>` wrapper to `<Prefabs>`
2. Change `<ShipBlueprint xsi:type="...ShipBlueprintDefinition">` to `<Prefab xsi:type="...PrefabDefinition">`
3. Add `<Id Type="MyObjectBuilder_PrefabDefinition" Subtype="UNIQUE_NAME" />`
4. Place in `Data\Prefabs\` in your mod

**Prefab → ShipBlueprint (for personal use):**
1. Change `<Prefabs>` wrapper to `<ShipBlueprints>`
2. Change `<Prefab xsi:type="...PrefabDefinition">` to `<ShipBlueprint xsi:type="...ShipBlueprintDefinition">`
3. Rename file to `bp.sbc`
4. Place in `%AppData%\SpaceEngineers\Blueprints\Local\<FolderName>\bp.sbc`

### Gotcha

- SubtypeId values should be globally unique — reusing an existing prefab SubtypeId overwrites it.

---

## Finding SBC Files and Definition IDs

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Finding_SBC -->

Internal block names are often completely different from display names. "Action Relay" is a `TransponderBlock` type — you cannot guess these.

### Workflow: display name → SBC file

1. Open `Content\Data\Localization\MyTexts.resx`
2. Search for the block's display name (e.g. "Custom Turret Controller")
3. Copy the `name` attribute from the matching `<data>` element:
   ```xml
   <data name="DisplayName_TurretControlBlock" xml:space="preserve">
     <value>Custom Turret Controller</value>
   </data>
   ```
   → internal key is `DisplayName_TurretControlBlock`
4. Use Notepad++ Find in Files (or any multi-file search tool):
   - Search pattern: `DisplayName_TurretControlBlock`
   - File filter: `*.sbc`
   - Directory: `Content\Data\`
5. The matching SBC file and `<SubtypeId>` are the source definition to copy.

### Notes

- Visual names and internal names diverge frequently — always confirm via `MyTexts.resx`.
- `Content\Data\Localization\MyTexts.resx` contains **all** English display strings for vanilla blocks, items, and components.

---

## BlockCategories — Extended Reference

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/BlockCategories -->

Extends the existing Block Category section above with additional field details and positioning tricks.

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

### Tool and hotbar visibility

`<IsToolCategory>true</IsToolCategory>` is required for weapons and hand tools to appear on the character hotbar. Without it, they only show in the G-menu.

### Block pairing behavior

If a small grid block and a large grid block share the same `BlockPairName` and both are in the same `BlockCategory`, **only the large grid block** displays in the category. The small grid variant is accessible via grid-size swap (R key) but won't show as a separate entry.

### Full field reference (supplement to existing table)

| Field | Default | Notes |
|-------|---------|-------|
| `<Name>` | — | Identity key for additive merging. Must be unique for new tabs; must match exactly for appending to existing. |
| `<DisplayName>` | — | Ignored when appending to existing category. Only used on initial definition. Supports `{LOC:Key}` syntax. |
| `<IsToolCategory>` | `false` | Set `true` for weapons/tools to appear on hotbar. |
| `<StrictSearch>` | `false` | Prevents BVG members from auto-appearing in categories containing the group's first block. |
| `<SearchBlocks>` | `true` | Controls whether blocks appear in G-menu search. |
| `<ShowInCreative>` | `true` | Visibility in creative mode. |
| `<IsBlockCategory>` | `true` | Standard placeable block category. |
| `<IsShipCategory>` | `false` | Visibility in ship toolbars (cockpit, seat, RC). |
| `<IsAnimationCategory>` | `false` | Character emote categories. |

