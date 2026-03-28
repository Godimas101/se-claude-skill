# SBC Templates — Space Engineers

Copy-paste XML templates for common modding patterns. Always cross-reference against vanilla SBCs at `D:\SteamLibrary\steamapps\common\SpaceEngineers\Content\Data\` for exact schema.

---

## File Header (Required on all SBC files)

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <!-- content here -->
</Definitions>
```

---

## Text Surface Script Registration

```xml
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

The `Subtype` must exactly match the first argument of `[MyTextSurfaceScript("SCRIPT_SUBTYPE_ID", "...")]` in the C# attribute.

---

## Mod Adjuster Patch (Minimal Override)

Only include the fields you're changing. Leave everything else out — the game merges, not replaces.

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

## Full Block Definition (Large Grid, Simple Block)

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
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
        <!-- Critical component last (or use CriticalComponent tag) -->
        <Component Subtype="SteelPlate" Count="5" />
      </Components>
      <CriticalComponent Subtype="Motor" Index="0" />
      <BuildProgressModels>
        <Model BuildPercentUpperBound="0.33" File="Models\Cubes\Large\MyBlock_BS1.mwm" />
        <Model BuildPercentUpperBound="0.67" File="Models\Cubes\Large\MyBlock_BS2.mwm" />
        <Model BuildPercentUpperBound="1.00" File="Models\Cubes\Large\MyBlock_BS3.mwm" />
      </BuildProgressModels>
      <MountPoints>
        <MountPoint Side="Bottom" StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Top" StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Left" StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Right" StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Front" StartX="0" StartY="0" EndX="1" EndY="1" />
        <MountPoint Side="Back" StartX="0" StartY="0" EndX="1" EndY="1" />
      </MountPoints>
      <BlockPairName>MY_BLOCK_ID</BlockPairName>
      <EdgeType>Light</EdgeType>
      <PCU>25</PCU>
      <IsAirTight>false</IsAirTight>
    </Definition>
  </CubeBlocks>
</Definitions>
```

---

## Physical Item Definition

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <PhysicalItems>
    <PhysicalItem xsi:type="MyObjectBuilder_PhysicalItemDefinition">
      <Id Type="MyObjectBuilder_Ore" Subtype="MY_ORE" />
      <DisplayName>My Ore</DisplayName>
      <Description>Description of this ore</Description>
      <Icon>Textures\GUI\Icons\component\MY_ORE.dds</Icon>
      <Size>
        <X>0.07</X><Y>0.07</Y><Z>0.07</Z>
      </Size>
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

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
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

## Block Category (G-menu filter tab)

Two distinct use cases — choose the right one:

### A) Extend an existing vanilla category (add blocks to a vanilla tab)

Use the **full vanilla `<Name>`** — SE merges items by Name. Omit SubtypeId (use empty tag) to avoid conflicting with the vanilla definition.

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <CategoryClasses>
    <Category xsi:type="MyObjectBuilder_GuiBlockCategoryDefinition">
      <Id>
        <TypeId>GuiBlockCategoryDefinition</TypeId>
        <SubtypeId/>
      </Id>
      <DisplayName>DisplayName_Category_Weapons</DisplayName>
      <Name>Section1_Position3_Weapons</Name>
      <ItemIds>
        <string>LargeMissileTurret/MY_TURRET_SUBTYPE</string>
        <string>SmallMissileLauncher/MY_LAUNCHER_SUBTYPE</string>
      </ItemIds>
    </Category>
  </CategoryClasses>
</Definitions>
```

**Key vanilla category Names** (use the full name exactly):

| What it shows in G-menu | `<Name>` value |
|-------------------------|----------------|
| Weapons (turrets, guns) | `Section1_Position3_Weapons` |
| Decorative (shelves, props) | `Section1_Position3_Decorative` |
| All large grid blocks | `Section1_Position1_LargeBlocks` |
| All small grid blocks | `Section1_Position1_SmallBlocks` |
| Propulsion (thrusters) | `Section1_Position3_Propulsion` |
| Power | `Section1_Position3_Power` |
| Production | `Section1_Position3_Production` |

> **Do NOT use short names** like `Weapons` or `LargeBlocks` — those create a NEW separate tab with the same label, not merge with vanilla.

### B) Create a new custom category tab

Only use this for blocks that have no vanilla home. Use a unique Name so it doesn't collide.

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <CategoryClasses>
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
  </CategoryClasses>
</Definitions>
```

> `ItemIds` format is `TypeId/SubtypeId` — NOT `MyObjectBuilder_TypeId/SubtypeId`.

---

## Block Variant Group (hotbar scroll group)

Groups multiple blocks into one hotbar slot; mouse wheel scrolls through variants.

### A) Extend an existing vanilla variant group (add blocks to a vanilla scroll group)

Use the matching vanilla Subtype. Only include `<Id>` and `<Blocks>` — omit Icon/DisplayName/Description to preserve vanilla metadata. SE appends your blocks to the existing group.

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlockVariantGroups>
    <BlockVariantGroup>
      <Id Type="MyObjectBuilder_BlockVariantGroup" Subtype="TurretGroup" />
      <Blocks>
        <Block Type="MyObjectBuilder_LargeMissileTurret" Subtype="MY_TURRET_SUBTYPE" />
      </Blocks>
    </BlockVariantGroup>
  </BlockVariantGroups>
