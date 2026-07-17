<p align="center">
  <img src="https://capsule-render.vercel.app/api?type=waving&height=170&color=0:140A22,45:7C3AED,100:C084FC&text=🚀%20Space%20Engineers%20Skill&fontColor=ffffff&fontAlignY=35&fontSize=30&desc=Claude%20Code%20help%20for%20SBC,%20C%23,%20PB,%20and%20framework%20mods&descAlignY=57&descSize=18" />
</p>

> **"Because reading SBC files by hand is how you lose a weekend."**

An expert modding assistant for Claude Code covering the full spectrum of Space Engineers mod development — from your first `.sbc` file to shipping a full compiled C# mod with custom 3D assets.

> **Patch notes:** see [`CHANGELOG.md`](CHANGELOG.md) or the [GitHub Releases page](https://github.com/Godimas101/se-claude-skill/releases) for major milestones. **v4.0.0 is a structural refactor** — one monolithic skill became a Claude Code plugin with ten focused skills.

---

## 📦 The 10 skills

Each activates on its own set of triggers and stays out of the others' way. Descriptions include explicit `SKIP for:` clauses so Claude doesn't over-activate.

| Skill | When it activates |
|-------|-------------------|
| **[se-core](skills/se-core/SKILL.md)** | Start-of-session workspace checks and mod-type routing. Ambiguous SE questions land here. |
| **[se-getting-started](skills/se-getting-started/SKILL.md)** | User is new to SE modding and doesn't know what mod type to build. |
| **[se-sbc](skills/se-sbc/SKILL.md)** | SBC/XML content: blocks, items, blueprints, categories, LCD registration. |
| **[se-csharp](skills/se-csharp/SKILL.md)** | Compiled C# — session components, game logic components. MDK2, decompiler, block API queries. |
| **[se-tss](skills/se-tss/SKILL.md)** | Text Surface Scripts — the compiled DLL type that draws to LCD screens. |
| **[se-pb-scripts](skills/se-pb-scripts/SKILL.md)** | In-game Programmable Block scripts — sandboxed C# with whitelist restrictions. |
| **[se-frameworks](skills/se-frameworks/SKILL.md)** | MES, WeaponCore, Mod Adjuster, AI Enabled, Animation Engine, Scope Framework, Tank Tracks, Vanilla+. |
| **[se-assets](skills/se-assets/SKILL.md)** | 3D models (Blender/SEUT), textures (DX11 channel packing), Havok collisions, audio. |
| **[se-plugins](skills/se-plugins/SKILL.md)** | Torch (dedicated server) and Pulsar (client) plugin development — outside the mod system. |
| **[se-troubleshooting](skills/se-troubleshooting/SKILL.md)** | Diagnostic — log reading, error catalog, patch/DLC tracking. |

## 🔌 On session start

The plugin ships a **SessionStart hook** ([`hooks/se-context.sh`](hooks/se-context.sh)) that detects an SE modding workspace by looking for common signals: `Data/CubeBlocks/`, `Bin64_Profile/`, `SpaceEngineers.log`, or a subscribed Workshop directory (`steamapps\workshop\content\244850\`). When detected, it injects a note so Claude prefers the SE skills without you typing `/space-engineers`.

**Windows note:** the hook is bash. On Windows you need Git for Windows (Git Bash) or WSL on `PATH`. Without it, the hook doesn't fire but the skills still work — you just have to invoke them manually.

## 📦 Install

### Claude Code plugin (recommended, after v2.0)

```
/plugin marketplace add /path/to/claude-skills
/plugin install space-engineers@claude-skills
```

Adjust marketplace name to whatever directory you registered.

### Manual (legacy, pre-v2.0)

Copy the `space-engineers/` folder into your Claude Code skills directory:

**Windows:**
```
C:\Users\[YourName]\.claude\skills\space-engineers\
```

**Linux/Mac:**
```
~/.claude/skills/space-engineers/
```

Note: manual install treats the entire folder as a single skill, which doesn't match the plugin structure. Prefer the plugin install path.

---

## 🗂️ Recommended workspace setup

The plugin works out of the box, but it becomes **significantly more powerful** when Claude can browse your actual game files. `se-core` prompts for any missing directories on session start.

Add these as **additional working directories** in your VS Code workspace:

| Directory | Why |
|-----------|-----|
| `[Steam]\steamapps\common\SpaceEngineers\` | Vanilla SBC files — ground truth for all block/item definitions, balance values, XML schema |
| `[Steam]\steamapps\common\SpaceEngineersModSDK\` | API DLLs with XML documentation — required for compiled mod and PB script work |
| Your mod project folder | Your actual mod source files |
| `[Steam]\steamapps\workshop\content\244850\` | Your subscribed mods — used to cross-reference frameworks and other mods |
| `%AppData%\SpaceEngineers\` | Game logs — needed to debug crashes and mod load errors |

> **Default Steam path on Windows:** `C:\Program Files (x86)\Steam\` or `D:\SteamLibrary\` depending on your install.
>
> **Default AppData path on Windows:** `C:\Users\[YourName]\AppData\Roaming\SpaceEngineers\`

---

## 💬 Usage examples

```
> I want to add scrolling to the battery list on my status LCD screen
   → activates: se-tss

> Help me write a Mod Adjuster patch to increase the power output of all solar panels by 50%
   → activates: se-frameworks

> Write a PB script that monitors battery charge and broadcasts a warning via IGC when below 20%
   → activates: se-pb-scripts

> My mod isn't loading — here's the game log, can you find the error?
   → activates: se-troubleshooting

> I want to add a custom block with a 3D model — where do I start?
   → activates: se-getting-started (or se-assets if you know the drill)
```

---

## Requirements

- [Claude Code](https://www.anthropic.com/claude-code)
- Space Engineers installed via Steam
- Space Engineers ModSDK installed (free via Steam → Library → Tools)
- For compiled mods: [MDK2](https://github.com/malforge/mdk2/releases) and **VS Code** (recommended) or Visual Studio / Rider
- For Mod Adjuster mods: [Mod Adjuster](https://steamcommunity.com/workshop/filedetails/?id=3017795356) subscribed in Steam Workshop
- For asset pipeline work: Blender 4.0+ with the [SEUT addon](https://spaceengineers.wiki.gg/wiki/Modding/Tools/Space_Engineers_Utilities)
- For the SessionStart hook on Windows: Git for Windows (Git Bash) or WSL

---

## Credits

Built by **Godimas** and **Claude**. v2.0 plugin refactor modeled after [Epic Games' Unreal Engine skills plugin](https://github.com/EpicGames/unreal-engine-skills-for-claude-code-plugin) and Romuald Członkowski's [n8n-skills](https://github.com/czlonkowski/n8n-skills).

Mod Adjuster XML format reverse-engineered from the [Mod Adjuster](https://steamcommunity.com/workshop/filedetails/?id=3017795356) mod source (Workshop ID: 3017795356). Framework documentation sourced from the [Space Engineers Wiki](https://spaceengineers.wiki.gg/wiki/Modding/Reference) and community resources.

---

## 🧡 Support

This skill is free and always will be. If it helps with your mods, consider supporting on Patreon — it helps keep the tools and mods coming.

[![Support on Patreon](https://raw.githubusercontent.com/Godimas101/personal-projects/main/patreon/images/buttons/patreon-medium.png)](https://patreon.com/Godimas101)

---

*Jetpack not included.* 🚀
