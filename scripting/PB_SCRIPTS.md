# Space Engineers Programmable Block Script Expert

Expert guidance for writing **Programmable Block (PB) ingame scripts** for Space Engineers.

PB scripts run inside a sandboxed VM — they are completely different from compiled mods. No file I/O, no threading, no reflection. Access to game state is via a whitelisted API only.

> For compiled C# mods and text surface scripts use `/se-mod`. For Mod Adjuster patches use `/se-mod-adjuster`.

---

## The Fundamental Difference

| | PB Script | Compiled Mod |
|---|---|---|
| Written in | C# inside the game | External C# files compiled to DLL |
| Runs as | Sandboxed VM, instruction-limited | Full .NET, unrestricted |
| File access | ❌ None | ✅ Full |
| Threading | ❌ None | ✅ Full |
| Reflection | ❌ None | ✅ Full |
| I/O | ❌ None | ✅ Full |
| API access | Whitelist only | All SE namespaces |
| Persistence | `Storage` string + CustomData | Any mechanism |
| Entry point | `Main(string, UpdateType)` | `Run()` / `LoadData()` / etc. |

---

## Program Structure

Every PB script is a class that extends `MyGridProgram`. You never write the class declaration — SE wraps your code in it automatically. Just write the body:

```csharp
// Fields and constructor at the top
private List<IMyBatteryBlock> _batteries = new List<IMyBatteryBlock>();
private int _tickCounter = 0;

public Program()
{
    // Called once when the script loads or recompiles
    // Set your update frequency here
    Runtime.UpdateFrequency = UpdateFrequency.Update10;

    // Parse any saved state
    // _myValue = Storage; (Storage is a plain string)
}

public void Save()
{
    // Called before world save — persist anything important
    Storage = _myValue;
}

public void Main(string argument, UpdateType updateSource)
{
    // Called every update tick, or when triggered manually/by timer
    _tickCounter++;

    // Dispatch on argument for command handling
    switch (argument)
    {
        case "start":  HandleStart();  break;
        case "stop":   HandleStop();   break;
        default:       HandleTick();   break;
    }
}
```

---

## Update Frequency

### Setting the frequency

```csharp
// In constructor or Main():
Runtime.UpdateFrequency = UpdateFrequency.Update10;   // every 10 ticks
Runtime.UpdateFrequency = UpdateFrequency.Update100;  // every 100 ticks
Runtime.UpdateFrequency = UpdateFrequency.Update1;    // every tick (expensive!)
Runtime.UpdateFrequency = UpdateFrequency.None;       // stop automatic updates
Runtime.UpdateFrequency = UpdateFrequency.Once;       // run one more time, then stop

// Combine: update every 10 ticks AND run once immediately
Runtime.UpdateFrequency = UpdateFrequency.Update10 | UpdateFrequency.Once;
```

### Knowing how you were called

```csharp
public void Main(string argument, UpdateType updateSource)
{
    if ((updateSource & UpdateType.Update10) != 0)
    {
        // Called by the 10-tick timer
    }
    if ((updateSource & UpdateType.Trigger) != 0)
    {
        // Called by a timer block, sensor, or event controller
    }
    if ((updateSource & UpdateType.Terminal) != 0)
    {
        // Player clicked "Run" in the terminal
    }
    if ((updateSource & UpdateType.IGC) != 0)
    {
        // Inter-grid communication message arrived
    }
}
```

### Tick math
- **Update1** = every tick (~60/sec). Very expensive, avoid unless necessary.
- **Update10** = every 10 ticks (~6/sec). Good for reactive scripts.
- **Update100** = every 100 ticks (~0.6/sec). Good for status displays, slow monitoring.
- `Runtime.TimeSinceLastRun` — actual elapsed time since last call (TimeSpan)

---

## Core API Reference

### Available Properties (from MyGridProgram)

```csharp
IMyGridTerminalSystem GridTerminalSystem  // Access all blocks on grid
IMyProgrammableBlock Me                   // This PB block
IMyGridProgramRuntimeInfo Runtime         // Performance + scheduling
IMyIntergridCommunicationSystem IGC       // Radio / antenna comms
string Storage                            // Persistent string (saved with world)
Action<string> Echo                       // Output to PB terminal screen
```

