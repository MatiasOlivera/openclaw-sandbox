# Bound the gateway autostart restart policy so logged-out state cannot storm the keyring

- Status: accepted
- Deciders: Matias Olivera
- Date: 2026-10-10

## Context and Problem Statement

The `openclaw-sbx.service` autostart unit (`Restart=always`, `RestartSec=5`)
looped ~500 times while logged out of Docker: every cycle ran
`sbx daemon start` (Secret Service activation) plus a failing `sbx exec`
(`401 / not signed in`). Each activation coincided with a
`gnome-keyring-daemon 50.0` ABRT, leaving the login keyring locked and
popping "login keyring did not get unlocked" during the session. This record
supersedes `0003-sandbox-autostart` on restart policy only; autostart itself
stands.

## Decision Drivers

- A persistent, non-transient failure (missing `sbx login`) must fail fast,
  never retry every few seconds against the Secret Service / keyring.
- Transient gateway crashes should still be supervised after boot.
- Maintenance budget is one person; no new daemons, watchers, or wrappers.
- Auth state lives outside the unit; the unit cannot fix it by retrying.

## Considered Options

| Option       | Outcome                | Cost                    |
| ------------ | ---------------------- | ----------------------- |
| `Restart=on-failure` + `RestartSec=60` + `StartLimitBurst=3/5min` | Won: transient crashes still restart; persistent auth failure stops after 3 tries, no secret storm | Two-line unit change + README note |
| `ExecCondition` auth pre-check | Lost: the check itself would query the secret store, adding the same activations it tries to prevent | New wrapper command to own and debug |
| Remove autostart entirely | Lost: returns the reboot friction `0003-…` was accepted to fix | Deletes working feature for a policy bug |
| Keep `Restart=always/5s` | Lost: proven 500-restart storm crashing `gnome-keyring 50.0` (upstream LP #2162595 / #2161749 pattern) | Zero files, recurring keyring lockups |

## Decision Outcome

Chosen option: **`Restart=on-failure` + backoff + burst limit**, because it
keeps supervision for real crashes while making the logged-out state stop
after 3 attempts instead of looping forever.

Rules: repo copy at `systemd/openclaw-sbx.service` is authoritative; after
`sbx login`, reinstall with `cp systemd/openclaw-sbx.service
~/.config/systemd/user/` + `systemctl --user daemon-reload` + `enable --now`.
Host stays disabled until login is restored.

### Positive Consequences

- Logged-out gateway fails 3× max per 5 min, then stays dead; keyring gets no storm.
- Genuine gateway crashes still restart (60s backoff, visible in unit logs).
- Re-enable path is one documented command after `sbx login`.

### Negative Consequences

- After 3 rapid transient crashes the unit also stops until manual start;
  mitigate with `systemctl --user start` + unit logs (acceptable: signals a
  real problem, not auth).
- Burst tuning (3/5min, 60s) is a guess; adjust if legitimate crash recovery
  ever needs more attempts.
