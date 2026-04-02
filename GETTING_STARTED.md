# Getting Started — Space Engineers Modding

Beginner's orientation. If you already know what you're building, skip straight to the relevant reference file.

---

## What Kind of Mod Do You Want to Make?

SE modding has three completely separate disciplines. Pick the one that fits your goal.

### SBC Modding (XML only — no programming)
**What it can do:** Add or change blocks, items, components, blueprints, balance values, planets, audio, UI categories — anything that's defined in the game's data files.

**What it cannot do:** Change how the game engine itself works. You can add a block that shoots missiles (because missile blocks already exist), but you can't invent a new kind of physics interaction.

**Learning curve:** Low. You're editing XML files. The main skill is knowing which fields do what.

**Start here:** [SBC_RULES.md](sbc/SBC_RULES.md)

---

### C# Mod Scripting (compiled code)
**What it can do:** Anything. Session components run as background game logic. Text Surface Scripts drive LCD screens. Both have full .NET access and the complete game API.

**What it cannot do:** Nothing meaningful — if the game API exposes it, you can use it.

**Learning curve:** High. Requires C# knowledge, IDE setup, and understanding of the game's event model.

**Start here:** [CSHARP_PROJECT_SETUP.md](scripting/CSHARP_PROJECT_SETUP.md) · [CSHARP_PATTERNS.md](scripting/CSHARP_PATTERNS.md) · [TSS_PATTERNS.md](scripting/TSS_PATTERNS.md) · [SKILL.md](SKILL.md)

---

### Asset Modding (3D models, textures, audio)
**What it can do:** Add custom 3D models, textures, sounds, animations, and characters.

**What it cannot do:** Function without SBC definitions to reference the assets — assets alone do nothing.

**Learning curve:** Medium to high depending on discipline. Textures are easiest; full 3D models with colliders and LODs are the most work.

**Tools:** SEUT (Blender plugin, free) for models; texconv for textures; xWMAEncode (bundled with ModSDK) for audio.

---

### Programmable Block Scripts (ingame, sandboxed)
These are not mods — they're player-written scripts that run inside the game's Programmable Block. They use a separate, restricted API and cannot access most game systems.

**Start here:** [PB_SCRIPTS.md](PB_SCRIPTS.md)

---

## Tools You Need

### Always
| Tool | Cost | Purpose | Get it |
|------|------|---------|--------|
| Space Engineers ModSDK | Free (Steam Tools) | DLL references, model tools, audio tools | Steam → Library → Tools → "Space Engineers - Mod SDK" |

### For SBC Modding
| Tool | Cost | Purpose |
|------|------|---------|
| **VS Code** (recommended) | Free | XML editing with validation via RedHat XML extension |
| Notepad++ | Free | Alternative XML editor; "Find in Files" is invaluable for searching vanilla SBCs |
| Unofficial Keen Schemas | Free | VS Code schema files that give you autocomplete on SBC fields |

Install the **RedHat XML extension** in VS Code for SBC editing: `redhat.vscode-xml`

---

### For C# Mod Scripting
| Tool | Cost | Purpose |
|------|------|---------|
| **VS Code** (recommended) | Free | C# editing with C# Dev Kit extension |
| **MDK Hub** | Free | Creates project templates, manages build pipeline, deploys to mod folder |
| Visual Studio Community | Free (MS account) | Alternative to VS Code; Windows only; min v17.10 |
| JetBrains Rider | ~$169/yr | Cross-platform alternative; most polished but paid |

**VS Code extensions for C# mods:**
- `ms-dotnettools.csdevkit` — C# Dev Kit (required)
- `redhat.vscode-xml` — also useful for SBC files in the same project

**MDK Hub:** download from https://github.com/malforge/mdk2/releases — installs .NET 9 automatically, provides project templates, runs the whitelist analyzer at edit time.

---

### For Asset Modding
| Tool | Cost | Purpose |
|------|------|---------|
| Blender | Free | 3D modelling |
| **SEUT** (Space Engineers Utilities) | Free | Blender plugin — exports .mwm, sets up colliders and mount points |
| texconv | Free (bundled with ModSDK) | Converts images to .dds format with correct channel packing |
| xWMAEncode | Free (bundled with ModSDK) | Converts .wav → .xwm for in-game audio |
| **Universal Image Converter** | Free | GUI tool that handles all SE texture conversions automatically |
| **Universal Audio Converter** | Free | Batch converts audio and auto-generates Audio.sbc entries |

SEUT wiki: `spaceengineers.wiki.gg/wiki/Modding/Tools/Space_Engineers_Utilities`

---

## Mod Folder Structure

