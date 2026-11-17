# Fork sync

This fork adds two things to `openai/codex-plugin-cc`:

- the `codex-rescue` forwarder subagent runs on **haiku**;
- `/codex:rescue --danger` runs Codex with sandbox `danger-full-access` (approvals are already `never`).

`sync.sh` runs weekly via launchd (`com.pm.codex-fork-sync`, Mondays 10:00) on each Mac.
It rebases `main` onto `upstream/main` only if there are no conflicts and the tests pass, then pushes and runs `claude plugin update codex@openai-codex`.
On a conflict it changes nothing; check `~/Library/Logs/codex-fork-sync.log`.

Install on a Mac:

```sh
git clone https://github.com/pmmendoza/codex-plugin-cc ~/src/codex-plugin-cc
cd ~/src/codex-plugin-cc && git remote add upstream https://github.com/openai/codex-plugin-cc
sed "s#HOME#$HOME#g" fork-sync/com.pm.codex-fork-sync.plist > ~/Library/LaunchAgents/com.pm.codex-fork-sync.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.pm.codex-fork-sync.plist
```
