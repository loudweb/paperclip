# Weekly upstream rebase

This fork tracks [`paperclipai/paperclip`](https://github.com/paperclipai/paperclip) `master`. Upstream is in rapid development (a few hundred commits per week), so we rebase weekly to stay current without getting buried in conflicts.

## Cadence

Monday morning, or whenever you notice upstream has moved significantly. The script is idempotent — running it when already up-to-date is a no-op.

## Prerequisites (one-time)

Make sure the `upstream` remote is configured: