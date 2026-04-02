# Text Surface Script — Drawing Reference

LCD drawing API: sprite helpers, base classes, surface colors, viewport, block enumeration, charts, text sizing, and the full LCD App Script pattern.

> For TSS class structure, update loop, scrolling, and subgrid caching: see [TSS_PATTERNS.md](TSS_PATTERNS.md).
> For project setup, MDK2, and namespace rules: see [CSHARP_PROJECT_SETUP.md](../csharp/CSHARP_PROJECT_SETUP.md).
> For block API queries (power, gas, inventory) used in TSS: see [CSHARP_BLOCK_QUERIES.md](../csharp/CSHARP_BLOCK_QUERIES.md).
> For a complete end-to-end TSS recipe: see [RECIPES.md](../../RECIPES.md).

---

## Text Surface Drawing Helpers

### Draw a Text Line

```csharp
private void DrawText(MySpriteDrawFrame frame, string text, Vector2 pos, float scale, Color color,
    TextAlignment align = TextAlignment.LEFT, string font = "White")
{
    frame.Add(new MySprite
    {
        Type = SpriteType.TEXT,
        Data = text,
        Position = pos,
        Color = color,
        FontId = font,
        Alignment = align,
        RotationOrScale = scale
    });
}
```

### Draw a Progress Bar

```csharp
private void DrawBar(MySpriteDrawFrame frame, Vector2 pos, Vector2 size, float fillRatio,
    Color fillColor, Color bgColor)
{
    // Background
    frame.Add(new MySprite
    {
        Type = SpriteType.TEXTURE,
        Data = "SquareSimple",
        Position = pos,
        Size = size,
        Color = bgColor,
        Alignment = TextAlignment.LEFT
    });

    // Fill
    var fillSize = new Vector2(size.X * Math.Max(0f, Math.Min(1f, fillRatio)), size.Y);
    if (fillSize.X > 0)
    {
        frame.Add(new MySprite
        {
            Type = SpriteType.TEXTURE,
            Data = "SquareSimple",
            Position = pos,
            Size = fillSize,
            Color = fillColor,
            Alignment = TextAlignment.LEFT
        });
    }
}
```

### Clear the Screen (Important for flicker prevention)

```csharp
// Always clear before drawing, or sprites accumulate
using (var frame = mySurface.DrawFrame())
{
    frame.Add(MySprite.CreateClearClipRect());
    // ... draw your sprites
}
```

---

## Two Base Classes for Text Surface Scripts

There are two base classes used by real mods:

### `MyTextSurfaceScriptBase` (lower-level, used by most mods)
Direct base from `Sandbox.Game.GameSystems.TextSurfaceScripts`. Provides:
- `mySurface` field is NOT available — you must store the surface yourself
- Constructor receives `IMyTextSurface surface, IMyCubeBlock block, Vector2 size`
- Inherited: `m_block` (the cube block), but surface must be stored manually

```csharp
[MyTextSurfaceScript("MyScriptId", "My Script Name")]
public class MyScript : MyTextSurfaceScriptBase
{
    IMyTextSurface _surface;
    IMyTerminalBlock Block => (IMyTerminalBlock)m_block;

    public MyScript(IMyTextSurface surface, IMyCubeBlock block, Vector2 size)
        : base(surface, block, size)
    {
        _surface = surface;
    }
}
```

### `MyTSSCommon` (higher-level, Keen internal helper)
From `Sandbox.Game.GameSystems.TextSurfaceScripts`. Provides additional pre-built helpers:
- `m_surface` — the text surface
- `m_halfSize` — center of the surface (useful for centering sprites)
- `m_fontId` — the selected font ID string
- `m_fontScale` — auto-calculated font scale
- `m_foregroundColor` — the surface's script foreground color
- `FitRect(size, ref innerSize)` — scales an aspect-ratio rect to fit the surface
- `AddBackground(frame, color)` — draws the standard background fill
- `AddBrackets(frame, size, scale)` — draws decorative corner brackets

```csharp
[MyTextSurfaceScript("MyScriptId", "My Script Name")]
public class MyScript : MyTSSCommon
{
    public MyScript(IMyTextSurface surface, IMyCubeBlock block, Vector2 size)
        : base(surface, block, size) { }
    // m_surface, m_halfSize, m_fontId, m_fontScale, m_foregroundColor all available
}
```

> **Which to use:** `MyTextSurfaceScriptBase` gives more control; `MyTSSCommon` is a faster start. InfoLCD uses `MyTextSurfaceScriptBase` directly.

---

## Surface Color Properties (LCD Theme Integration)

LCD surfaces expose theme colors that respect the user's in-game color settings. Always prefer these over hardcoded colors:

```csharp
// The LCD's configured script foreground color (user-settable)
Color fg = surface.ScriptForegroundColor;

// The LCD's configured script background color
Color bg = surface.ScriptBackgroundColor;

// Usage: dim the foreground for secondary text
Color dimFg = new Color((int)(fg.R * 0.5f), (int)(fg.G * 0.5f), (int)(fg.B * 0.5f));

// Usage: semi-transparent background overlay
Color overlay = new Color(fg, 0.66f);  // fg with 66% alpha
```

