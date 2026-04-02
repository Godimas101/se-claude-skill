# Text Surface Script — Patterns & Reference

Practical patterns for Text Surface Script (TSS) development. TSS mods run as compiled DLLs with full .NET access — none of the PB sandbox restrictions apply.

> For class structure (`MyTextSurfaceScriptBase` vs `MyTSSCommon`), project setup, and performance rules: see [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md).
> For a complete end-to-end TSS recipe: see [RECIPES.md](../RECIPES.md).

---

## Class Structure Quick Reference

```csharp
using Sandbox.ModAPI;
using VRage.Game.GUI.TextPanel;
using VRageMath;

[MyTextSurfaceScript("MyScriptId", "Display Name")]
public class MyScreen : MyTextSurfaceScriptBase
{
    IMyTerminalBlock Block => (IMyTerminalBlock)m_block;

    public MyScreen(IMyTextSurface surface, IMyCubeBlock block, Vector2 viewport)
        : base(surface, block, viewport) { }

    public override ScriptUpdate NeedsUpdate => ScriptUpdate.Update10;

    public override void Run()
    {
        // ⚠️ ALWAYS bail on dedicated server
        if (MyAPIGateway.Utilities?.IsDedicated ?? false) return;

        try
        {
            using (var frame = mySurface.DrawFrame())
            {
                // Your drawing code here
            }
        }
        catch { } // Never crash the game
    }

    public override void Dispose() { }
}
```

---

## The Update10 Rule — CRITICAL

`ScriptUpdate.Update10` means `Run()` fires every **10 game ticks** (6 times per second).

```csharp
// ❌ WRONG — increments 1 per call, so 1/6th of expected speed
ticksSinceLastScroll++;

// ✅ CORRECT — reflects actual ticks elapsed per call
ticksSinceLastScroll += 10;
```

`scrollSpeed = 60` → ~1 second. `scrollSpeed = 120` → ~2 seconds. Always design timers in ticks (60 = ~1 second at Update10).

### Dedicated Server Guard

```csharp
if (MyAPIGateway.Utilities?.IsDedicated ?? false) return;
```

Use `?.` because `Utilities` can be null during early init.

---

## Drawing on LCD Surfaces

### Sprite Frame Pattern

```csharp
using (MySpriteDrawFrame frame = mySurface.DrawFrame())
{
    frame.Add(new MySprite()
    {
        Type = SpriteType.TEXT,
        Data = "Hello World",
        Position = new Vector2(x, y),
        Color = Color.White,
        FontId = "White",
        Alignment = TextAlignment.LEFT,
        RotationOrScale = textSize
    });
}
```

### Surface Sizing

```csharp
Vector2 screenSize = mySurface.SurfaceSize;
Vector2 viewportOffset = (mySurface.TextureSize - screenSize) / 2f;
float localX = viewportOffset.X + padding;
float localY = viewportOffset.Y + padding;
```

### Position-Based Space Calculation (for scrolling lists)

```csharp
float lineHeight = 30 * surfaceData.textSize;
float currentY = position.Y - surfaceData.viewPortOffsetY;
float remainingHeight = mySurface.SurfaceSize.Y - currentY;
int availableLines = Math.Max(1, (int)(remainingHeight / lineHeight));
```

---

## Accessing Game State

### Grid and Blocks

```csharp
IMyCubeGrid grid = Block.CubeGrid;

var batteries = new List<IMyBatteryBlock>();
grid.GetFatBlocks(batteries);
```

### Inventory Scanning

```csharp
// ⚠️ ALWAYS use composite key — SubtypeId alone is not unique
var typeId = item.Type.TypeId.Split('_')[1];
var subtypeId = item.Type.SubtypeId;
string key = $"{typeId}_{subtypeId}";

// ⚠️ Amounts are VRage.MyFixedPoint, not int/float
int amount = item.Amount.ToIntSafe();
```

### CustomData Config (MyIni Pattern)

```csharp
private MyIni _config = new MyIni();

private void ParseConfig()
{
    if (!_config.TryParse(Block.CustomData)) return;
    _toggleScroll = _config.Get("MyScreen", "EnableScroll").ToBoolean(false);
    _scrollSpeed  = _config.Get("MyScreen", "ScrollSpeed").ToInt32(60);
}
```

---

## Scrolling List Pattern

### Approach 1 — Flat List

```csharp
// State fields
bool toggleScroll = false;
bool reverseDirection = false;
int scrollSpeed = 60;
int scrollLines = 1;
int scrollOffset = 0;
int ticksSinceLastScroll = 0;

// In Run()
if (toggleScroll)
{
    ticksSinceLastScroll += 10;   // ← ALWAYS +10, never ++
    if (ticksSinceLastScroll >= scrollSpeed)
    {
        ticksSinceLastScroll = 0;
        scrollOffset += reverseDirection ? -scrollLines : scrollLines;
    }
}
else { scrollOffset = 0; ticksSinceLastScroll = 0; }

// Draw with wraparound
int total = itemList.Count;
int startIndex = (toggleScroll && total > 0)
    ? ((scrollOffset % total) + total) % total : 0;

int drawn = 0;
for (int i = 0; i < total && drawn < availableLines; i++)
{
    int idx = (startIndex + i) % total;
    // Draw itemList[idx]
    drawn++;
}
```

### Approach 2 — Multi-Category with MaxListLines

```csharp
int maxListLines = 5;  // 0 = unlimited
if (maxListLines > 0)
    availableLines = Math.Min(availableLines, maxListLines);
```

---

## Subgrid Caching Pattern

```csharp
private List<IMyTerminalBlock> _mainBlocks = new List<IMyTerminalBlock>();
private List<IMyTerminalBlock> _subgridCache = new List<IMyTerminalBlock>();
private int _tick = 0;

private void UpdateBlocks()
{
    _mainBlocks.Clear();
    Block.CubeGrid.GetFatBlocks(_mainBlocks);

    _tick += 10;
    if (_tick >= 300)  // ~5 seconds
    {
        _tick = 0;
        _subgridCache.Clear();
        var connectedGrids = new List<IMyCubeGrid>();
        Block.CubeGrid.GetConnectedGrids(GridLinkTypeEnum.Mechanical, connectedGrids);
        foreach (var subgrid in connectedGrids)
        {
            if (subgrid == Block.CubeGrid) continue;
            var sub = new List<IMyTerminalBlock>();
            subgrid.GetFatBlocks(sub);
            _subgridCache.AddRange(sub);
        }
    }
}
```

---

## SBC Registration

> For the `TextSurfaceScripts.sbc` registration template, see [sbc/SBC_MISC.md](../sbc/SBC_MISC.md).

The `Subtype` must match `[MyTextSurfaceScript("MyScriptId", "...")]` in C#.

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting](https://spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting) — official C# mod scripting reference
- [github.com/malforge/mdk2](https://github.com/malforge/mdk2) — MDK2: project templates and build tools

### Internal
- [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md) — class structure, project setup, Save/Sync, performance rules
- [../sbc/SBC_MISC.md](../sbc/SBC_MISC.md) — `TextSurfaceScripts.sbc` registration template
- [../RECIPES.md](../RECIPES.md) — full end-to-end LCD App Script worked example

### Local
- ModSDK API DLLs (with XML docs): `[Steam]\steamapps\common\SpaceEngineersModSDK\`
