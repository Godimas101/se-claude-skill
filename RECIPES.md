# Recipes — Space Engineers Modding

End-to-end walkthroughs for complete, self-contained modding tasks. Each recipe is a checklist you follow top-to-bottom.

---

## Recipe: LCD App Mod Script (C#)

<!-- source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script -->

A compiled C# mod that registers a new app in the LCD screen list. Players select it from the terminal just like vanilla apps (Energy, Inventory, etc.).

### Prerequisites

- C# basics
- MDK2 installed: `dotnet new install Mal.Mdk2.ScriptTemplates`
- IDE with C#/.NET and NuGet support (VS Code + C# Dev Kit, Visual Studio, or Rider)

### Step-by-step

**1. Create project**

In your IDE, create a new project using the "Mod (MDK2)" template. **Do NOT create the project inside your local mods folder** — MDK2 deploys to it automatically on build.

**2. Create your LCD script class**

Add a new `.cs` file. Replace the namespace/class names and the attribute strings with your own.

```csharp
using System;
using Sandbox.Game.GameSystems.TextSurfaceScripts;
using Sandbox.ModAPI;
using VRage.Game;
using VRage.Game.GUI.TextPanel;
using VRage.Game.ModAPI;
using VRage.ModAPI;
using VRage.Utils;
using VRageMath;

namespace YourName.YourModName
{
    // First string: internal ID (must be unique across all mods)
    // Second string: display name shown to players in the terminal
    [MyTextSurfaceScript("YourAppInternalName", "Your App Display Name")]
    public class YourLCDApp : MyTSSCommon
    {
        // How often Run() is called: Update1, Update10, Update100, or None
        public override ScriptUpdate NeedsUpdate { get; } = ScriptUpdate.Update10;

        readonly IMyTerminalBlock TerminalBlock;

        public YourLCDApp(IMyTextSurface surface, IMyCubeBlock block, Vector2 size)
            : base(surface, block, size)
        {
            TerminalBlock = (IMyTerminalBlock)block;
            // Required: prevents memory leak when the block is destroyed
            TerminalBlock.OnMarkForClose += BlockDeleted;
        }

        public override void Dispose()
        {
            base.Dispose();
            TerminalBlock.OnMarkForClose -= BlockDeleted;
        }

        void BlockDeleted(IMyEntity _) => Dispose();

        public override void Run()
        {
            base.Run();

            using (var frame = Surface.DrawFrame())
            {
                frame.Add(new MySprite
                {
                    Type = SpriteType.TEXT,
                    Data = "Hello World",
                    Alignment = TextAlignment.CENTER,
                    FontId = MyFontEnum.White,
                    Color = null,      // null = use surface's script foreground color
                    Position = null,   // null = centered
                    Size = null,
                    RotationOrScale = 1f,
                });
            }
        }
    }
}
```

**3. Build**

- Visual Studio: Build → Build Solution
- VS Code: `Ctrl+Shift+B`
- MDK2 auto-deploys the built mod to your local mods folder

**4. Test in-game**

