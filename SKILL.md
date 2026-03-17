# Space Engineers Modding Expert

Expert guidance for all Space Engineers mod and script development.

---

## ON SKILL LOAD — Workspace Check

**Every time this skill is invoked, run these checks before doing anything else.**

### 1. SE Game Directory
Look for a directory containing `Content/Data/` with `.sbc` files (e.g. `CubeBlocks`, `Components.sbc`).

- ✅ Found → You have access to vanilla SBC definitions. Use them as ground truth.
- ❌ Not found → Tell the user:
  > "I don't see the Space Engineers game directory in your workspace. Please add `[Steam]\steamapps\common\SpaceEngineers\` as an additional working directory in VS Code. This gives me access to vanilla block definitions."

### 2. ModSDK Directory
Look for a directory containing `Bin64_Profile\` with `.dll` and `.xml` files (e.g. `Sandbox.Game.xml`).

- ✅ Found → You have full API documentation available.
- ❌ Not found → Tell the user:
  > "I don't see the Space Engineers ModSDK in your workspace. Please add `[Steam]\steamapps\common\SpaceEngineersModSDK\` as an additional working directory. Install it free via Steam → Library → Tools → 'Space Engineers - Mod SDK'. This gives me access to the full C# API documentation."

### 3. AppData Directory
Look for a directory containing `SpaceEngineers.log` and a `Crashes\` folder.

Standard path: `C:\Users\[Username]\AppData\Roaming\SpaceEngineers\`

- ✅ Found → You have access to crash logs and game logs. When the user reports a bug or crash, check here first.
- ❌ Not found → Tell the user:
  > "I don't see your Space Engineers AppData folder in your workspace. Add `%AppData%\Roaming\SpaceEngineers\` as a working directory — this gives me access to crash logs and the game log when you need to debug issues."

**Key files in the AppData directory:**

| Path | Contents |
|------|---------|
| `SpaceEngineers.log` | Main game log — mod load errors, exceptions, warnings |
| `Crashes\` | Crash dump files with timestamps |
| `Saves\` | Save game files |
| `Mods\` | Locally developed mods (not Workshop) |
| `Storage\[modId]\` | Per-mod persistent data written by session components |

**Log filename format:** `SpaceEngineers_YYYYMMDD_HHMMSSms.log` — always use the **most recent** log file, not `SpaceEngineers.log`.

**Log reading strategy — logs can be massive (thousands of lines). Never read top-to-bottom.**
1. Start at the **end** of the log and search upward
2. Search for these terms in priority order:

| Search term | What it finds |
|-------------|--------------|
| `ERROR` | Hard errors — always investigate |
| `CRITICAL_ERROR` | Fatal errors |
| `EXCEPTION` | .NET exceptions with stack traces |
| `No definition` | Missing SBC definition (wrong TypeId/SubtypeId) |
| `Failed to find definition` | Mod Adjuster patch couldn't find its target |
| `Warning:` | Non-fatal issues — may still matter |
| `BuildInfo ModderHelp:` | Build Info mod hints about XML problems |
| `[YourModName]` | Any output from your specific mod |
| `ModAdjuster` | All Mod Adjuster patch results (success + failure) |

**Key log sections and what to look for:**

```
MyScriptManager.LoadData()          ← compiled mods load here
  Script loaded: YourMod            ← ✅ your DLL compiled and loaded
  (missing = your mod has a compile error)

List of used mods (N)               ← all active mods listed here
  Id = Steam:0                      ← local mod (AppData\Mods\)
  Id = Steam:XXXXXXXXX              ← workshop mod

Loading cube blocks                 ← SBC block definitions load
  Created definition for: ...       ← ✅ block registered successfully
  Loading cube block: Type/Subtype  ← ✅ block patched/overridden
  No definition 'Type/Subtype'      ← ❌ bad TypeId or SubtypeId in SBC

Init ModAdjuster                    ← Mod Adjuster session component starts
  Loaded definition for ...         ← ✅ MA patch applied
  Failed to find definition for ... ← ❌ MA patch target not found
