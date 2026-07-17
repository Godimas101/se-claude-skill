---
name: se-plugins
description: "Use for Space Engineers server or client plugin development. Torch = dedicated server framework (plugins load into a headless server process, use TorchAPI, NexusV3 for multi-server). Pulsar = client-side plugin loader (plugins load into the game client via PluginHub, HarmonyLib for patching). Concrete triggers: 'write a Torch plugin', 'Pulsar plugin', HarmonyLib patch on a game method, TorchAPI usage, multi-server (NexusV3) coordination, dedicated-server-only modding without changing the game files. SKIP for: mods that ship with a saved game / world (use se-csharp / se-sbc / etc.), in-game PB scripts (use se-pb-scripts). Plugins are NOT mods — different install path, different lifecycle, different auth model."
---

# SE Plugins — Torch (server) and Pulsar (client)

Server and client extensibility that sit **outside** the mod system. Plugins load into their respective host process at startup.

## Which one?

| Framework | Runs in | Reference |
|-----------|---------|-----------|
| **Torch** | Dedicated server process | [references/torch.md](references/torch.md) |
| **Pulsar** | Game client process | [references/pulsar.md](references/pulsar.md) |

Ask the user which and where it's installed — install paths differ.

## Cross-cutting notes

- **Plugins vs mods.** Mods ship inside `Data/` and are Workshop-distributed. Plugins are separate DLLs loaded by Torch or Pulsar, distributed via TorchAPI / PluginHub. A plugin cannot rely on mod-only APIs, and vice versa.
- **HarmonyLib.** Both frameworks use HarmonyLib for monkey-patching game methods. Standard cautions apply — patches break on game updates that rename or restructure the target method.
- **Multi-server (Torch)** — NexusV3 for coordinating a fleet. Reference doc covers the manifest format.
