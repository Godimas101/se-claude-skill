---
name: se-troubleshooting
description: "Use when a Space Engineers mod is misbehaving: crashes, missing definitions, mod not loading, patch broke something, DLC content changed. Covers log reading strategy (SpaceEngineers.log — never top-to-bottom, search from the end), error catalog with fixes, patch-notes tracking (breaking changes by patch), and DLC catalogue (SubtypeId → DLC pack). Concrete triggers: 'my mod isn't loading', 'the game crashes when', 'this definition doesn't apply', 'what changed in patch X', 'is this SubtypeId from a DLC'. SKIP for: authoring new content (route to se-sbc / se-csharp / etc.); this skill is exclusively diagnostic."
---

# SE Troubleshooting — logs, errors, patch notes, DLC catalogue

Purely diagnostic. Use when something is broken, not when authoring.

## Log reading — the discipline

Logs are massive (thousands of lines). **Never read top-to-bottom.**

1. Start at the **end** of the most recent `SpaceEngineers_YYYYMMDD_HHMMSSms.log` (not the plain `SpaceEngineers.log` — that's stale).
2. Search upward for these terms in priority order:

| Search term | What it finds |
|-------------|--------------|
| `ERROR` | Hard errors — always investigate |
| `CRITICAL_ERROR` | Fatal errors |
| `EXCEPTION` | .NET exceptions with stack traces |
| `No definition` | Missing SBC definition (wrong TypeId/SubtypeId) |
| `Failed to find definition` | Mod Adjuster patch couldn't find its target |
| `Warning:` | Non-fatal, but may still matter |
| `BuildInfo ModderHelp:` | Build Info mod hints about XML problems |
| `[YourModName]` | Any output from your specific mod |
| `ModAdjuster` | All Mod Adjuster patch results (success + failure) |

3. Key log sections and what "success" vs "failure" looks like are in [references/errors.md](references/errors.md) under "Key log sections".

## Local mod vs Workshop mod in the log

- `Id = Steam:0` → loading from `%AppData%\Roaming\SpaceEngineers\Mods\[ModName]\`
- `Id = Steam:XXXXXXXXX` → loading from `[Steam]\steamapps\workshop\content\244850\XXXXXXXXX\`

## Full error catalog

**[references/errors.md](references/errors.md)** — every common error with causes and fixes. Search this first before diagnosing from scratch.

## Patch notes (breaking changes)

**[references/patch-notes.md](references/patch-notes.md)** — modding-relevant changes by patch. Quick reference for "did this break because of an update?" questions.

## DLC catalogue

**[references/dlc-catalogue.md](references/dlc-catalogue.md)** — full DLC pack listing with SubtypeIds. Also used by `se-core` for the DLC/patch check on session start.

## AppData paths (know where to look)

| Path | Contents |
|------|----------|
| `%AppData%\Roaming\SpaceEngineers\SpaceEngineers_*.log` | Main game log |
| `%AppData%\Roaming\SpaceEngineers\Crashes\` | Crash dumps |
| `%AppData%\Roaming\SpaceEngineers\Saves\` | Save games |
| `%AppData%\Roaming\SpaceEngineers\Mods\` | Locally developed mods (not Workshop) |
| `%AppData%\Roaming\SpaceEngineers\Storage\[modId]\` | Per-mod persistent data written by session components |
