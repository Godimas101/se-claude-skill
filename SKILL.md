---
name: space-engineers
description: Space Engineers Modding Expert
---

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

### 4. Workshop Mod Directory
Look specifically for the Steam Workshop directory — it contains many numbered subfolders (each is a Workshop ID). Default path: `[Steam]\steamapps\workshop\content\244850\`

To detect it: look for a directory that contains 10+ numeric-named subfolders (e.g. `3017795356\`, `2668820525\`, etc.).

- ✅ Found with `MOD_CATALOGUE.md` → Read the catalogue. Check the `Catalogued:` date — if it is more than 30 days ago, tell the user the catalogue is stale and offer to refresh it.
- ✅ Found without `MOD_CATALOGUE.md` → Tell the user:
  > "I can see your workshop mod directory but there's no MOD_CATALOGUE.md yet. Would you like me to build one? It indexes all your subscribed mods so I can reference them when helping you."
- ❌ Not found → Tell the user:
  > "I don't see your Steam Workshop mod directory in your workspace. Please add `[Steam]\steamapps\workshop\content\244850\` as an additional working directory in VS Code. This is required before I can build or read a mod catalogue."

  **Do not attempt to create or reference a MOD_CATALOGUE.md until the workshop directory is in the workspace.**

### 5. DLC / Patch Check

SE patches regularly. Detect new content before starting work.

1. Read `[SE]\Content\Data\Game\DLCs.sbc` and extract all `<SubtypeId>` values
2. Compare against the known list in [DLC_CATALOGUE.md](troubleshooting/DLC_CATALOGUE.md)
3. If any SubtypeIds are present in the file but **not** in the catalogue:
   > "I've detected new DLC in your game files not in my catalogue: [list]. A patch was likely released. Would you like me to research the new content?"
   - If yes: web-search each new SubtypeId and update working knowledge for the session
4. If the lists match: proceed silently — no new content

### 6. What Are We Working On?

After the workspace checks, use the `AskUserQuestion` tool to ask:

```
Question: "What brings you here today?"
Header: "How can I help?"
Options:
  - label: "I'm new to modding"
    description: "Not sure where to start, or have beginner questions"
  - label: "Working on a mod"
    description: "SBC mod, compiled C# mod, MES/AI encounter, Mod Adjuster patch, or PB script"
  - label: "Torch or Pulsar plugin"
    description: "Torch dedicated server plugin, or Pulsar client-side plugin"
  - label: "Just ask"
    description: "I have a specific question — skip the setup"
