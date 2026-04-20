# @loudweb/paperclip

A fork of [paperclipai/paperclip](https://github.com/paperclipai/paperclip) tuned for developers running Paperclip on the **Claude Max plan**.

Upstream Paperclip is excellent, and this fork is not a replacement — it's a handful of opinionated patches and a dashboard plugin that make the Max 5x and Max 20x subscriptions more practical to use as a build substrate for multi-agent development.

If you pay per-token on the Anthropic API, vanilla upstream is probably what you want. If you're running Paperclip on a Claude Max subscription where the binding constraint is the weekly Sonnet cap and the 5-hour rolling window, this fork may help.

---

## What this fork changes

Four additions, each small and independent:

1. **Per-step cost tagging on `costEvents`**
   Adds `stepTag` and `taskKind` columns so you can answer "how much did categorization cost this week?" instead of only "how much did agent X cost this week?". The rest of the fork measures itself against this.

2. **Smart model routing for `claude_local`**
   Implements the adapter-local cheap-preflight pattern described in `doc/plans/2026-04-06-smart-model-routing.md`. On fresh heartbeats, Haiku runs a bounded preflight (read wake context, post first status comment), then hands off to the primary model (Sonnet or Opus) for the real work. Segmented cost reporting via the tagging patch above. Typical saving on lead "read and react" heartbeats: 40–60%.

3. **Quota-aware model downgrader**
   A cron-driven service that watches weekly Sonnet consumption from `costEvents`. When it crosses a configurable threshold, it atomically downgrades any lead agent whose `adapterConfig.model` matches `sonnet*` to `haiku*`, posts a comment to the company's Board inbox, and reverses the swap at the next weekly reset. Turns "downgrade leads when the cap trends hot" from a standing order into enforced behavior.

4. **Opus gating**
   Agents default to `opusAllowed: false`. Any agent without the flag cannot have an Opus model set on its `adapterConfig.model`. Prevents accidental Opus escalation on specialist agents and lets you deliberately grant Opus access to the CEO/CTO only.

Plus one plugin:

5. **`@loudweb/paperclip-control-room`**
   A unified dashboard plugin that combines four tiles in one nav screen: quota status (5-hour and weekly windows), cost-by-step (uses the tagging patch), org health (active agents, last heartbeats), and pipeline state (work in flight). One tab in the morning, not four.

---

## Why these specific changes

Running Paperclip on Max changes the economics.

On pay-per-token, every optimization translates to dollars. On Max, dollars are fixed and the real constraint is **messages per 5-hour rolling window** and **separate weekly Sonnet caps**. A heartbeat that uses Sonnet for work Haiku could handle isn't a budget line — it's a slot you can't use later in the week. By Thursday afternoon, that slot might have been the difference between merging and not merging.

The four patches above each target one source of unnecessary Sonnet spend:

- Patch 1 makes the waste visible so you can measure whether patches 2-4 are working
- Patch 2 uses Haiku for orchestration work that doesn't need Sonnet's intelligence
- Patch 3 enforces the "downgrade when trending hot" rule you'd otherwise have to apply manually
- Patch 4 prevents an agent configured as Sonnet from quietly becoming an Opus agent via a well-meaning config edit

None of these are about making Claude smarter or cheaper. They're about making Max usable as an engineering substrate for real projects, not just experimentation.

---

## Relationship to upstream

Tracks [`paperclipai/paperclip`](https://github.com/paperclipai/paperclip) main. Weekly rebase. The patches are carried locally because they're opinionated defaults for a specific audience (Max users), not generic features upstream maintainers would necessarily want merged in this shape.

Original Paperclip README is preserved at [`README-UPSTREAM.md`](./README-UPSTREAM.md). For questions about Paperclip itself — architecture, plugins, governance, adapter protocol — read that and the [upstream docs](https://paperclip.ing/docs). This README covers only what the fork changes.

If an upstream maintainer wants any of these patches, they're welcome to cherry-pick — the commits are structured one-patch-per-branch for that purpose.

---

## Status

Actively used. No release cadence yet; tagged commits at meaningful milestones. The first public tag is `v0.0.0-loudweb-baseline` (clean fork, no patches applied), and every subsequent patch gets its own tag for bisection.

If you're reading this and considering using the fork yourself, know that:

- It's a personal platform first, a community contribution second
- Bug reports and PRs are welcome but responses may be slow
- Breaking changes to the fork's patches are possible if upstream moves faster than expected
- The upstream Paperclip project is the canonical source of truth; when in doubt, defer to it

---

## Installation

Clone the fork and follow the upstream quickstart — installation is identical:

```bash
git clone https://github.com/loudweb/paperclip.git
cd paperclip
pnpm install
pnpm build
pnpm dev
```

To track upstream yourself:

```bash
git remote add upstream https://github.com/paperclipai/paperclip.git
git fetch upstream
```

For migrating an existing Paperclip instance to this fork, see [`docs/MIGRATING_FROM_UPSTREAM.md`](./docs/MIGRATING_FROM_UPSTREAM.md) (coming soon — currently no schema-breaking changes on the fork, so a simple swap of the repo works).

---

## Roadmap

Short version, in order:

- [x] Fork baseline (`v0.0.0-loudweb-baseline`)
- [x] Patch 1 — per-step cost tagging (`v0.0.1-loudweb-step-cost-tagging`)
- [ ] `@loudweb/paperclip-control-room` plugin (MVP with quota + cost tiles)
- [ ] Patch 2 — smart model routing for `claude_local`
- [ ] Patch 3 — quota-aware model downgrader
- [ ] Patch 4 — Opus gating
- [ ] Control Room plugin (org health + pipeline tiles)
- [ ] Thin + thick company templates

Each patch ships as its own branch, with its own tests, and its own bisection tag.

No support matrix for other adapters yet. The smart-routing patch is `claude_local`-only by design; if you want it for `codex_local` or others, file an issue and we'll see.

---

## License

MIT, same as upstream. See [`LICENSE`](./LICENSE).
