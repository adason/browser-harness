# browser-harness setup — handoff

Security-hardened setup for the `browser-harness` skill (Browser Use, v0.1.13).
Read this before first use or after any upgrade. Full risk audit: telemetry and
cookie-sync findings — key decision: agent's browser runs in an ISOLATED Chrome
instance; the daily browser is never attached.

## Invariants (do not break)

1. `BU_CDP_URL=http://127.0.0.1:9333` — always. The wrapper at
   `~/.local/bin/browser-harness` exports it if unset; the real uv launcher is
   `~/.local/bin/browser-harness.uv`.
2. Dedicated Chrome only: `--user-data-dir=$HOME/.browser-harness-chrome
   --remote-debugging-port=9333`. Own cookie jar, zero overlap with daily Chrome.
3. Telemetry OFF. Two layers: fork code is opt-in by default
   (`telemetry.py` `is_enabled()` returns False unless `telemetry enable` / config
   `"enabled": true` / `BH_TELEMETRY=1`), and this machine also carries a legacy
   `"disabled": true` in `~/.config/browser-harness/telemetry.json`. Verify:
   `browser-harness telemetry status` → `"enabled": false`.
4. Daily Chrome: remote debugging via `chrome://inspect` stays OFF. Never attach to
   9222/9223.
5. Never run: `browser-harness --update` (agent-triggered self-update is disabled
   by policy; user upgrades manually), `curl ... profile.sh | sh`,
   `sync_local_profile(...)`, `start_remote_daemon(...)` / any Browser Use Cloud use
   (cookies uploaded to third party + billing).

## Operations

Start dedicated Chrome (only when port is down):

```bash
curl -s --max-time 2 http://127.0.0.1:9333/json/version || \
  open -na "Google Chrome" --args --user-data-dir="$HOME/.browser-harness-chrome" --remote-debugging-port=9333
```

Use (unchanged from skill docs):

```bash
browser-harness <<'PY'
print(page_info())
PY
```

First attach after Chrome start: daemon may wait up to 30s. If a site needs a
login, user logs in once in the dedicated window (persists in that data dir).

## Verification (run after upgrade or when something is off)

```bash
browser-harness --version                      # expect wrapper passthrough, e.g. 0.1.13
browser-harness telemetry status | grep '"enabled": false'
curl -s --max-time 2 http://127.0.0.1:9333/json/version | head -c 120
```

## Upgrading the tool (fork flow — NOT `uv tool upgrade`)

The installed CLI is this fork, so `uv tool upgrade browser-harness` would
silently replace it with upstream — do not run it. Upgrade path:

```bash
git fetch upstream && git rebase upstream/main   # resolve, then `uv run --with pytest pytest tests/unit -q`
git push origin main
uv tool install --force <repo-path>
mv ~/.local/bin/browser-harness ~/.local/bin/browser-harness.uv
cp bin/browser-harness-wrap.sh ~/.local/bin/browser-harness && chmod +x ~/.local/bin/browser-harness
browser-harness --reload
```

After rebasing, check upstream did not re-land telemetry/cookie defaults you
hardened (telemetry must stay opt-in; verify `bin/browser-harness-wrap.sh`
still matches the launcher name).

Also: skill copy at `~/.agents/skills/browser-harness/` — install/sync it from
this FORK, not the upstream repo, so the `REQUIRED: isolated Chrome only`
section survives re-syncs.

## If teardown is wanted

```bash
browser-harness telemetry enable   # only if user opts back in
rm -rf ~/./.browser-harness-chrome # wipes agent logins/cookies
rm -rf ~/.config/browser-harness   # wipes daemon state, telemetry id
```