</Definitions>
```

**Key vanilla variant group Subtypes:**

| What it groups | `Subtype` |
|----------------|-----------|
| All turrets (gatling, missile, calibre, interior) | `TurretGroup` |
| Fixed weapons (launchers, railguns, autocannons) | `ShipWeaponStaticGroup` |
| Turret control blocks | `TurretControlGroup` |
| Batteries | `BatteryGroup` |
| Solar panels | `SolarGroup` |
| Wind turbines | `WindTurbineGroup` |
| Advanced rotors (stators + rotor parts) | `RotorGroup` |
| Hinges (stator bases + hinge heads) | `HingeGroup` |
| Storage shelves | `StorageShelves` ⚠️ **DO NOT EXTEND** — crashes game (see note below) |

> Find more in `D:\SteamLibrary\steamapps\common\SpaceEngineers\Content\Data\BlockVariantGroups.sbc`.

> ⚠️ **StorageShelves known crash bug:** Extending the `StorageShelves` group causes a `NullReferenceException` in `MyRadialMenuItemCubeBlock.Init` and aborts session load. Root cause: the vanilla `StorageShelves` definition uses `<DisplayName>` (a localization string key) but the RadialMenu system requires `<DisplayNameEnum>`, which vanilla never set. Adding any block to the group triggers the RadialMenu to process it and hit the null. Workaround: add the block to a `BlockCategories.sbc` entry instead — players can find it in the tab, but won't be able to scroll-cycle to it from a shelf.

### B) Create a new custom variant group

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlockVariantGroups>
    <BlockVariantGroup>
      <Id Type="MyObjectBuilder_BlockVariantGroup" Subtype="MyMod_UniqueGroupName" />
      <Icon>Textures\GUI\Icons\Cubes\MyIcon.dds</Icon>
      <DisplayName>My Block Group</DisplayName>
      <Description>Scroll to cycle through variants</Description>
      <Blocks>
        <Block Type="MyObjectBuilder_CubeBlock" Subtype="MY_VARIANT_A" />
        <Block Type="MyObjectBuilder_CubeBlock" Subtype="MY_VARIANT_B" />
        <Block Type="MyObjectBuilder_CubeBlock" Subtype="MY_VARIANT_C" />
      </Blocks>
    </BlockVariantGroup>
  </BlockVariantGroups>
</Definitions>
```

> `Block Type` uses the `MyObjectBuilder_` prefix format (e.g. `MyObjectBuilder_LargeMissileTurret`), unlike `ItemIds` in categories which use the bare TypeId.

---

## LCD Texture Definition (Static Image on LCD)

Registers a custom `.dds` image as a selectable LCD texture (shown in the LCD texture picker in-game). Requires both `TexturePath` (applied to the block model) and `SpritePath` (used in sprite rendering). `LocalizationId` is the display name in the picker. `Selectable` controls whether it appears in the picker UI.

```xml
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

> Both `TexturePath` and `SpritePath` are required. If `SpritePath` is omitted the texture may not render correctly in scripts. The `SubtypeId` is also usable as a display name if `LocalizationId` is absent (older mods did this).

---

## Custom LCD Block (TextPanelDefinition)

Defines a new block that has LCD screen surfaces. Key fields beyond standard block definitions:
- `ScreenAreas` — defines named surfaces (each gets its own script/texture slot)
- `TextureResolution` — render resolution (512, 1024, 2048)
- `ScreenWidth/Height` — aspect ratio for the surface
- `MaxScreenRenderDistance` — distance at which LCD stops rendering (performance)

```xml
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
      <!-- Mount points, build progress models, etc. as normal -->
      <!-- LCD-specific fields: -->
      <ScreenWidth>1</ScreenWidth>    <!-- Aspect ratio width -->
      <ScreenHeight>1</ScreenHeight>  <!-- Aspect ratio height -->
      <TextureResolution>512</TextureResolution>
      <ScreenAreas>
        <!-- Each ScreenArea = one IMyTextSurface surface index (0, 1, 2...) -->
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

> Multiple `ScreenArea` entries create a multi-surface block. Each surface is independently addressable via `IMyTextSurfaceProvider.GetSurface(index)`.

---

## Localization File (MyTexts.resx)

For blocks using `{LOC:Key}` display names — requires a `Data/Localization/MyTexts.resx` file:

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

Then in the SBC:
```xml
<DisplayName>{LOC:DisplayName_MyMod_BlockName}</DisplayName>
<Description>{LOC:Description_MyMod_BlockName}</Description>
```

---

## Common SubtypeId Reference (Vanilla Components)

Use these exact SubtypeIds when writing component costs — typos silently fail.

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

> Cross-reference against `D:\SteamLibrary\steamapps\common\SpaceEngineers\Content\Data\Components.sbc` for definitive list including mass/volume values.