```

**Local mods vs Workshop mods in the log:**
- `Id = Steam:0` → loading from `%AppData%\Roaming\SpaceEngineers\Mods\[ModName]\`
- `Id = Steam:XXXXXXXXX` → loading from `[Steam]\steamapps\workshop\content\244850\XXXXXXXXX\`

### 4. Mod Directory (Steam Workshop or ModDB)
Look for a directory with many numbered folders (Steam: `244850\`) OR a `MOD_CATALOGUE.md` file.

- ✅ Found with `MOD_CATALOGUE.md` → Read the catalogue. Check the `Catalogued:` date — if it is more than 30 days ago, tell the user the catalogue is stale and offer to refresh it.
- ✅ Found without `MOD_CATALOGUE.md` → Tell the user:
  > "I can see your mod directory but there's no MOD_CATALOGUE.md yet. Would you like me to build one? It indexes all your subscribed mods so I can reference them when helping you."
- ❌ Not found → Tell the user:
  > "I don't see a mod directory in your workspace. If you use Steam Workshop mods, add `[Steam]\steamapps\workshop\content\244850\` as a working directory. If you use ModDB or a local mod folder, add that instead. This lets me reference your subscribed mods when helping you build or patch things."

---

## MOD_CATALOGUE.md — Format & Maintenance

The catalogue lives at the root of your mod directory (e.g. `244850\MOD_CATALOGUE.md`).

### Format

```markdown
# Space Engineers Workshop Mod Catalogue

**Total mods:** [count]
**Catalogued:** [YYYY-MM-DD]
**Workshop folder:** `[path]`

---

## Notes on Name Resolution
[how names were found — modinfo.sbmi, metadata.mod, SBC class names, folder names, etc.]

**Categories used:**
- **Script** — PB scripts or compiled C# session/LCD mods (no new blocks)
- **Block** — Adds new blocks to the game
- **LCD/HUD** — LCD texture packs or HUD modifications
- **Survival** — Food, farming, survival mechanics
- **Weapons** — Weapons, ammo, turrets
- **Visual** — Decor, cosmetic blocks, paint, animations
- **NPC/AI** — NPC spawns, AI systems
- **Economy** — Trade, economy, logistics
- **Blueprint** — Ship blueprint (not a gameplay mod)
- **Other** — Miscellaneous / unclear

---

## Catalogue (sorted by mod name)

| Workshop ID | Mod Name | Category | Notes |
|-------------|----------|----------|-------|
| [id] | [name] | [category] | [notes] |
```

### Building or Refreshing the Catalogue

To build or refresh the catalogue:

1. List all subdirectories in the mod folder (each is a Workshop ID)
2. For each mod folder, find its name by checking in order:
   - `modinfo.sbmi` → `<WorkshopId>` / `<Name>` fields
   - `metadata.mod` → `<Name>` field
   - Any `.sbc` file → block `<DisplayName>` or script class name
   - Folder name as last resort
3. Categorize based on file contents:
   - Has `Scripts/` with `.cs` files → Script or compiled mod
   - Has `CubeBlocks*.sbc` → Block
   - Has `LCDTextures.sbc` → LCD/HUD
   - Has weapon/ammo SBCs → Weapons
   - Folder name / display name contains "Blueprint" → Blueprint
4. Sort the table alphabetically by Mod Name
5. Update the header count and date
6. **Remind the user:** "Catalogue updated. Next refresh due by [date + 30 days]."

### Refresh Schedule
- Minimum: **once per month**
- Also refresh when: user says they added/removed mods, or when the user asks "what mods do I have?"

---

## CRITICAL: Know Which Type You're Working On

Four completely different environments. Get this wrong and nothing works.

| Type | How It Runs | C# Access | Invoked By |
|------|-------------|-----------|------------|
| **Text Surface Script** | Compiled DLL, runs on LCD blocks | Full .NET, all namespaces | InfoLCD mod screens |
| **Session Component** | Compiled DLL, runs as game component | Full .NET, all namespaces | Background game logic |
| **SBC-only Mod** | XML loaded at game start | No C# | Block/item/balance definitions |
| **Mod Adjuster Mod** | Session component + XML patches | Patches live definitions at runtime | Non-destructive cross-mod balance overrides |
| **PB Script** | Sandboxed VM inside the game | Whitelist only — NO I/O, NO threading, NO reflection | Player-written ingame scripts |

> **InfoLCD is a Text Surface Script mod.** Full .NET access. None of the PB sandbox restrictions apply.
>
> For Mod Adjuster details see [MOD_ADJUSTER.md](MOD_ADJUSTER.md).
> For PB scripting details see [PB_SCRIPTS.md](PB_SCRIPTS.md).

---

## Text Surface Script — The Basics

### Class Structure

```csharp
using Sandbox.ModAPI;
using VRage.Game.GUI.TextPanel;
using VRageMath;

[MyTextSurfaceScript("MyScriptId", "Display Name")]
public class MyScreen : MyTextSurfaceScriptBase
{
    IMyTerminalBlock Block => (IMyTerminalBlock)m_block;

