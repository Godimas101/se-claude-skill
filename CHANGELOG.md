# Changelog

All notable changes to `se-claude-skill` are tracked here.

Major milestone snapshots are also published on the GitHub [Releases](https://github.com/Godimas101/se-claude-skill/releases) page.

---

## [Unreleased]

- Track in-progress work here before the next release.

---

## [v4.0.0] — Plugin refactor _(2026-07-16)_

### Highlights
- Converted the monolithic skill into a **Claude Code plugin** with ten focused skills under `skills/*/`
- Each skill has its own frontmatter with an explicit `SKIP for:` clause so Claude doesn't over-activate
- Added a **SessionStart hook** (`hooks/se-context.sh`) that auto-detects an SE modding workspace (SBC files, ModSDK, Workshop dir, or game log paths) and primes the context
- Each skill's `SKILL.md` is now a compact router (~50 lines) with detail moved into `skills/<name>/references/*.md`
- Retired the 456-line root `SKILL.md`; content redistributed to per-skill references
- Renamed `MOD_CATALOGUE.md` and `MOD_MAKING_NOTES.md` to `.template.md` under `se-core/` to make intent explicit — these are templates the skill copies into user mod projects, not skill content
- Modeled after Epic Games' Unreal Engine skills plugin and the n8n-skills project

### The ten skills
`se-core` (workspace + routing), `se-getting-started` (beginner onboarding), `se-sbc` (SBC/XML content), `se-csharp` (compiled session/game logic), `se-tss` (Text Surface Scripts), `se-pb-scripts` (in-game PB scripts, sandboxed), `se-frameworks` (MES/WeaponCore/Mod Adjuster/etc.), `se-assets` (models/textures/audio), `se-plugins` (Torch + Pulsar), `se-troubleshooting` (logs, errors, patches, DLC).

### Migration notes
- **Manual install path (pre-v4.0) still works** but treats the whole folder as one skill and won't benefit from the SKIP triggers or SessionStart hook. Prefer the `/plugin marketplace add` path from v4.0 onward.
- **Windows users:** SessionStart hook needs Git for Windows (Git Bash) or WSL on PATH. Without it, skills still work — you just have to invoke them manually.

### Outcome
Cleaner discovery, lower default context load, auto-context detection, and clearer skill boundaries. This is the current recommended baseline going forward.

---

## [v3.0.0] — Third major update _(2026-04-01 to 2026-04-03)_

### Highlights
- reorganized the skill into clearer, smaller sections under `sbc/`, `scripting/csharp/`, `scripting/tss/`, and `examples/`
- replaced the old monolithic examples flow with `EXAMPLES_MANIFEST.md` and dedicated worked examples
- cleaned up Local references, MOD_CATALOGUE lookups, workshop ID tables, and framework categories
- extracted supporting files, fixed broken links, trimmed `SKILL.md`, and polished the public repo layout

### Outcome
This is the current recommended baseline for the Space Engineers skill.

---

## [v2.0.0] — Second major overhaul _(2026-03-30)_

### Highlights
- major structural overhaul with new files, cleaner organization, and public-ready cleanup
- added stronger onboarding and troubleshooting coverage for first-run use
- reworked the question flow to route users by mod type: brand new, framework, compiled C#, or PB script
- expanded guidance for SBC rules, script patterns, asset pipeline work, and patch-aware debugging

### Outcome
This release turned the skill from a solid reference into a more guided workflow.

---

## [v1.0.0] — First release _(2026-03-22 to 2026-03-29)_

### Highlights
- first public release of the Space Engineers skill for Claude Code
- shipped core guidance for framework mods, Torch/Pulsar plugins, workshop context, and asset pipeline workflows
- established the README, install steps, and baseline skill coverage for day-to-day SE modding help

### Outcome
This was the first stable public foundation for the skill.
