---
name: se-tss
description: "Use for Space Engineers Text Surface Scripts — compiled C# code that runs on LCD blocks and is invoked by the InfoLCD mod. Covers MyTextSurfaceScriptBase subclasses, TextSurfaceScripts.sbc registration, scroll timers, subgrid caching, drawing API (helpers, base classes, viewport, charts, MeasureStringInPixels). Concrete triggers: writing a `MyTextSurfaceScriptBase` subclass, registering an LCD app in TextSurfaceScripts.sbc, drawing to `MySprite`, scrolling long content on an LCD, custom LCD apps. SKIP for: session components / game logic mods (use se-csharp — different lifecycle and registration), in-game PB scripts (use se-pb-scripts — sandboxed), SBC content without C# (use se-sbc)."
---

# SE TSS — Text Surface Scripts (LCD screens)

Compiled DLL that draws to LCD blocks. Full .NET access, but a specific lifecycle: instantiated per-LCD when the InfoLCD mod invokes the registered subtype.

## Read first

- **[references/patterns.md](references/patterns.md)** — class structure, `Run()` invocation, `Update10` rule (scroll timer `+= 10`, never `++`), scrolling, subgrid caching, SBC registration via `TextSurfaceScripts.sbc`.
- **[references/drawing.md](references/drawing.md)** — drawing helpers, base classes, viewport, surface colors, charts, `MeasureStringInPixels`, the full LCD App Script pattern.
- **[references/example-lcd-app.md](references/example-lcd-app.md)** — worked example end-to-end.

## Key distinctions from se-csharp

| | TSS | Session Component |
|---|---|---|
| Invoked by | InfoLCD mod on the LCD block | `MyScriptManager` at game load |
| Instance | One per LCD | Global singleton |
| SBC registration | `TextSurfaceScripts.sbc` with a `MyTextSurfaceScriptDefinition` | `MySessionComponentDescriptor` attribute |
| Update rate | Per-frame (be cheap) | `UpdateAfterSimulation*` variants |
| Save/load | None built in | `IsBeforeSave`, `LoadData`, `SaveData` |

## Shipping checklist

- [ ] Scroll timer uses `+= 10`, not `++`
- [ ] Tested on small, large, and corner LCD panels
- [ ] Handles empty block lists gracefully (don't divide by zero on line count)
- [ ] `MeasureStringInPixels` used for text layout, not hardcoded pixel offsets
- [ ] Registered subtype in `TextSurfaceScripts.sbc` matches the `MyTextSurfaceScript` attribute