---

## Viewport Calculation (Two Equivalent Patterns)

```csharp
// Pattern A — RectangleF viewport (used by some mods)
var viewport = new RectangleF((surface.TextureSize - surface.SurfaceSize) / 2f, surface.SurfaceSize);
var startPos = new Vector2(5, 5) + viewport.Position;  // 5px padding from top-left

// Pattern B — manual offset (used by InfoLCD and others)
Vector2 viewportOffset = (surface.TextureSize - surface.SurfaceSize) / 2f;
float startX = viewportOffset.X + padding;
float startY = viewportOffset.Y + padding;
```

Both produce identical results. Pattern B is more explicit; Pattern A is more concise.

---

## GetBlocks() with Filter vs GetFatBlocks()

Two ways to enumerate grid blocks in a Text Surface Script:

```csharp
// Pattern A: GetFatBlocks<T>() — typed, returns only blocks with that component
// Fast for specific block types, skips armor/structural
var batteries = new List<IMyBatteryBlock>();
Block.CubeGrid.GetFatBlocks(batteries);

// Pattern B: GetBlocks() with filter lambda — more flexible, works with IMySlimBlock
// Useful when you need FatBlock.HasInventory or similar checks
var slimBlocks = new List<IMySlimBlock>();
Block.CubeGrid.GetBlocks(slimBlocks, x => x.FatBlock != null && x.FatBlock.HasInventory);

foreach (var slim in slimBlocks)
{
    var inventory = slim.FatBlock.GetInventory(0);
    // ...
}
```

> `GetBlocks()` includes armor/structural blocks (with null FatBlock). Always filter with `x.FatBlock != null` when using it.

---

## Drawing Charts and Complex Shapes on LCD

### Line Segment Between Two Points

To draw a line between two points, use a thin `SquareSimple` sprite rotated to the correct angle:

```csharp
private void DrawLine(List<MySprite> sprites, Vector2 point0, Vector2 point1, Color color, float thickness = 2f)
{
    float length = Vector2.Distance(point0, point1);
    Vector2 midpoint = (point0 + point1) / 2f;
    // Angle: atan2 of delta, offset by 90° because sprite's "up" is the height axis
    float angle = -(float)(Math.Atan2(point1.Y - point0.Y, point1.X - point0.X) + MathHelper.PiOver2);

    sprites.Add(new MySprite
    {
        Type = SpriteType.TEXTURE,
        Data = "SquareSimple",
        Position = midpoint,
        Size = new Vector2(thickness, length),
        Color = color,
        RotationOrScale = angle
    });
}
```

### Pie Chart Using Circle + SemiCircle Sprites

The game includes `Circle` and `SemiCircle` built-in sprites. A pie/radial-fill gauge is drawn by overlapping them:

```csharp
// Draw a pie chart showing `value` (0.0 to 1.0) filled
private void DrawPie(List<MySprite> sprites, Vector2 center, Vector2 size, float value,
    Color fillColor, Color bgColor)
{
    // Background circle
    sprites.Add(new MySprite
    {
        Type = SpriteType.TEXTURE,
        Data = "Circle",
        Position = center - size / 2,
        Size = size,
        Color = bgColor
    });

    if (value >= 1.0f) return;  // Full — background IS the fill

    float deg = 360f * value;
    float flip = value < 0.5f ? 1f : -1f;
    float val = value < 0.5f ? 180f : 0f;

    // Fill SemiCircle (rotated to represent the filled portion)
    sprites.Add(new MySprite
    {
        Type = SpriteType.TEXTURE,
        Data = "SemiCircle",
        Position = center - size / 2,
        Size = size,
        Color = fillColor,
        RotationOrScale = MathHelper.ToRadians((flip * 90f) + deg - val)
    });

    // Cover SemiCircle (hides the back half when < 50% filled)
    sprites.Add(new MySprite
    {
        Type = SpriteType.TEXTURE,
        Data = "SemiCircle",
        Position = center - size / 2,
        Size = size,
        Color = value > 0.5f ? fillColor : bgColor,
        RotationOrScale = MathHelper.ToRadians(flip * (-90f))
    });
}
```

> **Built-in sprite names:** `SquareSimple`, `Circle`, `SemiCircle`, `Triangle`, `RightTriangle`, `Screen`, `Grid` — these work without any texture files.

---

## MeasureStringInPixels — Dynamic Text Sizing

Use `surface.MeasureStringInPixels()` to calculate text dimensions before drawing, enabling centered or right-aligned text and auto-scaling:

