# Modular Encounters System (MES)

**Workshop ID:** 1521905890
**Author:** Meridius_IX / Lucas
**Workshop:** [Modular Encounters Systems](https://steamcommunity.com/sharedfiles/filedetails?id=1521905890)
**GitHub:** [MeridiusIX/Modular-Encounters-Systems](https://github.com/MeridiusIX/Modular-Encounters-Systems)

MES is the standard framework for adding custom NPC ships, drones, stations, and creature encounters to Space Engineers. It acts as a shell — the mod itself handles all the spawning logic, AI routing, faction management, and encounter lifecycle. Modders build on top of it by creating SBC profile files that MES reads at runtime.

> **On load, MES automatically disables** vanilla cargo ship spawning, random encounter spawning, and creature spawners (wolves/spiders) — replacing them with its own systems. If your server runs MES, vanilla encounters are off.

> **Key insight:** MES does NOT use custom SBC types. All configuration is passed through the standard SE `<Description>` field as `[Key:Value]` tag blocks. MES scans these fields at startup and builds its internal profile database from them.

**Integration APIs available:** MES exposes hooks for CoreSystems, Defense Shields, AiEnabled, Water Mod, and Nebula Mod. Third-party mods can register callbacks for spawn events.

**Documentation:** A full GitHub Wiki is linked from the Workshop page (ID: 1521905890). It documents every `[Key:Value]` tag for every profile type.

---

## Finding Installed MES Mods

Check the user's **MOD_CATALOGUE.md** for all mods with category **MES** — these are the MES framework and any encounter packs they have installed. Use these as local reference examples when building new encounters.

The MES framework itself is Workshop ID `1521905890`. Notable well-known MES mods (may or may not be installed):

| Workshop ID | Mod | Purpose |
|-------------|-----|---------|
| 1521905890 | Modular Encounters System | The framework itself — required by all child mods |
| 1400364273 | NPC Programming Extender | Plugin: expands trigger/action options |
| 2999925713 | Ares at War | Mega-mod: full NPC faction ecosystem |

---

## How MES Mods Are Structured

A typical MES child mod's `Data/` folder contains:

```
Data/
  SpawnGroups.sbc          ← What to spawn, where, and when
  Behavior.sbc             ← How the NPC acts (AI behavior tree + trigger list)
  Factions.sbc             ← NPC faction tags and reputation
  Prefabs/                 ← Blueprint SBC files for the actual ships/stations
  Triggers/                ← Individual trigger + action definitions
  Replenish/               ← Optional: ammo/item replenishment profiles
  SpawnConditions/         ← Optional: standalone spawn condition profiles
  Loot/                    ← Optional: loot table profiles
  Autopilot/               ← Optional: custom autopilot profiles
```

---

## The [Key:Value] Tag System

Every MES profile is defined inside an SBC `<Description>` field. The first line declares the profile type. Subsequent lines are configuration tags.

**All profile definitions use this SBC wrapper:**
```xml
<EntityComponent xsi:type="MyObjectBuilder_InventoryComponentDefinition">
  <Id>
    <TypeId>Inventory</TypeId>
    <SubtypeId>YourMod-ProfileType-UniqueName</SubtypeId>
  </Id>
  <Description>

    [Profile Type Header]

    [Key:Value]
    [Key:Value]

  </Description>
</EntityComponent>
```

Profiles are referenced from other profiles by their SubtypeId. The convention is `ModName-ProfileType-DescriptiveName` (e.g. `RobotRaiderPods-Trigger-ArriveAtDrop`).

---

## Profile Types Reference

### SpawnGroup — What to Spawn

SpawnGroups use vanilla SE `<SpawnGroupDefinition>` SBC type, not `EntityComponent`. The `<Description>` field carries all MES config.

```xml
<SpawnGroup>
  <Id>
    <TypeId>SpawnGroupDefinition</TypeId>
    <SubtypeId>YourMod-SpawnGroup-MyShip</SubtypeId>
  </Id>
  <Description>

    [Modular Encounters SpawnGroup]

    [DroneEncounter:true]             <!-- Spawns as flying drone/ship -->
    [FactionOwner:SPRT]               <!-- NPC faction tag -->
    [ReplenishSystems:true]           <!-- Refill ammo and power at spawn -->

    [MinimumPlayerTime:600]           <!-- Seconds player must be online before spawning -->
    [MaximumPlayerTime:3600]          <!-- Max player time cap -->
    [DroneEncounterChance:10]         <!-- % chance per spawn attempt -->

    [MinDroneDistance:500]            <!-- Min distance from player to spawn -->
    [MaxDroneDistance:5000]           <!-- Max distance -->
    [MinDroneAltitude:1000]           <!-- Min altitude (planetary) -->
    [MaxDroneAltitude:2000]           <!-- Max altitude -->

    [UseRivalAi:true]                 <!-- Enable RivalAI behavior system -->
    [RivalAiReplaceRemoteControl:true] <!-- Replace remote control with RivalAI -->

    [UseThreatLevelCheck:true]        <!-- Only spawn if player threat is below cap -->
    [ThreatScoreMaximum:1000]

    [UseBlockReplacerProfile:true]    <!-- Swap block types at spawn (e.g. NPC thrusters) -->
    [BlockReplacerProfileNames:MES-NpcThrusters-Hydro]

    [CreatureSpawn:true]              <!-- Spawn AI creatures (not ships) via AI Enabled -->
    [BotProfiles:MyBotSubtypeId]      <!-- AI Enabled bot type to spawn -->
    [MinCreatureCount:1]
    [MaxCreatureCount:5]

    [SpawnConditionsProfiles:YourMod-Conditions-MyCondition]  <!-- Reference SpawnConditions profile -->

    [AdminSpawnOnly:true]             <!-- Only spawns via admin commands -->

  </Description>
  <IsPirate>true</IsPirate>
  <Frequency>5.0</Frequency>
  <Prefabs>
    <Prefab SubtypeId="YourPrefabSubtypeId">
      <Position><X>0</X><Y>0</Y><Z>0</Z></Position>
      <Speed>25</Speed>
      <Behaviour>YourMod-Behavior-MyBehavior</Behaviour>  <!-- Behavior SubtypeId -->
    </Prefab>
  </Prefabs>
</SpawnGroup>
```

**For creature spawns** (AI Enabled integration), use `SubtypeId="MES-CreaturePrefabDummy"` as a placeholder prefab — AI Enabled handles the actual creature creation.

---

### Behavior — How the NPC Acts

Defines the top-level behavior state machine. References an autopilot profile and a list of triggers.

```xml
<EntityComponent xsi:type="MyObjectBuilder_InventoryComponentDefinition">
  <Id>
    <TypeId>Inventory</TypeId>
    <SubtypeId>YourMod-Behavior-Fighter</SubtypeId>
  </Id>
  <Description>

    [RivalAI Behavior]

    [BehaviorName:Fighter]            <!-- Base behavior class: Fighter, Horsefly, Passive, Strike, etc. -->

    [AutopilotData:YourMod-Autopilot-Fighter]   <!-- Reference to Autopilot profile -->

    [Triggers:YourMod-Trigger-OnDamage]         <!-- List of active trigger profiles -->
    [Triggers:YourMod-Trigger-OnRetreat]
    [Triggers:YourMod-Trigger-OnIdle]

  </Description>
</EntityComponent>
```

**Built-in BehaviorName values:** `Fighter`, `Horsefly`, `Passive`, `Strike`, `CargoShip`, `HorseflyNoTarget`

---

### Autopilot — Movement and Navigation

Controls how the NPC moves: speed, altitude, waypoint behavior, evasion.

```xml
<EntityComponent xsi:type="MyObjectBuilder_InventoryComponentDefinition">
  <Id>
    <TypeId>Inventory</TypeId>
    <SubtypeId>YourMod-Autopilot-MyShip</SubtypeId>
  </Id>
  <Description>

    [RivalAI Autopilot]

    [IdealMinSpeed:20]
    [IdealMaxSpeed:80]
    [MaxSpeedTolerance:5]

    [IdealPlanetAltitude:1500]          <!-- Target altitude when flying on a planet -->
    [MinimumPlanetAltitude:800]
    [FlyLevelWithGravity:true]

    [OffsetPlanetMinDistFromTarget:100]  <!-- Circling distance around target -->
    [OffsetPlanetMaxDistFromTarget:250]

    [SlowDownOnWaypointApproach:true]
    [WaypointTolerance:20]
    [WaypointWaitTimeTrigger:120]

    [UseVelocityCollisionEvasion:true]
    [LimitRotationSpeed:true]

  </Description>
</EntityComponent>
```

---

### Trigger — When to Do Something

Triggers fire based on conditions (damage taken, time elapsed, behavior state change, etc.) and execute an Action.

```xml
<EntityComponent xsi:type="MyObjectBuilder_InventoryComponentDefinition">
  <Id>
    <TypeId>Inventory</TypeId>
    <SubtypeId>YourMod-Trigger-OnDamaged</SubtypeId>
  </Id>
  <Description>

    [RivalAI Trigger]

    [UseTrigger:true]
    [Type:Damage]                     <!-- Trigger type: Damage, Timer, BehaviorTriggerA/B/C, etc. -->

    [MinCooldownMs:5000]
    [MaxCooldownMs:10000]
    [StartsReady:false]

    [MaxActions:3]                    <!-- How many times this trigger can fire total -->
    [Actions:YourMod-Action-CallReinforcements]

  </Description>
</EntityComponent>
```

**Common Trigger Types:** `Damage`, `Timer`, `BehaviorTriggerA`, `BehaviorTriggerB`, `BehaviorTriggerC`, `PlayerNear`, `PlayerFar`, `TargetDestroyed`, `GridDestroyed`

---

### Action — What to Do When Triggered

Actions are what execute when a trigger fires. They can change behavior, spawn new entities, send chat messages, enable/disable triggers, and more.

```xml
<EntityComponent xsi:type="MyObjectBuilder_InventoryComponentDefinition">
  <Id>
    <TypeId>Inventory</TypeId>
    <SubtypeId>YourMod-Action-CallReinforcements</SubtypeId>
  </Id>
  <Description>

    [RivalAI Action]

    [ChangeAutopilotSpeed:true]
    [NewAutopilotSpeed:120]

    [ChangeBehaviorSubclass:true]
    [NewBehaviorSubclass:Aggressive]

    [BroadcastChatMessage:true]
    [BroadcastChatMessageText:Calling for backup!]
    [BroadcastChatAuthor:NPC Commander]

    [EnableTriggers:true]
    [EnableTriggerNames:YourMod-Trigger-Retreat]

    [TriggerTimerBlocks:true]
    [TimerBlockNames:Timer Block - Alert]

    [SpawnEncounter:true]
    [EncounterSpawnGroupSubtypeId:YourMod-SpawnGroup-Reinforcements]

  </Description>
</EntityComponent>
```

---

### SpawnConditions — Fine-Grained Spawn Filtering

Referenced from a SpawnGroup with `[SpawnConditionsProfiles:SubtypeId]`. Controls planet, time-of-day, biome, threat level, and other conditions.

```xml
<EntityComponent xsi:type="MyObjectBuilder_InventoryComponentDefinition">
  <Id>
    <TypeId>Inventory</TypeId>
    <SubtypeId>YourMod-Conditions-PlanetOnly</SubtypeId>
  </Id>
  <Description>

    [MES Spawn Conditions]

    [CreatureSpawn:true]
    [PlanetWhitelist:EarthLike,Pertam,Alien]   <!-- Only spawn on these planets -->
    [MinAirDensity:0.5]                         <!-- Require breathable atmosphere -->

    [UseDayOrNightOnly:true]
    [SpawnOnlyAtNight:true]

    [FactionOwner:SPRT]

    [BotProfiles:MyCreatureSubtypeId]           <!-- AI Enabled creature type (if creature spawn) -->
    [MinCreatureCount:3]
    [MaxCreatureCount:8]
    [MinCreatureDistance:30]
    [MaxCreatureDistance:80]

  </Description>
</EntityComponent>
```

---

## Typical Child Mod Folder Structure

```
MyMod/
  Data/
    SpawnGroups.sbc                  ← One or more SpawnGroup definitions
    Behavior.sbc                     ← One or more Behavior + Autopilot definitions
    Factions.sbc                     ← Faction definitions (tags, reputation)
    Prefabs/
      (NPC-MyMod) MyShip.sbc         ← Blueprint prefab (export from SE, save as SBC)
    Triggers/
      OnDamaged.sbc                  ← Trigger + Action pairs
      OnRetreat.sbc
    SpawnConditions/
      PlanetConditions.sbc           ← Optional standalone conditions
    Replenish/
      IceReplenish.sbc               ← Optional: replenishment profile
  metadata.mod
  thumb.jpg
```

---

## MES + AI Enabled Integration

MES handles the **ship/vehicle** side; AI Enabled handles the **character/creature** side. They connect via:

- `[CreatureSpawn:true]` in SpawnGroup — tells MES to delegate creature creation to AI Enabled
- `[AiEnabledReady:true]` in SpawnGroup — gate spawn until AI Enabled is loaded
- `[BotProfiles:SubtypeId]` in SpawnGroup or SpawnConditions — references an AI Enabled bot character SubtypeId

See [AI_ENABLED.md](AI_ENABLED.md) for the bot character definition format.

---

## Key Gotchas

1. **SubtypeId naming conventions matter** — use a consistent prefix (your mod name) on every profile to avoid collisions with other mods: `MyMod-SpawnGroup-MyShip`, `MyMod-Behavior-Fighter`, etc.
2. **Prefabs must be exported as SBC blueprints** — build the ship in SE, export via blueprint screen, then reference the SubtypeId in `<Prefab SubtypeId="...">`.
3. **`[FactionOwner:TAG]`** must reference a real faction tag defined in Factions.sbc or an existing SE faction (e.g. `SPRT` = Space Pirates, `RAIDER` = Raiders). Wrong faction = ship is neutral and won't be attacked.
4. **RivalAI vs vanilla AI** — `[UseRivalAi:true]` enables the full behavior tree system. Without it, ships use basic vanilla drone AI (much less capable).
5. **Block replacer profiles** — NPC ships use special low-value thruster/armor variants so players don't exploit them for components. Reference `MES-NpcThrusters-Hydro`, `MES-NpcThrusters-Ion`, etc. from the MES mod itself.
6. **`[AdminSpawnOnly:true]`** — invaluable for testing. Your spawn group only appears via admin commands, not during normal play.

---

## References

### External
- [Workshop Page](https://steamcommunity.com/sharedfiles/filedetails?id=1521905890)
- [GitHub Repository](https://github.com/MeridiusIX/Modular-Encounters-Systems) — full wiki and `[Key:Value]` tag reference for every profile type
- Ares at War (large MES example mod) — Workshop ID `2999925713`

### Internal
- [AI_ENABLED.md](AI_ENABLED.md) — character/creature framework; MES handles ships, AI Enabled handles crew
- [../sbc/SBC_MISC.md](../sbc/SBC_MISC.md) — prefab SBC format (used for NPC ship blueprints)
- [../sbc/SBC_RULES.md](../sbc/SBC_RULES.md) — SBC load order and override rules

### Local

Search the user's `MOD_CATALOGUE.md` for entries in the **MES** category. Any listed mod is a locally installed MES child or encounter pack and is valid reference material for spawn group structure and encounter design.

**Workshop IDs — check MOD_CATALOGUE for local paths:**
| Workshop ID | Mod Name | Category | Notes |
|-------------|----------|----------|-------|
| 1521905890 | Modular Encounters Systems | Framework Mod | Framework source |
| 2999925713 | Ares at War | MES | Large example mod |
