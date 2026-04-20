#!/usr/bin/env bash
# Weekly rebase of the loudweb/paperclip fork against upstream paperclipai/paperclip.
#
# Happy path: run this on Monday, review the summary, force-push master.
# Conflict path: the script aborts into a conflict-resolution state. Resolve,
# `git rebase --continue`, then re-run this script starting from the `verify` step.
#
# Usage:
#   ./scripts/rebase-upstream.sh              # full rebase + verify
#   ./scripts/rebase-upstream.sh verify       # skip the rebase, just run tests
#   ./scripts/rebase-upstream.sh --dry-run    # show what would change, no mutations

set -euo pipefail

UPSTREAM_REMOTE="upstream"
UPSTREAM_BRANCH="master"
LOCAL_BRANCH="master"

bold()  { printf "\033[1m%s\033[0m\n" "$1"; }
red()   { printf "\033[31m%s\033[0m\n" "$1"; }
green() { printf "\033[32m%s\033[0m\n" "$1"; }
yellow(){ printf "\033[33m%s\033[0m\n" "$1"; }
blue()  { printf "\033[34m%s\033[0m\n" "$1"; }
die()   { red "ERROR: $1"; exit 1; }

MODE="full"
case "${1:-}" in
  ""|"full")    MODE="full" ;;
  "verify")     MODE="verify" ;;
  "--dry-run")  MODE="dry-run" ;;
  "-h"|"--help")
    echo "Usage: $0 [full|verify|--dry-run]"
    exit 0 ;;
  *) die "unknown argument: $1" ;;
esac

bold "==> Preflight checks"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not a git repo"

current_branch=$(git rev-parse --abbrev-ref HEAD)
if [[ "$current_branch" != "$LOCAL_BRANCH" ]]; then
  die "must be on $LOCAL_BRANCH (currently on: $current_branch)"
fi

if ! git remote | grep -qx "$UPSTREAM_REMOTE"; then
  die "remote '$UPSTREAM_REMOTE' not configured. Run:
    git remote add $UPSTREAM_REMOTE https://github.com/paperclipai/paperclip.git"
fi

if [[ -n "$(git status --porcelain)" ]]; then
  git status --short
  die "working tree is dirty — commit, stash, or discard changes first"
fi

if [[ -d .git/rebase-merge || -d .git/rebase-apply ]]; then
  die "a rebase is already in progress. Run 'git rebase --abort' or --continue first"
fi

green "  ✓ on $LOCAL_BRANCH, clean working tree"

if [[ "$MODE" != "verify" ]]; then
  bold "==> Fetching $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"
  git fetch --tags "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"

  old_tip=$(git rev-parse HEAD)
  new_tip=$(git rev-parse "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")

  if [[ "$old_tip" == "$new_tip" ]]; then
    green "  ✓ already at upstream tip ($new_tip). Nothing to rebase."
    exit 0
  fi

  ahead=$(git rev-list --count "HEAD..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")
  behind=$(git rev-list --count "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH..HEAD")

  echo ""
  blue "  upstream is ahead by $ahead commit(s)"
  blue "  you have $behind commit(s) upstream doesn't"
  echo ""

  bold "==> Incoming upstream commits"
  git log --oneline --no-decorate "HEAD..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" | head -30
  incoming_count=$(git rev-list --count "HEAD..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")
  if (( incoming_count > 30 )); then
    yellow "  ... (showing 30 of $incoming_count)"
  fi

  echo ""
  bold "==> Diff stat (upstream vs local)"
  git diff --stat "HEAD..$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" | tail -20

  if [[ "$MODE" == "dry-run" ]]; then
    echo ""
    yellow "==> --dry-run: stopping here. No changes made."
    exit 0
  fi
fi

if [[ "$MODE" == "full" ]]; then
  echo ""
  bold "==> Rebasing $LOCAL_BRANCH onto $UPSTREAM_REMOTE/$UPSTREAM_BRANCH"

  if ! git rebase "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"; then
    echo ""
    red "==> Rebase stopped with conflicts."
    yellow "    Resolve, then: git add <files> && git rebase --continue"
    yellow "    Or bail out:    git rebase --abort"
    yellow ""
    yellow "    After finishing: ./scripts/rebase-upstream.sh verify"
    exit 2
  fi

  green "  ✓ rebase clean"
fi

bold "==> Verifying post-rebase build"

echo ""
blue "  → pnpm install"
pnpm install --prefer-offline

echo ""
blue "  → pnpm -r typecheck"
if ! pnpm -r typecheck; then
  red "  ✗ typecheck failed"
  exit 3
fi

echo ""
blue "  → pnpm -r test"
if ! pnpm -r test; then
  red "  ✗ tests failed"
  exit 3
fi

echo ""
bold "==> Rebase complete"
green "  ✓ typecheck + tests passed"
echo ""
yellow "  Force-push required (rebase rewrote history):"
echo "    git push --force-with-lease origin $LOCAL_BRANCH"