```

(Other is shown automatically for freeform input.)

**Based on the answer:**

- **New to modding** → Read [GETTING_STARTED.md](GETTING_STARTED.md) before responding. Walk them through the concepts: what mod types exist, what tools they need, and what kind of mod fits what they want to build. Do not assume any prior knowledge.

- **Working on a mod** → Ask a follow-up to narrow the type:
  ```
  Question: "What type of mod are you working on?"
  Options:
    - label: "Brand new mod"
      description: "Adding blocks, items, sounds, LCD images, planets, or other game content via SBC/XML"
    - label: "Framework mod"
      description: "Building on top of MES, AI Enabled, WeaponCore, Mod Adjuster, Animation Engine, Scope Framework, or Tank Tracks"
    - label: "Compiled C# mod"
      description: "Text Surface Script (LCD screen), Session Component, or Game Logic — requires C# and MDK2"
    - label: "Programmable Block script"
      description: "Ingame PB script — sandboxed C#, whitelist restrictions apply"
  ```
  Then:
  - **Brand new mod** → Ask which mod they're working on. Read the relevant CLAUDE.md and MOD_MAKING_NOTES.md. Always read [SBC_RULES.md](sbc/SBC_RULES.md) first. Then load the appropriate sub-file based on what they're building:
    - Block/item definitions, categories, variant groups, component lists → [SBC_BLOCKS.md](sbc/SBC_BLOCKS.md)
    - Blueprints, production tabs, research/progression locks → [SBC_PRODUCTION.md](sbc/SBC_PRODUCTION.md)
    - LCD registration, localization, loot tables, prefabs → [SBC_MISC.md](sbc/SBC_MISC.md)
    - Also reference [PATCH_NOTES.md](troubleshooting/PATCH_NOTES.md) for breaking changes. If the mod includes custom 3D models or textures, also read [ASSETS.md](ASSETS.md). For step-by-step worked examples, see [RECIPES.md](RECIPES.md).
  - **Framework mod** → Ask which framework:
    ```
    Question: "Which framework?"
    Options:
      - label: "MES — Modular Encounters System"
        description: "NPC ship and vehicle encounter spawns"
      - label: "AI Enabled"
        description: "NPC characters, creatures, and crew"
      - label: "WeaponCore"
        description: "Custom weapons using the WeaponCore framework"
      - label: "Mod Adjuster"
        description: "Non-destructive balance patches against any mod or vanilla"
      - label: "Animation Engine"
        description: "Custom block animations using the Animation Engine framework"
      - label: "Scope Framework"
        description: "Weapon scope/optic overlays using the Scope Framework"
      - label: "Tank Tracks"
        description: "Tracked vehicle movement using the Tank Tracks framework"
      - label: "Vanilla+ Framework"
        description: "Advanced projectile and weapon behaviors on vanilla weapons (server-side)"
    ```
    Then:
    - **MES** → Read [MES.md](framework-mods/MES.md). Ask which mod they're working on and reference the mod catalogue for installed MES packs.
    - **AI Enabled** → Read [AI_ENABLED.md](framework-mods/AI_ENABLED.md). Reference the mod catalogue for installed AI Enabled mods.
    - **WeaponCore** → Read [WEAPONCORE.md](framework-mods/WEAPONCORE.md). Reference the mod catalogue for the WeaponCore Workshop ID and any child mods.
    - **Mod Adjuster** → Read [MOD_ADJUSTER.md](framework-mods/MOD_ADJUSTER.md). Reference the mod catalogue to find the target mod's Workshop ID and SBC definitions.
    - **Animation Engine** → Read [ANIMATION_ENGINE.md](framework-mods/ANIMATION_ENGINE.md).
    - **Scope Framework** → Read [SCOPE_FRAMEWORK.md](framework-mods/SCOPE_FRAMEWORK.md).
    - **Tank Tracks** → Read [TANK_TRACKS.md](framework-mods/TANK_TRACKS.md).
    - **Vanilla+** → Read [VANILLA_PLUS.md](framework-mods/VANILLA_PLUS.md). Note: framework Workshop listing is unlisted — docs are in the local workshop cache and the VPF Discord.
  - **Compiled C#** → Ask which mod they're working on. Read CLAUDE.md and MOD_MAKING_NOTES.md. Reference [CSHARP_PATTERNS.md](scripting/CSHARP_PATTERNS.md) for runtime patterns. For project setup, MDK2, or decompiler questions, see [CSHARP_PROJECT_SETUP.md](scripting/CSHARP_PROJECT_SETUP.md). For Text Surface Script / LCD work, also read [TSS_PATTERNS.md](scripting/TSS_PATTERNS.md). Clarify Text Surface Script vs Session Component vs Game Logic if not clear from context.
  - **PB script** → Apply PB sandbox restrictions throughout. See [PB_SCRIPTS.md](scripting/PB_SCRIPTS.md).

- **Torch or Pulsar plugin** → Ask "Torch or Pulsar?" and "Where is it installed?" See [TORCH.md](plugins/TORCH.md) or [PULSAR.md](plugins/PULSAR.md) accordingly.

- **Just ask / Other** → Take their question at face value and answer directly. No further setup questions.

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
- **MES** — Modular Encounters System framework or child/encounter pack mod
- **AI Enabled** — AI Enabled framework or character/creature/crew child mod
- **NPC/AI** — NPC spawns or AI systems that don't use MES or AI Enabled
- **Economy** — Trade, economy, logistics
- **Blueprint** — Ship blueprint (not a gameplay mod)
- **Scenario** — Workshop world save or scenario (not a gameplay mod)
- **WeaponCore** — WeaponCore (CoreSystems) framework source or child weapon mod
- **Vanilla+ Framework** — Vanilla+ Framework source or child mod
- **Animation Engine** — Animation Engine framework source or child mod
- **Scope Framework** — Scope Framework source or child mod
- **Tank Tracks** — Tank Tracks framework source or child mod
- **Mod Adjuster** — Mod Adjuster framework source or patch mod built with Mod Adjuster
- **Other** — Miscellaneous / unclear

---

## Catalogue (sorted by mod name)

| Workshop ID | Mod Name | Category | Notes |
|-------------|----------|----------|-------|
| [id] | [name] | [category] | [notes] |
```

### Building or Refreshing the Catalogue

**Before scanning — size check:**
1. Count the subdirectories in the workshop folder (each is a mod).
   - **500 or more mods:** Stop and ask before proceeding:
     > "Your workshop folder contains [n] mods. Building a full catalogue will take a while — want me to proceed, or would you prefer to scan only a specific range?"
   - **Under 500:** Continue automatically.