Every mod lives under `%AppData%\SpaceEngineers\Mods\`.

```
%AppData%\SpaceEngineers\Mods\
└── YourModName\
    ├── Data\                 ← REQUIRED — even if empty; mod fails to load without it
    │   ├── CubeBlocks\       ← SBC files can be in any subfolder under Data\
    │   │   └── MyBlocks.sbc
    │   └── Scripts\
    │       └── YourModName\  ← C# scripts must be in a named subfolder (matches mod name)
    │           └── MyScript.cs
    ├── modinfo.sbmi          ← auto-generated on first Workshop publish
    └── thumb.png             ← optional thumbnail
```

**Critical rules:**
- `Data\` must exist or the game won't load the mod
- All `.sbc` files anywhere under `Data\` are loaded automatically — folder names don't matter
- `.sbc` must be lowercase — `.SBC` is ignored
- C# scripts must be inside `Data\Scripts\YourModName\` — not directly in `Scripts\`

---

## Verifying Your Mod Loads

1. Launch SE → New Game (or load existing world) → Edit Settings → Mods
2. Your mod appears in the **Local** tab with a house icon
3. Add it to the world, start the game
4. Open `%AppData%\SpaceEngineers\` and find the most recent `.log` file (sort by date)
5. Search for `ERROR` or `MOD_CRITICAL_ERROR` — if none, your mod loaded cleanly

For SBC mods, also search for `No definition` — this means a TypeId or SubtypeId was wrong.

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for a full error reference.

---

## Setting Up a C# Mod Project (VS Code + MDK2)

**Step 1 — Install MDK Hub**
Download and run the installer from https://github.com/malforge/mdk2/releases. It installs .NET 9 and the project templates.

**Step 2 — Create the project**
```bash
dotnet new mdk2mod -n YourModName -o YourModName
```
Or use MDK Hub's GUI "New Project" button.

**Step 3 — Open in VS Code**
File → Open Folder → select the folder containing the `.csproj`.

**Step 4 — Install extensions**
- `ms-dotnettools.csdevkit`
- `redhat.vscode-xml`

**Step 5 — Configure output path**
Create `YourMod.mdk.local.ini` next to the `.csproj`:
```ini
[mdk]
type=mod
binarypath=auto
output=C:\Users\[Username]\AppData\Roaming\SpaceEngineers\Mods\YourModName
interactive=ShowNotification
```

**Step 6 — Build**
`Ctrl+Shift+B` in VS Code, or `dotnet build` in the terminal.

The MDK2 whitelist analyzer will flag any disallowed API calls with red squiggles as you type.

**Important C# project rules:**
- Target `net48` — SE runs on .NET Framework 4.8, not net6/net8
- Language version is C# 6 — newer features cause compile errors
- Platform must be `x64` — not AnyCPU
- Never `using Sandbox.ModAPI.Ingame;` — use type aliases instead (causes ambiguous reference errors)

---

## Publishing to Steam Workshop

1. Load any world in SE
2. Edit Settings → Mods → find your local mod
3. Click **Publish** → choose tags → confirm
4. Game auto-generates `modinfo.sbmi` in your mod folder with the Workshop ID

**Updating:** Same process — the presence of `modinfo.sbmi` makes SE show an "update" prompt instead of creating a new item.

**If modinfo.sbmi goes missing:**
```xml
<?xml version="1.0"?>
<MyObjectBuilder_ModInfo xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <WorkshopIds>
    <WorkshopId>
      <Id>YOUR_WORKSHOP_ID</Id>
      <ServiceName>Steam</ServiceName>
    </WorkshopId>
  </WorkshopIds>
</MyObjectBuilder_ModInfo>
```

Workshop ID is the number in the Workshop URL: `?id=1234567890`

---

## Using Another Mod's Assets (Without Copying Them)

You can reference models, textures, and icons from another Workshop mod using the `..\\` path syntax — no copying required, no permission needed.

```xml
<!-- Your own mod's assets (standard) -->
<Icon>Textures\GUI\Icons\MyBlock.dds</Icon>

