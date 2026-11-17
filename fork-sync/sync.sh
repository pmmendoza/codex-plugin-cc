#!/bin/bash
# Weekly: rebase this fork onto upstream (only if clean + tests pass), push, then refresh the installed plugin.
# Safe on several machines at once: the rebase is idempotent and the push uses --force-with-lease.
set -uo pipefail
export PATH=/opt/homebrew/bin:/opt/local/bin:$HOME/.local/bin:/usr/bin:/bin:$PATH
cd "$(dirname "$0")/.." || exit 1
log() { echo "$(date '+%F %T') $*"; }

git checkout -q main && git pull -q --rebase origin main || { log "pull of origin/main failed"; exit 1; }
git fetch -q upstream main || { log "fetch upstream failed"; exit 1; }

if git merge-base --is-ancestor upstream/main HEAD; then
  log "already on top of upstream/main"
else
  before=$(git rev-parse HEAD)
  if ! git rebase -q upstream/main; then
    git rebase --abort; log "CONFLICT rebasing onto upstream; left fork untouched"; exit 2
  fi
  if ! env -i HOME="$HOME" PATH="$PATH" node --test tests/*.test.mjs >/tmp/codex-fork-sync-tests.log 2>&1; then
    git reset -q --hard "$before"; log "tests failed after rebase (see /tmp/codex-fork-sync-tests.log); left fork untouched"; exit 3
  fi
  git push -q --force-with-lease="main:$before" origin main && log "rebased + pushed" || { log "push failed"; exit 1; }
fi

claude plugin marketplace update openai-codex && claude plugin update codex@openai-codex && log "plugin refreshed"