### Runtime Info

```csharp
Runtime.CurrentInstructionCount   // Instructions used this tick
Runtime.MaxInstructionCount       // Instruction budget (~100,000)
Runtime.LastRunTimeMs             // How long last Main() took (ms)
Runtime.TimeSinceLastRun          // TimeSpan since last call

// Monitor your budget:
Echo($"Instructions: {Runtime.CurrentInstructionCount}/{Runtime.MaxInstructionCount}");
```

---

## Finding Blocks

```csharp
// Single block by exact name
IMyBatteryBlock battery = GridTerminalSystem.GetBlockWithName("Battery 1") as IMyBatteryBlock;

// All blocks of a type
var batteries = new List<IMyBatteryBlock>();
GridTerminalSystem.GetBlocksOfType(batteries);

// All blocks of a type on THIS grid only (exclude subgrids)
GridTerminalSystem.GetBlocksOfType(batteries, b => b.CubeGrid == Me.CubeGrid);

// By block group
IMyBlockGroup group = GridTerminalSystem.GetBlockGroupWithName("Engines");
var thrusters = new List<IMyThrust>();
group?.GetBlocksOfType(thrusters);

// Tag-based filtering (name contains "[TAG]")
GridTerminalSystem.GetBlocksOfType(batteries, b => b.CustomName.Contains("[BATTERY]"));

// With condition
GridTerminalSystem.GetBlocksOfType(batteries, b => b.IsWorking && b.ChargeMode != ChargeMode.Discharge);
```

### ⚠️ Critical: Cache your block lists!

```csharp
// ❌ DO NOT scan every tick — expensive and hits instruction limit
public void Main(string arg, UpdateType src)
{
    var batteries = new List<IMyBatteryBlock>();
    GridTerminalSystem.GetBlocksOfType(batteries);  // ← kills performance
}

// ✅ Cache and refresh on a slow interval
private List<IMyBatteryBlock> _batteries = new List<IMyBatteryBlock>();
private int _refreshTick = 0;

public void Main(string arg, UpdateType src)
{
    _refreshTick++;
    if (_refreshTick >= 100)  // refresh every 100 ticks
    {
        _refreshTick = 0;
        _batteries.Clear();
        GridTerminalSystem.GetBlocksOfType(_batteries);
    }
    // use _batteries safely
}
```

---

## Common Block Interfaces

```csharp
// Power
IMyBatteryBlock       .CurrentStoredPower, .MaxStoredPower, .ChargeMode, .IsCharging
IMyReactor            .IsWorking, .Enabled
IJumpDrive            .Status (MyJumpDriveStatus), .CurrentStoredPower, .MaxStoredPower

// Movement
IMyThrust             .ThrustOverride, .ThrustOverridePercentage, .MaxThrust, .CurrentThrust, .Enabled
IMyGyro               .GyroOverride, .Pitch/Yaw/Roll (override values), .GyroPower

// Ship controller (cockpit/remote)
IMyShipController     .MoveIndicator (Vector3), .RotationIndicator (Vector2), .RollIndicator (float)
                      .DampenersOverride, .IsUnderControl, .CalculateShipMass()

// Storage
IMyCargoContainer     .GetInventory(0)
IMyConveyorSorter     .DrainAll, .Mode

// Connectors / docking
IMyShipConnector      .Status (MyShipConnectorStatus), .Connect(), .Disconnect(), .OtherConnector
IMyLandingGear        .IsLocked, .LockMode, .Lock(), .Unlock()

// Doors / atmosphere
IMyDoor               .Status (DoorStatus), .OpenDoor(), .CloseDoor()
IMyAirVent            .CanPressurize, .GetOxygenLevel()
IMyGasTank            .FilledRatio (double), .Capacity, .Stockpile

// Weapons
IMyUserControllableGun .IsShooting, .ShootOnce(), .SetShootFromTerminal(bool)
IMyLargeTurretBase    .IsUnderControl, .GetTargetedEntity(), .HasTarget

// Mechanical
IMyMotorStator        .Angle (radians), .TargetVelocityRPM, .UpperLimitDeg, .LowerLimitDeg
IMyPistonBase         .CurrentPosition, .MaxLimit, .MinLimit, .Velocity

// Displays
IMyTextPanel          .WriteText(string), .ReadText()
IMyTextSurface        .DrawFrame() → MySpriteDrawFrame (same sprite API as compiled mods)

// Comms
IMyRadioAntenna       .Radius, .EnableBroadcasting, .Enabled
IMyBeacon             .Radius, .HudText, .Enabled

// Misc
IMyTimerBlock         .TriggerDelay, .StartCountdown(), .StopCountdown(), .Trigger()
IMyProjector          .BuildableBlocksCount, .TotalBlocksCount, .RemainingBlocksCount
IMyProgrammableBlock  .Run(string argument)  // run another PB
```

