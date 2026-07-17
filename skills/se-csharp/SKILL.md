---
name: se-csharp
description: "Use for compiled C# Space Engineers mods: session components, game logic components, MDK2 project setup, decompiler workflows, block API queries (power/gas/inventory/production/doors/conveyor), C# runtime patterns (config via MyIni, save/sync, logging, type conversions like MyFixedPoint). Concrete triggers: writing a MySessionComponentBase subclass, wiring MyGameLogicComponent, querying block state at runtime, setting up a .csproj with MDK2, decompiling a game DLL to find an API. SKIP for: Text Surface Scripts / LCD screen code (use se-tss — separate lifecycle), in-game Programmable Block scripts (use se-pb-scripts — sandboxed, whitelist restrictions), SBC/XML content (use se-sbc), Mod Adjuster patches (use se-frameworks)."
---

# SE C# — compiled session components and game logic

Full .NET access, DLL loaded by `MyScriptManager` at game start. Runs on client and (for session components) server.

## Read first

- **[references/project-setup.md](references/project-setup.md)** — MDK2 install, `.csproj` template, folder structure (`Data/Scripts/YourMod/`), namespaces, decompiler strategies (dnSpy, ILSpy), dealing with obfuscated names.
- **[references/patterns.md](references/patterns.md)** — session component template, config with `MyIni`, save/sync, logging, `MyFixedPoint` conversion (`.ToIntSafe()`, `(float)(double)amount`), performance rules.
- **[references/block-queries.md](references/block-queries.md)** — power, gas, inventory, production blocks, doors, conveyor push/pull.

## The mod type table (why this matters)

C# mods come in three flavors that share compilation but differ in invocation:

| Type | Runs where | Notes |
|------|-----------|-------|
| Session component | Global game-wide | Extend `MySessionComponentBase`, called every tick |
| Game logic component | Per-entity | `MyGameLogicComponent` attached via `MyEntityComponentDescriptor` |
| Text Surface Script | Per-LCD-block | **Use `se-tss` instead — different SBC registration** |

## Known runtime gotchas

- **`Components.Get<T>()` returns null when missing** — always null-check.
- **`DetailedInfo` is a localized string** — format changes across game updates; don't parse it in stable code.
- **Item type collisions** — composite key `$"{typeId}_{subtypeId}"` when comparing inventory items.
- **`MyFixedPoint`** — use `.ToIntSafe()` or `(float)(double)amount`; direct cast underflows.
- **Dedicated server** — a `Run()` that touches player UI on a headless server crashes the mod. Guard with `MyAPIGateway.Utilities.IsDedicated`.

## Shipping checklist

- [ ] Dedicated server guard in every entry point that touches UI
- [ ] All `Components.Get<T>()` calls are null-checked
- [ ] All inventory keys use composite `typeId_subtypeId`
- [ ] CustomData config keys unchanged from previous version (backward compat)
- [ ] No unhandled exceptions that could crash the game (wrap in `try/catch`, log via `MyLog`)
- [ ] Tested in Creative mode before publishing
