# Patch Changes — Space Engineers Modding Reference

Community-documented changes discovered by comparing decompiled game code across patches. Most items are **not** in the official changelog. Source: `Modding/Reference/Overview_of_Modding-Relevant_Changes_in_Game_Patches`

Full patch URLs: `https://spaceengineers.wiki.gg/wiki/Modding/Reference/Patch_Changes/[version]`

---

## Breaking Changes Quick Reference

Issues that will break existing mods without action:

| Version | Breaking Change | Action Required |
|---------|----------------|----------------|
| 1.208 | `MaintenancePanelComponent`: `<SimpleOpen>` removed, replaced by `<IsRotation>` — **opposite meaning and default** | Update SBC definitions |
| 1.208 | `MyInventory.RaiseConsumedEvent()` renamed to `RecordConsumedFood()` | Update C# calls |
| 1.207 | Character mods need new EntityContainers + CharacterStatComponent entries | Update character mod SBCs |
| 1.207 | `CubeBlockDefinition` removed: `<NavigationDefinition>`, `<CreateFracturedPieces>`, `<CompoundEnabled>`, `<CompoundTemplates>`, `<MultiBlock>`, `<SubBlockDefinitions>` | Remove from SBCs (silently ignored or error) |
| 1.207 | `MyCharacterComponent` no longer base class for other components | Refactor C# class hierarchy |
| 1.205 | `ModAPI.IMyOxygenGenerator` **fully removed** | Remove/replace all API references |
| 1.205 | `Ingame.IMyOxygenGenerator` **fully removed** | Remove/replace all PB script references |
| 1.205 | Assembler speed formula changed: multiplier now wraps `(base + modules)` not just base | Rebalance assembler productivity values |
| 1.205 | `AirtightSlideDoor` and `AirtightHangarDoor` now place in **closed** state (was open) | Test/fix any placement scripts |
| 1.205 | `SpawnGroup.<IsPirate>` **removed** — use `<FactionTypes>` with `"Pirate"` string | Update encounter/NPC mods |
| 1.205 | `IMyFactionCollection.CreateFaction()` marked obsolete | Use `CreateFactionNew()` |
| 1.203 | Missile ammo `<MissileRicochetAngle>` and `<MissileRicochetProbability>` replaced with min/max versions | Update weapon mod SBCs |
| 1.202 | `IMyOxygenTank` PB interface **removed** (was obsolete) | Remove from PB scripts |
| 1.202 | `MyInventory.AddEntity()` and `RemoveItemsInternal()` removed | Update C# inventory code |
| 1.200 | `MyGridProgram.ElapsedTime` **removed** | Use `Runtime.TimeSinceLastRun` instead |
| 1.200 | `PassengerSeatSmall` hidden, replaced by `PassengerSeatSmallNew` | Update blueprints/references |

---

## Notable Non-Breaking Changes by Patch

### Patch 1.208 — Core Systems
- **MySync cap raised to 64** per type (was 32) — blocks with 32–64 syncs now work correctly
- **Multiple gamelogic bug fixed** — `OnAddedToScene`, `OnRemovedFromScene`, `UpdatingStopped` now trigger correctly when multiple `GameLogicComponent`s exist on the same block (was previously unreliable)
- `ConsumableItem.<ExtraInventoryTooltipLine>` and `Blueprint.<DisplayName>` now support stat replacement — **crash risk if malformed**
- `MyGridStorageHelper` changed from internal to public
- Font additions: white/white_shadow fonts now include characters e033–e053
- `VRage.Game.ObjectBuilders.Components.*` added to mod whitelist

### Patch 1.207 — Apex Survival
- New EntityComponents: `ConveyorEndpointComponent`, `LightingComponent`, `FarmPlotLogic`, `ResourceSourceComponent`, `ResourceStorageComponent`, etc.
- New survival definitions: `SeedItem`, `Forageable`, `HazardExposureComponent`, food/radiation stats
- New buffs system: `SurvivalBuffsProgression` and buff definitions
- `VoxelMaterial.<SpawnsFromMeteorites>` no longer functional
- `FunctionalBlock` type now usable as standalone element

### Patch 1.206 — Fieldwork
- **PB execution hard-capped at 3 seconds** — throws `ScriptOutOfTimeException` on exceed
- **PB memory monitoring** — throws `ScriptOutOfMemoryException` on overuse
- `Program.World` property added to PB
- `Runtime.LifetimeTicks` property added
- Max voxel materials per world: **256**
- `IMyShipDrill`: got `TerrainClearingMode`