**Scan cap — 200 mods per session:**
Process a maximum of 200 mod folders per build/refresh run. If there are more:
- Write the catalogue with however many were processed, noting in the header: `**Scanned:** [n] of [total] — run again to continue`
- Tell the user how many remain and offer to continue in the next run

**Per-mod steps:**
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
   - Has `Profiles/` subfolder OR any SBC containing `[Modular Encounters SpawnGroup]` → **MES**
   - Has `<Bot xsi:type="MyObjectBuilder_AnimalBotDefinition">` in any SBC OR has `AnimationControllers/` folder → **AI Enabled**
   - Workshop ID `3154371364` → **WeaponCore**
   - Workshop ID `2880317963` → **Animation Engine**
   - Workshop ID `2754014019` → **Scope Framework**
   - Workshop IDs `3208995513`, `3209005014`, `3209008231` → **Tank Tracks**
   - Workshop IDs `2915780227`, `3014670447` → **Vanilla+ Framework**
   - Workshop ID `3017795356` OR has `3017795356` as a dependency in `modinfo.sbmi` OR any SBC file contains `ModAdjust` XML types → **Mod Adjuster**
   - **Unknown / doesn't match any rule above → use "Other"** — never leave Category blank
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
> For Mod Adjuster details see [MOD_ADJUSTER.md](framework-mods/MOD_ADJUSTER.md).
> For PB scripting details see [PB_SCRIPTS.md](scripting/PB_SCRIPTS.md).

---

## Text Surface Scripts (TSS / LCD)

> See [scripting/TSS_PATTERNS.md](scripting/TSS_PATTERNS.md) for class structure, Update10 rule, drawing patterns, scrolling, and subgrid caching.

---

## SBC Quick Reference

> For registering a Text Surface Script in SBC, see [scripting/TSS_PATTERNS.md](scripting/TSS_PATTERNS.md).

### Mod Folder Structure

```
MyMod/                        ← local: %AppData%\SpaceEngineers\Mods\MyMod\
├── Data/                     ← REQUIRED — must exist even if empty
│   ├── Scripts/
│   │   └── MyMod/            ← scripts subfolder — must match mod name
│   │       └── MyScript.cs
│   ├── TextSurfaceScripts.sbc
│   └── CubeBlocks/
│       └── MyBlocks.sbc
├── modinfo.sbmi              ← auto-generated on first Workshop publish; required for updates
└── thumb.png                 ← optional thumbnail (Steam: <1 MB; mod.io: required, min 512×288)
```

**`Data/` is mandatory** — without it the game fails to load the mod entirely, even for collection mods with no content. Never name it anything else.

**`modinfo.sbmi`** is auto-created when you first publish. If it goes missing, see [GETTING_STARTED.md](GETTING_STARTED.md) for the template.

---

## Known Gotchas

