# Session journal — MOD_MAKING_NOTES.md

A `MOD_MAKING_NOTES.md` in the mod project's root captures the trail between sessions: decisions, bugs found/fixed, unfinished work. Different from the mod catalogue (which lives in the Workshop dir and indexes external mods).

## When to read

Start of every session before making changes. It's the source-of-truth for "what were we doing last time."

## When to update

- After significant work is done (feature added, bug fixed)
- When a design decision is made that a future reader wouldn't be able to guess from the code
- When leaving something unfinished — note WHAT's unfinished and WHY, so the next session picks up cleanly

## Format

Living template alongside this reference: [`../MOD_MAKING_NOTES.template.md`](../MOD_MAKING_NOTES.template.md). Copy it into the mod project when starting fresh.

## Distinction from git commit messages

- **Commit messages** describe what changed and why-in-that-commit
- **MOD_MAKING_NOTES.md** describes the shape of the project, its constraints, and what's still open

Both are useful; don't collapse one into the other.
