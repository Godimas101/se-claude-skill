# SBC Miscellaneous — Space Engineers

LCD/screen setup, localization, loot tables, prefabs, and finding definition IDs. For SBC rules and shared field references, see [SBC_RULES.md](SBC_RULES.md).

> For block/item templates and the block type reference: see [SBC_BLOCKS.md](SBC_BLOCKS.md).
> For blueprints, production tabs, and progression locks: see [SBC_PRODUCTION.md](SBC_PRODUCTION.md).

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

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/SBC](https://spaceengineers.wiki.gg/wiki/Modding/Reference/SBC) — official SBC modding reference

### Internal
- [SBC_RULES.md](SBC_RULES.md) — universal SBC rules, override/additive behavior
- [SBC_BLOCKS.md](SBC_BLOCKS.md) — block definitions; required when adding LCD screens to custom blocks
- [../scripting/tss/TSS_PATTERNS.md](../scripting/tss/TSS_PATTERNS.md) — writing the C# Text Surface Script that pairs with LCD SBC registration

### Local
- Localization files: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\Localization\`
- Vanilla loot table SBCs: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\ContainerTypes.sbc`
- Vanilla prefab SBCs: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\Prefabs\`
