# SBC Rules & Foundations — Space Engineers

Core rules, structural patterns, and field references that apply across all SBC modding. Load this first for any SBC work.

> For block/item templates, category definitions, and the block type reference: see [SBC_BLOCKS.md](SBC_BLOCKS.md).
> For blueprints, production tabs, and progression locks: see [SBC_PRODUCTION.md](SBC_PRODUCTION.md).
> For LCD registration, localization, loot, and prefabs: see [SBC_MISC.md](SBC_MISC.md).

---

## Universal SBC Rules

These apply to ALL `.sbc` files without exception:

- **File extension must be lowercase** — `.sbc` only. `.SBC` or `.Sbc` will not load.
- **Never edit vanilla game files.** Copy the target vanilla SBC into your mod's `Data/` folder, strip what you don't need, and edit your copy.
- **All `.sbc` files in `Data/` and all subfolders are loaded automatically.** File naming is irrelevant — only the XML content matters.
- **TypeId cannot be invented.** You can only use TypeIds that exist in the game engine. SubtypeId can be anything.
- **`MyObjectBuilder_` prefix is optional** in most places — the game accepts `CubeBlock` and `MyObjectBuilder_CubeBlock` interchangeably.
- **Wiki default values come from game code, not vanilla SBC files.** Vanilla SBCs may not declare a field even when it equals the default.
- **Binary cache files (`.sbcB5` / `.sbsB5`)** store pre-parsed versions of SBCs. If you change an SBC that has a cache, delete the cache or the change won't apply.

### Override vs Additive Behavior

| Behavior | Definition Types |
|----------|-----------------|
| **Override** — last-loaded mod wins, same Type+Subtype | Most definitions (CubeBlocks, BlockVariantGroups, etc.) |
| **Additive** — new entries appended to existing | BlockCategories (by `<Name>`), BlueprintClassEntries, MaterialProperties, AnimationController |
| **Merged** | Environment Definition |
| **No Override** | Decal, EmissiveColor, EmissiveColorStatePreset |

### Mod Load Order

Mods load **bottom-to-top** in the in-game mod list. The mod **highest in the list** is loaded last and wins any definition conflicts. To override another mod's definition, your mod must be higher in the list than theirs.

### Definitions That Cannot Be Modded

| File | Issue |
|------|-------|
| `RadialMenu.sbc` | Not moddable — Keen ticket #47915 |
| `GuiTextures.sbc` | Mod textures silently fail |
| `ControllerSchemes.sbc` | New entries don't appear in GUI |
| `WheelModels.sbc` | Code using it is disabled |
| `DLCs.sbc` | No modding support |
| `AssetModifiers.sbc` | Broken support |

---

## Cross-Mod Asset References

You can reference models, textures, icons, and sounds from **another Workshop mod** without copying their files — using the `..\\` path syntax.

### How It Works

Workshop mods all live in the same parent folder:
```
[Steam]\steamapps\workshop\content\244850\
  12345678\     ← mod with Workshop ID 12345678
  99887766\     ← your mod with Workshop ID 99887766
```

The `..\\` prefix navigates up one level from your mod's root to the `244850\` folder, then into the target mod by its ID:

```xml
<!-- Standard path (your own mod's assets) -->
<Icon>Textures\GUI\Icons\MyBlock.dds</Icon>
<Model>Models\Cubes\Large\MyBlock.mwm</Model>

<!-- Cross-mod reference (assets owned by Workshop mod 12345678) -->
<Icon>..\\12345678\\Textures\\GUI\\Icons\\FancyBlock.dds</Icon>
<Model>..\\12345678\\Models\\Cubes\\Large\\FancyBlock.mwm</Model>
```

Use `\\` (double backslash) — standard SE XML path separator.

Works for: `<Icon>`, `<Model>`, `<BuildProgressModel>`, `<LOD>` entries, `<ColorMetalTexture>` and other material paths, and audio `<File>` references in AudioDefinition SBCs. Confirmed to work for LOD model paths too.

### Local Testing Without Uploading

