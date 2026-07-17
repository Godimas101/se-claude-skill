# C# Block API Queries — Space Engineers

Runtime query patterns for reading block state in compiled mods. These work in both Session Components and Text Surface Scripts.

> For project setup, MDK2, folder structure, and decompiler strategies: see [CSHARP_PROJECT_SETUP.md](CSHARP_PROJECT_SETUP.md).
> For runtime patterns (session component, config, save/sync): see [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md).
> For TSS class structure, scrolling, and update rules: see [TSS_PATTERNS.md](../tss/TSS_PATTERNS.md).
> For TSS drawing API, base classes, charts, and the full LCD App pattern: see [TSS_DRAWING.md](../tss/TSS_DRAWING.md).

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

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting](https://spaceengineers.wiki.gg/wiki/Modding/Reference/ModScripting) — official C# mod scripting reference

### Internal
- [CSHARP_PROJECT_SETUP.md](CSHARP_PROJECT_SETUP.md) — project setup: MDK2, .csproj, folder structure, namespaces, decompiler strategies
- [CSHARP_PATTERNS.md](CSHARP_PATTERNS.md) — session components, config/MyIni, save/sync, logging, type conversions
- [TSS_PATTERNS.md](../tss/TSS_PATTERNS.md) — TSS class structure, update loop, scrolling, subgrid caching
- [TSS_DRAWING.md](../tss/TSS_DRAWING.md) — TSS drawing API: helpers, base classes, viewport, charts, full LCD App pattern

### Local
- ModSDK API DLLs (with XML docs): `[Steam]\steamapps\common\SpaceEngineersModSDK\`
