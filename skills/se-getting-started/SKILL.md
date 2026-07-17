---
name: se-getting-started
description: "Beginner onboarding for Space Engineers modding. Use when the user says they're new to modding, don't know where to start, don't know what mod type to build, or asks conceptual questions about the mod ecosystem (SBC vs C# vs PB script vs framework mod). Walks through mod-type concepts, required tools, folder structure, and publishing basics. SKIP for: users who already know their mod type — route directly to the domain skill (se-sbc, se-csharp, se-tss, se-pb-scripts, se-frameworks). Also SKIP for advanced questions from an experienced modder."
---

# SE Getting Started — beginner onboarding

For the newcomer who doesn't yet know what kind of mod they want to build.

## What to do

Read [references/onboarding.md](references/onboarding.md) before responding. It's a decision-tree walkthrough covering:

- What mod types exist and what each is for
- Required tools per type (SE install, ModSDK, MDK2, Blender+SEUT, Mod Adjuster subscription, etc.)
- Folder structure of a minimal mod (`Data/` is mandatory)
- Publishing basics (Workshop, modinfo.sbmi, thumbnail requirements)

Do not assume prior knowledge. Walk them through concepts before dropping into any specific domain skill.

## Handoff pattern

Once the user has picked a mod type, hand off explicitly:

- **SBC/XML** → "You'll want `se-sbc` next. It covers block definitions, item definitions, blueprints, and categories."
- **Compiled C# session component / game logic** → "You'll want `se-csharp` next."
- **LCD script** → "You'll want `se-tss` next."
- **In-game PB script** → "You'll want `se-pb-scripts` next — different sandbox rules apply."
- **Framework mod** (MES, WeaponCore, Mod Adjuster, etc.) → "You'll want `se-frameworks` next."
- **3D models / textures** → "You'll want `se-assets` next — pipeline is Blender/SEUT → MWM."

Once handed off, this skill's job is done.