---

## Displaying Output

### PB Terminal Screen (Echo)

```csharp
// Appears in the PB's "Output" panel in the terminal
Echo("Status: Running");
Echo($"Batteries: {_batteries.Count}");
Echo($"Power: {totalPower:F1} MWh");
// Note: Echo is additive within one Main() call but resets each call
```

### Writing to Text Panels

```csharp
IMyTextPanel screen = GridTerminalSystem.GetBlockWithName("Status Screen") as IMyTextPanel;
if (screen != null)
{
    // Simple text
    screen.ContentType = ContentType.TEXT_AND_IMAGE;
    screen.WriteText("Hello World\n");
    screen.WriteText($"Power: {power:F1} MWh\n", true);  // append

    // Sprite drawing (same as compiled mod surfaces)
    screen.ContentType = ContentType.SCRIPT;
    screen.Script = "";
    using (var frame = screen.DrawFrame())
    {
        frame.Add(new MySprite
        {
            Type = SpriteType.TEXT,
            Data = "Hello",
            Position = new Vector2(128, 128),
            Color = Color.White,
            FontId = "White",
            RotationOrScale = 1.0f
        });
    }
}
```

### Writing to the PB's own surface

```csharp
// The PB itself has one text surface (index 0)
IMyTextSurface pbScreen = Me.GetSurface(0);
pbScreen.ContentType = ContentType.TEXT_AND_IMAGE;
pbScreen.WriteText("Script Running\n");
```

---

## Configuration via CustomData

```csharp
private MyIni _ini = new MyIni();
private string _tag = "[CARGO]";
private float _threshold = 0.9f;

public Program()
{
    LoadConfig();
}

private void LoadConfig()
{
    _ini.Clear();
    if (!_ini.TryParse(Me.CustomData))
    {
        // Invalid INI — write defaults
        SaveConfig();
        return;
    }
    _tag = _ini.Get("Config", "Tag").ToString(_tag);
    _threshold = (float)_ini.Get("Config", "Threshold").ToDouble(_threshold);
}

private void SaveConfig()
{
    _ini.Set("Config", "Tag", _tag);
    _ini.Set("Config", "Threshold", _threshold);
    Me.CustomData = _ini.ToString();
}
```

---

## Persistent State (Storage)

`Storage` is a plain string saved with the world. Max useful size: a few KB.

```csharp
public Program()
{
    // Restore state on load
    if (!string.IsNullOrEmpty(Storage))
    {
        _myState = Storage;
    }
}

public void Save()
{
    // SE calls this before saving the world
    Storage = _myState;
}
```

For more complex state, use MyIni or manual serialization into the Storage string.

---

## Argument Handling (Commands)

```csharp
public void Main(string argument, UpdateType updateSource)
{
    // Trim to handle accidental spaces
    switch (argument.Trim().ToLower())
    {
        case "start":
            _running = true;
            Runtime.UpdateFrequency = UpdateFrequency.Update10;
            break;
        case "stop":
            _running = false;
            Runtime.UpdateFrequency = UpdateFrequency.None;
            break;
        case "reset":
            Reset();
            break;
        case "":
            // No argument — normal tick
            break;
        default:
            Echo($"Unknown command: {argument}");
            break;
    }
}
```

---

## Coroutines (Multi-Tick Operations)

When an operation needs more instructions than fit in one tick, split it with a coroutine:

