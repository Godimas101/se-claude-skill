# Mod catalogue workflow

`MOD_CATALOGUE.md` lives at the root of the user's Workshop mod directory (e.g. `steamapps\workshop\content\244850\MOD_CATALOGUE.md`). It indexes their subscribed mods so Claude can reference them by name.

## Key rules

- **Size check before scanning:** 500+ mods → ask before proceeding. A full scan uses significant context.
- **Scan cap:** 200 mods per session. Note progress in the catalogue header and offer to continue in the next session.
- **Always use "Other" for unrecognized mods** — never leave `Category` blank.
- **Refresh minimum:** once per month, or whenever the user adds/removes mods.

## Format

The living template ships alongside this reference: [`../MOD_CATALOGUE.template.md`](../MOD_CATALOGUE.template.md). Copy it into the Workshop directory when starting a fresh catalogue.

## Category reference (short version)

Each catalogue row has a Category. Use these first; fall back to "Other" only when nothing fits.

- **Framework** — MES, WeaponCore, Mod Adjuster, AI Enabled, Animation Engine, Scope Framework, Tank Tracks, Vanilla+
- **Framework child** — a mod that adds definitions consumed by one of the above frameworks
- **Blocks** — new cube blocks (armor, functional, decoration)
- **Items** — components, physical items, ammo, tools
- **Weapons** — vanilla-based weapon mods (not WeaponCore)
- **Balance** — Mod Adjuster patches, vanilla balance mods
- **QOL** — UI, HUD, hotkeys, quality-of-life
- **Encounters / NPCs** — MES packs, AI Enabled child mods
- **Planets / worlds** — planet generators, world templates
- **Audio / visual** — sounds, textures, particles
- **Scripts** — programmable block scripts (usually pre-loaded via mod)
- **Other** — anything else

## Workshop ID → framework mapping (partial)

Reference these to identify framework mods during a scan:

| Workshop ID | Framework |
|-------------|-----------|
| `3017795356` | Mod Adjuster |
| `1521905890` | MES (Modular Encounters System) |
| `2596208372` | AI Enabled |
| _(check the catalogue for WeaponCore, Animation Engine, Scope Framework, Tank Tracks — IDs vary by version)_ | — |

Full mapping is maintained in the template.
