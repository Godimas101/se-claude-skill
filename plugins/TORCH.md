# Torch — Space Engineers Dedicated Server Framework

## What Is Torch?

Torch is a community-developed wrapper for the Space Engineers Dedicated Server (the successor to SE Server Extender). It replaces the vanilla DS executable with an extended version that provides:

- **WPF-based GUI** for server management without joining the game
- **In-game chat integration** — admins can read and send chat, run commands remotely
- **Entity manager** — inspect and modify grids/blocks in real time
- **Config editor** — structured UI for `SpaceEngineers-Dedicated.cfg`
- **Plugin system** — extensible architecture for community plugins

Torch is **server-side only**. All changes affect every player on the dedicated server.

---

## Installation

1. Download the latest Torch release from [torchapi.com](https://torchapi.com/)
2. Extract to your server folder (replaces the vanilla DS)
3. Run `Torch.Server.exe` instead of `SpaceEngineersDedicated.exe`
4. On first run Torch generates `Torch.cfg` and `Instance/` directories

### Folder Structure

```
Torch/
├── Torch.Server.exe          ← run this instead of vanilla DS
├── Torch.cfg                 ← main Torch config (plugin GUIDs live here)
├── Plugins/                  ← drop plugin .zip files here
├── Instance/                 ← SE world data (same as vanilla DS instance)
│   ├── SpaceEngineers-Dedicated.cfg
│   └── Saves/
└── UserData/                 ← Torch-specific data (logs, plugin configs)
```

---

## Plugin System

### Installing Plugins (Admin)

1. Find the plugin at [torchapi.com/plugins](https://torchapi.com/plugins) — note the GUID from the URL
2. Download the `.zip` file — place it in `Plugins/` **without extracting**
3. Edit `Torch.cfg` and add the GUID:

```xml
<Plugins>
  <guid>cbfdd6ab-4cda-4544-a201-f73efa3d46c0</guid>  <!-- Essentials -->
  <guid>your-plugin-guid-here</guid>
</Plugins>
```

4. Restart the server — Torch loads plugins on startup

---

## Developing a Torch Plugin

### Prerequisites

- Visual Studio 2022 or JetBrains Rider
- .NET Framework 4.8.1 Developer Pack
- Space Engineers Dedicated Server installed locally
- Python 3.x (for setup scripts)

### Recommended Starting Point

Use the official plugin template:
[github.com/sepluginloader/PluginTemplate](https://github.com/sepluginloader/PluginTemplate)

It covers client, Torch, and dedicated server plugins in one solution with shared code.

### Project Setup

```
MyPlugin/
├── MyPlugin.sln
├── manifest.xml              ← plugin metadata
├── MyPlugin/
│   ├── MyPlugin.cs           ← main plugin class
│   └── MyPlugin.csproj
└── Setup (run before opening solution).bat
```

Run the setup bat first — it creates a symlink to the SE DS DLLs so the project can reference them.

### manifest.xml

```xml
<?xml version="1.0"?>
<PluginManifest xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <Name>My Plugin Name</Name>
  <Guid>xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx</Guid>
  <Version>1.0.0</Version>
  <Dependencies>
    <!-- Optional: list GUIDs of plugins this depends on -->
  </Dependencies>
</PluginManifest>
```

Generate a GUID with `[Guid]::NewGuid()` in PowerShell or Visual Studio.

### Core Interface — ITorchPlugin

```csharp
using Torch.API;
using Torch.API.Plugins;

namespace MyPlugin
{
    public class MyPlugin : TorchPluginBase
    {
        // Called once before the game loop starts
        public override void Init(ITorchBase torch)
        {
            base.Init(torch);
            // Store torch reference, load config, register commands
        }

        // Called every game tick
        public override void Update()
        {
            // Runs each server tick — keep this fast
        }

        // Called on plugin unload / server shutdown
        public override void Dispose()
        {
            // Cleanup
        }
    }
}
```

`TorchPluginBase` is the convenience base class that implements `ITorchPlugin`. Key members:

| Member | Description |
|--------|-------------|
| `Torch` | Reference to `ITorchBase` — access to server, config, managers |
| `Init(ITorchBase)` | Startup hook, runs before game loop |
| `Update()` | Runs every server tick |
| `Dispose()` | Shutdown / cleanup |
| `State` | `PluginState` enum (Enabled, Disabled, Error, etc.) |
| `IsReloadable` | Whether plugin supports hot-reload |

### Optional: WPF UI Panel

Implement `IWpfPlugin` to add a settings panel in the Torch GUI:

```csharp
public class MyPlugin : TorchPluginBase, IWpfPlugin
{
    private MyControl _control;

    public UserControl GetControl()
    {
        return _control ?? (_control = new MyControl(this));
    }
}
```

### Patching Game Code (HarmonyLib)

Most plugins patch game internals using HarmonyLib:

```csharp
using HarmonyLib;

[HarmonyPatch(typeof(SomeGameClass), "SomeMethod")]
public static class MyPatch
{
    public static bool Prefix(ref int someParam)
    {
        // Return false to skip the original method
        return true;
    }
}
```

In `Init()`:

```csharp
var harmony = new Harmony("com.myname.myplugin");
harmony.PatchAll(Assembly.GetExecutingAssembly());
```

### EnsureCode — Crash Prevention

From the plugin template — annotate patches with a hash of the original method so the plugin safely disables itself if the game updates and the method changes:

```csharp
[EnsureCode("a1b2c3d4")]
[HarmonyPatch(typeof(SomeGameClass), "SomeMethod")]
public static class MyPatch { ... }
```

---

## Key APIs

| API | Description |
|-----|-------------|
| `Torch` / `ITorchBase` | Root object — access everything |
| `Torch.CurrentSession` | Active server session |
| `Torch.Config` | `ITorchConfig` — server config |
| `Torch.Managers` | Service locator for manager components |
| `Torch.ChatManager` | Send/receive in-game chat |
| `TorchPluginBase.Torch` | Access from within a plugin |

---

## Notable Plugins

| Plugin | Purpose |
|--------|---------|
| **Essentials** | Must-have admin tools: custom commands, voting, player ranks/permissions |
| **Concealment** | Performance — stops updating grids far from any player, critical for large servers |
| **NexusV3** | Multi-server networking — sectors, world sync, Nexus gates |
| **Performance Improvements** | Various server-side optimizations (safe zone caching, grid merge improvements) |
| **Torch Build and Repair** | Server-side build and repair ship block |
| **ALE** plugins | Various admin/economy tools by ALE-Dev |

---

## NexusV3 — Multi-Server Sectoring

Nexus is the flagship multi-server plugin for Torch. It lets you run one large SE world across multiple physical servers.

### How It Works

- A **Cluster** = the whole world shared across servers
- **Sectors** = subdivisions of the world, each handled by a different server instance
- A separate **controller application** acts as master node, proxying network messages between servers

### Sector Shapes

| Shape | Use Case |
|-------|----------|
| **Sphere** | Planets, moons, atmospheres — center point + radius in km |
| **Cuboid** | Grid-like space division, rectangular zones |
| **Torus** | Asteroid belts, ring systems |

### What Gets Synced

Chat, economy, factions, player identities, reputation — all synchronized in real time across servers in the cluster.

### Nexus Gates

Configurable portal blocks that teleport players between server sectors. Customizable particle effects.

### Server Types

| Type | Behavior |
|------|---------|
| Synced & Sectored | Full live sync, participates in world sectoring |
| Synced & Non-Sectored | Connected but not split into sectors |
| Non-Synced | Mostly standalone, minimal Nexus integration |
| Start-Synced | Pulls initial data then goes isolated (good for events) |

---

## Limitations

- Torch must be kept up to date when SE updates — game patches can break Torch until it's updated
- Not all SE features work identically through Torch vs vanilla DS
- Plugin load order can matter if plugins patch the same game methods
- HarmonyLib patches can conflict between plugins — check compatibility
- Nexus V2 is deprecated; use NexusV3

---

## Resources

- [torchapi.com](https://torchapi.com/) — downloads, plugin directory
- [wiki.torchapi.com](https://wiki.torchapi.com/) — official wiki
- [github.com/TorchAPI/Torch](https://github.com/TorchAPI/Torch) — source code
- [github.com/TorchAPI/Essentials](https://github.com/TorchAPI/Essentials) — reference plugin
- [github.com/sepluginloader/PluginTemplate](https://github.com/sepluginloader/PluginTemplate) — unified plugin template
- [se-nexus.net](https://se-nexus.net/) — Nexus documentation
