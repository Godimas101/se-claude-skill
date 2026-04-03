# MOD_MAKING_NOTES.md — Template & Format Guide

Full spec for creating and maintaining the per-workspace session journal.

---

## Purpose

Mod work often spans many sessions with long breaks in between. Claude only has the current conversation in context. Without a persistent record, every new session starts blind — re-explaining decisions already made, re-discovering bugs already solved, losing track of what's done and what isn't.

A `MOD_MAKING_NOTES.md` file in your mod directory solves this. Keep it next to your mods and add it to your VS Code workspace so Claude can read it at the start of every session.

---

## When to Read It

At the start of any mod work session — before making any changes — check if a notes file exists and read it. The session log is the most important part: it tells you what was done last time and what was left unfinished.

## When to Update It

- After completing a significant piece of work, add an entry to the Session Log
- When a decision is made (why X was done instead of Y), write it down under the relevant mod section
- When a bug is found and fixed, record it in the session log and under Known Issues if it's likely to recur
- When a feature is added, update any status tables in that mod's section

---

## Template

```markdown
# Space Engineers - Mod Making Notes

Consolidated notes for all mods in this workspace.

---

## Table of Contents
- [Mod Name](#mod-name)

---

## Mod Name

**Purpose:** What this mod does.
**Status:** In progress / Released / On hold

### Current Goals

- [ ] Thing to do
- [ ] Another thing

### Known Issues

*Add issues here as they are discovered.*

### Design Decisions

*Record any non-obvious choices and why they were made.*

---

## Session Log

### YYYY-MM-DD — Short description
- What was done
- What was discovered
- What was left unfinished → pick up next session from here
```

---

## Format Guidelines

- **Session Log goes at the bottom** — newest entries at the bottom, not the top
- **Dates use ISO format** (YYYY-MM-DD)
- **Keep entries factual** — bugs found, fixes applied, decisions made, things still pending
- **One file covers all mods** in the workspace — separate sections per mod, shared session log
