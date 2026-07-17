---
name: se-sbc
description: "Use for Space Engineers SBC/XML modding: block definitions, item definitions, categories, variant groups, blueprints, production tabs, progression/research locks, LCD registration, localization, loot tables, prefabs, DefinitionBase fields, TypeId/SubtypeId, override behavior, load order. Concrete triggers: editing .sbc files, adding a new block or item, patching balance values, defining a category or variant group, questions about DefinitionBase or MyObjectBuilder_*. SKIP for: C# runtime code (use se-csharp), TSS/LCD screen code (use se-tss), PB in-game scripts (use se-pb-scripts), Mod Adjuster XML specifically (use se-frameworks), 3D models or textures (use se-assets)."
---

# SE SBC — XML content mods

SBC (SandBoxContent) is Space Engineers' XML content format. Every non-code mod ultimately writes SBC files.

## Read first

**[references/rules.md](references/rules.md)** — universal SBC rules: override vs additive behavior, load order (mods load bottom-to-top, top of list wins on same Type+Subtype), cross-mod references, DefinitionBase fields. **Read this before writing any SBC.**

## By subject area

| I'm working on… | Read |
|---|---|
| Block or item definitions, categories, variant groups, component lists | [references/blocks.md](references/blocks.md) |
| Blueprints, production tabs (BlueprintClass), research/progression locks | [references/production.md](references/production.md) |
| LCD registration, localization, loot tables, prefabs, finding definition IDs | [references/misc.md](references/misc.md) |
| Worked examples end-to-end | [references/examples-index.md](references/examples-index.md), then [example-armor-block.md](references/example-armor-block.md) |
| Wiki deep-dives on any of the above | [references/wiki-index.md](references/wiki-index.md) |

## Mod folder shape

```
MyMod/
├── Data/                     ← REQUIRED — game fails to load the mod without it
│   ├── CubeBlocks/*.sbc
│   ├── TextSurfaceScripts.sbc  (if registering LCD scripts)
│   └── Scripts/MyMod/*.cs      (if it's a compiled mod)
├── modinfo.sbmi              ← auto-generated on first Workshop publish
└── thumb.png                 ← optional; Steam <1MB, mod.io required min 512x288
```

`Data/` is mandatory even for collection mods with no content — never rename it.

## Shipping checklist

- [ ] `modinfo.sbmi` present with correct `WorkshopId` (auto-generated on first publish; recreate manually if missing)
- [ ] No TypeId/SubtypeId renamed or removed (breaks existing saves)
- [ ] Only modified fields included in patches (don't copy entire definitions)
- [ ] `xsi:type` values use correct prefix (`MyObjectBuilder_` for vanilla SBC; stripped for Mod Adjuster)
- [ ] New block SubtypeIds are globally unique
- [ ] Tested in Creative mode before publishing

## Known gotchas

- **Item type collisions** — always key inventory items on composite `$"{typeId}_{subtypeId}"`.
- **SBC load order** — mods load bottom-to-top in the in-game list. Top of list wins on same Type+Subtype. Use Mod Adjuster (see `se-frameworks`) for non-destructive patches.
- **Backward compatibility** — never rename CustomData keys; add new ones, keep old ones.
- **`.sbm` files in mod folders** — old ZIP-based packaging; safe to delete. **BUT** `.sbm` files under `Storage/` are runtime data — do NOT delete those.
