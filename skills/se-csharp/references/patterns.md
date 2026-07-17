# C# Patterns — Space Engineers Mod Development

Runtime patterns for Space Engineers compiled mods: session component lifecycle, config (MyIni), save/sync, logging, and type conversions.

> For project setup, MDK2, folder structure, namespaces, and decompiler strategies: see [CSHARP_PROJECT_SETUP.md](CSHARP_PROJECT_SETUP.md).
> For block API queries (power, gas, inventory, production, conveyor): see [CSHARP_BLOCK_QUERIES.md](CSHARP_BLOCK_QUERIES.md).
> For TSS class structure, scrolling, and update rules: see [TSS_PATTERNS.md](../tss/TSS_PATTERNS.md).
> For TSS drawing API, base classes, charts, and the full LCD App pattern: see [TSS_DRAWING.md](../tss/TSS_DRAWING.md).

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

## SBC: Localization (Translation Support)

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

> For the full RESX XML template and key matching rules, see [sbc/SBC_MISC.md](../../sbc/SBC_MISC.md).

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting](https://spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting) — official C# mod scripting reference

### Internal
- [CSHARP_PROJECT_SETUP.md](CSHARP_PROJECT_SETUP.md) — project setup: MDK2, .csproj, folder structure, namespaces, decompiler strategies
- [CSHARP_BLOCK_QUERIES.md](CSHARP_BLOCK_QUERIES.md) — block API queries: power, gas, inventory, production, doors, conveyor network
- [TSS_PATTERNS.md](../tss/TSS_PATTERNS.md) — TSS class structure, update loop, scrolling, subgrid caching
- [TSS_DRAWING.md](../tss/TSS_DRAWING.md) — TSS drawing API: helpers, base classes, viewport, charts, full LCD App pattern
- [PB_SCRIPTS.md](../PB_SCRIPTS.md) — Programmable Block scripting (sandboxed; different from compiled mods)
- [../../sbc/SBC_MISC.md](../../sbc/SBC_MISC.md) — LCD SBC registration; `Subtype` must match the C# script attribute

### Local
- ModSDK API DLLs (with XML docs): `[Steam]\steamapps\common\SpaceEngineersModSDK\`