    public MyScreen(IMyTextSurface surface, IMyCubeBlock block, Vector2 viewport)
        : base(surface, block, viewport) { }

    public override ScriptUpdate NeedsUpdate => ScriptUpdate.Update10;

    public override void Run()
    {
        // ⚠️ ALWAYS bail on dedicated server
        if (MyAPIGateway.Utilities?.IsDedicated ?? false) return;

        try
        {
            using (var frame = mySurface.DrawFrame())
            {
                // Your drawing code here
            }
        }
        catch { } // Never crash the game
    }

    public override void Dispose() { }
}
```

### The Update10 Rule — CRITICAL

`ScriptUpdate.Update10` means Run() fires every **10 game ticks** (6 times per second).

```csharp
// ❌ WRONG — increments 1 per call, so 1/6th of expected speed
ticksSinceLastScroll++;

// ✅ CORRECT — reflects actual ticks elapsed per call
ticksSinceLastScroll += 10;
```

`scrollSpeed = 60` → ~1 second. `scrollSpeed = 120` → ~2 seconds. Always design timers in ticks (60 = ~1 second at Update10).

### Dedicated Server Guard

```csharp
if (MyAPIGateway.Utilities?.IsDedicated ?? false) return;
```

Use `?.` because `Utilities` can be null during early init.

---

## Drawing on LCD Surfaces

### Sprite Frame Pattern

```csharp
using (MySpriteDrawFrame frame = mySurface.DrawFrame())
{
    frame.Add(new MySprite()
    {
        Type = SpriteType.TEXT,
        Data = "Hello World",
        Position = new Vector2(x, y),
        Color = Color.White,
        FontId = "White",
        Alignment = TextAlignment.LEFT,
        RotationOrScale = textSize
    });
}
```

### Surface Sizing

```csharp
Vector2 screenSize = mySurface.SurfaceSize;
Vector2 viewportOffset = (mySurface.TextureSize - screenSize) / 2f;
float localX = viewportOffset.X + padding;
float localY = viewportOffset.Y + padding;
```

### Position-Based Space Calculation (for scrolling lists)

```csharp
float lineHeight = 30 * surfaceData.textSize;
float currentY = position.Y - surfaceData.viewPortOffsetY;
float remainingHeight = mySurface.SurfaceSize.Y - currentY;
int availableLines = Math.Max(1, (int)(remainingHeight / lineHeight));
```

---

## Accessing Game State

### Grid and Blocks

```csharp
IMyCubeGrid grid = Block.CubeGrid;

var batteries = new List<IMyBatteryBlock>();
grid.GetFatBlocks(batteries);
```

### Inventory Scanning

```csharp
// ⚠️ ALWAYS use composite key — SubtypeId alone is not unique
var typeId = item.Type.TypeId.Split('_')[1];
var subtypeId = item.Type.SubtypeId;
string key = $"{typeId}_{subtypeId}";

// ⚠️ Amounts are VRage.MyFixedPoint, not int/float
int amount = item.Amount.ToIntSafe();
```

### CustomData Config (MyIni Pattern)

```csharp
private MyIni _config = new MyIni();

private void ParseConfig()
{
    if (!_config.TryParse(Block.CustomData)) return;
    _toggleScroll = _config.Get("MyScreen", "EnableScroll").ToBoolean(false);
    _scrollSpeed  = _config.Get("MyScreen", "ScrollSpeed").ToInt32(60);
}
```

---

## Scrolling List Pattern

### Approach 1 — Flat List

```csharp
// State fields
bool toggleScroll = false;
bool reverseDirection = false;
int scrollSpeed = 60;
int scrollLines = 1;
int scrollOffset = 0;
int ticksSinceLastScroll = 0;

// In Run()
if (toggleScroll)
{
    ticksSinceLastScroll += 10;   // ← ALWAYS +10, never ++
    if (ticksSinceLastScroll >= scrollSpeed)
    {
        ticksSinceLastScroll = 0;
        scrollOffset += reverseDirection ? -scrollLines : scrollLines;
    }
}
else { scrollOffset = 0; ticksSinceLastScroll = 0; }

// Draw with wraparound
int total = itemList.Count;
int startIndex = (toggleScroll && total > 0)
    ? ((scrollOffset % total) + total) % total : 0;

int drawn = 0;
for (int i = 0; i < total && drawn < availableLines; i++)
{
    int idx = (startIndex + i) % total;
    // Draw itemList[idx]
    drawn++;
}
```

### Approach 2 — Multi-Category with MaxListLines

```csharp
int maxListLines = 5;  // 0 = unlimited
if (maxListLines > 0)
    availableLines = Math.Min(availableLines, maxListLines);
