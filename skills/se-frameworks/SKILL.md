---
name: se-frameworks
description: "Use for Space Engineers mods that build on top of a framework: MES (Modular Encounters System), AI Enabled, WeaponCore, Mod Adjuster, Animation Engine, Scope Framework, Tank Tracks, Vanilla+ Framework. Concrete triggers: writing a Mod Adjuster XML patch, defining an MES spawn group / prefab, adding a WeaponCore weapon, authoring an AI Enabled bot, integrating with Animation Engine / Scope Framework / Tank Tracks / Vanilla+. SKIP for: vanilla SBC content with no framework dependency (use se-sbc), general C# session components not integrating with a framework (use se-csharp), asset creation (use se-assets)."
---

# SE Frameworks — building on top of MES, WeaponCore, Mod Adjuster, and friends

Each framework has its own conventions, SBC extensions, and load-order requirements. Load only the reference for the framework in play.

## Pick the framework

| Framework | Purpose | Reference |
|-----------|---------|-----------|
| **Mod Adjuster** | Non-destructive balance patches against any mod or vanilla; runs as a session component that applies XML patches | [references/mod-adjuster.md](references/mod-adjuster.md) |
| **MES** — Modular Encounters System | NPC ship/vehicle encounter spawns | [references/mes.md](references/mes.md) |
| **AI Enabled** | NPC characters, creatures, crew | [references/ai-enabled.md](references/ai-enabled.md) |
| **WeaponCore** | Custom weapons with WC-specific SBC | [references/weaponcore.md](references/weaponcore.md) |
| **Animation Engine** | Custom block animations, triggers, subparts | [references/animation-engine.md](references/animation-engine.md) |
| **Scope Framework** | Weapon scope / iron-sights for handheld weapons | [references/scope-framework.md](references/scope-framework.md) |
| **Tank Tracks** | Tracked vehicle movement | [references/tank-tracks.md](references/tank-tracks.md) |
| **Vanilla+ Framework** | Advanced projectile / turret behaviors on vanilla weapons (server-side); Workshop listing is unlisted | [references/vanilla-plus.md](references/vanilla-plus.md) |

## Cross-cutting notes

- **Framework Workshop IDs live in the mod catalogue** ([../se-core/MOD_CATALOGUE.template.md](../se-core/MOD_CATALOGUE.template.md)). If the user's Workshop dir is mounted, reference by ID.
- **Load order matters.** Framework mods usually have a required load position relative to their child mods; each reference doc calls this out.
- **Child mod pattern.** Most of these frameworks have a "child mod" convention — a small mod that adds definitions the framework consumes. `references/*.md` covers the child-mod structure per framework.
- **Mod Adjuster xsi:type** — Mod Adjuster patches use the **stripped** type name (no `MyObjectBuilder_` prefix), unlike vanilla SBC. Easy trap.
