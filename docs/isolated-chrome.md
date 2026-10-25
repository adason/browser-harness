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
3. Telemetry OFF (`~/.config/browser-harness/telemetry.json` → `"disabled": true`).
   Verified 2026-07-21. If it flips back on, run `browser-harness telemetry disable`.
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

## After upgrading the tool (`uv tool upgrade browser-harness`)

`uv tool upgrade` may replace `~/.local/bin/browser-harness` with its own
launcher, silently destroying the wrapper. Check and re-apply if needed:

```bash
head -1 ~/.local/bin/browser-harness   # want: #!/bin/sh (wrapper), NOT a python shebang
```

If replaced: `mv ~/.local/bin/browser-harness ~/.local/bin/browser-harness.uv`
then recreate the wrapper:

```sh
#!/bin/sh
BU_CDP_URL="${BU_CDP_URL:-http://127.0.0.1:9333}"
export BU_CDP_URL
exec "$(dirname "$0")/browser-harness.uv" "$@"
```

Also: skill copy at `~/.agents/skills/browser-harness/` may re-sync from GitHub —
the `REQUIRED: isolated Chrome only` section at the top of `SKILL.md` gets clobbered.
Re-add it (it is self-describing) or diff after `npx skills` updates.

## If teardown is wanted

```bash
browser-harness telemetry enable   # only if user opts back in
rm -rf ~/./.browser-harness-chrome # wipes agent logins/cookies
rm -rf ~/.config/browser-harness   # wipes daemon state, telemetry id
```
