# Pulsar — Space Engineers Client Plugin Loader

## What Is Pulsar?

Pulsar is a community-maintained **client-side plugin loader** for Space Engineers. It is the continuation of the discontinued PluginLoader project. When a player launches the game through Pulsar, it injects plugins into the running game client at runtime.

**Key distinction:**
- **Pulsar plugins** = client-side only — affect only the local player's game
- **Torch plugins** = server-side — affect everyone on a dedicated server

This means a Pulsar plugin can do things like modify the HUD, change rendering, or add custom UI overlays — things that game mods (which run through the server's mod list) cannot touch.

---

## How It Works

Pulsar replaces the normal game launch process. Instead of Steam launching `SpaceEngineers.exe` directly, it launches Pulsar first, which then:

1. Loads and validates installed plugins
2. Compiles plugin source code from GitHub (all plugins must be open source)
3. Injects plugins into the game process
4. Starts the game normally

Because plugins are **compiled on the player's machine from GitHub source**, every plugin must be publicly hosted on GitHub. This is both a transparency measure and a security feature — users can read what they're running.

---

## Three Executables

Pulsar ships three variants to cover different SE versions and runtimes:

| Executable | Target |
|------------|--------|
| **Legacy** | Space Engineers 1 on .NET Framework |
| **Interim** | Space Engineers 1 on .NET 10 (via se-dotnet-compat) |
| **Modern** | Space Engineers 2 on .NET 10 |

---

## Installation (Player)

### Option A — Pulsar Installer (recommended)

Use the Windows installer from [github.com/StarCpt/Pulsar-Installer](https://github.com/StarCpt/Pulsar-Installer). It automates the Steam configuration step.

### Option B — Manual

1. Download the latest Pulsar release from [github.com/SpaceGT/Pulsar/releases](https://github.com/SpaceGT/Pulsar/releases)
2. Extract to any folder (keep it clean — Pulsar overwrites files on update)
3. In Steam, set Space Engineers launch options:
   - **Windows:** `[PulsarPath] %command%`
   - **Linux:** `bash -c 'exec "${@:0:$#}" [PulsarPath] "${@:$#}"' %command%`
4. Launch the game through Steam — Pulsar loads first, then the game starts

---

## Plugin Sources

Pulsar can load plugins from multiple sources. The officially endorsed source is **PluginHub**.

### PluginHub

[github.com/StarCpt/PluginHub](https://github.com/StarCpt/PluginHub) — a curated registry of vetted plugins. Plugins here have been reviewed by the approval team before listing.

Additional community plugin registries can be added in-game, though users accept more risk with unvetted sources.

### Notable Plugins

| Plugin | Purpose |
|--------|---------|
| **Multigrid Projector** | Project and weld multi-grid blueprints |
| **Better Inventory Search** | Improved inventory search/filter UI |
| **GPS Folders** | Organize GPS markers into folders |
| **SE WorldGen** | World generation enhancements |
| **Performance** tools | Client-side FPS/sim speed improvements |

---

## Developing a Pulsar Plugin

### Core Rules

1. **Must be open source** — hosted publicly on GitHub
2. **Compiled on player's machine** — from the exact GitHub commit registered in PluginHub
3. **Client-side only** — plugins affect the local player, not the server
4. **Security review on PluginHub submission** — reviewed before listing (no legal guarantees)

### Prerequisites

- Visual Studio 2022 or JetBrains Rider
- Space Engineers installed (Steam)
- .NET Framework 4.8.1 Developer Pack (for SE1 Legacy)
- .NET 10 SDK (for SE1 Interim / SE2 Modern)
- Python 3.x (for template setup script)

### Recommended Starting Point

Use the unified plugin template that covers client (Pulsar), Torch, and dedicated server:
[github.com/sepluginloader/PluginTemplate](https://github.com/sepluginloader/PluginTemplate)

```
PluginTemplate/
├── ClientPlugin/         ← Pulsar client-side plugin
├── TorchPlugin/          ← Torch server plugin
├── DedicatedPlugin/      ← Vanilla DS plugin
├── Shared/               ← Code shared across all three
└── Doc/                  ← Documentation and examples
```

Setup steps:
1. Click **Use this template** on GitHub and create your repo
2. Clone locally
3. Run `setup.py MyPluginName` (uses CapitalizedWords format)
4. Open the `.sln` in Visual Studio or Rider
5. Build and test

### Plugin Class Structure

```csharp
using HarmonyLib;

namespace MyPlugin
{
    // Pulsar discovers this class automatically
    public class MyClientPlugin : IPlugin
    {
        public void Init()
        {
            // Called when plugin is loaded, before game loop
            var harmony = new Harmony("com.myname.myplugin");
            harmony.PatchAll(Assembly.GetExecutingAssembly());
        }

        public void Update()
        {
            // Called every game tick
        }

        public void Dispose()
        {
            // Called on unload / game exit
        }
    }
}
```

### Patching Game Internals (HarmonyLib)

Pulsar plugins access game internals through HarmonyLib patches and the game's decompiled code. Since SE is not open source, developers use tools like **dnSpy** or **ILSpy** to decompile game assemblies and understand what to patch.

```csharp
[HarmonyPatch(typeof(MyHudClass), "DrawHudElement")]
public static class HudPatch
{
    public static void Postfix()
    {
        // Run after the original method — add custom HUD overlay
    }
}
```

### EnsureCode — Crash Prevention

The plugin template includes an `EnsureCode` attribute. Annotate patches with a hash of the original method body. If a game update changes the method, the plugin disables safely instead of crashing:

```csharp
[EnsureCode("a1b2c3d4")]
[HarmonyPatch(typeof(SomeGameClass), "SomeMethod")]
public static class MyPatch { ... }
```

### Conditional Compilation

The template uses preprocessor symbols to share code across plugin types:

```csharp
#if !TORCH
    // Client and dedicated only
#endif

#if DEDICATED
    // Dedicated server only
#endif
```

The `TORCH` symbol is defined in the Torch project; `DEDICATED` in the DS project. Client/Pulsar plugins have neither.

### Accessing Internal Game Members

SE game classes often have `internal` or `private` members. Use a **publicizer** tool at build time to expose them:

- Add `publicizer` as a NuGet package or use the template's built-in setup
- This generates a modified reference assembly where all members are public
- Only used at compile time — no changes to the actual game files

---

## Publishing to PluginHub

1. Host your plugin on a **public GitHub repo**
2. Fork [github.com/StarCpt/PluginHub](https://github.com/StarCpt/PluginHub)
3. Add an XML descriptor file to the `Plugins/` folder:

```xml
<!-- Plugins/MyPlugin.xml -->
<PluginItem>
  <Name>My Plugin Name</Name>
  <Author>YourName</Author>
  <Repository>YourGitHubUser/MyPlugin</Repository>
  <Commit>abc1234</Commit>                  <!-- exact commit to compile -->
  <Description>What this plugin does</Description>
</PluginItem>
```

4. Submit a pull request — the approval team reviews it
5. Once merged, players can find and install it through Pulsar's in-game plugin browser

---

## Pulsar vs Torch — Quick Reference

| | Pulsar | Torch |
|--|--------|-------|
| **Scope** | Client-side (one player) | Server-side (all players) |
| **Who installs** | Each player individually | Server admin only |
| **What it can modify** | HUD, UI, rendering, client behavior | Server logic, world state, entities |
| **Requires server** | No | Yes (replaces DS executable) |
| **Plugin source** | Open source GitHub (compiled locally) | Closed or open, distributed as .zip |
| **Use case** | Personal QoL, HUD mods, client fixes | Admin tools, performance, multi-server |

---

## Interaction with Game Mods

Pulsar plugins and normal SE mods are complementary:

- A **game mod** (Workshop/mod.io) runs on the server and affects the world for all players — it can add new blocks, change definitions, run session components
- A **Pulsar plugin** runs on the client and can read that mod's data and do things with it locally — e.g., a mod adds an LCD block type, a plugin reads its content and renders it on the player's HUD

Some mods are specifically designed to work with a paired plugin. When helping a user with such a mod, check if a companion plugin is required.

---

## Safety Notes

- Install plugins only from trusted sources (PluginHub is the safest)
- Plugins have **full access to the player's PC** — they are not sandboxed like PB scripts or mods
- Pulsar does not pose VAC ban risk (Space Engineers is not VAC protected), but server admins may run anticheat plugins
- Plugins that modify network traffic or fake server data may be considered cheating on PvP servers

---

## Resources

- [github.com/SpaceGT/Pulsar](https://github.com/SpaceGT/Pulsar) — Pulsar source and releases
- [github.com/StarCpt/Pulsar-Installer](https://github.com/StarCpt/Pulsar-Installer) — Windows installer
- [github.com/StarCpt/PluginHub](https://github.com/StarCpt/PluginHub) — official plugin registry
- [github.com/sepluginloader/PluginTemplate](https://github.com/sepluginloader/PluginTemplate) — unified plugin template
- [spaceengineers.wiki.gg/wiki/Plugins](https://spaceengineers.wiki.gg/wiki/Plugins) — SE wiki plugin overview
