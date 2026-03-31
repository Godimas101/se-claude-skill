# C# Patterns — Space Engineers Mod Development

Extended reference for C# patterns used in Space Engineers compiled mods (text surface scripts, session components). This is **not** Programmable Block scripting — full .NET access is available.

---

## Project Setup Requirements

### Target Framework and Language Version

```xml
<TargetFramework>net48</TargetFramework>   <!-- .NET Framework 4.8 — do NOT use net6/net8 -->
<Platforms>x64</Platforms>                 <!-- Must be x64, NOT AnyCPU -->
<LangVersion>6</LangVersion>               <!-- C# 6 — do NOT use newer features -->
```

SE runs on .NET Framework 4.8. Using `net6` or `net8` will produce a DLL the game cannot load. C# 7+ features (pattern matching, tuples, etc.) will cause compile errors.

### MDK2 — The Standard Project Setup Tool

All compiled SE mods should use **MDK2** (Malware's Development Kit 2):
- **MDK Hub** (GUI): download from https://github.com/malforge/mdk2/releases — manages templates, builds, and output paths
- **Templates:** `dotnet new mdk2mod` (mods) or `dotnet new mdk2pbscript` (PB scripts)
- **NuGet packages** (add to `.csproj`):
  - `Mal.Mdk2.ModAnalyzers` — whitelist analyzer, flags disallowed API calls at edit time
  - `Mal.Mdk2.References` — SE DLL references without hardcoded paths

```xml
<ItemGroup>
  <PackageReference Include="Mal.Mdk2.ModAnalyzers" Version="*" />
  <PackageReference Include="Mal.Mdk2.References" Version="*" />
</ItemGroup>
```

**Do NOT put `.csproj` inside `Data\Scripts\`** — this causes whitelist analyzer conflicts. Keep it at the mod root or in a sibling folder.

---

## Mod Script Folder Structure

Scripts must live in exactly **one named folder** directly under `Scripts/`:

```
YourMod/
└── Data/
    └── Scripts/
        └── YourModName/       ← required — one folder, named after your mod
            ├── YourScript.cs
            └── AnotherFile.cs
```

- `Scripts/` directly containing `.cs` files (no subfolder) will **not** compile
- **Only one folder** should exist directly inside `Scripts/` — multiple sibling folders compile as separate assemblies with no cross-visibility, causing silent breakage
- Nested subfolders inside `YourModName/` are fine for organization
- **Folder name should match your mod name** — the game uses it to identify your mod's storage folder in `%AppData%\SpaceEngineers\Storage\`

### Profiler Injection Warning

The game injects a mod profiler into **every compiled method**, including property accessors (except auto-properties). This has a real performance cost on hot paths:

```csharp
// ❌ Profiler injected on every access — costly in tight loops
public float SomeValue { get { return _value; } }

// ✅ Auto-property — profiler NOT injected
public float SomeValue { get; private set; }

// ✅ Field access — no injection overhead
private float _someValue;
```

In tight loops called at Update1/Update10 rates, prefer direct field access or auto-properties over manual getters.

---

## Key Namespaces

```csharp
using Sandbox.Common.ObjectBuilders;
using Sandbox.Game.EntityComponents;
using Sandbox.ModAPI;
using Sandbox.ModAPI.Ingame;         // For IMyTerminalBlock, IMyBatteryBlock, etc.
using SpaceEngineers.Game.ModAPI;    // For game-specific block types
using VRage.Game;
using VRage.Game.Components;
using VRage.Game.GUI.TextPanel;      // For IMyTextSurface, MySpriteDrawFrame
using VRage.Game.ModAPI;
using VRage.ModAPI;
using VRageMath;
```

### Namespace Ambiguity — CRITICAL

Several types exist in **both** `Sandbox.ModAPI` and `Sandbox.ModAPI.Ingame` (e.g. `IMyTerminalBlock`, `IMyBatteryBlock`). Adding a bare `using Sandbox.ModAPI.Ingame;` in a compiled session component or text surface script causes **ambiguous reference errors** at compile time.

**Rule: never `using` any namespace with "Ingame" in the name.**

```csharp
// ❌ Causes ambiguous reference compile errors in compiled mods
using Sandbox.ModAPI.Ingame;

// ✅ Use an alias for the specific Ingame type you need
using IMyGridTerminalSystem = Sandbox.ModAPI.Ingame.IMyGridTerminalSystem;

// ✅ Or fully qualify — verbose but unambiguous
Sandbox.ModAPI.Ingame.IMyGridTerminalSystem gts = ...;
```

The `Sandbox.ModAPI` version is correct for compiled session components and text surface scripts. Only PB scripts should use `Sandbox.ModAPI.Ingame` types directly.

---

## Session Component (Background Mod Logic)

When you need logic that runs independently of any specific block:

```csharp
[MySessionComponentDescriptor(MyUpdateOrder.BeforeSimulation)]
public class MySessionComponent : MySessionComponentBase
{
    public static MySessionComponent Instance;

    public override void LoadData()
    {
        Instance = this;
        // Initialize — called when session starts
    }

    public override void UpdateBeforeSimulation()
    {
        // Called every game tick (60fps)
        // Keep this fast — expensive work every N ticks
    }

    protected override void UnloadData()
    {
        Instance = null;
        // Cleanup
    }
}
```

---

## Power System Queries

```csharp
// Get power consumption of a block
var sink = block.Components.Get<MyResourceSinkComponent>();
if (sink != null)
{
    float currentDraw = sink.CurrentInputByType(MyResourceDistributorComponent.ElectricityId);
    float maxDraw = sink.MaxRequiredInputByType(MyResourceDistributorComponent.ElectricityId);
}

// Get power output of a generator/battery
var source = block.Components.Get<MyResourceSourceComponent>();
if (source != null)
{
    float currentOutput = source.CurrentOutputByType(MyResourceDistributorComponent.ElectricityId);
    float maxOutput = source.MaxOutputByType(MyResourceDistributorComponent.ElectricityId);
}

// Battery specific
var battery = block as IMyBatteryBlock;
if (battery != null)
{
    float chargeRatio = battery.CurrentStoredPower / battery.MaxStoredPower;
    bool isCharging = battery.IsCharging;
}

// Quick power grid summary (if you have all blocks)
float totalOutput = 0f, totalInput = 0f, totalStored = 0f, maxStored = 0f;
foreach (var block in powerBlocks)
{
    var bat = block as IMyBatteryBlock;
    if (bat != null)
    {
        totalStored += bat.CurrentStoredPower;
        maxStored += bat.MaxStoredPower;
    }
    // etc.
}
```

---

## Gas System Queries

```csharp
var gasTank = block as IMyGasTank;
if (gasTank != null)
{
    float fillRatio = (float)gasTank.FilledRatio;  // 0.0 to 1.0
    float capacity = gasTank.Capacity;
    float stored = fillRatio * capacity;
    bool isStockpiling = gasTank.Stockpile;
}

// Determine gas type from block definition (hydrogen vs oxygen)
// Check block CustomName or BlockDefinitionId.SubtypeName for "Hydrogen"/"Oxygen"
```

---

## Inventory Queries

```csharp
// Get all items from a cargo container
var cargo = block as IMyCargoContainer;
if (cargo != null)
{
    var inventory = cargo.GetInventory(0);
    var items = new List<VRage.Game.ModAPI.Ingame.MyInventoryItem>();
    inventory.GetItems(items);

    foreach (var item in items)
    {
        // ⚠️ Always use composite key — SubtypeId alone is not unique
        string typeId = item.Type.TypeId.Split('_').Last();  // e.g., "Component"
        string subtypeId = item.Type.SubtypeId;              // e.g., "SteelPlate"
        string key = $"{typeId}_{subtypeId}";

        // ⚠️ Amount is MyFixedPoint — convert before arithmetic
        int amount = item.Amount.ToIntSafe();
        float amountF = (float)(double)item.Amount;  // More precise
    }
}

// Check if inventory can accept item
bool canAdd = inventory.CanItemsBeAdded(100, new VRage.Game.MyDefinitionId(
    typeof(MyObjectBuilder_Component), "SteelPlate"));

// Transfer items between inventories
IMyInventory from = sourceBlock.GetInventory(0);
IMyInventory to = destBlock.GetInventory(0);
from.TransferItemTo(to, 0);  // Transfer item at index 0
```

---

## Production Block Queries

```csharp
var assembler = block as IMyAssembler;
if (assembler != null)
{
    bool isProducing = assembler.IsProducing;
    bool isQueueEmpty = assembler.IsQueueEmpty;

    var queue = new List<VRage.Game.ModAPI.Ingame.MyProductionItem>();
    assembler.GetQueue(queue);
    foreach (var queueItem in queue)
    {
        string name = queueItem.BlueprintId.SubtypeName;
        decimal amount = (decimal)queueItem.Amount;
    }
}

var refinery = block as IMyRefinery;
if (refinery != null)
{
    bool isProducing = refinery.IsProducing;
    // Refinery has input inventory [0] and output inventory [1]
    var inputInv = refinery.GetInventory(0);
    var outputInv = refinery.GetInventory(1);
}
```

---

## Door and Airtight Queries

```csharp
var door = block as IMyDoor;
if (door != null)
{
    var status = door.Status;
    bool isOpen = status == DoorStatus.Open;
    bool isClosed = status == DoorStatus.Closed;
    bool isMoving = status == DoorStatus.Opening || status == DoorStatus.Closing;
}

var hangar = block as IMyAirtightHangarDoor;
// etc. — various door types implement IMyDoor

// Check grid airtightness at a position
bool sealed = block.CubeGrid.IsRoomAtPositionAirtight(block.Position);
```

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

## Config Pattern — Full MyIni Implementation

```csharp
private MyIni _ini = new MyIni();
private const string SECTION = "ScreenName";

// Fields with defaults
private bool _scrollEnabled = false;
private int _scrollSpeed = 60;
private int _maxLines = 0;
private bool _showTitle = true;

private void ReadConfig()
{
    _ini.Clear();
    if (!_ini.TryParse(Block.CustomData))
    {
        // CustomData is invalid INI — don't wipe it, just use defaults
        return;
    }

    _scrollEnabled = _ini.Get(SECTION, "ScrollEnabled").ToBoolean(_scrollEnabled);
    _scrollSpeed = _ini.Get(SECTION, "ScrollSpeed").ToInt32(_scrollSpeed);
    _maxLines = _ini.Get(SECTION, "MaxLines").ToInt32(_maxLines);
    _showTitle = _ini.Get(SECTION, "ShowTitle").ToBoolean(_showTitle);
}

private void WriteConfig()
{
    _ini.Clear();
    _ini.Set(SECTION, "ScrollEnabled", _scrollEnabled);
    _ini.Set(SECTION, "ScrollSpeed", _scrollSpeed);
    _ini.Set(SECTION, "MaxLines", _maxLines);
    _ini.Set(SECTION, "ShowTitle", _showTitle);

    Block.CustomData = _ini.ToString();
}

// For CreateConfig() output (human-readable with comments):
private void AppendConfig(StringBuilder sb)
{
    sb.AppendLine($"; [ {SECTION.ToUpper()} - OPTIONS ]");
    sb.AppendLine($"[{SECTION}]");
    sb.AppendLine("; Enable auto-scrolling of long lists");
    sb.AppendLine($"ScrollEnabled={_scrollEnabled}");
    sb.AppendLine("; Ticks between scroll steps (60 = ~1 second)");
    sb.AppendLine($"ScrollSpeed={_scrollSpeed}");
    sb.AppendLine("; Max visible lines per category (0 = unlimited)");
    sb.AppendLine($"MaxLines={_maxLines}");
    sb.AppendLine("; Show section title headers");
    sb.AppendLine($"ShowTitle={_showTitle}");
}
```

---

## Save and Sync Patterns

### Option 1 — CustomData (simplest, most limited)

```csharp
// Reading
var ini = new MyIni();
if (ini.TryParse(block.CustomData))
{
    myValue = ini.Get("Section", "Key").ToString("default");
}

// Writing
ini.Set("Section", "Key", myValue);
block.CustomData = ini.ToString();
```

**Gotchas:**
- CustomData is shared — PB scripts and other mods may also write to it. Use `MyIni` sections with a unique section name to avoid conflicts.
- Never overwrite the entire string if you don't own all the content.
- Changes are not synced automatically in MP — writing `CustomData` on client doesn't sync to server.

### Option 2 — MyModStorageComponent (recommended for persistent entity data)

Stores string values per-entity, keyed by GUID. Survives save/load. Synced in MP.

```csharp
// Declare your GUID as a static field
static readonly Guid StorageGuid = new Guid("YOUR-GUID-HERE");

// Write
if (!entity.Storage.ContainsKey(StorageGuid))
    entity.Storage.Add(StorageGuid, "");
entity.Storage.SetValue(StorageGuid, MySerializedData);

// Read
string data;
if (entity.Storage.TryGetValue(StorageGuid, out data))
    MySerializedData = data;
```

**SBC registration required** — add a `<ModStorageComponentDefinition>` to your mod's Data:

```xml
<Definitions>
  <EntityComponents>
    <EntityComponent xsi:type="MyObjectBuilder_ModStorageComponentDefinition">
      <Id Type="MyObjectBuilder_ModStorageComponentDefinition" Subtype="YourModStorageKey" />
      <RegisteredStorageGuids>
        <guid>YOUR-GUID-HERE</guid>
      </RegisteredStorageGuids>
    </EntityComponent>
  </EntityComponents>
</Definitions>
```

### Option 3 — MySync (small blittable values, MP-synced)

```csharp
// Declare as a static field on your game logic component
static MySync<float, SyncDirection.BothWays> MySharedFloat;

// Usage
MySharedFloat.Value = 1.5f;  // automatically syncs to all clients
float current = MySharedFloat.Value;
```

**Hard limits:**
- Only **blittable** value types: `int`, `float`, `bool`, `double`, simple `struct` with blittable fields
- **Hard cap of 64 MySync instances per type** (raised from 32 in patch 1.208) — exceed this and the game crashes
- Not suitable for strings, arrays, or complex objects — use `MyModStorageComponent` or packets instead

### Option 4 — Packet Sending (full control, custom data)

```csharp
// Register handler (in LoadData)
MyAPIGateway.Multiplayer.RegisterSecureMessageHandler(CHANNEL_ID, OnPacketReceived);

// Send to server
byte[] data = MyAPIGateway.Utilities.SerializeToBinary(myPayload);
MyAPIGateway.Multiplayer.SendMessageToServer(CHANNEL_ID, data);

// Send to all clients
MyAPIGateway.Multiplayer.SendMessageToOthers(CHANNEL_ID, data);

private void OnPacketReceived(ushort channelId, byte[] data, ulong senderId, bool isFromServer)
{
    // ⚠️ ALWAYS validate on server — clients can send forged packets
    if (!MyAPIGateway.Multiplayer.IsServer) return;  // Only process on server
    // ... deserialize and act
}
```

**Security rule:** Never trust data from clients without server-side validation. A client can send any payload to any registered channel. Validate sender, check permissions, clamp values.

---

## Logging (Debug Output)

```csharp
// Logs to %AppData%\SpaceEngineers\SpaceEngineers.log
MyLog.Default.WriteLine($"[MyMod] Value: {someValue}");
MyLog.Default.Warning($"[MyMod] Warning: {message}");
MyLog.Default.Error($"[MyMod] Error: {ex.Message}");

// Optional: Show in HUD (visible to player, use sparingly)
MyAPIGateway.Utilities.ShowMessage("MyMod", "Debug message");
MyAPIGateway.Utilities.ShowNotification("Temporary HUD message", 2000, "White");
```

---

## Common Type Conversions

```csharp
// MyFixedPoint (inventory amounts)
int asInt = fixedPoint.ToIntSafe();
float asFloat = (float)(double)fixedPoint;
VRage.MyFixedPoint fromInt = (VRage.MyFixedPoint)someInt;

// Vector conversions
Vector3D worldPos = block.GetPosition();
Vector3I gridPos = block.Position;  // Grid coordinate

// Color utilities
Color fromHSV = Color.FromNonPremultiplied(r, g, b, a);  // 0-255
Color dimmed = color * 0.5f;  // 50% brightness

// String → TypeId
var typeId = new MyDefinitionId(typeof(MyObjectBuilder_Component), "SteelPlate");
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

## Performance Guidelines

1. **Never allocate in tight loops.** Cache lists and reuse them between frames.
   ```csharp
   // ❌ Allocates every Update10 call
   var blocks = new List<IMyTerminalBlock>();

   // ✅ Allocated once, cleared and refilled each call
   private List<IMyTerminalBlock> _blocks = new List<IMyTerminalBlock>();
   // In Run(): _blocks.Clear(); grid.GetFatBlocks(_blocks);
   ```

2. **Cache expensive queries.** Grid scans, inventory totals, power calculations — don't recompute every frame if data doesn't change that fast.

3. **Minimize LINQ in hot paths.** LINQ is fine for setup/init code, but in `Run()` called 6×/second, prefer for loops.

4. **Subgrid scans are expensive.** Cache subgrid block lists and refresh every 5 seconds (300 ticks), not every frame.

5. **Guard against null everywhere.** Blocks can be removed from the grid between frames. Always null-check before accessing block state.

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

---

## SBC: Adding LCD Screens to Custom Blocks

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/SBC/Screens -->

To add LCD screen functionality to a modded block, add a `<ScreenAreas>` section to the block's CubeBlocks SBC definition:

```xml
<ScreenAreas>
    <!-- Name must match the material name in the block's 3D model -->
    <!-- whose ColorMetal texture will be replaced by the LCD output -->
    <ScreenArea
        Name="MaterialNameHere"
        DisplayName="Screen name in terminal"
        ScreenWidth="1"
        ScreenHeight="1"
        TextureResolution="512"
        Script="" />
    <!-- Add more ScreenArea elements for additional screens on the same block -->
</ScreenAreas>
```

**Parameter notes:**
- `Name` — must match the material name in the model file exactly (case-sensitive)
- `DisplayName` — shown in the terminal UI; supports localization keys like `{LOC:MyKey}`
- `ScreenWidth` / `ScreenHeight` — integer ratio determining aspect ratio; measure the UV'd surface dimensions
- `TextureResolution` — suggested resolution (default 512); actual resolution scales by aspect ratio
- `Script` — internal name of the LCD app to run by default; leave empty for "No Script"

**Built-in script internal names** (can be used in `Script=""` attribute):
`TSS_Jukebox`, `TSS_ClockAnalog`, `TSS_ArtificialHorizon`, `TSS_ClockDigital`,
`TSS_EnergyHydrogen`, `TSS_FactionIcon`, `TSS_Gravity`, `TSS_TargetingInfo`,
`TSS_Velocity`, `TSS_VendingMachine`, `TSS_Weather`

**Model requirements:**
- The screen UV must be centered and touch edges on at least one axis
- A backing plane behind the screen plane is required (any texture)
- Verify the target block type supports LCDs before adding the definition

---

## Conveyor Network Push and Pull

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Conveyor_Network_Push_and_Pull -->

The conveyor system API allows mods to programmatically move items through the conveyor network from a block's perspective.

### Method Signatures

```csharp
// Pull items from the conveyor network into destinationInventory.
// Returns the amount actually pulled.
// remove: if false, items are NOT removed from the network (dry-run/check mode)
MyFixedPoint PullItem(
    MyDefinitionId itemDefinitionId,
    MyFixedPoint? amount,          // null = 0 = pulls nothing; pass a real value
    IMyEntity startingBlock,
    IMyInventory destinationInventory,
    bool remove);

// Push items from sourceBlock into the conveyor network (spawns them).
// Returns false when partial push occurred, but items may still have been pushed.
// transferredAmount: actual amount moved into the network
bool PushGenerateItem(
    MyDefinitionId itemDefinitionId,
    MyFixedPoint? amount,
    out MyFixedPoint transferredAmount,
    IMyEntity sourceBlock,
    bool partialPush);
```

### Basic Pull Example

```csharp
// Pull up to 10 Computer components from the conveyor network into block's inventory
MyFixedPoint pulled = block.CubeGrid.ConveyorSystem.PullItem(
    MyDefinitionId.Parse("MyObjectBuilder_Component/Computer"),
    (MyFixedPoint)10,
    block,
    block.GetInventory(),
    remove: true);  // true = actually consume from network
```

### Safe Push Pattern (Update100 — preserves item data integrity)

```csharp
// ⚠️ PushGenerateItem spawns NEW item instances — it does NOT move the original.
// This means per-item data (durability, flags, datapad content) is LOST.
// The pattern below skips items that carry special data.
void PushOneItemToConveyor(IMyCubeBlock block)
{
    MyInventory inv = (MyInventory)block.GetInventory();
    foreach (var item in inv.GetItems())
    {
        // Skip items that carry per-item state — pushing would destroy that data
        if (item.Content.DurabilityHP != null || item.Content.Flags != 0)
            continue;
        if (item.Content is MyObjectBuilder_GasContainerObject
         || item.Content is MyObjectBuilder_Datapad
         || item.Content is MyObjectBuilder_BlockItem
         || item.Content is MyObjectBuilder_Package)
            continue;
        var ammoMag = item.Content as MyObjectBuilder_AmmoMagazine;
        if (ammoMag != null && ammoMag.ProjectilesCount != 0)
            continue;

        var itemDefId = item.Content.GetId();
        MyFixedPoint transferred;
        block.CubeGrid.ConveyorSystem.PushGenerateItem(
            itemDefId, item.Amount, out transferred, block, partialPush: true);

        if (transferred > 0)
        {
            // Must manually remove the original — PushGenerateItem only spawns copies
            block.GetInventory().RemoveItemsOfType(transferred, itemDefId);
        }
        break;  // Push one item type per call to avoid overloading in a single tick
    }
}
```

**Gotchas:**
- `PushGenerateItem` **spawns new item instances** — the original item is NOT moved. Always remove from source manually based on `transferredAmount`.
- Passing `null` as amount is equivalent to 0 — no transfer occurs. Always pass an explicit amount.
- `partialPush: true` allows partial transfers; method returns `false` on partial but items were still pushed.
- On newly initialized conveyor networks, the first pull call may return 0 — the network needs one tick to initialize its graph.
- `PullItem` with `remove: false` is useful for checking availability without consuming.

### Utility Checks

```csharp
// Check if two blocks are conveyor-connected (by terminal name)
bool connected = MyVisualScriptLogicProvider.IsConveyorConnected(
    "Block Name A", "Block Name B");

// Check if a specific item type can be transferred between two inventories
bool canTransfer = block.GetInventory().CanTransferItemTo(
    otherBlock.GetInventory(), new MyItemType("MyObjectBuilder_Component", "Computer"));
```

---

## Debugging with dnSpy

<!-- Source: https://spaceengineers.wiki.gg/wiki/Scripting/Debugging_with_dnSpy -->

### Attaching to a Running Game

1. Launch Space Engineers normally
2. Open dnSpy (64-bit .NET Framework version from https://github.com/0xd4d/dnSpy/releases)
3. `Debug → Attach to process (Ctrl+Alt+P)` → select `SpaceEngineers.exe`
4. If the process isn't listed, run dnSpy as administrator

### Catching Exceptions Automatically

Enable via `Debug → Windows → Exception settings (Ctrl+Alt+E)`:
- Search "null" → enable `NullReferenceException` (most common mod crash)
- Add `VRage.Compiler.ScriptOutOfRangeException` for script complexity errors

Trigger the error in-game — dnSpy pauses at the throw site. Then:
- `Debug → Windows → Locals (Alt+4)` — inspect variable values at the crash point
- `Debug → Windows → Call Stack (Ctrl+Alt+C)` — trace the full call chain

### Breakpoint Workaround for In-Memory Compiled Scripts

Mod scripts compiled at runtime generate new modules each time — normal breakpoints don't survive recompile. Use this pattern during development only:

```csharp
// Forces a debugger break at this exact location when dnSpy is attached.
// ⚠️ DEBUGGING ONLY — remove before release. Never ship empty catch blocks.
try { throw new InvalidOperationException("debug break point"); }
catch (Exception) { }
```

### Launching the Game Directly from dnSpy (Full Variable Inspection)

This disables JIT optimizations so local variables aren't elided:
1. Ensure `steam_appid.txt` exists in `Bin64\` with content: `244850`
2. In dnSpy: `F5` → Debug engine: `.NET Framework`
3. Browse to `SpaceEngineers.exe` in `Bin64\`
4. Optional launch args: `-skipintro -nosplash`

Note: Game runs noticeably slower when launched this way — use only for deep debugging sessions.

### Inspecting Game Code (Decompiler Mode)

```
File → Open → navigate to SpaceEngineers\Bin64\
Select all .dll and .exe files
Edit → Search Assemblies (Ctrl+Shift+K)
```

Right-click any type/method → **Analyze** to see where it's called, implemented, or assigned. Use this to discover what interfaces a block type implements, what overrides exist, or how Keen wires up their own components.

---

## Exploring Game Code — Decompiler Strategies

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Exploring_Game_Code -->

### Setup

Use **ILSpy** (faster, simpler) or **dnSpy** (more features). Both support full decompilation of non-obfuscated SE assemblies.

1. Launch decompiler → `File → Open List` (creates a persistent assembly list)
2. Navigate to `SpaceEngineers\Bin64\` and open all DLLs
3. Remove `.XmlSerializers.dll` files to reduce noise in search results

### Search Strategies

| Decompiler | Search command |
|-----------|---------------|
| ILSpy | `View → Search` |
| dnSpy | `Edit → Search Assemblies (Ctrl+Shift+K)` |

Search by partial class name, method name, or property name. Example: searching `safezone` finds both `MySafeZone` (entity) and `MySafeZoneBlock` (block implementation).

### Navigating the Code Graph

- **Forward:** Click any method name to jump to its implementation
- **Backward:** Right-click → **Analyze** → shows all callers, implementors, and assignments as a tree

**Limitation:** Analyzing an interface method implementation via the class won't show interface-level callers — analyze the interface method directly instead.

### Naming Conventions to Know

```
MyObjectBuilder_*   — Serializable data classes. Used for SBC definitions, save data,
                      network packets, and blueprints. The "builder" is the data container;
                      the runtime object is typically a separate class.

*Definition         — SBC definition data, deserialized from .sbc files into
                      MyDefinitionManager at load time. Read-only at runtime.
```

### Finding Enum Values

`const` fields and `enum` values can't be analyzed (compiler inlines them). Workaround:

```
ILSpy: File → Save code
dnSpy: File → Export to project
```

Then use Notepad++ find-in-files or WinMerge to search across the exported source.

### Verifying API Whitelist Access

Before calling any game method in a mod, confirm it's on the whitelist:
- Open the method in the decompiler
- Check it has `[ModAPI]` attribute or is in a whitelisted namespace
- Use MDK2's analyzer — it flags disallowed calls at edit time with a red squiggle

---

## SBC: Localization (Translation Support)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Localization -->

### Using Localization Keys in SBC

Replace any display string in a `.sbc` file with a localization key using `{LOC:KeyName}` syntax:

```xml
<DisplayName>{LOC:DisplayName_MyCoolBlock}</DisplayName>
<Description>{LOC:Description_MyCoolBlock}</Description>
```

### RESX File Structure

Create `Data\Localization\MyTexts.resx` for English (default), then add language-specific variants:

```
Data/Localization/
├── MyTexts.resx          ← English (default fallback)
├── MyTexts.de.resx       ← German
├── MyTexts.fr.resx       ← French
└── MyTexts.ru.resx       ← Russian
```

Each `.resx` file is XML with name/value pairs:

```xml
<?xml version="1.0" encoding="utf-8"?>
<root>
  <data name="DisplayName_MyCoolBlock" xml:space="preserve">
    <value>My Cool Block</value>
  </data>
  <data name="Description_MyCoolBlock" xml:space="preserve">
    <value>A block that does cool things.</value>
  </data>
</root>
```

The key in `name=""` must exactly match the key used in `{LOC:KeyName}` in the SBC.

---

## Canonical MDK2 Project File (.csproj)

<!-- Source: https://spaceengineers.wiki.gg/wiki/Modding/Tutorials/Convert_old_projects_to_new_SDK -->

The full canonical `.csproj` for a compiled mod using MDK2. The `.csproj` and `.sln` must live at the **mod root** (not inside `Data\Scripts\`):

```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net48</TargetFramework>
    <Platforms>x64</Platforms>
    <LangVersion>6</LangVersion>
    <!-- Suppress auto-generated attributes that can conflict with SE's loader -->
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <GenerateNeutralResourcesLanguageAttribute>false</GenerateNeutralResourcesLanguageAttribute>
    <GenerateTargetFrameworkAttribute>false</GenerateTargetFrameworkAttribute>
  </PropertyGroup>

  <ItemGroup>
    <!-- Whitelist analyzer: flags disallowed API calls at edit time (red squiggles) -->
    <PackageReference Include="Mal.Mdk2.ModAnalyzers" Version="*" />
    <!-- Auto-detects SE install and provides DLL references without hardcoded paths -->
    <PackageReference Include="Mal.Mdk2.References" Version="*" />
    <!-- Packages the mod output into the correct workshop folder structure on build -->
    <PackageReference Include="Mal.Mdk2.ModPackager" Version="*" />
  </ItemGroup>
</Project>
```

**Migration from old SDK:**
1. Close your IDE
2. Move `.csproj` and `.sln` to the mod root directory
3. Delete `bin\`, `obj\`, `.vs\`, `.ruleset`, and `.user` files
4. Replace `.csproj` contents with the template above
5. Reopen solution — Visual Studio will restore NuGet packages automatically
6. Right-click any folders you don't want compiled → "Exclude from project"

**Three packages, three roles:**
- `ModAnalyzers` — static analysis only; runs at edit time
- `References` — provides SE DLL references; no hardcoded paths needed
- `ModPackager` — copies output to workshop folder on build (optional but recommended)