1. Launch SE → create or open an **offline** world (local mods don't work in online worlds)
2. World Options → Mods → find your mod in the Local tab (house icon)
3. Add it, start the world
4. Place a block with an LCD surface (battery, cockpit, dedicated LCD panel, etc.)
5. Open the block terminal → find your app near the end of the LCD app list by its display name
6. Select it — "Hello World" should appear

### Checklist

- [ ] `[MyTextSurfaceScript]` attribute — internal name unique, display name human-readable
- [ ] `NeedsUpdate` set to appropriate frequency (`Update10` = ~6 times/sec)
- [ ] `OnMarkForClose` subscribed in constructor, unsubscribed in `Dispose()`
- [ ] Test in **offline** world
- [ ] Check F11 console for compile errors
- [ ] Check `%AppData%\SpaceEngineers\*.log` for runtime errors

### Common mistakes

| Mistake | Result |
|---------|--------|
| Project created inside local mods folder | MDK2 deploy conflicts, double-writing |
| Duplicate internal name across mods | One silently wins, other app doesn't appear |
| Missing `OnMarkForClose` unsubscribe | Memory leak; crashes over time when blocks are destroyed |
| Testing in online world | Local mods rejected; app doesn't appear |
| `using Sandbox.ModAPI.Ingame;` at top of file | Ambiguous reference compile errors |

### Key inherited members from `MyTSSCommon`

| Member | Type | Description |
|--------|------|-------------|
| `Surface` | `IMyTextSurface` | The LCD surface being drawn to |
| `m_surface` | `IMyTextSurface` | Same surface (alternate accessor) |
| `m_block` | `IMyCubeBlock` | The owning block |
| `m_halfSize` | `Vector2` | Center point of the surface (useful for centering) |
| `m_fontId` | `string` | Currently selected font ID |
| `m_fontScale` | `float` | Auto-calculated font scale |
| `m_foregroundColor` | `Color` | Surface's configured script foreground color |

For more drawing patterns (progress bars, lines, charts) see [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md).

---

## Recipe: Armor Block Mod (SBC + Asset)

<!-- source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/Armor_Block -->

A full custom armor block shape. Requires Blender + SEUT for model export. Result: a new block that appears in the G-menu, is buildable, colorable, skinnable, and has proper build stages.

### Prerequisites

- SEUT (Space Engineers Utilities) Blender plugin installed
- Completed basic SEUT setup (see SEUT installation guide on wiki)
- VS Code for SBC editing

### Naming convention

SEUT uses the SubtypeId to auto-generate file paths. Follow this format:

```
[YourNick]_[GridSize]_[ArmorType]_[ShapeName]
```

Examples: `AQD_LG_LA_SlopeCorner`, `MyMod_SG_HA_Panel`

- Grid size: `LG` (large grid) or `SG` (small grid)
- Armor type: `LA` (light armor) or `HA` (heavy armor)

### Phase 1 — Blender/SEUT model

**1. Create .blend file, configure SEUT**
- Set SubtypeId using the naming convention above
- Set Mod folder to your mod directory
- SEUT auto-sets the Model folder based on grid size

**2. Build the main model**
- Model your armor shape in Blender
- Apply armor texture from SEUT's Asset Browser (Armor section)
- Use light/large-grid material variants for the base shape
- Place mesh in the `Main` collection

**3. Export (first pass)**
- Export Current Scene as Large Grid (or Small Grid)
- Generates: `[SubtypeId].mwm` + a starter `.sbc` file
- Test in-game immediately: search by SubtypeId in the G-menu, verify coloring/skinning works

**4. Add mountpoints**
- Follow SEUT Mountpoints tutorial
- Defines which faces can connect to adjacent blocks

**5. Set up mirroring**
- Follow SEUT Mirroring tutorial
- Enables symmetry placement across X/Y/Z axes

**6. Create collision model**
- Copy main model as base
- Remove all materials
- Place in `Collision` collection
- Simplify geometry for performance

**7. Build stages**

*BS1 collection (initial placement — frame):*
- Frame version of the block using Construction material
- Use Offset + Solidify + Bevel modifiers

*BS2 collection (partial weld):*
- Combine BS1 frame with a scaled-down main model
- Add more stages (BS3, etc.) for more granularity if desired

**8. LOD models** (in `BS_LOD` collection)

| LOD level | Detail | Visible from |
|-----------|--------|-------------|
| LOD1 | 50–80% | ~25m |
| LOD2 | 20–40% | ~50m |
| LOD3 | 5–10% | ~100m |

Set LOD Distance in the SEUT properties panel.

**9. Generate icon**
- Use SEUT's Icon Render Mode
- Adjust angle with Camera View dials
- Set render path to `[YourMod]\Textures\`
- Auto-saves to mod directory

**10. Export (final pass)**
- Export Current Scene
- SBC export mode: "Update" — updates the existing SBC with mountpoints, mirroring data, and icon path

### Phase 2 — SBC files

**File: `Data\CubeBlocks\[SubtypeId].sbc`**

Start from SEUT's generated SBC. Merge with the equivalent vanilla block definition (same shape) from `[SE install]\Content\Data\CubeBlocks\`. Key fields:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <CubeBlocks>
    <Definition xsi:type="MyObjectBuilder_CubeBlockDefinition">
      <Id>
        <TypeId>CubeBlock</TypeId>
        <SubtypeId>YourNick_LG_LA_YourShape</SubtypeId>
      </Id>
      <DisplayName>Your Block Name</DisplayName>
      <Icon>Textures\YourNick_LG_LA_YourShape.png</Icon>
      <CubeSize>Large</CubeSize>
      <BlockTopology>TriangleList</BlockTopology>
      <Size x="1" y="1" z="1" />
      <ModelOffset x="0" y="0" z="0" />
      <Model>Models\Cubes\Large\YourNick_LG_LA_YourShape.mwm</Model>
      <UseNeighbourCubes>false</UseNeighbourCubes>
      <DeformationRatio>0</DeformationRatio>
      <BuildProgressModels>
        <Model BuildPercentUpperBound="0.33"
               File="Models\Cubes\Large\YourNick_LG_LA_YourShape_BS1.mwm" />
        <Model BuildPercentUpperBound="0.66"
               File="Models\Cubes\Large\YourNick_LG_LA_YourShape_BS2.mwm" />
        <Model BuildPercentUpperBound="1.00"
               File="Models\Cubes\Large\YourNick_LG_LA_YourShape.mwm" />
      </BuildProgressModels>
      <BlockPairName>YourNick_LG_LA_YourShape</BlockPairName>
      <MirroringY>Z</MirroringY>
      <MirroringZ>Y</MirroringZ>
      <EdgeType>Light</EdgeType>
      <BuildTimeSeconds>6</BuildTimeSeconds>
      <DisassembleRatio>2.5</DisassembleRatio>
      <PCU>1</PCU>
      <IsAirTight>false</IsAirTight>
      <Components>
        <Component Subtype="SteelPlate" Count="5" />
        <Component Subtype="Construction" Count="1" />
      </Components>
      <CriticalComponent Subtype="SteelPlate" Index="0" />
      <MountPoints>
        <!-- Auto-generated by SEUT from mountpoint setup -->
      </MountPoints>
    </Definition>
  </CubeBlocks>
</Definitions>
```

Do NOT include `<CubeDefinition>` or `<Skeleton>` elements — those are for vanilla deformable armor only.

**File: `Data\CubeBlocks\BlockCategories.sbc`**

Adds the block to G-menu tabs. BlockCategories is **additive** — you only need `<Name>` and the item entry:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <CategoryClasses>
    <!-- Large Blocks tab -->
    <Category xsi:type="MyObjectBuilder_GuiBlockCategoryDefinition">
      <Id Type="GuiBlockCategoryDefinition" Subtype="" />
      <Name>Section1_Position1_LargeBlocks</Name>
      <ItemIds>
        <string>CubeBlock/YourNick_LG_LA_YourShape</string>
      </ItemIds>
    </Category>
    <!-- Armor Blocks sub-tab -->
    <Category xsi:type="MyObjectBuilder_GuiBlockCategoryDefinition">
      <Id Type="GuiBlockCategoryDefinition" Subtype="" />
      <Name>Armorblocks</Name>
      <ItemIds>
        <string>CubeBlock/YourNick_LG_LA_YourShape</string>
      </ItemIds>
    </Category>
  </CategoryClasses>
</Definitions>
```

**File: `Data\BluePrintClassEntries.sbc`**

Makes the block buildable via Assembler. Copy `BluePrintClasses.sbc` from the game's `Content\Data\` folder, rename it, delete all `BluePrintClass` entries, keep only one `BluePrintClassEntry`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <BlueprintClassEntries>
    <BlueprintClassEntry>
      <Class>LargeBlocks</Class>
      <BlueprintSubtypeId>CubeBlock/YourNick_LG_LA_YourShape</BlueprintSubtypeId>
    </BlueprintClassEntry>
  </BlueprintClassEntries>
</Definitions>
```

Use `SmallBlocks` for small-grid blocks.

**File: `Data\ResearchBlocks.sbc`**

Locks the block behind the research system (analyzed via Analyzer block). Copy vanilla `ResearchBlocks.sbc`, delete all but one entry, modify:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <ResearchBlocks>
    <ResearchBlock>
      <Id>
        <TypeId>ResearchBlock</TypeId>
        <SubtypeId>Armor</SubtypeId>
      </Id>
      <AnalyzedEntity Type="CubeBlocks" Subtype="YourNick_LG_LA_YourShape" />
      <UnlockedByGroups>
        <Group>1</Group>
      </UnlockedByGroups>
    </ResearchBlock>
  </ResearchBlocks>
</Definitions>
```

**Optional: `Data\Localization\[LanguageCode]\[LanguageCode].resx`**

Add a display name key if you want proper localization. See: `spaceengineers.wiki.gg/wiki/Modding/Tutorials/Localization`

### Phase 3 — Test checklist

**G-menu:**
- [ ] Block appears in Large Blocks category tab
- [ ] Block appears in Armor Blocks sub-tab
- [ ] Block appears in assembler Production tab → Blocks
- [ ] Block appears in variant group scroll (if you added a BlockVariantGroup entry)

**Functional:**
- [ ] Mountpoints connect correctly to adjacent blocks on all sides
- [ ] Mirroring works across X, Y, Z axes
- [ ] Block rotates correctly when placed mirrored
- [ ] BS1 (frame) shows on initial placement
- [ ] BS2 (partial weld) shows mid-weld
- [ ] Fully welded shows main model
- [ ] Collision prevents building through block
- [ ] LOD levels switch at correct distances (test via Model Quality graphics setting)
- [ ] Block is colorable (paint gun works)
- [ ] Block accepts skins

### Known limitations

- Custom armor shapes **cannot support armor deformation** — hits don't dent or deform the mesh
- Connected textures across adjacent blocks **do not work** for modded armor — only vanilla blocks get seam-blending textures
- Model changes require a **full game restart** — a simple world reload is not enough

### Key reference

Always copy the vanilla block definition of the same shape as your starting template. The full vanilla SBCs are at:
```
[Steam]\steamapps\common\SpaceEngineers\Content\Data\CubeBlocks\
```

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/Armor_Block](https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/Armor_Block) — official armor block recipe
- [spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script](https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script) — official LCD App Script recipe

### Internal
- [sbc/SBC_RULES.md](sbc/SBC_RULES.md) — universal SBC rules and DefinitionBase fields
- [sbc/SBC_BLOCKS.md](sbc/SBC_BLOCKS.md) — block and item definition templates
- [scripting/CSHARP_PATTERNS.md](scripting/CSHARP_PATTERNS.md) — C# project setup, class structure, performance rules
- [scripting/TSS_PATTERNS.md](scripting/TSS_PATTERNS.md) — TSS drawing patterns used in the LCD App recipe
- [ASSETS.md](ASSETS.md) — full asset pipeline for the armor block model steps

### Local
- Vanilla block SBCs: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\CubeBlocks\`
