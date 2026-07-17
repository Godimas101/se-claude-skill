# Mod types — pick the right one before writing anything

Space Engineers has **five completely different mod environments**. Get this wrong and nothing works. Confirm the type before writing any code or SBC.

| Type | How it runs | C# access | Invoked by | Skill |
|------|-------------|-----------|------------|-------|
| **Text Surface Script** | Compiled DLL loaded per LCD block | Full .NET, all namespaces | InfoLCD mod screens (via `TextSurfaceScripts.sbc` registration) | `se-tss` |
| **Session Component** | Compiled DLL, runs as global game component | Full .NET, all namespaces | `MyScriptManager` on game load | `se-csharp` |
| **Game Logic Component** | Compiled DLL, attached per-entity | Full .NET, all namespaces | `MyEntityComponentDescriptor` attribute | `se-csharp` |
| **SBC-only Mod** | XML loaded at game start | No C# | Automatic on mod load | `se-sbc` |
| **Mod Adjuster Mod** | Session component + XML patches | Patches live definitions at runtime | Applied by the Mod Adjuster mod (Workshop ID `3017795356`) | `se-frameworks` |
| **PB Script** | Sandboxed VM inside the game | Whitelist only — NO I/O, NO threading, NO reflection | Player-written; runs inside a Programmable Block | `se-pb-scripts` |

## The traps

- **InfoLCD is a Text Surface Script mod** — full .NET access, none of the PB sandbox restrictions apply. First-timers confuse the two constantly.
- **Mod Adjuster mods** are technically session components — but they patch existing definitions rather than replacing them. Use these for cross-mod balance work. See `se-frameworks`.
- **PB scripts run in a sandboxed VM**. Anything a compiled mod can do (I/O, threading, reflection, most `System.*`) will crash a PB script. `se-pb-scripts` enforces this throughout.
- **Data/ is mandatory for all mods** — even collection mods with zero content. Without a `Data/` folder the game silently ignores the mod.
