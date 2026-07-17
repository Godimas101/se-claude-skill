---
name: se-core
description: "Use at the start of any Space Engineers modding session, or when routing between mod types. Verifies workspace is set up correctly (SE game dir, ModSDK, AppData, Workshop), triggers the mod-catalogue check, watches for DLC/patch changes, and routes to the right domain skill (SBC, C#, TSS, PB, frameworks, assets, plugins). Concrete triggers: session start on an SE workspace, 'I want to mod SE', 'what type of mod should I build', an ambiguous SE question that could belong to multiple domains. SKIP for: focused domain work when the mod type is already clear — go straight to se-sbc, se-csharp, se-tss, se-pb-scripts, se-frameworks, se-assets, or se-plugins instead."
---

# SE Core — workspace setup and mod-type routing

Run this before touching any other SE skill on a new session. Confirms the workspace is wired up and steers to the right domain skill.

## Workspace check (do this first)

Read [references/workspace-checks.md](references/workspace-checks.md) and walk through the four paths. For each one that's not mounted in the workspace, tell the user exactly what to add and why. You don't need all four to work — missing dirs just mean less context.

## Mod catalogue

If the Workshop mod directory is mounted, check for `MOD_CATALOGUE.md` at its root:

- **Present and fresh** → read silently.
- **Present but >30 days old** → offer to refresh.
- **Absent** → offer to build one (indexes subscribed mods for reference-by-name).

Format spec, scan rules, and Workshop-ID → framework mappings: [references/catalogue-workflow.md](references/catalogue-workflow.md). The living template is [MOD_CATALOGUE.template.md](MOD_CATALOGUE.template.md); copy it into the Workshop dir when building the first catalogue.

## DLC / patch check

Compare `[SE]\Content\Data\Game\DLCs.sbc` SubtypeIds against [../se-troubleshooting/references/dlc-catalogue.md](../se-troubleshooting/references/dlc-catalogue.md). Flag any new SubtypeIds that aren't in the catalogue — a patch likely shipped new content and warrants research before deeper work.

## Mod type routing

Ask the user via `AskUserQuestion`:

| Option | Route to |
|--------|----------|
| **I'm new to modding** | `se-getting-started` |
| **Working on a mod** | Follow up with type question (below) |
| **Torch or Pulsar plugin** | `se-plugins` |
| **Just ask** | Answer directly; no further setup |

For "Working on a mod", the type question maps:

| Type | Route to |
|------|----------|
| Brand new SBC/XML mod | `se-sbc` (+ `se-assets` if custom 3D/textures) |
| Framework mod | `se-frameworks` |
| Compiled C# — session component / game logic | `se-csharp` |
| Compiled C# — Text Surface Script (LCD) | `se-tss` |
| Programmable Block script | `se-pb-scripts` |

## Mod type table (know which one you're on)

The five mod types differ significantly. See [references/mod-types.md](references/mod-types.md) for the reference table (how each runs, C# access, invocation). Getting this wrong wastes hours — always confirm the type before writing code.

## Session journal

Every mod project should carry a `MOD_MAKING_NOTES.md` — records decisions, bugs fixed, unfinished work. Read at session start, update after significant work. Template: [MOD_MAKING_NOTES.template.md](MOD_MAKING_NOTES.template.md). Rationale: [references/session-journal.md](references/session-journal.md).

## Key paths

Absolute-path reference (`[SE]`, `[ModSDK]`, `[Steam]`, `%AppData%`): [references/key-paths.md](references/key-paths.md).