```csharp
// Auto-scale text to fill a target height
private float CalcFontScale(IMyTextSurface surface, string sampleText, float targetHeight, string fontId)
{
    // Measure at scale 1.0 to get base size
    var sb = new StringBuilder(sampleText);
    Vector2 baseSize = surface.MeasureStringInPixels(sb, fontId, 1.0f);
    return targetHeight / baseSize.Y;  // Scale factor to hit targetHeight
}

// Center a string horizontally
private void DrawCenteredText(MySpriteDrawFrame frame, IMyTextSurface surface,
    string text, float y, float scale, Color color, string fontId = "White")
{
    var sb = new StringBuilder(text);
    Vector2 size = surface.MeasureStringInPixels(sb, fontId, scale);
    float x = surface.SurfaceSize.X / 2f;  // Or use TextureSize center if using absolute coords

    frame.Add(new MySprite
    {
        Type = SpriteType.TEXT,
        Data = text,
        Position = new Vector2(x, y),
        Color = color,
        FontId = fontId,
        Alignment = TextAlignment.CENTER,
        RotationOrScale = scale
    });
}
```

---

## LCD App Script — Full Working Pattern (MyTSSCommon)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Recipes/LCD_App_Mod_Script -->

`MyTSSCommon` is the recommended base for LCD app scripts. It provides `Surface`, `m_halfSize`, `m_fontId`, `m_fontScale`, and `m_foregroundColor` pre-wired.

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
    // First string: internal ID used in SBC Script="" attribute
    // Second string: display name shown in terminal dropdown
    [MyTextSurfaceScript("YourAppInternalName", "Your app display name")]
    public class YourLCDApp : MyTSSCommon
    {
        // Control update rate: Update1, Update10, Update100, or None
        public override ScriptUpdate NeedsUpdate { get; } = ScriptUpdate.Update10;

        readonly IMyTerminalBlock TerminalBlock;

        public YourLCDApp(IMyTextSurface surface, IMyCubeBlock block, Vector2 size)
            : base(surface, block, size)
        {
            TerminalBlock = (IMyTerminalBlock)block;
            // ⚠️ Required: subscribe to OnMarkForClose to prevent use-after-free
            // The game has a bug where Dispose() is not reliably called when a block
            // is deleted — this event fires reliably.
            TerminalBlock.OnMarkForClose += BlockDeleted;
        }

        public override void Dispose()
        {
            base.Dispose();
            // Always unsubscribe to avoid memory leaks and phantom callbacks
            TerminalBlock.OnMarkForClose -= BlockDeleted;
        }

        void BlockDeleted(IMyEntity _)
        {
            Dispose();
        }

        public override void Run()
        {
            base.Run();  // ⚠️ Call base.Run() first — it clears the frame

            using (var frame = Surface.DrawFrame())
            {
                // Surface, m_halfSize, m_fontId, m_fontScale, m_foregroundColor
                // are all available from MyTSSCommon base class
                frame.Add(new MySprite
                {
                    Type = SpriteType.TEXT,
                    Data = "Hello World",
                    Alignment = TextAlignment.CENTER,
                    FontId = MyFontEnum.White,
                    // Position = null means centered on surface (default behavior)
                    Position = m_halfSize,
                    Color = m_foregroundColor,
                    RotationOrScale = m_fontScale,
                });
            }
        }
    }
}
```

**Key points:**
- `NeedsUpdate = ScriptUpdate.Update10` runs `Run()` ~6×/second. Use `Update100` for slow-changing data.
- Always call `base.Run()` — it handles the frame clear that prevents sprite accumulation.
- The `OnMarkForClose` subscription is a required workaround for a game bug where `Dispose()` isn't called on block deletion.
- `Surface.DrawFrame()` returns a `MySpriteDrawFrame` — use `using` to auto-flush it.
- No SBC registration needed for the script itself. The `[MyTextSurfaceScript]` attribute registers it automatically. To pre-assign the script to a block's LCD, set `Script="YourAppInternalName"` in the block's `ScreenArea` definition.

> For a step-by-step worked example with test plan and shipping checklist, see [RECIPES.md](../../RECIPES.md).

---

## SBC: Adding LCD Screens to Custom Blocks

> For the `ScreenAreas` SBC definition template, field reference, and built-in script names, see [sbc/SBC_MISC.md](../../sbc/SBC_MISC.md).

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting](https://spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting) — official C# mod scripting reference
- [github.com/malforge/mdk2](https://github.com/malforge/mdk2) — MDK2: project templates and build tools

### Internal
- [TSS_PATTERNS.md](TSS_PATTERNS.md) — TSS class structure, update loop, scrolling, subgrid caching, SBC registration
- [CSHARP_PATTERNS.md](../csharp/CSHARP_PATTERNS.md) — session component, config (MyIni), save/sync, logging, type conversions, performance rules
- [CSHARP_BLOCK_QUERIES.md](../csharp/CSHARP_BLOCK_QUERIES.md) — block API queries: power, gas, inventory, production, doors, conveyor network
- [../../sbc/SBC_MISC.md](../../sbc/SBC_MISC.md) — `TextSurfaceScripts.sbc` and `ScreenAreas` SBC templates
- [../../RECIPES.md](../../RECIPES.md) — full end-to-end LCD App Script worked example

### Local
- ModSDK API DLLs (with XML docs): `[Steam]\steamapps\common\SpaceEngineersModSDK\`