1. **Item type collisions** — composite key always: `$"{typeId}_{subtypeId}"`
2. **MyFixedPoint** — use `.ToIntSafe()` or `(float)(double)amount`, never cast directly
3. **Block components are nullable** — always null-check `Components.Get<T>()`
4. **DetailedInfo is fragile** — localized string, format changes with game updates
5. **SBC load order** — mods load **bottom-to-top** in the in-game mod list. The mod highest in the list wins on same Type+Subtype. Use Mod Adjuster for non-destructive patches
6. **Backward compatibility** — never rename CustomData keys; add new ones, keep old ones
7. **`.sbm` files** — renamed ZIP archives (old mod packaging format). Safe to delete or ignore. `.sbm` files in `Storage\` subdirectories are NOT the same — those are **mod runtime data folders** (named like `.sbm_12345678`) and must NOT be deleted.
8. **`.bin` files in mod folders** — old binary archive format, same as `.sbm`. Safe to ignore.

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
| `_add.dds` | R = Ambient Occlusion, G = Emissive, A = Paintability/Alpha mask | AO + emissive + paint support |
| `_alphamask.dds` | A only | Transparency cutout for GLASS/DECAL techniques |

- **Recommended format:** BC7 (use `texconv -f BC7_UNORM_SRGB` for colour textures, `BC7_UNORM` for normal maps)
- DXT5 still works but BC7 gives better quality at the same size
- Preview: `[ModSDK]\Tools\VRageEditor\` → ModelViewer plugin

**Technique values** (set in the material definition `<Technique>` field):

| Technique | Use |
|-----------|-----|
| `MESH` | Standard opaque geometry (default for most blocks) |
| `DECAL` | Appears as part of underlying model surface |
| `DECAL_NOPREMULT` | Higher transparency accuracy than DECAL |
| `DECAL_CUTOUT` | Cuts into the underlying model |
| `ALPHA_MASKED` | Opacity driven by alphamask texture |
| `FOLIAGE` | Semi-transparent; shadows observe texture transparency |
| `GLASS` | Transparent with refraction — material name must match a SubtypeId in `TransparentMaterials.sbc` |
| `HOLO` | Emissive glass — also needs a `TransparentMaterials.sbc` entry |
| `SHIELD` | Animated distorted glass — **may crash on certain blocks**; needs `TransparentMaterials.sbc` entry |

**Transparent materials** (GLASS/HOLO/SHIELD): the material `Name` attribute must match a `SubtypeId` in `TransparentMaterials.sbc`. These use a CA (Color/Alpha) texture instead of CM, where the alpha channel controls transparency.

### LCD Textures (LCDTextureDefinition mods)
```
PNG / JPG / etc.  →  texconv (BC7_UNORM_SRGB)  →  .dds  →  TexturePath + SpritePath in LCDTextures.sbc
```
- Alpha channel = **inverse emissivity** (alpha=1 ≈ fully self-lit — Keen's recommended value)
- Must use `-sepalpha` when generating mipmaps — prevents premultiplied alpha from destroying mip quality
- Full mipmap chain required; use 1024px+ source images for good quality at game distances
- **Recommended tool:** [Universal Image Converter](https://github.com/Godimas101/mods/tree/main/space-engineers-mods/Tools/universal-image-converter) — handles BC7_UNORM_SRGB, mipmaps, emissivity alpha, and all screen presets automatically

### Audio
```
WAV (16-bit PCM, 44100 Hz)  →  xWMAEncode.exe  →  .xwm  →  reference in Audio.sbc
```
- **xWMAEncode.exe is bundled with the ModSDK:** `[ModSDK]\Tools\xWMAEncode.exe`
- No separate DirectX SDK download needed
- Also available: `[ModSDK]\Tools\AdpcmEncode.exe` for ADPCM format
- **Recommended tool:** [Universal Audio Converter](https://github.com/Godimas101/mods/tree/main/space-engineers-mods/Tools/universal-audio-converter) — batch converts WAV/MP3/FLAC/OGG to .xwm and generates Audio.sbc entries automatically

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
| DLC definitions | `[SE]\Content\Data\Game\DLCs.sbc` |
| MES (Modular Encounters System) | Workshop ID `1521905890` in workshop folder |
| AI Enabled | Workshop ID `2596208372` in workshop folder |

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

- [SBC_RULES.md](sbc/SBC_RULES.md) — Universal SBC rules, override behavior, cross-mod references, DefinitionBase
- [SBC_BLOCKS.md](sbc/SBC_BLOCKS.md) — Block/item templates, categories, variant groups, block type reference
- [SBC_PRODUCTION.md](sbc/SBC_PRODUCTION.md) — Blueprints, production tabs, progression locks
- [SBC_MISC.md](sbc/SBC_MISC.md) — LCD registration, localization, loot, prefabs, finding definition IDs
- [CSHARP_PATTERNS.md](scripting/CSHARP_PATTERNS.md) — Extended C# patterns: session components, block queries, config, save/sync
- [CSHARP_PROJECT_SETUP.md](scripting/CSHARP_PROJECT_SETUP.md) — Project setup: MDK2, .csproj, folder structure, namespaces, decompiler strategies
- [TSS_PATTERNS.md](scripting/TSS_PATTERNS.md) — TSS/LCD drawing patterns, scrolling, subgrid caching
- [ASSETS.md](ASSETS.md) — Model pipeline, textures, collisions, materials
- [RECIPES.md](RECIPES.md) — Step-by-step worked examples (LCD App Script, Armor Block)
- [TROUBLESHOOTING.md](troubleshooting/TROUBLESHOOTING.md) — Error lookup, log reading, common failures
- [MOD_ADJUSTER.md](framework-mods/MOD_ADJUSTER.md) — Full Mod Adjuster guide
- [PB_SCRIPTS.md](scripting/PB_SCRIPTS.md) — Full Programmable Block scripting guide
- [TORCH.md](plugins/TORCH.md) — Torch dedicated server framework: installation, plugin dev, NexusV3
- [PULSAR.md](plugins/PULSAR.md) — Pulsar client plugin loader: installation, plugin dev, PluginHub
- [MES.md](framework-mods/MES.md) — Modular Encounters System: profile types, SBC format, child mod structure
- [AI_ENABLED.md](framework-mods/AI_ENABLED.md) — AI Enabled: bot definitions, character SBC, MES integration, child mods
- [DLC_CATALOGUE.md](troubleshooting/DLC_CATALOGUE.md) — Full DLC pack listing + patch detection instructions

---

## Quick Checklist Before Shipping

### All Mods
- [ ] `modinfo.sbmi` present with correct `WorkshopId` (auto-generated on first publish; recreate manually if missing)
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

---

## Wiki Reference Index

Key pages on the official modding wiki. Fetch these when you need deep detail on a topic.

**Base URL:** `https://spaceengineers.wiki.gg/wiki/`

