---
name: se-pb-scripts
description: "Use for Space Engineers in-game Programmable Block scripts — user-written C# code that runs in a sandboxed VM inside a PB. Covers the Main loop, `Program` class structure, `UpdateFrequency`, `IMyGridTerminalSystem`, `IMyIntergridCommunicationSystem` (IGC), coroutines, `Echo`, `Me.CustomData`, `Storage`, and the whitelist. Concrete triggers: writing a Main method that runs on a PB, GridTerminalSystem.GetBlocksOfType, IGC broadcasting, PB CustomData config, unbounded-loop instruction limit errors. SKIP for: compiled DLL mods with full .NET (use se-csharp or se-tss — different sandbox, different capabilities), SBC-only mods (use se-sbc). PB scripts CANNOT do I/O, threading, reflection, or use most `System.*` namespaces — this skill enforces those constraints throughout."
---

# SE PB Scripts — Programmable Block scripts

Sandboxed C# that runs inside a Programmable Block. Whitelisted namespaces only. **Whitelist restrictions apply throughout — enforce them in every suggestion.**

## Read first

**[references/scripts.md](references/scripts.md)** — Main loop, `UpdateFrequency`, `IMyGridTerminalSystem`, `IMyIntergridCommunicationSystem` (IGC), coroutines, sandbox restrictions, whitelist reference.

## Sandbox — the hard constraints

- **No I/O.** No `System.IO`, no file access, no `Console`. State goes in `Storage` (persistent string) or `Me.CustomData` (mutable in-game).
- **No threading.** No `Task`, no `Thread`, no `async`/`await`. Long work uses coroutines (`yield return`).
- **No reflection.** No `Type.GetType()` beyond whitelisted names.
- **Limited System.*.** `System.Collections.Generic`, `System.Linq`, `System.Text` mostly OK. `System.Net` — no.
- **Instruction budget per tick.** Long loops trip `ScriptOutOfRangeException`. Break large sweeps across ticks with coroutines.

## The five mod types — where PB fits

PB scripts are a completely separate environment from compiled mods. See [../se-core/references/mod-types.md](../se-core/references/mod-types.md) for the table. Get this wrong and none of your compiled-mod code will work in a PB.

## Shipping checklist

- [ ] Instruction count checked — no unbounded loops over large block lists per tick
- [ ] `Storage` used for state that must survive recompile
- [ ] `Echo()` used for debug output, not `Me.GetSurface(0)` hardcoded
- [ ] Graceful handling when expected blocks are missing from the grid
- [ ] `Save()` implemented if state persistence matters