### Patch 1.205 — Contact
- `IMyMotorStator.RotateToAngle()` added to PB API
- `IMyPistonBase.MoveToPosition()` added to PB API
- `IMyTerminalBlock.CustomName` setter limited to **512 characters maximum**
- New MyCubeGrid global block events: `OnBlockAddedGlobally`, `OnBlockRemovedGlobally`, `OnBlocksChangeFinishedGlobally`
- `MyFakes.ENABLE_TYPES_FROM_MODS` set to true — custom ObjectBuilders now allowed in mods
- `SpawnGroup` major expansion with global/planetary encounter settings

### Patch 1.204 — Signal
- `MyFakes.ENABLE_TYPES_FROM_MODS` set to true — custom OBs allowed in mods (also applies here)
- New block types: `TransponderBlock`, `BroadcastController`
- New entity components: `ChatBroadcastEntityComponent`, `SignalSenderEntityComponent`, etc.
- `IMyGasTank.ChangeFilledRatio()` added
- `IMyInventory.CanPutItems` now get+set; `MaxVolume` now settable

### Patch 1.203 — Warfare Evolution
- `block.Components.TryGet<T>()` now supports **interface** as type parameter
- New EntityComponents: `RotatingSubpartComponent`, `ParticleEntityComponent`, `LcdSurfaceComponent`, `MultiTextPanelComponent`
- New interfaces: `IMyResourceSinkComponent`, `IMyLcdSurfaceComponent`, `IMyMultiTextPanelComponentOwner`
- `IMyEntityComponentContainer` added (`MyEntity.Components` type changed to this)
- `VRage.Game.Components.Interfaces` namespace whitelisted

### Patch 1.202 — Automatons
- New block types: `EventControllerBlock`, `PathRecorderBlock`, `BasicMissionBlock`, `FlightMovementBlock`, `DefensiveCombatBlock`, `OffensiveCombatBlock`, `EmotionControllerBlock`
- **PB color in detailed info:** `[color=#AARRGGBB]...[/color]` syntax; bare `[` alone = yellow text
- `IMyThrust.CurrentThrustPercentage` added
- `IMyPistonBase.NormalizedPosition` added
- `IMyCubeGrid.LinearVelocity`, `Speed` added to PB API
- `Vector2`/`Vector2D` now implicitly castable — **precision loss possible**

### Patch 1.201 — Most Wanted
- 9 new deformable armor cube topologies
- Character model: `Gender` property added
- Cockpit: `CharacterAnimationMale`/`CharacterAnimationFemale` added
- `IMyEntityCapacitorComponent` added (railgun systems)

### Patch 1.200 — Warfare 2 "Broadside"
- New block types: `TurretControlBlock`, `Searchlight`, `HeatVentBlock`
- All blocks gained: `<ScreenAreas>` (LCD support), `<TargetingGroups>`, `<PriorityModifier>`, damage/explosion fields
- `MySync<,>` generic type added to mod whitelist
- `IMyCubeGrid` major expansion: `GetGridGroup()`, `GetFatBlocks<T>()`, `ResourceDistributor`, `ConveyorSystem`, `WeaponSystem`, etc.
- `IMyVoxelMaps.CreatePredefinedVoxelMap()`, `SpawnPlanet()` added
- `MyAPIGateway.Projectiles`, `Missiles`, `DLC` properties added
- `IMyMissile` interface added
- `IMyGui.ShowTerminalPage()`, `ChangeInteractedEntity()` added
- `IMyDamageSystem.RaiseBeforeDamageApplied()`, `RaiseAfterDamageApplied()` added

---

## Gotchas Discovered Across Patches

| Gotcha | Patch |
|--------|-------|
| SHIELD technique may crash on certain blocks | Materials wiki |
| Particle textures must be exactly 8192×8192 with mipmaps | Materials wiki |
| Facing on materials: shadows don't reflect mesh rotation | Materials wiki |
| PB execution hard cap 3s (`ScriptOutOfTimeException`) | 1.206 |
| `ConsumableItem` stat replacement: potential crash if malformed | 1.208 |
| Multiple gamelogics on same block was buggy before 1.208 | 1.208 |
| `MaintenancePanelComponent`: `<IsRotation>` has **opposite** meaning to removed `<SimpleOpen>` | 1.208 |
| `IMyOxygenGenerator` removed from both PB and Mod API | 1.205 |
| Assembler speed formula changed — productivity multiplier scope changed | 1.205 |
| `AirtightSlideDoor`/`HangarDoor` now place closed (was open) | 1.205 |
| `IMyOxygenTank` PB interface removed | 1.202 |
| `Vector2`/`Vector2D` implicit cast can silently lose precision | 1.202 |
| `MyGridProgram.ElapsedTime` removed — use `Runtime.TimeSinceLastRun` | 1.200 |
| `SpawnGroup.<IsPirate>` removed — use `<FactionTypes>` | 1.205 |
| Character mods need SBC updates for 1.207 survival system | 1.207 |