### SBC Reference Pages

| Topic | URL path |
|-------|----------|
| SBC overview & rules | `Modding/Reference/SBC` |
| DefinitionBase (shared fields) | `Modding/Reference/SBC/DefinitionBase` |
| Block type index (TypeId → xsi:type table) | `Modding/Reference/SBC/CubeBlocks` |
| CubeBlock Definition (full field reference) | `Modding/Reference/SBC/CubeBlocks/CubeBlock_Definition` |
| MountPoints | `Modding/Reference/SBC/MountPoints` |
| Block Categories (G-menu tabs) | `Modding/Reference/SBC/BlockCategories` |
| Block Variant Groups (scroll groups) | `Modding/Reference/SBC/BlockVariantGroups` |
| BVG tutorial (step-by-step) | `Modding/Tutorials/SBC/BlockVariantGroups` |
| Items index (Component, PhysicalItem, Ammo...) | `Modding/Reference/SBC/Items` |
| Component Definition | `Modding/Reference/SBC/Items/Component_Definition` |
| Blueprint Definition | `Modding/Reference/SBC/Blueprints/Blueprint_Definition` |
| BlueprintClass Definition | `Modding/Reference/SBC/Blueprints/BlueprintClass_Definition` |
| BlueprintClasses tutorial (non-destructive recipes) | `Modding/Tutorials/SBC/BlueprintClasses` |
| LCD Texture Definition | `Modding/Reference/SBC/LCDTexture_Definition` |
| LCD Screens tutorial | `Modding/Tutorials/SBC/Screens` |
| LCD App Mod Script tutorial | `Modding/Tutorials/Recipes/LCD_App_Mod_Script` |
| Weapon Definition | `Modding/Reference/SBC/Weapon_Definition` |
| Entity Components | `Modding/Reference/SBC/EntityComponents` |
| Localization tutorial | `Modding/Tutorials/Localization` |
| Deformable Armor | `Modding/Reference/Deformable_Armor` |

### General Reference Pages

| Topic | URL path |
|-------|----------|
| Main reference index | `Modding/Reference` |
| Known crash solutions | `Modding/Reference/Known_Solutions_to_crashes_or_errors` |
| Mod scripting reference | `Modding/Reference/ModScripting` |
| Mod script whitelist | `Modding/Reference/ModScriptWhitelist` |
| Materials reference | `Modding/Reference/Materials` |
| Old SBM/BIN files | `Modding/Reference/Old_SBM_and_BIN_Files_Explained` |
| Modding-relevant patch changes | `Modding/Reference/Overview_of_Modding-Relevant_Changes_in_Game_Patches` |
| UseObjects (detector dummy names) | `Modding/Reference/UseObjects` |
| Conveyor system | `Modding/Reference/Conveyor_System` |
| Physics | `Modding/Reference/Physics` |
| Text Variables | `Modding/Reference/Text_Variables` |
| Data Types | `Modding/Reference/Data_Types` |

### Tutorial Pages

| Topic | URL path |
|-------|----------|
| All tutorials index | `Modding/Tutorials` |
| Armor block mod (beginner) | `Modding/Tutorials/Recipes/Armor_Block_Mod` |
| Version control (recommended) | `Modding/Tutorials/Version_Control` |
| Adding localization | `Modding/Tutorials/Localization` |

### Official External Links

| Resource | URL |
|----------|-----|
| Official ModAPI docs | `https://keensoftwarehouse.github.io/SpaceEngineersModAPI/api/index.html` |
| Unofficial ModAPI docs | `https://malforge.github.io/spaceengineers/modapi/` |
| Script examples (THDigi) | `https://github.com/THDigi/SE-ModScript-Examples/tree/master/Data/Scripts/Examples` |

### Important "Not Moddable" Notes

> See [sbc/SBC_RULES.md](sbc/SBC_RULES.md) for the full list of SBC files that cannot be overridden.