```csharp
private IEnumerator<bool> _routine = null;

public void Main(string argument, UpdateType updateSource)
{
    if (argument == "scan")
    {
        _routine = ScanAllBlocks();
        Runtime.UpdateFrequency = UpdateFrequency.Update1;
    }

    if (_routine != null)
    {
        if (!_routine.MoveNext())
        {
            _routine.Dispose();
            _routine = null;
            Runtime.UpdateFrequency = UpdateFrequency.None;
        }
    }
}

private IEnumerator<bool> ScanAllBlocks()
{
    var allBlocks = new List<IMyTerminalBlock>();
    GridTerminalSystem.GetBlocks(allBlocks);

    for (int i = 0; i < allBlocks.Count; i++)
    {
        // Process one block
        ProcessBlock(allBlocks[i]);

        // Every 50 blocks, yield to next tick
        if (i % 50 == 0)
            yield return true;
    }
    Echo($"Scan complete: {allBlocks.Count} blocks");
}
```

---

## Inter-Grid Communication (IGC)

```csharp
private IMyBroadcastListener _listener;

public Program()
{
    // Register to receive on a channel
    _listener = IGC.RegisterBroadcastListener("MY_CHANNEL");
    _listener.SetMessageCallback("IGC_MESSAGE");  // triggers Main("IGC_MESSAGE")
}

public void Main(string argument, UpdateType updateSource)
{
    // Handle incoming messages
    if (argument == "IGC_MESSAGE")
    {
        while (_listener.HasPendingMessage)
        {
            MyIGCMessage msg = _listener.AcceptMessage();
            string data = msg.Data.ToString();
            long senderId = msg.Source;
            Echo($"Got: {data} from {senderId}");
        }
    }
}

// Send a broadcast
private void SendStatus(string status)
{
    IGC.SendBroadcastMessage("MY_CHANNEL", status);
}

// Send to specific grid (unicast)
private void SendTo(long targetId, string data)
{
    IGC.SendUnicastMessage(targetId, "MY_CHANNEL", data);
}
```

---

## Common Script Patterns

### Pattern 1 — Status Display

```csharp
private List<IMyBatteryBlock> _batteries = new List<IMyBatteryBlock>();
private IMyTextPanel _display;

public Program()
{
    Runtime.UpdateFrequency = UpdateFrequency.Update100;
    GridTerminalSystem.GetBlocksOfType(_batteries, b => b.CubeGrid == Me.CubeGrid);
    _display = GridTerminalSystem.GetBlockWithName("Power Display") as IMyTextPanel;
}

public void Main(string arg, UpdateType src)
{
    float stored = 0, max = 0;
    foreach (var bat in _batteries)
    {
        stored += bat.CurrentStoredPower;
        max += bat.MaxStoredPower;
    }
    float pct = max > 0 ? stored / max * 100 : 0;

    var sb = new StringBuilder();
    sb.AppendLine($"Batteries: {_batteries.Count}");
    sb.AppendLine($"Stored: {stored:F1}/{max:F1} MWh");
    sb.AppendLine($"Charge: {pct:F0}%");

    _display?.WriteText(sb.ToString());
    Echo(sb.ToString());
}
```

### Pattern 2 — Command Dispatcher with State

```csharp
private enum State { Idle, Running, Stopping }
private State _state = State.Idle;

public void Main(string argument, UpdateType updateSource)
{
    if (!string.IsNullOrEmpty(argument))
        HandleCommand(argument);
    else
        HandleUpdate();
}

private void HandleCommand(string cmd)
{
    switch (cmd)
    {
        case "start":
            _state = State.Running;
            Runtime.UpdateFrequency = UpdateFrequency.Update10;
            break;
        case "stop":
            _state = State.Stopping;
            break;
    }
}

private void HandleUpdate()
{
    switch (_state)
    {
        case State.Running:  DoRunning();  break;
        case State.Stopping: DoStopping(); break;
    }
}
```

### Pattern 3 — Tag-Based Block Discovery (used by most professional scripts)

```csharp
private const string TAG = "[MYMOD]";
private List<IMyCargoContainer> _taggedContainers = new List<IMyCargoContainer>();

public Program()
{
    RefreshBlocks();
    Runtime.UpdateFrequency = UpdateFrequency.Update100;
}

private void RefreshBlocks()
{
    _taggedContainers.Clear();
    GridTerminalSystem.GetBlocksOfType(_taggedContainers,
        b => b.CustomName.Contains(TAG) && b.CubeGrid == Me.CubeGrid);
    Echo($"Found {_taggedContainers.Count} tagged containers");
}

public void Main(string arg, UpdateType src)
{
    if (arg == "refresh") RefreshBlocks();
    // Process _taggedContainers...
}
```