```

---

## Subgrid Caching Pattern

```csharp
private List<IMyTerminalBlock> _mainBlocks = new List<IMyTerminalBlock>();
private List<IMyTerminalBlock> _subgridCache = new List<IMyTerminalBlock>();
private int _tick = 0;

private void UpdateBlocks()
{
    _mainBlocks.Clear();
    Block.CubeGrid.GetFatBlocks(_mainBlocks);

    _tick += 10;
    if (_tick >= 300)  // ~5 seconds
    {
        _tick = 0;
        _subgridCache.Clear();
        var connectedGrids = new List<IMyCubeGrid>();
        Block.CubeGrid.GetConnectedGrids(GridLinkTypeEnum.Mechanical, connectedGrids);
        foreach (var subgrid in connectedGrids)
        {
            if (subgrid == Block.CubeGrid) continue;
            var sub = new List<IMyTerminalBlock>();
            subgrid.GetFatBlocks(sub);
            _subgridCache.AddRange(sub);
        }
    }
}
```

---

## SBC XML — Quick Reference

### Register a Text Surface Script

```xml
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <LCDScripts>
    <LCDScript>
      <Id Type="MyObjectBuilder_LCDScript" Subtype="MyScriptId" />
      <DisplayName>My Screen Display Name</DisplayName>
      <Description>What this screen shows</Description>
    </LCDScript>
  </LCDScripts>
</Definitions>
```

The `Subtype` must match `[MyTextSurfaceScript("MyScriptId", "...")]` in C#.

### Mod Folder Structure

```
MyMod/
├── Data/
│   ├── Scripts/YourNamespace/YourScript.cs
│   ├── TextSurfaceScripts.sbc
│   └── CubeBlocks/MyBlocks.sbc
├── metadata.mod
└── thumb.png
```

---

## Known Gotchas

1. **Item type collisions** — composite key always: `$"{typeId}_{subtypeId}"`
2. **MyFixedPoint** — use `.ToIntSafe()` or `(float)(double)amount`, never cast directly
3. **Block components are nullable** — always null-check `Components.Get<T>()`
4. **DetailedInfo is fragile** — localized string, format changes with game updates
5. **SBC load order** — last mod loaded wins on same Type+Subtype; use Mod Adjuster for non-destructive patches
6. **Backward compatibility** — never rename CustomData keys; add new ones, keep old ones

---

## Asset Pipeline Overview

Space Engineers uses custom asset formats. Source files must be converted before they work in-game.

### Models
```
FBX (Blender/3ds Max)  →  MwmBuilder  →  .mwm  →  reference in SBC
```
- Tool: `[ModSDK]\Tools\VRageEditor\` → ModelBuilder plugin
- Documentation: `[ModSDK]\Tools\VRageEditor\Plugins\ModelBuilder\MwmBuilderReadme.txt`
- Build progress models (`_BS1`, `_BS2`, `_BS3`) are separate .mwm files

### Textures (DX11 channel packing)
SE uses packed texture channels — **do not use vanilla naming conventions from old tutorials**:

| File suffix | Channels | Contents |
|-------------|----------|---------|
| `_cm.dds` | RGB = Color, A = Metalness | Diffuse colour + metal mask |
| `_ng.dds` | RGB = Normal, A = Glossiness | Normal map + gloss mask |
| `_add.dds` | RGB = Emissive additive, A = unused | Self-illumination |

- Format: DDS with DXT5 compression recommended
- Preview: `[ModSDK]\Tools\VRageEditor\` → ModelViewer plugin

### Audio
```
WAV (16-bit PCM, 44100 Hz)  →  xWMAEncode.exe  →  .xwm  →  reference in Audio.sbc
```
- **xWMAEncode.exe is bundled with the ModSDK:** `[ModSDK]\Tools\xWMAEncode.exe`
- No separate DirectX SDK download needed
- Also available: `[ModSDK]\Tools\AdpcmEncode.exe` for ADPCM format

---

## Key Reference Files

| What | Where (default Steam path) |
|------|-------|
| Game API DLLs + XML docs | `[ModSDK]\Bin64_Profile\` |
| Vanilla block/item SBCs (107 files) | `[SE]\Content\Data\` |
| CubeBlock definitions (27 category files) | `[SE]\Content\Data\CubeBlocks\` |
| Audio definitions | `[SE]\Content\Data\Audio.sbc` |
| Planet generator (with mod example!) | `[SE]\Content\Data\PlanetGeneratorDefinitions.sbc` |
| ModSDK tools | `[ModSDK]\Tools\` |
| xWMAEncode (audio) | `[ModSDK]\Tools\xWMAEncode.exe` |
| VRageEditor (model/anim tools) | `[ModSDK]\Tools\VRageEditor\` |
| Subscribed workshop mods | `[Steam]\steamapps\workshop\content\244850\` |
| Mod Adjuster source | Workshop ID `3017795356` in workshop folder |

> `[ModSDK]` = `[Steam]\steamapps\common\SpaceEngineersModSDK`
> `[SE]` = `[Steam]\steamapps\common\SpaceEngineers`

---

## Mod Making Notes — Your Session Journal

Mod work often spans many sessions with long breaks in between. Claude only has the current conversation in context. Without a persistent record, every new session starts blind — re-explaining decisions that were already made, re-discovering bugs that were already solved, losing track of what's done and what isn't.

A `MOD_MAKING_NOTES.md` file in your mod directory solves this. Keep it next to your mods and add it to your VS Code workspace so Claude can read it at the start of every session.

### When to read it
At the start of any mod work session — before making any changes — check if a notes file exists and read it. The session log is the most important part: it tells you what was done last time and what was left unfinished.

### When to update it
- After completing a significant piece of work, add an entry to the Session Log
- When a decision is made (why X was done instead of Y), write it down under the relevant mod section
- When a bug is found and fixed, record it in the session log and under Known Issues if it's likely to recur
- When a feature is added, update any status tables in that mod's section

### Creating a new notes file

If the user's mod directory doesn't have a `MOD_MAKING_NOTES.md`, offer to create one. Use this structure:

```markdown
# Space Engineers - Mod Making Notes

