# Space Engineers Asset Pipeline

Reference for shipping assets from scratch: models, textures, collisions, materials, and block configuration.

Source pages fetched: spaceengineers.wiki.gg/wiki/Modding/Reference/Materials, /Reference/Models, /Tutorials/Tools/SEUT/*, /Tutorials/Recipes/Armor_Block, and spaceengineersgame.com/modding-guides/moddable-collision-models/. The originally requested /Tutorials/Models, /Textures, /VoxelTextures, /Audio, /Animations, /LCDTextures, /MWMBuilder, /Havok URLs all returned 404 — content has been reorganized under the paths above.

---

## Required Tools

For all asset work:

| Tool | Purpose | Source |
|------|---------|--------|
| Blender 4.0+ | Modeling, UV, export | blender.org |
| SEUT (Space Engineers Utilities) | Blender addon that drives the full pipeline | spaceengineers.wiki.gg/wiki/Modding/Tools/Space_Engineers_Utilities |
| Space Engineers ModSDK | MwmBuilder.exe, reference assets | Steam Tools library |
| Havok Content Tools v2012.2.0 | Physics collision export (.hkt) | Separate download (referenced in SEUT setup) |
| Microsoft .NET Framework 3.5 | MwmBuilder dependency | Windows optional feature |
| Visual C++ Redistributable 2012 | Havok Content Tools dependency | Microsoft |
| texconv | DDS texture conversion | DirectXTex (Microsoft) |
| Universal Image Converter | GUI wrapper for DDS conversion (all 4 channel types, batch) | [GitHub](https://github.com/Godimas101/mods/tree/main/space-engineers-mods/Tools/universal-image-converter) |

SEUT installation path: Blender Preferences → Add-ons → Install → select `space_engineers_utilities_***.zip`.

After installation, configure:
- **Game Directory**: path to SpaceEngineers install (e.g. `[Steam]\steamapps\common\SpaceEngineers\`)
- **Asset Directory**: 15 GB+ free space, must NOT be inside ModSDK or game folders
- **Havok**: point to `hctStandAloneFilterManager.exe`
- Click "Update Textures from Game Files" — runs 30+ min, monitor via Blender System Console

---

## Model Pipeline Overview

What goes in → what comes out:

```
.blend (Blender source)
  └─ SEUT export
       ├─ .fbx  (mesh, dummies, animations)
       ├─ .hkt  (Havok collision data)
       └─ .xml  (material-to-texture links, LOD distances)
            └─ MwmBuilder.exe
                 └─ .mwm  (final game-ready model)
```

MWM is a binary format — **you cannot decompile it back to FBX**. Keep your .blend originals.

---

## Folder Structure (Mod Root)

```
YourMod/
├── Data/
│   └── CubeBlocks/
│       └── MyBlock.sbc
├── Models/
│   └── LargeGrid/
│       ├── MyBlock.mwm
│       ├── MyBlock_LOD1.mwm
│       └── MyBlock_LOD2.mwm
└── Textures/
    └── Models/
        └── MyBlock_cm.dds
        └── MyBlock_ng.dds
        └── MyBlock_add.dds
```

Critical: The game finds the mod root by searching the file path left-to-right for the first occurrence of "models" (case-insensitive). The `Models/` folder must exist and contain at least one .mwm file.

---

## LOD Naming and Setup

LOD0 = main model file (e.g. `MyBlock.mwm`). LODs are separate files named with suffix:

- `MyBlock_LOD1.mwm` — 50–80% detail, shown from ~25 m
- `MyBlock_LOD2.mwm` — 20–40% detail, shown from ~50 m
- `MyBlock_LOD3.mwm` — 5–10% detail, shown from ~100 m

LOD distances are set in the .xml file (relative paths from mod root) and influenced by graphics settings, screen resolution, and FOV. The baseline calibration is 1080p / 70° FOV / high quality.

Rules for LOD files:
- Do NOT include dummies, collisions, or nested LODs in LOD1+
- Moving .mwm files breaks LOD path references — update the .xml if you relocate
- High graphics quality renders LOD0 only; medium/low cap at LOD1

For armor blocks, a `BS_LOD` collection in Blender applies to all build stages unless per-stage variants are created.

---

## Dummies (Empties) Naming

Dummies are named transforms in LOD0 that the game reads for functional positions (conveyor ports, interactive zones, tool areas, subparts). They perform no function on their own — naming determines behavior.

- Subparts: prefix with `subpart_` in the parent model; game strips this prefix when referencing
- Conveyor, terminal, screen, etc.: use SEUT's "Add Highlight Empty" for correct naming
- Dummies are loaded from LOD0 only; game systems don't reliably access dummies in LOD1+

Subparts support their own LODs, dummies, and nested subparts. CPU-animated subparts run on every tick regardless of distance — avoid overusing them on dedicated servers.

---

## Textures

### Channel Packing (4 texture maps)

**_cm — Color / Metalness**
- RGB: base color
- Alpha: metalness (affects light reflection)
- DDS format: `BC7_UNORM_SRGB`
- Command:
  ```
  texconv [input] -ft DDS -f BC7_UNORM_SRGB -sepalpha -sRGB -y -o [output_dir]
  ```

**_ng — Normal / Gloss**
- RGB: normal map
- Alpha: gloss (influences reflection sharpness together with metalness)
- DDS format: `BC7_UNORM` (linear, no sRGB)
- Set Color Space to `Non-Color` in Blender
- Command:
  ```
  texconv [input] -ft DDS -f BC7_UNORM -sepalpha -y -o [output_dir]
  ```

**_add — Ambient Occlusion / Emissive / Paintability**
- Red: ambient occlusion (use full white if unused)
- Green: emissiveness (glow intensity; color comes from CM texture)
- Blue: deprecated/unused
- Alpha: paintability (how strongly paint overlays apply)
- DDS format: `BC7_UNORM_SRGB` with dithering
- Command:
  ```
  texconv [input] -ft DDS -f BC7_UNORM_SRGB -if POINT_DITHER_DIFFUSION -sepalpha -sRGB -y -o [output_dir]
  ```

**_alphamask — Opacity Mask**
- RGB: opacity mask (white = opaque, black = transparent)
- Alpha: unused
- DDS format: `BC7_UNORM` with dithering
- Command:
  ```
  texconv [input] -ft DDS -f BC7_UNORM -if POINT_DITHER_DIFFUSION -y -o [output_dir]
  ```

### Transparent Materials (_ca texture)

Used with GLASS, HOLO, or SHIELD technique:

**_ca — Color / Alpha**
- RGB: base color
- Alpha: transparency (white = opaque, black = transparent)
- DDS format: `BC7_UNORM` with premultiplied alpha (`-pmalpha`)
- Premultiplied alpha prevents edge fringing artifacts

### Resolution Rules
- Must be powers of 2: 4, 8, 16, 32 … 4096
- Width and height do not need to match
- Particle textures: exactly 8192×8192 with mipmaps; filename prefix `Atlas_` recommended

### Source Workflow
1. Work in TIF format in Blender (SEUT can display these)
2. Place files in `[SEUT Assets]\Textures\Custom\[your name]\` (any path containing `\Textures\` works)
3. SEUT auto-converts TIF → DDS on export (compares modification dates to skip unchanged files)
4. Deploy the final DDS files into your mod's `Textures/` folder — game does not use TIF

**Prefer the Universal Image Converter** ([GitHub](https://github.com/Godimas101/mods/tree/main/space-engineers-mods/Tools/universal-image-converter)) over raw `texconv` commands — it handles all 4 channel types with correct flags, supports batch conversion, and is purpose-built for SE modding.

### Key Gotcha
Blender's material node tree is irrelevant to in-game appearance. The game only reads texture files and material XML parameters. The node tree is purely for Blender viewport preview.

---

## Materials

### Shader Techniques

| Technique | Use |
|-----------|-----|
| MESH | Standard opaque surface |
| DECAL | Decal overlays |
| DECAL_CUTOUT | Decal with alpha cutout |
| ALPHA_MASKED | Uses _alphamask texture |
| FOLIAGE | Wind-animated vegetation |
| GLASS | Transparent, refs TransparentMaterials.sbc |
| HOLO | Holographic, refs TransparentMaterials.sbc |
| SHIELD | Shield effect, refs TransparentMaterials.sbc |

GLASS/HOLO/SHIELD do not reference model textures directly — they use definitions in `TransparentMaterials.sbc`.

### Other Parameters

| Parameter | Purpose |
|-----------|---------|
| Facing | Camera alignment: None, Vertical, Full, Imposter |
| Wind Scale | Displacement magnitude for foliage animation |
| Wind Frequency | Speed for foliage animation |

### Material Library Workflow (SEUT)

1. Create a .blend file with sphere display objects, one per material
2. Build materials using SEUT's "Create SEUT Material" button in Shader Editor
3. Right-click material in list → "Mark as Asset"
4. In Asset Browser: set author, add tags, mark as `Vanilla` or `DLC`
5. Organize into catalogs under `Custom\[your name]\`
6. Save .blend to `[SEUT Assets]\Materials\`
7. Click "Export Materials" in Export Panel to generate XML files alongside .blend

When reusing library materials in working files, always set Asset Browser to **Link** mode (not Copy/Append) to keep a single source reference.

Critical: always include the DDS texture files for any custom materials in the final mod folder — the material library .blend doesn't ship those automatically.

---

## Collision Models (Havok)

### Constraints
- Maximum 10 collision objects per block total (5 recommended per cube)
- All collision shapes must be **convex** — concave geometry gets auto-filled into convex volumes
- All collision objects must stay within the bounding box, or the game may revert to default box collisions
- Rigid body shapes cannot be rotated — they have a fixed facing

### Performance Ranking (best to worst)
`Sphere` > `Capsule` > `Cylinder` > `Box` > `Convex Hull`

Unsupported shapes in SEUT: `Cone`, `Mesh`, `Compound Parent`.

### SEUT Collision Setup
1. Create a `Collision` collection under `Main` (or under `BSx` for per-build-stage collisions)
2. Build collision geometry using convex primitives
3. Assign Havok Rigid Body to each object in Blender's physics properties
4. Ensure all pivot points are at world origin (0,0,0) with world-aligned axes
5. Export via SEUT — collision exports as .hkt alongside the .fbx

### Havok Content Tools Pipeline (legacy / non-SEUT workflow)
Filter pipeline order in `hctStandAloneFilterManager.exe`:
1. Core / Transform Scene
2. Physics / Create Rigid Bodies
3. Core / Write to Platform

XML config required:
```xml
<Parameter Name="RescaleFactor">0.01</Parameter>
<Parameter Name="RescaleToLengthInMeters">False</Parameter>
```

### Gotchas
- Collision data only loads at game startup — complete restart required to test changes (not just world reload)
- Rigid Bodies don't update properly after you change the attached collision object. Fix: reapply transformations, then delete and recreate the Rigid Body
- Subpart collision is generally unsupported unless the parent block specifically enables it
- Debug visualization: in-game F11 → Debug Draw → Physics Primitives (red=Convex Hull, blue=Box, white=Sphere, orange=Cylinder, yellow=Capsule)

---

## Mountpoints

Mountpoints define which faces of a block accept connections from adjacent blocks.

### Setup in SEUT
1. Update the bounding box first (must fully encompass model)
2. Enable Mountpoint Mode in SEUT Main Panel
3. Edit turquoise plane areas in Object Mode (move, scale, delete)
4. Use "Add Area" button with a face empty selected to add multiple regions per side
5. Disable Mountpoint Mode to save values — they export into the generated SBC

### Constraints
- Mountpoint areas cannot be rotated (saved as X/Y dimensions only)
- Areas extending beyond the bounding box are trimmed automatically
- Diagonal mountpoint areas are not supported
- Editing mountpoint areas in Edit Mode (rather than Object Mode) causes misalignment — apply transforms if you do

### Testing
Use **Digi's BuildInfo mod** in-game — holds block shows mountpoints in yellow.

---

## Mirroring

Mirroring in SE doesn't create a true mirror — it defines which rotation of the block achieves a mirrored appearance.

### Setup in SEUT
1. Enable Mirroring Mode in SEUT Main Panel
2. Rotate the three mirror empties (`Mirror FrontBack`, `Mirror LeftRight`, `Mirror TopBottom`) in 90° increments to match visual reflection
3. Disable Mirroring Mode to save rotation values into the SBC

### Rules
- Always rotate in 90° increments; axis values must be ±90° or ±180°
- Only predefined rotation combinations are valid — the game cannot read arbitrary values
- If a required rotation isn't in the valid set, try alternate axis combinations with same visual result

### Asymmetric Blocks
If the block has no axis symmetry, create a second scene in the same .blend file (separate model), apply Blender's Mirror modifier, and designate it as `Mirror Model` in scene configuration.

### Gotchas
- "Huge geometry" bug when entering Mirroring Mode: disable mode → Apply Scale → re-enable
- Incorrect rotation values error: try an alternative axis combination

---

## Interaction Highlights

Highlight empties define the crosshair detection zones for interactive surfaces (terminal, screen, conveyor, etc.).

### Setup
1. All model parts must be parented to a single object or empty
2. Select the object to make interactive
3. Add → Create Empty → Add Highlight Empty → choose type (Conveyor, Terminal, Screen, etc.)
4. Resize the empty to cover the target surface
5. Target object is auto-renamed with type suffix

### Naming Rules
- No two empties of the same type can share the same index number
- Empty and target object must share identical parent hierarchy
- If naming is wrong, recreate the empty — it auto-applies correct naming

### Testing
Yellow square highlight in-game = incorrect empty-to-object association. Check: shared parent, naming conformance, unique type indices. Requires full game restart to test changes.

---

## Block SBC Configuration

### SubtypeId Convention
```
[Creator]_[GridSize]_[BlockType]_[Name]
```
Example: `MyCorp_LG_LA_ArmorCorner`
- GridSize: `LG` (large grid) or `SG` (small grid)
- BlockType: `LA` (light armor), `HA` (heavy armor), etc.

### Supporting SBC Files

| File | Purpose |
|------|---------|
| `Data/CubeBlocks/*.sbc` | Block definition (components, PCU, build time) |
| `Data/BlockCategories.sbc` | G-menu categorization |
| `Data/BlockVariantGroups.sbc` | UI scroll list grouping |
| `Data/BluePrintClassEntries.sbc` | Assembler production availability |
| `Data/ResearchBlocks.sbc` | Tech tree integration |
| `Data/Localization/*.resx` | Display names |

### Key SBC Fields

| Field | Purpose |
|-------|---------|
| `CriticalComponent` | Component that determines block functional status |
| `BuildTimeSeconds` | Construction duration |
| `DisassembleRatio` | Multiplier for grind time (usually 1.0–2.0) |
| `PCU` | Performance Cost Units |

---

## Export Checklist (Block from Scratch)

1. Model in Blender, organized into SEUT collections (Main, LOD1, LOD2, Collision, etc.)
2. Assign materials using SEUT Material tool; link textures from Asset Directory
3. Set bounding box, configure mountpoints, mirroring, interaction highlights
4. Set SubtypeId and target grid size in SEUT scene properties
5. Export → SEUT generates .mwm files and a default .sbc
6. Convert source textures to DDS using texconv commands above
7. Copy DDS files into mod `Textures/` folder
8. Edit generated .sbc to add CriticalComponent, PCU, localization, etc.
9. Add BlockCategories, BluePrintClassEntries, ResearchBlocks SBC entries
10. Full game restart to test (not world reload)

### In-Game Validation Sequence
- Appearance and colorability
- G-menu presence and category
- Mountpoint attachment on all faces
- Mirroring on all rotation axes
- Build stage progression (BS1 → BS2 → complete)
- Collision behavior
- LOD transitions at varying distances (test with graphics quality changes)

---

## Common Gotchas

- Game does NOT reload model/material changes on world reload — full restart required every time
- MWM cannot be decompiled back to FBX — keep .blend originals
- Modded armor blocks cannot support connected textures across adjacent blocks (deformation system limitation)
- Do not use `SquarePlate` material as the primary surface material for armor blocks
- Build stages use `Construction` material exclusively
- Moving .mwm files after export breaks LOD path references in the .xml
- High graphics setting shows LOD0 only; test LOD transitions by lowering quality settings

---

## Audio

SE uses `.xwm` (XMA2-encoded WMA) for in-game audio. Source files are typically `.wav` or `.ogg`.

### Universal Audio Converter

Use the **Universal Audio Converter** ([GitHub](https://github.com/Godimas101/mods/tree/main/space-engineers-mods/Tools/universal-audio-converter)) for all SE audio work. It handles:
- Converting source audio (WAV, OGG, MP3, etc.) → XWM for SE
- Editing audio files (trim, volume, fade, etc.) before conversion
- Batch processing

### SBC Registration

Audio files must be registered in a `SoundCategories.sbc` (or `Sounds.sbc`) file in your mod's `Data/` folder. Reference the vanilla `Sounds.sbc` in `Content/Data/` for the required XML schema.
- CPU-animated subparts run on every server tick regardless of render distance — minimize count
