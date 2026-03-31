# Space Engineers DLC Catalogue

Reference for all released DLC packs and the patch detection check.

---

## Patch & DLC Detection — ON SKILL LOAD

Space Engineers receives regular patches. Each major update typically includes:
- New free gameplay content for all players (blocks, mechanics, systems)
- An optional paid cosmetic DLC pack

**Not Just For Looks** and **Not Just For Looks - Without Weapons** are mods that give the paid cosmetic DLC blocks functional stats. Keep this in mind when working with DLC blocks — they can be modded.

### How to check for new content

The authoritative DLC list is at: `[SE]\Content\Data\Game\DLCs.sbc`

**On skill load, do this check:**

1. Read `DLCs.sbc` and extract all `<SubtypeId>` values
2. Compare against the known SubtypeIds listed in this catalogue
3. If any new SubtypeIds are found that aren't in this catalogue:

> **Tell the user:** "I've detected new DLC in your game files that isn't in my catalogue yet: [list new SubtypeIds]. This likely means SE has received a patch since my knowledge was last updated. Would you like me to research the new content so I can give you accurate guidance?"

4. If they say yes: web-search for "Space Engineers [SubtypeId] DLC" and summarize the new blocks and mechanics. Update your working knowledge for the session.
5. If the list matches exactly: no action needed — game content matches catalogue.

**Known SubtypeId list (as of 2026-03-19):**
```
DeluxeEdition, PreorderPack, DecorativeBlocks, Economy, StylePack,
DecorativeBlocks2, Frostbite, SparksOfTheFuture, ScrapRace, Warfare1,
HeavyIndustry, Warfare2, Automatons, DecorativeBlocks3, Anniversary,
Signal, Contact, Fieldwork, ApexSurvival, CoreSystems
```

---

## DLC Pack Reference

All DLC packs follow the same pattern: **free patch content** (new blocks/mechanics for everyone) + **paid cosmetic pack** (decorative blocks, skins, suits — cosmetic only by default).

| SubtypeId | Steam AppId | Display Name | Free Content | Paid Cosmetics |
|-----------|-------------|-------------|--------------|----------------|
| `DeluxeEdition` | 573160 | Deluxe Edition | — | Decorative blocks, 3 suits, bonus sounds and music |
| `PreorderPack` | 999999990 | Pre-order Pack | — | Pre-order exclusive cosmetics |
| `DecorativeBlocks` | 1049790 | Decorative Pack #1 | — | Interior decor: chairs, tables, beds, plants, bar blocks, catwalk variants |
| `Economy` | 1135960 | Economy Expansion | Trade stores, NPC contracts, factions, safe zones | Economy-themed decorative blocks |
| `StylePack` | 1084680 | Style Pack | — | Character suit skins |
| `DecorativeBlocks2` | 1167910 | Decorative Pack #2 | — | More interior decor: office furniture, hospital items, kitchen blocks, window variants |
| `Frostbite` | 1241550 | Frostbite Pack | Frostbite scenario (ice planet), survival mechanics | Polar/industrial themed blocks, snow suit |
| `SparksOfTheFuture` | 1307680 | Sparks of the Future | Sci-fi scenario, new emotes | Sci-fi styled LCD panels, interior lights, new thrusters skins |
| `ScrapRace` | 1374610 | Scrap Race Pack | Wheels rework, racing scenario | Wheel variants, outdoor furniture, racing suit |
| `Warfare1` | 1475830 | Warfare Evolution | Battle Cannon and Blast Door rework, new weapons | Warfare-themed blocks, military suit |
| `HeavyIndustry` | 1676100 | Heavy Industry Pack | Conveyor improvements, new industrial blocks (free tier) | Large industrial decor blocks, heavy suit |
| `Warfare2` | 1783760 | Passage (Warfare 2) | Passage scenario, new turrets and weapons | Sci-fi military blocks, assault suit |
| `Automatons` | 1958640 | Automatons | AI drone blocks, automated ship systems, new AI grid management | Drone-themed decor, automaton suit |
| `DecorativeBlocks3` | 2504720 | Decorative Pack #3 | — | More decor variants, new LCD displays, signs, panels |
| `Anniversary` | 2569770 | 10th Anniversary Pack | — | Anniversary cosmetics, suit |
| `Signal` | 2914120 | Signal Pack | Antenna/communication improvements, LCD scripting additions | Signal-themed blocks, new LCD surfaces, communication decor |
| `Contact` | 3066290 | Contact Pack | Alien encounter scenario, new alien blocks | Alien-themed decorative blocks, contact suit |
| `Fieldwork` | 3601770 | Fieldwork Pack | Planetary exploration improvements | Outdoor/field equipment blocks, fieldwork suit |
| `ApexSurvival` | 3858380 | Apex Survival Pack | Survival rework (Apex update), new survival mechanics and blocks (free tier) | Survival-themed cosmetic blocks, apex suit |
| `CoreSystems` | 4116960 | Core Systems Pack | Core game systems improvements | Core-themed blocks, systems suit |

---

## Notes for Modders

### Referencing DLC blocks in SBC
Blocks gated to a DLC use `<DLCId>SubtypeId</DLCId>` in their `CubeBlock` definition. To reference a DLC block as a requirement or component, use its SubtypeId.

### Not Just For Looks pattern
The NJFL mods override the `<Components>`, `<BuildTimeSeconds>`, and stats of cosmetic DLC blocks using Mod Adjuster patches — giving them functional equivalents without duplicating the block. If a user wants to make DLC blocks functional, this is the established pattern to follow.

### DLC blocks in InfoLCD / other display mods
If a mod references DLC block TypeIds, it should handle the case where the player doesn't own the DLC (block won't exist in their game). Use null checks on any block list that might contain DLC-gated blocks.
