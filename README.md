# 🚀 Space Engineers Modding Skill for Claude Code

> Because reading SBC files by hand is how you lose a weekend.

An expert skill for Claude Code covering all three types of Space Engineers mod development:

- **Compiled mods** — C# text surface scripts (LCD screens), session components, SBC XML definitions
- **Mod Adjuster mods** — Runtime definition patching via the [Mod Adjuster](https://steamcommunity.com/workshop/filedetails/?id=3017795356) framework
- **Programmable Block scripts** — Sandboxed ingame scripts (Main loop, GridTerminalSystem, IGC, etc.)

---

## Install

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

## Recommended VS Code Workspace Setup

The skill works out of the box, but it is **significantly more useful** when Claude can browse your actual game files directly. When you invoke `/space-engineers`, Claude will check whether these directories are available and ask you to add any that are missing.

Add these as **additional working directories** in your VS Code workspace (or Claude Code settings):

| Directory | Why |
|-----------|-----|
| `[Steam]\steamapps\common\SpaceEngineers\` | Vanilla SBC files — the ground truth for all block/item definitions. Required for looking up block properties, component costs, and balance values. |
| `[Steam]\steamapps\common\SpaceEngineersModSDK\` | API DLLs with XML documentation. Required for compiled mod and PB script work — intellisense, method signatures, interface definitions. |
| Your mod project folder | Your actual mod source files. Required for editing your mod. |
| `[Steam]\steamapps\workshop\content\244850\` | Your subscribed mods — useful for cross-referencing how other mods are structured. Optional but recommended. |
| `%AppData%\SpaceEngineers\` | Game logs and local mod files. Needed for debugging crashes and mod load errors. |

> **Default Steam path on Windows:** `C:\Program Files (x86)\Steam\` or `D:\SteamLibrary\` depending on your install.
>
> **Default AppData path on Windows:** `C:\Users\[YourName]\AppData\Roaming\SpaceEngineers\`

### How to add workspace directories in Claude Code

In VS Code, open your workspace settings and add the paths above as additional working directories. This lets Claude browse game files without you having to copy-paste paths into every prompt.

**ModSDK includes these tools out of the box (no extra downloads needed):**
- `Tools\xWMAEncode.exe` — WAV → XWM audio conversion for sound mods
- `Tools\AdpcmEncode.exe` — WAV → ADPCM audio conversion
- `Tools\VRageEditor\` — ModelViewer, ModelBuilder (FBX→MWM), AnimationController, VisualScripting

---

## What Claude Will Do Automatically

When you invoke `/space-engineers`, Claude will:

- **Check for required directories** — if the game directory, ModSDK, or a mod folder aren't in your workspace, Claude will ask you to add them before proceeding
- **Read your mod notes** — if a `MOD_MAKING_NOTES.md` exists in your mod directory, Claude reads it first to catch up on what was done in previous sessions and what's still pending. If one doesn't exist, Claude will offer to create it.
- **Check your mod catalogue** — if a `MOD_CATALOGUE.md` exists, Claude uses it to understand what mods you have and avoid naming collisions

---

## What's Inside

| File | Contents |
|------|---------|
| `SKILL.md` | Main skill — all mod types, SBC XML, C# patterns, asset pipeline, log reading, gotchas |
| `CSHARP_PATTERNS.md` | Extended C# reference — power/gas/inventory queries, drawing helpers, config patterns, performance rules |
| `SBC_TEMPLATES.md` | Copy-paste XML templates for common SBC patterns |
| `MOD_ADJUSTER.md` | Full Mod Adjuster guide — file structure, XML format, all definition types, patch examples |
| `PB_SCRIPTS.md` | Full PB scripting guide — Main loop, UpdateFrequency, block interfaces, coroutines, IGC, sandbox restrictions |
| `TORCH.md` | Torch dedicated server framework — installation, plugin development, manifest format, NexusV3 multi-server |
| `PULSAR.md` | Pulsar client plugin loader — installation, plugin development, PluginHub publishing, HarmonyLib patching |
| `PATCH_NOTES.md` | Breaking changes and notable additions by patch (1.200–1.208) — quick reference for mod compatibility |

---

## Usage Examples

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

---

## Requirements

- [Claude Code](https://www.anthropic.com/claude-code)
- Space Engineers installed via Steam
- Space Engineers ModSDK installed (free via Steam Tools)
- For Mod Adjuster mods: [Mod Adjuster](https://steamcommunity.com/workshop/filedetails/?id=3017795356) subscribed in Steam Workshop

---

## Credits

Built by **Godimas** and **Claude**.

Mod Adjuster XML format reverse-engineered from the [Mod Adjuster](https://steamcommunity.com/workshop/filedetails/?id=3017795356) mod source (Workshop ID: 3017795356).

---

## 🧡 Support

This skill is free and always will be. If it helps with your mods, consider supporting on Patreon — it helps keep the tools and mods coming.

[![Support on Patreon](https://raw.githubusercontent.com/Godimas101/personal-projects/main/patreon/patreon-medium.png)](https://patreon.com/Godimas101)

---

*Jetpack not included.* 🚀