### Pattern 4 — Gyro Override (autopilot/stabilization)

```csharp
private List<IMyGyro> _gyros = new List<IMyGyro>();

private void SetGyroOverride(float pitch, float yaw, float roll, bool enabled)
{
    foreach (var gyro in _gyros)
    {
        gyro.GyroOverride = enabled;
        if (enabled)
        {
            gyro.Pitch = pitch;
            gyro.Yaw = yaw;
            gyro.Roll = roll;
        }
    }
}

private void ReleaseGyros()
{
    foreach (var gyro in _gyros)
        gyro.GyroOverride = false;
}
```

---

## Sandbox Restrictions — What You CANNOT Do

```csharp
// ❌ File I/O
System.IO.File.ReadAllText("...");

// ❌ Threading
new System.Threading.Thread(() => { }).Start();
Task.Run(() => { });

// ❌ Reflection
Type.GetType("System.String");
typeof(IMyBatteryBlock).GetMethods();

// ❌ Network
System.Net.WebClient client = new System.Net.WebClient();

// ❌ Unsafe code
unsafe { int* p = &x; }

// ❌ P/Invoke
[DllImport("kernel32.dll")]

// ❌ Dynamic / late-binding
dynamic d = someObject;
```

---

## Performance Rules

1. **Never call `GetBlocksOfType` every tick.** Cache block lists and refresh every 100+ ticks.
2. **Watch your instruction count.** Check `Runtime.CurrentInstructionCount` during development.
3. **Use `StringBuilder` for string building.** String concatenation in loops creates tons of garbage.
4. **Update100 for displays, Update10 for control, Update1 only if truly necessary.**
5. **Event-driven > polling.** Use `SetMessageCallback` and Trigger-based updates instead of constant polling when possible.
6. **Split heavy work with coroutines.** Scanning 1000+ blocks should be spread across ticks.

---

## Script Types — What's Possible

| Script Type | What It Does | Key APIs |
|-------------|-------------|----------|
| **Status Display** | Shows power/gas/cargo on LCDs | `IMyBatteryBlock`, `IMyGasTank`, `IMyTextPanel` |
| **Inventory Manager** | Sorts items between containers | `IMyCargoContainer`, `IMyInventory.TransferItemTo()` |
| **Auto-Miner** | Controls drills + pistons/rotors | `IMyShipDrill`, `IMyPistonBase`, `IMyMotorStator` |
| **Autopilot** | Gyro + thruster override | `IMyGyro`, `IMyThrust`, `IMyShipController` |
| **Weapon Controller** | Aims turrets, fires weapons | `IMyLargeTurretBase`, `IMyUserControllableGun` |
| **Docking Assist** | Connector + landing gear automation | `IMyShipConnector`, `IMyLandingGear` |
| **Vehicle Control** | Wheel suspension + stabilization | `IMyMotorSuspension`, `IMyGyro` |
| **Airlock Controller** | Door sequencing + air vent | `IMyDoor`, `IMyAirVent` |
| **Production Manager** | Assembler/refinery queue | `IMyAssembler`, `IMyRefinery` |
| **IGC Network** | Multi-ship coordination | `IGC`, `IMyRadioAntenna` |

---

## Key Namespaces (Whitelisted)

```csharp
using Sandbox.ModAPI.Ingame;           // All block interfaces
using Sandbox.ModAPI.Interfaces;       // Terminal action/property access
using SpaceEngineers.Game.ModAPI.Ingame; // SE-specific blocks
using VRage.Game.GUI.TextPanel;        // Sprites, IMyTextSurface
using VRage.Game.ModAPI.Ingame;        // MyInventoryItem, MyFixedPoint
using VRageMath;                       // Vector2/3, Color, etc.
using VRage;                           // MyFixedPoint
using System.Text;                     // StringBuilder ✅
using System.Collections.Generic;      // List<T>, Dictionary<T> ✅
using System;                          // Math, DateTime, TimeSpan ✅
```