<!-- Another mod's assets (Workshop ID: 12345678) -->
<Icon>..\\12345678\\Textures\\GUI\\Icons\\TheirBlock.dds</Icon>
```

This works because all Workshop mods live in the same parent folder (`244850\`), and `..\\` navigates up to it.

**For local testing:** Copy the target mod's folder into `%AppData%\SpaceEngineers\Mods\` and rename it to the Workshop ID number. Your `..\\12345678\\` references will resolve correctly.

**Full guide:** [SBC_RULES.md — Cross-Mod Asset References](sbc/SBC_RULES.md)

---

## Changing Another Mod's Definitions

SE definitions are fully overwritten — your mod must include the complete definition to change any single field. But **Mod Adjuster** lets you patch only the fields you want to change, without copying the whole definition or any assets.

See [MOD_ADJUSTER.md](MOD_ADJUSTER.md) for the full guide.

**Note:** Mod Adjuster is C#-scripted, so it won't work on console.

---

## Mod Load Order

Mods load **bottom-to-top** in the in-game mod list. The mod **highest** in the list is loaded last and wins any definition conflicts.

---

## Where to Get Help

| Resource | Best for |
|----------|---------|
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Error messages, log reading, common failures |
| [Keen Discord](https://discord.gg/keenswh) | `#modding-programming` (C#), `#modding-art-sbc` (SBC/art) |
| [Keen Support](https://support.keenswh.com/spaceengineers) | Reporting confirmed engine bugs |
| [Official ModAPI docs](https://keensoftwarehouse.github.io/SpaceEngineersModAPI/api/index.html) | C# API reference |
| [Community ModAPI docs](https://malforge.github.io/spaceengineers/modapi/) | Broader C# API reference |
| SE Wiki | https://spaceengineers.wiki.gg/wiki/Modding |

---

## Finding a Block's TypeId and SubtypeId

<!-- source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Finding_SBC -->

Display names and internal IDs are often completely different (e.g., "Action Relay" is `TransponderBlock` internally). Use this workflow to find the correct identifiers for any block or item.

**Step 1 — Find the display name key in localization**

Open: `[SE install]\Content\Data\Localization\MyTexts.resx`

Search for the exact in-game display name (case-insensitive). Copy the `name` attribute value from the matching entry.

```xml
<!-- Example result when searching "Custom Turret Controller" -->
<data name="DisplayName_TurretControlBlock" xml:space="preserve">
  <value>Custom Turret Controller</value>
</data>
```

Copy: `DisplayName_TurretControlBlock`

**Step 2 — Find the block definition using that key**

In Notepad++ (Ctrl+Shift+F) or VS Code (search across files):
- **Find what:** `DisplayName_TurretControlBlock`
- **Filter:** `*.sbc`
- **Directory:** `[SE install]\Content\Data\`
- Disable case-sensitive and whole-word matching

**Step 3 — Read TypeId and SubtypeId from the result**

Open the matching file. The definition's `<Id>` block gives you what you need:

```xml
<Id>
  <TypeId>TurretControlBlock</TypeId>
  <SubtypeId>LargeTurretControlBlock</SubtypeId>
</Id>
```

**Shortcuts:**
- The vanilla SBC files are at: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\`
- Notepad++ "Find in Files" (`Ctrl+Shift+F`) is the fastest tool for this
- VS Code: `Ctrl+Shift+F` → set "files to include" to `*.sbc`

---

## Symlink Trick: Separate Source from Published Mod

<!-- source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Setting_Up_a_Modding_Environment -->

Keep your source files (`.blend`, `.csproj`, reference docs) outside the mod folder while SE reads from `%AppData%`. Use a directory junction (symlink):

```cmd
mklink /J "%AppData%\SpaceEngineers\Mods\YourModName" "C:\Dev\YourModName\Content"
```

This makes SE see `YourModName\Content\` as if it were the mod folder directly. Your source files stay in `C:\Dev\YourModName\` without appearing inside the mod.

**Also useful:** Create desktop shortcuts to:
- `%AppData%\SpaceEngineers\` (logs and local mods)
- `[Steam]\steamapps\common\SpaceEngineers\Content\Data\` (vanilla SBCs)
- Your mod development folder

---

## Wiki Tutorial Index

<!-- source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials -->

Key wiki pages not already linked elsewhere in these skill files:

| Topic | URL |
|-------|-----|
| Adding to Block Categories | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/BlockCategories` |
| Adding to Block Variant Groups | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/BlockVariantGroups` |
| Blueprint Classes (assembler tabs) | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/BlueprintClasses` |
| Progression / Research locks | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Progression` |
| Adding LCDs/Screens to blocks | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Screens` |
| Cargo loot tables | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Cargo_Loot` |
| Convert Prefab ↔ ShipBlueprint | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Convert_between_Prefab_and_ShipBlueprint` |
| Adding localization strings | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/Localization` |
| Exploring game code (decompile) | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/Exploring_Game_Code` |
| Debugging with dnSpy | `spaceengineers.wiki.gg/wiki/Scripting/Debugging_with_dnSpy` |
| Armor block recipe (full) | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/Armor_Block` |
| LCD App mod script recipe | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script` |
| Modifying mods by other creators | `spaceengineers.wiki.gg/wiki/Modding/Tutorials/Modifying_Mods_by_Other_Creators` |
| PB scripting (ingame scripts) | `spaceengineers.wiki.gg/wiki/Scripting` |

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding](https://spaceengineers.wiki.gg/wiki/Modding) — official modding overview and tutorial index
- [spaceengineers.wiki.gg/wiki/Modding/Tutorials/Creating_And_Uploading_Mods](https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Creating_And_Uploading_Mods) — publishing workflow

### Internal
- [sbc/SBC_RULES.md](sbc/SBC_RULES.md) — universal SBC rules; start here for any SBC work
- [RECIPES.md](RECIPES.md) — end-to-end worked examples for common mod types
- [ASSETS.md](ASSETS.md) — full asset pipeline for 3D models, textures, and audio
