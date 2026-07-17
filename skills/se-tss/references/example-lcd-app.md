# Example: LCD App Mod Script (C#)

End-to-end walkthrough: register a custom C# app in the LCD screen list. Players select it from the terminal just like vanilla apps (Energy, Inventory, etc.).

> For all examples, see [EXAMPLES_MANIFEST.md](EXAMPLES_MANIFEST.md).
> For C# project setup and MDK2: see [../scripting/csharp/CSHARP_PROJECT_SETUP.md](../scripting/csharp/CSHARP_PROJECT_SETUP.md).
> For TSS class structure, drawing API, and base classes: see [../scripting/tss/TSS_PATTERNS.md](../scripting/tss/TSS_PATTERNS.md) and [../scripting/tss/TSS_DRAWING.md](../scripting/tss/TSS_DRAWING.md).

<!-- source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script -->

---

### Prerequisites

- C# basics
- MDK2 installed: `dotnet new install Mal.Mdk2.ScriptTemplates`
- IDE with C#/.NET and NuGet support (VS Code + C# Dev Kit, Visual Studio, or Rider)

### Step-by-step

**1. Create project**

In your IDE, create a new project using the "Mod (MDK2)" template. **Do NOT create the project inside your local mods folder** — MDK2 deploys to it automatically on build.

**2. Create your LCD script class**

Add a new `.cs` file. Replace the namespace/class names and the attribute strings with your own.

```csharp
using System;
using Sandbox.Game.GameSystems.TextSurfaceScripts;
using Sandbox.ModAPI;
using VRage.Game;
using VRage.Game.GUI.TextPanel;
using VRage.Game.ModAPI;
using VRage.ModAPI;
using VRage.Utils;
using VRageMath;

namespace YourName.YourModName
{
    // First string: internal ID (must be unique across all mods)
    // Second string: display name shown to players in the terminal
    [MyTextSurfaceScript("YourAppInternalName", "Your App Display Name")]
    public class YourLCDApp : MyTSSCommon
    {
        // How often Run() is called: Update1, Update10, Update100, or None
        public override ScriptUpdate NeedsUpdate { get; } = ScriptUpdate.Update10;

        readonly IMyTerminalBlock TerminalBlock;

        public YourLCDApp(IMyTextSurface surface, IMyCubeBlock block, Vector2 size)
            : base(surface, block, size)
        {
            TerminalBlock = (IMyTerminalBlock)block;
            // Required: prevents memory leak when the block is destroyed
            TerminalBlock.OnMarkForClose += BlockDeleted;
        }

        public override void Dispose()
        {
            base.Dispose();
            TerminalBlock.OnMarkForClose -= BlockDeleted;
        }

        void BlockDeleted(IMyEntity _) => Dispose();

        public override void Run()
        {
            base.Run();

            using (var frame = Surface.DrawFrame())
            {
                frame.Add(new MySprite
                {
                    Type = SpriteType.TEXT,
                    Data = "Hello World",
                    Alignment = TextAlignment.CENTER,
                    FontId = MyFontEnum.White,
                    Color = null,      // null = use surface's script foreground color
                    Position = null,   // null = centered
                    Size = null,
                    RotationOrScale = 1f,
                });
            }
        }
    }
}
```

**3. Build**

- Visual Studio: Build → Build Solution
- VS Code: `Ctrl+Shift+B`
- MDK2 auto-deploys the built mod to your local mods folder

**4. Test in-game**

1. Launch SE → create or open an **offline** world (local mods don't work in online worlds)
2. World Options → Mods → find your mod in the Local tab (house icon)
3. Add it, start the world
4. Place a block with an LCD surface (battery, cockpit, dedicated LCD panel, etc.)
5. Open the block terminal → find your app near the end of the LCD app list by its display name
6. Select it — "Hello World" should appear

### Checklist

- [ ] `[MyTextSurfaceScript]` attribute — internal name unique, display name human-readable
- [ ] `NeedsUpdate` set to appropriate frequency (`Update10` = ~6 times/sec)
- [ ] `OnMarkForClose` subscribed in constructor, unsubscribed in `Dispose()`
- [ ] Test in **offline** world
- [ ] Check F11 console for compile errors
- [ ] Check `%AppData%\SpaceEngineers\*.log` for runtime errors

### Common mistakes

| Mistake | Result |
|---------|--------|
| Project created inside local mods folder | MDK2 deploy conflicts, double-writing |
| Duplicate internal name across mods | One silently wins, other app doesn't appear |
| Missing `OnMarkForClose` unsubscribe | Memory leak; crashes over time when blocks are destroyed |
| Testing in online world | Local mods rejected; app doesn't appear |
| `using Sandbox.ModAPI.Ingame;` at top of file | Ambiguous reference compile errors |

### Key inherited members from `MyTSSCommon`

| Member | Type | Description |
|--------|------|-------------|
| `Surface` | `IMyTextSurface` | The LCD surface being drawn to |
| `m_surface` | `IMyTextSurface` | Same surface (alternate accessor) |
| `m_block` | `IMyCubeBlock` | The owning block |
| `m_halfSize` | `Vector2` | Center point of the surface (useful for centering) |
| `m_fontId` | `string` | Currently selected font ID |
| `m_fontScale` | `float` | Auto-calculated font scale |
| `m_foregroundColor` | `Color` | Surface's configured script foreground color |

For more drawing patterns (progress bars, lines, charts) see [../scripting/csharp/CSHARP_PATTERNS.md](../scripting/csharp/CSHARP_PATTERNS.md).

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script](https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script) — official LCD App Script recipe

### Internal
- [EXAMPLES_MANIFEST.md](EXAMPLES_MANIFEST.md) — all examples
- [../scripting/csharp/CSHARP_PROJECT_SETUP.md](../scripting/csharp/CSHARP_PROJECT_SETUP.md) — project setup, MDK2, folder structure
- [../scripting/csharp/CSHARP_PATTERNS.md](../scripting/csharp/CSHARP_PATTERNS.md) — C# runtime patterns and drawing helpers
- [../scripting/tss/TSS_PATTERNS.md](../scripting/tss/TSS_PATTERNS.md) — TSS class structure, Update10 rule, scrolling
- [../scripting/tss/TSS_DRAWING.md](../scripting/tss/TSS_DRAWING.md) — TSS drawing API: sprites, base classes, charts, viewport