Consolidated notes for all mods in this workspace.

---

## Table of Contents
- [Mod Name](#mod-name)

---

## Mod Name

**Purpose:** What this mod does.
**Status:** In progress / Released / On hold

### Current Goals

- [ ] Thing to do
- [ ] Another thing

### Known Issues

*Add issues here as they are discovered.*

### Design Decisions

*Record any non-obvious choices and why they were made.*

---

## Session Log

### YYYY-MM-DD — Short description
- What was done
- What was discovered
- What was left unfinished → pick up next session from here
```

### Format guidelines
- **Session Log goes at the bottom** — newest entries at the bottom, not the top
- **Dates use ISO format** (YYYY-MM-DD)
- **Keep entries factual** — bugs found, fixes applied, decisions made, things still pending
- **One file covers all mods** in the workspace — separate sections per mod, shared session log

---

## Supporting Reference Files

- [SBC_TEMPLATES.md](SBC_TEMPLATES.md) — Copy-paste XML templates
- [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md) — Extended C# patterns
- [MOD_ADJUSTER.md](MOD_ADJUSTER.md) — Full Mod Adjuster guide
- [PB_SCRIPTS.md](PB_SCRIPTS.md) — Full Programmable Block scripting guide

---

## Quick Checklist Before Shipping

### All Mods
- [ ] `metadata.mod` present with correct `Name` and `WorkshopId`
- [ ] No TypeId/SubtypeId renamed or removed (breaks existing saves)
- [ ] Tested in Creative mode before publishing
- [ ] Workshop description updated if behavior changed

### Compiled Mods (Text Surface Scripts / Session Components)
- [ ] Dedicated server guard in every `Run()` method
- [ ] All `Components.Get<T>()` calls are null-checked
- [ ] All inventory keys use composite `typeId_subtypeId`
- [ ] CustomData config keys unchanged from previous version (backward compat)
- [ ] No unhandled exceptions that could crash the game (wrap in `try/catch`)

### Text Surface Scripts (LCD)
- [ ] Scroll timer uses `+= 10`, not `++`
- [ ] Tested on small, large, and corner LCD panels
- [ ] Handles empty block lists gracefully (don't divide by zero on line count)

### SBC / Mod Adjuster Mods
- [ ] Only modified fields included in patch (don't copy entire definition)
- [ ] xsi:type values use correct prefix (`MyObjectBuilder_` for vanilla SBC, stripped for Mod Adjuster)
- [ ] New block SubtypeIds are globally unique (won't collide with other mods)

### PB Scripts
- [ ] Instruction count checked — no unbounded loops over large block lists per tick
- [ ] `Storage` used for any state that must survive recompile
- [ ] `Echo()` used for debug output, not `Me.GetSurface(0)` hardcoded
- [ ] Graceful handling when expected blocks are missing from grid
