# AGENTS.md — se-claude-skill

Space Engineers modding skill for Claude Code. Backup + distribution copy of the SE-specific skill Chris uses when working on SE mods. When invoked, teaches Claude the SE modding conventions, SBC formats, common pitfalls, and points at the SDK + workshop directories.

## What this is

Space Engineers modding skill for Claude Code. Backup + distribution copy of the SE-specific skill Chris uses when working on SE mods. When invoked, teaches Claude the SE modding conventions, SBC formats, common pitfalls, and points at the SDK + workshop directories.

## Where work lives (RULE — non-negotiable)

**Every task on this repo is a ticket on the [Personal Projects board](https://github.com/users/Godimas101/projects/2).** YOU (the agent) create the ticket BEFORE touching anything. No exceptions for "small" work.

Concrete rules — same as everywhere:

- **Starting work?** Open a ticket, add to the board, set Status = **In Progress**, then start.
- **Have an idea for later?** Ticket in **Backlog**. Not in memory, not in a README, not in NOTES.md.
- **Need Chris to check something before closing?** Move to **In QA** and comment what he needs to look at. Do NOT set to Done — that's Chris's call after review.
- **Finished + verified yourself?** Close the ticket with a closing summary (what you did / problems + solutions / anything NOT done).
- **Same-session micro-work?** Open + close in the same session — but the ticket exists.
- **Older than 30 days in Done?** The weekly cron moves it to Archived. The closed ticket persists.

Ticket body shape: see memory `[[feedback-ticket-body-shape]]` — What/Why → Acceptance → Related → Notes. Priority defaults to P2, Kind defaults to Feature.

## How to verify (before flagging In QA or closing)

- If editing the skill's SKILL.md: test by invoking the skill in a fresh Claude Code session on an SE mod repo. Does Claude follow the new guidance?
- Cross-check with the mod repo AGENTS.md files — the skill and the AGENTS.md should agree, not conflict.
- If adding new modding patterns: also update the corresponding mod repo's AGENTS.md if the pattern is repo-specific.

## Publishing + feedback flow

This skill repo is wired into the [TCS Discord bot](https://github.com/The-Canadian-Space/tcs-forum-watcher) with tag `SE Claude Skill` under the `tools` category. Full flow: [`discord/release-and-feedback-flow`](https://docs.thecanadian.space/discord/release-and-feedback-flow/) (wiki, Cloudflare-Access-gated).

- Issues labelled `bug` or `suggestion` → `🐛-tool-feedback` thread (auto). Other labels don't mirror.
- GitHub releases → persistent thread in `📦-tool-updates`. **Public.**
- **Releases are user-driven.** Do NOT run `gh release create` autonomously. If the skill has meaningfully improved (new SE modding patterns, corrected knowledge, added workflows), **ask** — describe the release notes and let Chris decide.

**Downstream context**: this skill is loaded into SE-mod-work Claude sessions running in `mods/**` under `gitpush-mod`. Those mod repos each have their own `AGENTS.md` with a matching Publishing + feedback flow section. If you change how releases or feedback flow in a way that affects mod work, update both the skill (SKILL.md) AND the mod repos' AGENTS.md in the same pass — or the two will drift.

## MUST NOT

- Add game-specific fabrications — every SBC field, TypeId, or component name should be verified against the real vanilla SBCs.
- Contradict the mod repo AGENTS.md files without a strong reason (the skill is generalist; per-repo rules override).

## Related

- Used by: any repo under [`gitpush-mod`](https://github.com/gitpush-mod) with SE mods
- Bundled by: [`space-engineers-modders-tool-kit`](https://github.com/Godimas101/space-engineers-modders-tool-kit)

---

*Part of Chris's `Godimas101` personal repos. Companion guide: `personal-docs/git-infrastructure.md` (private companion repo) covers the full infrastructure.*