Cross-mod paths resolve relative to the **folder the mod lives in**. Workshop mods live in `244850\`. Local mods live in `%AppData%\SpaceEngineers\Mods\`.

To test locally, mirror the Workshop folder structure:

1. Copy the target mod's folder to `%AppData%\SpaceEngineers\Mods\`
2. Rename the copied folder to the Workshop ID (e.g., `12345678`)
3. Your local mod's `..\\12345678\\...` paths now resolve correctly

### Permissions and Restrictions

- Referencing assets = no copy, no permission needed
- Copying asset files into your mod = **requires express permission** from the original author
- Script (`.cs`) files cannot be referenced or patched — no method exists short of full permission
- If you use any DLC asset, you must add `<DLC>DLCName</DLC>` to your block definition

### Workshop Dependencies vs Load Order

Do **not** use the formal Workshop "Required Items" dependency system if you also need to override a definition from the target mod. The dependency is forced to load before your mod, which is usually correct for override purposes — but the system has known quirks. The safe approach:
- For **definition overrides**: link the original mod in your description, ask users to place it lower in their mod list
- For **asset references only**: load order doesn't matter; either approach works

---

## File Header

Required on all SBC files:

```xml
<?xml version="1.0" encoding="utf-8"?>
<Definitions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <!-- content here -->
</Definitions>
```

---

## DefinitionBase — Shared Fields

Every SBC definition type inherits these fields. They work the same everywhere.

| Field | Type | Required | Default | Notes |
|-------|------|----------|---------|-------|
| `<Id>` | | Yes | | Composite identifier — TypeId + SubtypeId |
| `<Id><TypeId>` or `Type=` attr | string | Yes | | Use element OR attribute, never both |
| `<Id><SubtypeId>` or `Subtype=` attr | string | No | `""` | Use element OR attribute, never both |
| `<DisplayName>` | string | Conditional | null | Required if object appears in menus. See format rules below. |
| `<Description>` | string | No | null | Shown in tooltips. Supports localization keys and `{0}` bind placeholders. |
| `<DescriptionArgs>` | string | No | null | Comma-separated control IDs for `{0}`, `{1}` substitution in Description |
| `<Icon>` | string | No | null | Path to `.dds` or `.png`. Declare multiple times to stack icons. |
| `<DLC>` | string | No | null | Required DLC SubtypeId(s). Declare multiple times for multiple requirements. |
| `<AvailableInSurvival>` | bool | No | `true` | Controls accessibility in survival mode |
| `<Public>` | bool | No | `true` | Controls menu visibility. Block is still buildable via blueprints/projectors when false. |
| `Enabled` (attribute) | bool | No | `true` | Set `<Definition Enabled="false">` to remove a definition after loading |

### DisplayName / Description Format Rules

- **Contains `DisplayName_`** → game looks it up in `.resx` localization files (localized string)
- **Contains `Description_`** → same localization lookup
- **Plain text** → displayed as-is, not localized
- **`{0}`, `{1}` in Description** → replaced by player's current keybind for the control IDs in `<DescriptionArgs>`
- **`{` or `}` in blueprint DisplayName** → must be escaped as `{{` and `}}` or the game throws a FormatException (bug #43912)
- **For mod-provided localized strings:** use `{LOC:DisplayName_MyKey}` syntax with a `Data/Localization/MyTexts.resx` file

### Id Shorthand vs Element Form

```xml
<!-- Element form -->
<Id>
  <TypeId>CubeBlock</TypeId>
  <SubtypeId>MyBlock</SubtypeId>
</Id>

<!-- Attribute shorthand — equivalent, preferred for compact definitions -->
<Id Type="CubeBlock" Subtype="MyBlock" />
```

---

## SBC Definition Chains

How the main game systems link together. Knowing the chain helps you find what file to copy and modify.

| System | Chain |
|--------|-------|
| Blocks | `CubeBlock → Components → BlueprintClassEntries → BlockCategories → BlockVariantGroups` |
| Weapons | `CubeBlock → WeaponDefinition → AmmoMagazine → Ammo` |
| Production | `CubeBlock → BlueprintClass → BlueprintClassEntries → Blueprints` |
| Hand tools | `HandItems → PhysicalItems → AnimationControllers → Blueprints` |
| Loot | `ContainerTypes → ContainerType node in prefab` |

---

## Files That Cannot Be Modded

Attempting to override these causes crashes or silent failures:

| File | Status |
|------|--------|
| `RadialMenu.sbc` | **Not moddable** — Keen confirmed in support ticket #47915. Overriding it crashes the game. |
| `GuiTextures.sbc` | Broken — mod textures silently fail |
| `ControllerSchemes.sbc` | Singleplayer only; new selections don't appear in GUI |
| `WheelModels.sbc` | Code that uses it is disabled |
| `Game/DLCs.sbc` | Informational only |
| `Screens/*.gsc` | Only loads from game folder with exact filenames |

---

## References

### External
- [spaceengineers.wiki.gg/wiki/Modding/Reference/SBC](https://spaceengineers.wiki.gg/wiki/Modding/Reference/SBC) — official SBC modding reference
- [spaceengineers.wiki.gg/wiki/Modding](https://spaceengineers.wiki.gg/wiki/Modding) — general modding overview

### Internal
- [SBC_BLOCKS.md](SBC_BLOCKS.md) — block/item templates, categories, variant groups, block type reference
- [SBC_PRODUCTION.md](SBC_PRODUCTION.md) — blueprints, production tabs, progression/research locks
- [SBC_MISC.md](SBC_MISC.md) — LCD registration, localization, loot tables, prefabs, finding definition IDs

### Local
- Vanilla SBC files: `[Steam]\steamapps\common\SpaceEngineers\Content\Data\`
