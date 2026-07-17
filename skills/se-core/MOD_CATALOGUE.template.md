# MOD_CATALOGUE.md — Format & Maintenance

Full spec for building, formatting, and maintaining the workshop mod catalogue.

---

## Format

```markdown
# Space Engineers Workshop Mod Catalogue

**Total mods:** [count]
**Catalogued:** [YYYY-MM-DD]
**Workshop folder:** `[path]`

---

## Notes on Name Resolution
[how names were found — modinfo.sbmi, metadata.mod, SBC class names, folder names, etc.]

**Categories used:**
- **Script** — PB scripts or compiled C# session/LCD mods (no new blocks)
- **Block** — Adds new blocks to the game
- **LCD/HUD** — LCD texture packs or HUD modifications
- **Survival** — Food, farming, survival mechanics
- **Weapons** — Weapons, ammo, turrets
- **Visual** — Decor, cosmetic blocks, paint, animations
- **MES** — Modular Encounters System framework or child/encounter pack mod
- **AI Enabled** — AI Enabled framework or character/creature/crew child mod
- **NPC/AI** — NPC spawns or AI systems that don't use MES or AI Enabled
- **Economy** — Trade, economy, logistics
- **Blueprint** — Ship blueprint (not a gameplay mod)
- **Scenario** — Workshop world save or scenario (not a gameplay mod)
- **WeaponCore** — WeaponCore (CoreSystems) framework source or child weapon mod
- **Vanilla+ Framework** — Vanilla+ Framework source or child mod
- **Animation Engine** — Animation Engine framework source or child mod
- **Scope Framework** — Scope Framework source or child mod
- **Tank Tracks** — Tank Tracks framework source or child mod
- **Mod Adjuster** — Mod Adjuster framework source or patch mod built with Mod Adjuster
- **Other** — Miscellaneous / unclear

---

## Catalogue (sorted by mod name)

| Workshop ID | Mod Name | Category | Notes |
|-------------|----------|----------|-------|
| [id] | [name] | [category] | [notes] |
```

---

## Building or Refreshing the Catalogue

**Before scanning — size check:**
1. Count the subdirectories in the workshop folder (each is a mod).
   - **500 or more mods:** Stop and ask before proceeding:
     > "Your workshop folder contains [n] mods. Building a full catalogue will take a while — want me to proceed, or would you prefer to scan only a specific range?"
   - **Under 500:** Continue automatically.

**Scan cap — 200 mods per session:**
Process a maximum of 200 mod folders per build/refresh run. If there are more:
- Write the catalogue with however many were processed, noting in the header: `**Scanned:** [n] of [total] — run again to continue`
- Tell the user how many remain and offer to continue in the next run

**Per-mod steps:**
1. List all subdirectories in the mod folder (each is a Workshop ID)
2. For each mod folder, find its name by checking in order:
   - `modinfo.sbmi` → `<WorkshopId>` / `<Name>` fields
   - `metadata.mod` → `<Name>` field
   - Any `.sbc` file → block `<DisplayName>` or script class name
   - Folder name as last resort
3. Categorize based on file contents:
   - Has `Scripts/` with `.cs` files → Script or compiled mod
   - Has `CubeBlocks*.sbc` → Block
   - Has `LCDTextures.sbc` → LCD/HUD
   - Has weapon/ammo SBCs → Weapons
   - Folder name / display name contains "Blueprint" → Blueprint
   - Has `Profiles/` subfolder OR any SBC containing `[Modular Encounters SpawnGroup]` → **MES**
   - Has `<Bot xsi:type="MyObjectBuilder_AnimalBotDefinition">` in any SBC OR has `AnimationControllers/` folder → **AI Enabled**
   - Workshop ID `3154371364` → **WeaponCore**
   - Workshop ID `2880317963` → **Animation Engine**
   - Workshop ID `2754014019` → **Scope Framework**
   - Workshop IDs `3208995513`, `3209005014`, `3209008231` → **Tank Tracks**
   - Workshop IDs `2915780227`, `3014670447` → **Vanilla+ Framework**
   - Workshop ID `3017795356` OR has `3017795356` as a dependency in `modinfo.sbmi` OR any SBC file contains `ModAdjust` XML types → **Mod Adjuster**
   - **Unknown / doesn't match any rule above → use "Other"** — never leave Category blank
4. Sort the table alphabetically by Mod Name
5. Update the header count and date
6. **Remind the user:** "Catalogue updated. Next refresh due by [date + 30 days]."

---

## Refresh Schedule

- Minimum: **once per month**
- Also refresh when: user says they added/removed mods, or when the user asks "what mods do I have?"
