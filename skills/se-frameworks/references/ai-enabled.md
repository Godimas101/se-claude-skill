# AI Enabled

**Workshop ID:** 2596208372
**Author:** Stollie / jTurp
**Workshop:** [AiEnabled](https://steamcommunity.com/sharedfiles/filedetails?id=2596208372)
**GitHub:** [jturp/AiEnabled](https://github.com/jturp/AiEnabled)

AI Enabled is the standard framework for adding living characters to Space Engineers — human NPCs, robots, animals, and alien creatures. Like MES handles ships, AI Enabled handles characters. The two frameworks are designed to work together and are frequently used in combination.

> **Key distinction from MES:** MES = vehicle/ship encounters. AI Enabled = character/creature encounters. A full NPC faction mod typically uses both: MES to spawn the ship, AI Enabled to populate it with crew.

---

## Dependencies

AI Enabled requires these mods to run:
- **Bot_spawner** (2336089504) — asset/definition layer providing base bot types. Not for direct use; purely a dependency. Provides: Drone_Bot, Boss_Bot, Police_Bot, Target_Dummy, Space_Skeleton, Space_Zombie, Ghost_Bot, RoboDog.
- **Text HUD API** — UI library required by AI Enabled's interface.

> **Important:** AI Enabled disables vanilla spiders and wolves on load to avoid performance conflicts. If you're making a creature mod that uses AI Enabled, expect vanilla creatures to be replaced.

## Finding Installed AI Enabled Mods

Check the user's **MOD_CATALOGUE.md** for all mods with category **AI Enabled** — these are the framework and any character/creature packs they have installed. Use these as local reference examples when building new bot mods.

The AI Enabled framework itself is Workshop ID `2596208372`. Notable well-known AI Enabled mods (may or may not be installed):

| Workshop ID | Mod | Purpose |
|-------------|-----|---------|
| 2596208372 | AI Enabled | The framework itself — required by all child mods |
| 2336089504 | Bot_spawner | **Dependency only** — base bot type definitions, not for direct use |

---

## How AI Enabled Mods Are Structured

AI Enabled bots are defined using a combination of:
- Standard SE `<Bot>` SBC definitions (character behavior, loot, faction)
- Custom character model definitions (character SBC, animation controllers)
- Optional audio SBC (custom sounds for the bot)
- Optional MES integration for spawning (SpawnGroups with `[BotProfiles:]`)

A typical child mod's `Data/` folder:

```
Data/
  MyBots.sbc                     ← Bot definitions (MyObjectBuilder_AnimalBotDefinition)
  MyCharacters.sbc               ← Character model + stats definitions
  AnimationControllers/
    AC_MyBot.sbc                 ← Animation state machine definitions
  Audio_MyBots.sbc               ← Optional custom audio
  Factions_MyBots.sbc            ← Faction definitions for these bots
  SpawnGroups.sbc                ← MES SpawnGroup definitions (if using MES for spawning)
  SpawnConditions.sbc            ← MES SpawnConditions (if using MES for spawning)
```

---

## Bot Definition SBC

The core building block. Defines how a character acts, what it targets, what it drops.

```xml
<Bots>
  <Bot xsi:type="MyObjectBuilder_AnimalBotDefinition">
    <Id>
      <TypeId>MyObjectBuilder_AnimalBot</TypeId>
      <SubtypeId>MyMod_HumanSoldier</SubtypeId>       <!-- Referenced by MES [BotProfiles:] -->
    </Id>
    <DisplayName>Human Soldier</DisplayName>
    <Icon>Textures\GUI\Icons\character.dds</Icon>

    <BotModel>MyMod_SoldierCharacter</BotModel>        <!-- SubtypeId of the Character definition -->

    <!-- Which behavior class governs this bot -->
    <BehaviorType>Wolf</BehaviorType>                  <!-- Wolf = aggressive melee/ranged -->
    <TargetType>Wolf</TargetType>
    <BotBehaviorTree Subtype="WolfBehavior" />         <!-- SE built-in behavior tree -->

    <Public>true</Public>
    <AvailableInSurvival>false</AvailableInSurvival>   <!-- false = only spawnable via AI Enabled/MES -->
    <RemoveAfterDeath>true</RemoveAfterDeath>

    <!-- Loot on death -->
    <InventoryContentGenerated>true</InventoryContentGenerated>
    <InventoryContainerTypeId>
      <TypeId>ContainerTypeDefinition</TypeId>
      <SubtypeId>MyMod_SoldierLoot</SubtypeId>
    </InventoryContainerTypeId>

    <FactionTag>MYFC</FactionTag>                      <!-- Must match a Factions.sbc entry -->

    <!-- Combat properties -->
    <GridDamage>5</GridDamage>
    <TargetGrids>false</TargetGrids>                   <!-- Can they attack ships? -->
  </Bot>
</Bots>
```

**BehaviorType options:**
| Type | Behavior |
|------|----------|
| `Wolf` | Aggressive — attacks players/targets, can use weapons |
| `Spider` | Aggressive + wall-crawling for alien creature types |
| `Ghost` | Passive/neutral — wanders, flees when attacked |
| `Drone` (AI Enabled custom) | Ranged combat, follows patrol routes |

---

## Character Definition SBC

Defines the visual model and physical stats of the bot. Bots need a `Character` SBC entry to set their model, movement speeds, health, and suit stats.

```xml
<Characters>
  <Character xsi:type="MyObjectBuilder_CharacterDefinition">
    <Id>
      <TypeId>MyObjectBuilder_Character</TypeId>
      <SubtypeId>MyMod_SoldierCharacter</SubtypeId>
    </Id>
    <Name>MyMod_SoldierCharacter</Name>
    <Model>Models\Characters\MyMod_Soldier.mwm</Model>

    <MaxHealth>150</MaxHealth>
    <Mass>100</Mass>

    <InitialAnimation>Idle</InitialAnimation>
    <AnimationController>MyMod_AC_Soldier</AnimationController>  <!-- Animation controller SubtypeId -->

    <!-- Movement speeds -->
    <MaxSprintSpeed>12</MaxSprintSpeed>
    <MaxRunSpeed>8</MaxRunSpeed>
    <MaxWalkSpeed>4</MaxWalkSpeed>

    <!-- Inventory -->
    <EnabledComponents>
      <string>Inventory</string>
    </EnabledComponents>
    <InventoryMaxVolume>0.5</InventoryMaxVolume>

    <!-- Not a player character -->
    <IsObstacle>false</IsObstacle>
    <NeedsOxygen>false</NeedsOxygen>
  </Character>
</Characters>
```

---

## MES Integration — Spawning Bots via MES

The most common way to spawn AI Enabled bots in the world is through a MES SpawnGroup. MES handles the "where and when", AI Enabled handles the "what".

**In your MES SpawnGroup `<Description>`:**
```
[Modular Encounters SpawnGroup]

[CreatureSpawn:true]
[AiEnabledReady:true]                              ← Wait for AI Enabled to be loaded

[BotProfiles:MyMod_HumanSoldier]                  ← AI Enabled Bot SubtypeId
[BotProfiles:MyMod_HumanHeavy]                    ← Multiple profiles = random selection

[MinCreatureCount:2]
[MaxCreatureCount:6]
[MinCreatureDistance:30]
[MaxCreatureDistance:80]

[FactionOwner:MYFC]

[PlanetWhitelist:EarthLike,Pertam]                 ← Optional: planet restriction
[UseDayOrNightOnly:true]
[SpawnOnlyAtNight:true]                            ← Optional: time restriction
```

Use `SubtypeId="MES-CreaturePrefabDummy"` as the prefab placeholder — AI Enabled creates the actual character:
```xml
<Prefabs>
  <Prefab SubtypeId="MES-CreaturePrefabDummy">
    <Position><X>0</X><Y>0</Y><Z>0</Z></Position>
    <Speed>25</Speed>
    <Behaviour></Behaviour>
  </Prefab>
</Prefabs>
```

---

## Child Mod Notes

### Crew Enabled (2803081060)
Adds human crew NPCs that can occupy ship seats and man stations. Crew can be assigned to grids via terminal or spawned automatically on player-owned ships. Intended for roleplay/immersion rather than combat.

Key difference from combat bots: crew bots use `BehaviorType:Neutral` or `Crew` and are associated with grid terminals, not wandering/attacking.

### Infestation Enabled (2809500674)
Adds an infestation mechanic — spiders colonize derelict NPC ships and stations from within. They navigate the conveyor system, nest in cargo containers, damage electronics from inside walls, and ramp up in response to gunfire/welding/grinding. A surviving spider can regrow the entire hive.

**Config file path:**
- Dedicated server: `{SE dir}/Saves/{save}/Storage/{mod name}/InfestationEnabledConfig.xml`
- Singleplayer/hosted: `%AppData%\SpaceEngineers\Saves\{playerID}\{save}\Storage\Infestation Enabled_InfestationEnabled\InfestationEnabledConfig.xml`

Key config params: `MaxLiveBugsPerGrid`, infestation spawn probability (default 20% on newly spawned grids). Edit only while the mod is not active; deleting regenerates defaults.

Requires: AiEnabled v1.9 + Small Spiders mod.

---

## Typical Combined MES + AI Enabled Mod Structure

For a mod that spawns humanoid NPC encounters (e.g. a raider faction with crews):

```
MyFactionMod/
  Data/
    Bots/
      MyFaction_Bots.sbc               ← Bot definitions (SubtypeIds)
      MyFaction_Characters.sbc         ← Character model/stats definitions
    AnimationControllers/
      AC_MyFaction_Soldier.sbc
    Factions.sbc                        ← Faction tag + reputation
    SpawnGroups.sbc                     ← MES SpawnGroups (ships + crew creatures)
    SpawnConditions.sbc                 ← MES spawn condition profiles
    Prefabs/
      (NPC-MyFaction) PatrolShip.sbc    ← Blueprint for the spawned ship
    Behavior.sbc                        ← RivalAI behavior for the ship
    Triggers/
      OnDamaged.sbc
    Audio/
      MyFaction_Audio.sbc               ← Optional custom bot audio
  metadata.mod
  thumb.jpg
```

---

## Key Gotchas

1. **`[AiEnabledReady:true]`** in MES SpawnGroups is required — without it MES may try to spawn before AI Enabled initialises, resulting in no bot appearing.
2. **BotModel must exactly match** the `<SubtypeId>` of the `Character` definition — mismatches cause the bot to spawn invisible or with the wrong model.
3. **FactionTag must exist** in a Factions.sbc — AI Enabled bots without a valid faction are neutral to everyone (won't attack or be attacked by default).
4. **Custom models require `.mwm` files** — bot characters need a custom 3D model exported via MwmBuilder. Can reuse vanilla character models as a shortcut by referencing existing Character SubtypeIds (e.g. `Default_Astronaut`).
5. **`AvailableInSurvival:false`** — keep this false for NPC-only bots. Setting it to true makes the bot type selectable by players, which is usually not what you want.
6. **Multiple `[BotProfiles:]` entries** in a SpawnGroup or SpawnConditions profile result in random selection per spawn — useful for varied encounters.

---

## References

### External
- [Workshop Page](https://steamcommunity.com/sharedfiles/filedetails?id=2596208372)
- [GitHub Repository](https://github.com/jturp/AiEnabled)
- Bot_spawner (required dependency) — Workshop ID `2336089504`
- Crew Enabled (child mod example) — Workshop ID `2803081060`
- Infestation Enabled (child mod example) — Workshop ID `2809500674`

### Internal
- [MES.md](MES.md) — encounter spawning framework; MES handles ships, AI Enabled handles crew
- [../sbc/SBC_RULES.md](../sbc/SBC_RULES.md) — SBC override rules for bot and character definitions

### Local

Search the user's `MOD_CATALOGUE.md` for entries in the **AI Enabled** category. Any listed mod is a locally installed AI Enabled child mod and is valid reference material for bot definitions and animation controllers.

**Workshop IDs — check MOD_CATALOGUE for local paths:**
| Workshop ID | Mod Name | Category | Notes |
|-------------|----------|----------|-------|
| 2596208372 | AI Enabled | Framework Mod | Framework source |
| 2336089504 | Bot_spawner | AI Enabled | Required dependency — not for direct use |
| 2803081060 | Crew Enabled | AI Enabled | Child mod example |
| 2809500674 | Infestation Enabled | AI Enabled | Child mod example |
