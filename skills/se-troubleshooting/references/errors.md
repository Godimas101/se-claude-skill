# Troubleshooting — Space Engineers Mods

Error reference compiled from `spaceengineers.wiki.gg/wiki/Modding/Troubleshooting` and the full Known Solutions page.

---

## First Steps — Always Do This First

1. **After ANY error that sends you to the main menu — restart the game before trying again.** The game doesn't clean up properly after errors, causing cascading `DuplicateIdException` and file-lock errors on the next load.
2. Sort log files by "Date Modified" — always use the newest one.
3. Use **Notepad++ Find in Files** (`Ctrl+Shift+F`) to search across all SBC files in `[SE]\Content\Data\` or the workshop folder when hunting for conflicting definitions.
4. After editing an SBC, **delete any matching `.sbcB5` / `.sbsB5` cache files** or your changes won't be read.
5. To find which mod caused an error: look at the stack trace file path — workshop folder numbers are Steam mod IDs.

---

## Log Files

**Location:** `%AppData%\SpaceEngineers\`
(Type directly into Windows Explorer address bar)

**File format:** `SpaceEngineers_YYYYMMDD_HHMMSSms.log` — sort by date modified, use the newest.
Plain text — open in VS Code, Notepad++, or any text editor.
Logs older than 3 days are auto-deleted.

**Key search terms (priority order):**

| Search term | What it finds |
|-------------|--------------|
| `MOD_CRITICAL_ERROR` | Mod failed to load entirely |
| `Fatal error compiling` | C# script compile failure |
| `Exception occurred` | Any .NET exception |
| `ERROR Entity init` | Block or entity initialization failure |
| `LOADED ONLY` | Partial mod load (some phases missing) |
| `No definition` | TypeId or SubtypeId not found |
| `Unknown UGC service name` | Steam mod download failure on non-Steam servers |
| `failed to save` | World save error |
| `Loading voxel` | Start of voxel-related error |
| `DuplicateId` | Entity ID conflict — restart game first |
| `KeyNotFoundException` | Missing SubTypeId, targeting group, or definition |

---

## Mod Load Failures

### MOD_CRITICAL_ERROR / LOADED ONLY n/6 PHASES
- Missing `Data\` folder — must exist even if empty
- `Data\` folder nested inside a zip subfolder instead of at root
- Local mod renamed or deleted (shows red in mod list)
- Missing `Type: Mod` declaration

### MOD_CRITICAL_ERROR / MyCubeBlockDefinition.Init
- Component SubTypeIds in `<Components>` list don't exist
- `<CriticalComponent>` references a non-existent component
- Definition copied from wrong vanilla TypeId (wrong base structure)
- **Fix:** Copy the vanilla definition for the exact TypeId you're using; verify all component SubTypeIds

### Fatal error compiling / "This item is likely not a mod"
- **Cause 1:** Full file path to the mod is too long → move `%AppData%` to a shorter path
- **Cause 2:** Malformed C# attribute syntax (closing paren in wrong place) → fix the attribute

### Cannot load file: Weapons.sbc
- **Cause 1:** Game files manually modified → delete `[SE]\Data\` folder, re-validate via Steam
- **Cause 2:** A mod's ammo magazine references a non-existent ammo SubTypeId → fix the reference

### Unknown UGC service name: Steam
- Mod is set to Friends-only or Hidden → must be Public or Unlisted for servers to download it

---

## SBC Definition Errors

### Value cannot be null / MyObjectFactory.GetProducedType
- TypeId doesn't exist — mods can only create new SubTypeIds, not new TypeIds
- **Fix:** Use a valid vanilla TypeId

### The given key was not present / MyWeaponDefinition.Init
- Ammo magazine SubTypeId not found, OR magazine points to non-existent ammo SubTypeId
- Also check for malformed XML: duplicate `</AmmoMagazines><AmmoMagazines>` tags

### Input string was not in a correct format / MyBlueprintDefinitionBase
- `{` or `}` in a blueprint `<DisplayName>` triggers a string format error
- **Fix:** Remove them, escape as `{{`/`}}`, or use a localization `.resx` key instead

### ArgumentNullException / MyDefinitionManager.InitBlockGroups
- Block definition missing `<BlockPairName>`
- **Fix:** Add `<BlockPairName>` to the definition

### ArgumentException / MyDefinitionManager.RegisterFactionDefinition
- Two mods use the same faction `Tag` with different SubTypeIds
- **Fix:** Use Notepad++ Find in Files; search `<Faction Tag="TAGNAME"` across the workshop folder; folder numbers = mod IDs

### NullReferenceException / MyBlockVariantGroup.ResolveBlocks
- `BlockVariantGroup` defined without `<Blocks>` list

### NullReferenceException / PostprocessRadialMenus
- Block definition missing `<Icon>`

### NullReferenceException / MyBlockBuilderBase.AddFastBuildModelWithSubparts
- `<MirroringBlock>` references wrong SubTypeId or mismatched TypeId

---

## Block-Specific Errors

### NullReferenceException / (AnyBlockClass).Init
- Missing or wrong `xsi:type` attribute on the definition
- **Fix:** Check vanilla SBC for your TypeId; copy the exact `xsi:type` value

### KeyNotFoundException / MyLargeGatlingTurret.OnModelChange
### NullReferenceException / MyLargeTurretBase.GetWorldMatrix
- Turret model missing required subpart chain
- **Fix:** See LargeGatlingTurret / LargeMissileTurret model setup docs for required subpart names

### KeyNotFoundException / MyLargeTurretTargetingSystem
### KeyNotFoundException / MyStringHash.get_String (turret context)
- Turret has a `<TargetingGroup>` referencing a non-existent targeting group (often after removing MES)
- **Fix:** Remove `<TargetingGroup>` from affected turret blocks; delete `.sbsB5` cache file

### TargetInvocationException / Unable to cast to MyTextPanel
- Model has a `detector_textpanel` dummy but the block is NOT a TextPanel type
- **Fix:** Remove the dummy or rename it to the correct detector type

### InvalidCastException / MyUseObjectAdvancedDoorTerminal
- `detector_advanceddoor` used in a non-AdvancedDoor block
- **Fix:** Change detector name or change block TypeId to AdvancedDoor

### IndexOutOfRangeException / MyConveyorLine.GetBlockLinePositions
- A conveyor dummy spans multiple directions — must align to exactly one direction

### IndexOutOfRangeException / MyConveyorConnector.InitializeConveyorSegment
### NullReferenceException / MyConveyorSegment.CanConnectTo
- ConveyorConnector requires exactly 2 ports; block has 0 or 1

### KeyNotFoundException / MyResourceDistributorComponent.GetTypeIndex
- Oxygen disabled in world settings, OR GasGenerator block missing oxygen in definitions

### NullReferenceException / MyPistonBase.GetTopMatrixLocal
- Required subparts missing from piston main or construction models

---

## C# Script Errors

### Exception during loading of type: [ClassName]
- Exception thrown in class constructor or field initializer
- Most common: accessing `MyAPIGateway.Session` in a constructor (it's null at load time)
- **Fix:** Attach dnSpy debugger to catch the real exception; move API access to `LoadData()`

### ProtoBuf.ProtoException: No parameterless constructor found
- Packet class missing a zero-argument constructor, or doesn't inherit the required base class

### IndexOutOfRangeException / MyConcurrentTwoLevelQueue.Enqueue
- Too many render messages queued in one frame (often from coloring blocks triggering mass emissive recolor)
- **Fix:** Use `ChangeColorAndSkin()` instead of color-only API

### IOException: file used by another process (on world load)
- Previous error left file handles open — restart the game entirely
- Also check Task Manager for invisible `SpaceEngineers.exe` processes

---

## Render / Model Errors

### IndexOutOfRangeException / MyHwBuffers.GetVertexBuffer
- Model has no UV mapping — apply UV map in your modelling tool

### KeyNotFoundException / MyMeshes.CreateSections
- Model has UV maps with zero-size UVs (improperly unwrapped) — properly unwrap all UVs

### ArgumentNullException / MyBillboardRenderer.GatherInternal
- A transparent material definition references a texture file that doesn't exist

### NullReferenceException / MyRender11.RenderMainSpritesWorker
- `<OverlayTexture>` blank or missing on a camera or turret block, while loading into a world controlling that block
- **Fix:** Provide a valid `<OverlayTexture>` file

---

## Voxel Errors

The log line `Loading voxel 'path/file.vx2'` precedes voxel errors but the cause is often elsewhere.

### InvalidOperationException / MyCompositeShapeProviderBase.ReadContentRange
- Procedural asteroid copied and spawned via VoxelMapStorage Definition — not supported
- **Fix:** Use hand-authored `.vx2` files instead

### NullReferenceException / MyCompositeShapes.FillSpan
- A `.vx2` file referenced by the asteroid generator doesn't exist at the declared path

---

## World Save / Load Errors

### SaveFinished: failed to save the world
- World name has a trailing space → remove it
- Screenshot write failure → check VRage log

### NullReferenceException / MySession.GatherVicinityInformation
- Modded character subtype saved in `ActiveInventory.sbl` but not available in current world
- **Fix:** Edit `%AppData%\SpaceEngineers\Saves\ActiveInventory.sbl`; change `<Model>` to `Default_Astronaut`

### ERROR Entity init / DuplicateIdException
- Caused by a previous error interrupting world load — **restart game first**, then retry

### NullReferenceException / MyTerminalProductionController.RefreshBlueprints (assembler terminal)
- A mod block was added to the build planner then the mod was removed
- **Fix:** Open G-menu → right-click each BuildPlanner entry until only the "+" slot remains

### NullReferenceException / PasteGridData.Callback
- Armor skin ID on a pasted grid no longer exists — check block skin assignments

---

## When Changes Don't Apply

### Requires full game restart
- Model changes (dummies, colliders, animations)
- Block Center definition changes
- `EmissiveColorStatePreset` / `EmissiveColor` definitions (no-override — new entries only, and even those can't change in the same session)
- Any error that sent you to the main menu

### Requires world reload only
- Most SBC definition changes

### Requires placing a new block
- Inventory stat changes (cached per-block in the save file)
- Entity component add/remove

### Requires planet respawn (or direct save file edit)
These planet properties are written to the save file on planet creation and **never update** from definition changes:
- `SurfaceGravity`, `GravityFalloffPower`, `HasAtmosphere`, `AtmosphereSettings Scale`

Workaround: edit values directly in `SANDBOX_0_0_0_.sbs` and delete `.sbsB5`, or use the **Reload Definitions** mod (Workshop ID `2366234777`).

### Textures only — no restart needed
F11 (offline worlds) → Debug Menu → "Reload Textures"

---

## Debug Tools

### In-Game (no install required)

| Tool | Access | Purpose |
|------|--------|---------|
| Debug Draw | F11 (offline only) | Visualize dummies, mount points, physics, solar rays |
| Reload Textures | F11 menu | Reload SBC-linked textures without restart |
| Reload Models | F11 menu | Reload model files without restart |
| Performance Metrics | Shift+F11 | FPS, UPS, CPU/GPU, network stats |
| Mod Profiler | Shift+F1 | Per-mod script performance summary |

F11 requires toggling "Enable debug draw" first.

### External Tools

| Tool | Purpose |
|------|---------|
| **dnSpy** | Attach live debugger to running game; catches suppressed exceptions; set breakpoints. Primary tool for diagnosing swallowed `Exception during loading of type` errors |
| **ILSpy** | Decompile game DLLs for read-only reference — learn how vanilla code works |
| **Notepad++** | Find in Files (`Ctrl+Shift+F`) across all SBC files |
| **Reload Definitions** (Workshop `2366234777`) | Hot-reload SBC definitions without restart — invaluable for planet modding |
| **Fix null-named GPS** (Workshop `3467839436`) | Fixes null-name GPS crash |

---

## References

### External
| Resource | URL |
|----------|-----|
| Keen Discord | discord.gg/keenswh — `#modding-programming` (C#), `#modding-art-sbc` (SBC) |
| Keen Support | support.keenswh.com/spaceengineers |
| Official ModAPI docs | keensoftwarehouse.github.io/SpaceEngineersModAPI/api/index.html |
| Community ModAPI docs | malforge.github.io/spaceengineers/modapi/ |
| SE Wiki Troubleshooting | [spaceengineers.wiki.gg/wiki/Modding/Troubleshooting](https://spaceengineers.wiki.gg/wiki/Modding/Troubleshooting) |

### Internal
- [PATCH_NOTES.md](PATCH_NOTES.md) — breaking changes by patch; check here when a mod stops working after an update
- [DLC_CATALOGUE.md](DLC_CATALOGUE.md) — DLC SubtypeIds; useful when diagnosing DLC-related block errors
