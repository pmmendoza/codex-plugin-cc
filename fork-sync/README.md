# Fork sync

This fork of `openai/codex-plugin-cc` adds:

- the `codex-rescue` forwarder subagent runs on **haiku**;
- `/codex:rescue --danger` runs Codex with sandbox `danger-full-access` (approvals are already `never`). Allowed only with `--model gpt-6.1-terra`+ at `--effort medium|high|xhigh`, or `--model gpt-6-astra`+ at any effort; anything else is refused before Codex starts;
- `/codex:rescue_nobox`: same as `/codex:rescue`, but always adds `--danger` and defaults to `--model gpt-6.1-terra --effort medium`;
- if Claude Code moves the forwarder's Bash call to the background (it does this after ~3 min for background subagents), the forwarder waits for the completion notice and returns the output file verbatim.

`sync.sh` runs weekly via launchd (`com.pm.codex-fork-sync`, Mondays 10:00) on each Mac.
It rebases `main` onto `upstream/main` only if there are no conflicts and the tests pass (run in a clean env), then pushes.
It then updates the plugin and, because `claude plugin update` only reinstalls on a version bump, reinstalls whenever the installed copy differs from `plugins/codex`.
Exit codes: 2 = conflict, 3 = tests failed; both leave the fork untouched. Log: `~/Library/Logs/codex-fork-sync.log`.

Install on a Mac:

```sh
git clone https://github.com/pmmendoza/codex-plugin-cc ~/src/codex-plugin-cc
cd ~/src/codex-plugin-cc && git remote add upstream https://github.com/openai/codex-plugin-cc
claude plugin marketplace remove openai-codex; claude plugin marketplace add pmmendoza/codex-plugin-cc
claude plugin install codex@openai-codex --scope user
sed "s#HOME#$HOME#g" fork-sync/com.pm.codex-fork-sync.plist > ~/Library/LaunchAgents/com.pm.codex-fork-sync.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.pm.codex-fork-sync.plist
```

## Status (2026-11-17)

Installed and verified on the MacBook and the Mac mini (`ssh macmini` → `mac-mini-headless` over Tailscale).
Verified: Haiku forwarder (subagent transcripts), `--danger` allowlist (luna and terra-6.1-low refused), `/codex:rescue_nobox` (ran on gpt-6.1-terra, medium, danger-full-access per `~/.codex-work/sessions`), 3-min background run returned complete, `sync.sh` clean / conflict / failing-test paths (simulated against local bare repos).

Notes for the next agent:

- Plugin Codex threads are logged under `~/.codex-work/sessions`, not `~/.codex`. There is no `~/.codex-work/config.toml`, so an unset model is unknown; that is why `--danger` requires an explicit model.
- After any reinstall, open Claude sessions need `/reload-plugins` before agent/command changes take effect.
- Run tests with `env -i HOME="$HOME" PATH="$PATH" node --test tests/*.test.mjs`; inside a Claude session `CLAUDE_PLUGIN_DATA` leaks in and 4 tests fail spuriously.

Open:

1. Nothing alerts on a failed weekly sync (exit 2/3); check the log occasionally, or add a notification if it becomes a problem.
