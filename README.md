# 🚀 Space Engineers Modding Skill for Claude Code

> Because reading SBC files by hand is how you lose a weekend.

An expert modding assistant for Claude Code covering the full spectrum of Space Engineers mod development — from your first `.sbc` file to shipping a full compiled C# mod with custom 3D assets.

**Coverage:**
- **SBC/XML mods** — blocks, items, blueprints, economy, planets, and more
- **Compiled C# mods** — Text Surface Scripts (LCD screens), Session Components, Game Logic
- **Programmable Block scripts** — Main loop, GridTerminalSystem, IGC, coroutines
- **Framework mods** — MES, AI Enabled, WeaponCore, Mod Adjuster, Animation Engine, Scope Framework, Tank Tracks, Vanilla+
- **Server/client plugins** — Torch dedicated server plugins, Pulsar client-side plugins
- **Asset pipeline** — 3D modeling with SEUT/Blender, texture conversion, Havok collisions, MWM export

---

## 📦 Install

1. Copy the `space-engineers/` folder into your Claude Code skills directory:

   **Windows:**
   ```
   C:\Users\[YourName]\.claude\skills\space-engineers\
   ```

   **Linux/Mac:**
   ```
   ~/.claude/skills/space-engineers/
   ```

2. That's it. The skill is available as `/space-engineers` in any Claude Code session.

---

## 🗂️ Recommended Workspace Setup

The skill works out of the box, but it becomes **significantly more powerful** when Claude can browse your actual game files. When you invoke `/space-engineers`, Claude will check whether these directories are in your workspace and ask you to add any that are missing.

Add these as **additional working directories** in your VS Code workspace:

| Directory | Why |
|-----------|-----|
| `[Steam]\steamapps\common\SpaceEngineers\` | Vanilla SBC files — ground truth for all block/item definitions, balance values, and XML schema |
| `[Steam]\steamapps\common\SpaceEngineersModSDK\` | API DLLs with XML documentation — required for compiled mod and PB script work |
| Your mod project folder | Your actual mod source files |
| `[Steam]\steamapps\workshop\content\244850\` | Your subscribed mods — used to cross-reference frameworks and other mods you're building on |
| `%AppData%\SpaceEngineers\` | Game logs — needed to debug crashes and mod load errors |

> **Default Steam path on Windows:** `C:\Program Files (x86)\Steam\` or `D:\SteamLibrary\` depending on your install.
>
> **Default AppData path on Windows:** `C:\Users\[YourName]\AppData\Roaming\SpaceEngineers\`

---

## 🔌 On Startup

Every time you invoke `/space-engineers`, Claude runs a short setup sequence before asking what you need. Here's what to expect:

### Step 1 — Workspace checks

Claude looks for four directories in your workspace. For each one that's missing, it will tell you exactly what to add and why:

| Directory | What it unlocks | If missing |
|-----------|----------------|------------|
| SE game directory | Vanilla SBC definitions — ground truth for all block, item, and balance lookups | Claude asks you to add it |
| ModSDK | Full C# API docs — required for compiled mods and PB scripts | Claude asks you to add it + install instructions |
| AppData (`%AppData%\SpaceEngineers\`) | Game logs and crash dumps — needed for debugging | Claude asks you to add it |
| Workshop mod directory | Your subscribed mods — used to build/read the mod catalogue | Claude asks you to add it |

> **You don't need all four.** Claude works with whatever is available — missing directories just mean less context. If you're only writing PB scripts you can skip the mod directory entirely, for example.

### Step 2 — Mod catalogue check

If the workshop directory is present, Claude checks for a `MOD_CATALOGUE.md` file:

- **Found and fresh** → Claude reads it silently and knows what mods you have
- **Found but stale** (>30 days old) → Claude offers to refresh it
- **Not found** → Claude offers to build one — this indexes all your subscribed mods so it can reference them by name going forward

### Step 3 — DLC / patch check

Claude compares your installed DLC against its known catalogue. If new content is detected (a recent patch shipped new DLC), it flags it and offers to research the new additions before you start work.

### Step 4 — "How can I help?"

Once setup is done, Claude presents a short menu:

| Option | When to pick it |
|--------|----------------|
| **I'm new to modding** | Not sure where to start, or need the concepts explained |
| **Working on a mod** | SBC mod, compiled C# mod, framework mod, or PB script |
| **Torch or Pulsar plugin** | Server-side Torch plugin or client-side Pulsar plugin |
| **Just ask** | You have a specific question — skips all the setup prompts |

Picking **Working on a mod** triggers one more follow-up to narrow the type (brand new mod, framework mod, compiled C#, or PB script), then Claude loads the right reference files and gets to work.

---

## 📁 What's Inside

### Core

| File | Contents |
|------|---------|
| `SKILL.md` | Main skill — workspace checks, mod type routing, log reading, TSS/Session Component patterns |
| `GETTING_STARTED.md` | Beginner onboarding — mod types decision tree, tool setup, folder structure, publishing workflow |
| `SBC_TEMPLATES.md` | Copy-paste XML templates — blocks, items, blueprints, LCD surfaces, all common SBC patterns |
| `ASSETS.md` | Full asset pipeline — Blender/SEUT modeling, texture channel packing, Havok collisions, MWM export |
| `RECIPES.md` | Step-by-step worked examples — LCD App Script from scratch, full Armor Block mod |

### Scripting

| File | Contents |
|------|---------|
| `scripting/CSHARP_PATTERNS.md` | Extended C# reference — project setup, conveyor API, LCD drawing helpers, Save/Sync, performance rules |
| `scripting/PB_SCRIPTS.md` | Programmable Block guide — Main loop, UpdateFrequency, block interfaces, coroutines, IGC, sandbox restrictions |

### Framework Mods

| File | Contents |
|------|---------|
| `framework-mods/MOD_ADJUSTER.md` | Mod Adjuster — file structure, XML format, all definition types, non-destructive balance patching |
| `framework-mods/MES.md` | Modular Encounters System — spawn groups, prefabs, encounter types, MES-specific SBC fields |
| `framework-mods/AI_ENABLED.md` | AI Enabled — bot definitions, animation controllers, faction setup, child mod structure |
| `framework-mods/WEAPONCORE.md` | WeaponCore — weapon definitions, ammo types, targeting, WC-specific SBC fields |
| `framework-mods/ANIMATION_ENGINE.md` | Animation Engine — animation definitions, triggers, subpart control |
| `framework-mods/SCOPE_FRAMEWORK.md` | Scope Framework — optic overlay definitions, zoom levels, reticle setup |
| `framework-mods/TANK_TRACKS.md` | Tank Tracks — tracked vehicle setup, wheel group definitions |
| `framework-mods/VANILLA_PLUS.md` | Vanilla+ Framework — child mod structure, VPFAmmoDefinition, VPFTurretDefinition |

### Plugins

| File | Contents |
|------|---------|
| `plugins/TORCH.md` | Torch — installation, plugin development, manifest format, NexusV3 multi-server |
| `plugins/PULSAR.md` | Pulsar — installation, plugin development, PluginHub publishing, HarmonyLib patching |

### Troubleshooting & Reference

| File | Contents |
|------|---------|
| `troubleshooting/TROUBLESHOOTING.md` | Error reference — log reading strategy, all common errors with causes and fixes |
| `troubleshooting/PATCH_NOTES.md` | Breaking changes and notable additions by patch — quick reference for mod compatibility |
| `troubleshooting/DLC_CATALOGUE.md` | Full DLC pack listing with SubtypeIds — used for patch detection on skill load |

---

## 💬 Usage Examples

```
/space-engineers
> I want to add scrolling to the battery list on my status LCD screen
```

```
/space-engineers
> Help me write a Mod Adjuster patch to increase the power output of all solar panels by 50%
```

```
/space-engineers
> Write a PB script that monitors battery charge and broadcasts a warning via IGC when below 20%
```

```
/space-engineers
> My mod isn't loading — here's the game log, can you find the error?
```

```
/space-engineers
> I want to add a custom block with a 3D model — where do I start?
```

---

## Requirements

- [Claude Code](https://www.anthropic.com/claude-code)
- Space Engineers installed via Steam
- Space Engineers ModSDK installed (free via Steam → Library → Tools)
- For compiled mods: [MDK2](https://github.com/malware-dev/MDK-SE) and Visual Studio or Rider
- For Mod Adjuster mods: [Mod Adjuster](https://steamcommunity.com/workshop/filedetails/?id=3017795356) subscribed in Steam Workshop
- For asset pipeline work: Blender 4.0+ with the [SEUT addon](https://spaceengineers.wiki.gg/wiki/Modding/Tools/Space_Engineers_Utilities)

---

## Credits

Built by **Godimas** and **Claude**.

Mod Adjuster XML format reverse-engineered from the [Mod Adjuster](https://steamcommunity.com/workshop/filedetails/?id=3017795356) mod source (Workshop ID: 3017795356). Framework documentation sourced from the [Space Engineers Wiki](https://spaceengineers.wiki.gg/wiki/Modding/Reference) and community resources.

---

## 🧡 Support

This skill is free and always will be. If it helps with your mods, consider supporting on Patreon — it helps keep the tools and mods coming.

[![Support on Patreon](https://raw.githubusercontent.com/Godimas101/personal-projects/main/patreon/images/buttons/patreon-medium.png)](https://patreon.com/Godimas101)

---

*Jetpack not included.* 🚀
