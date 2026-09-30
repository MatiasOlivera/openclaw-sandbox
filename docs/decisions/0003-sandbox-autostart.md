# Auto-start the sandbox gateway on host boot via a systemd user unit

- Status: accepted
- Deciders: matias
- Date: 2026-09-30

## Context and Problem Statement

After a host reboot the `openclaw-sbx` sandbox is `stopped`, so the host
OpenClaw client (`gateway.mode: remote`, `ws://127.0.0.1:18789/`) cannot
connect — the gateway only exists inside the sandbox. The sandbox must come
back without manual steps while staying the declared `sbxenv.yaml`
environment.

## Decision Drivers

- Gateway stays in the sandbox (isolation, egress audit per `0001-…`/`0002-…`).
- Reboot must not require manual recall of the restore command.
- Maintenance budget is one person; no new daemons or schedulers to own.
- The pinned `18789:18789` mapping keeps the Control UI origin stable.

## Considered Options

| Option       | Outcome                                                              | Cost                                        |
| ------------ | -------------------------------------------------------------------- | ------------------------------------------- |
| systemd user unit | Won: native autostart on login/boot, supervises the foreground gateway, `sbx exec` auto-starts a stopped sandbox | One unit file; host path baked in           |
| cron @reboot | Lost: fires once, no supervision/restart when the gateway later dies | Same one-liner, less resilience, no logs    |
| Manual command | Lost: `sbx env run -d` already restores the sandbox, but every reboot needs a human | Zero files, recurring friction              |

## Decision Outcome

Chosen option: **systemd user unit**, because it is the only option that both
restores the sandbox after boot and restarts a dead gateway.

Rules: the repo copy lives at `systemd/openclaw-sbx.service`; install with
`cp systemd/openclaw-sbx.service ~/.config/systemd/user/` then
`systemctl --user enable --now openclaw-sbx` (plus
`loginctl enable-linger $USER` for boot without login). `ExecStartPre`
idempotently ensures `sandboxd` is up (`sbx daemon start`); `ExecStart` runs
`sbx exec openclaw-sbx -- openclaw gateway run` foreground under
`Restart=always` — `sbx exec` auto-starts a stopped sandbox, so no agent
re-attach happens on gateway restarts.

### Positive Consequences

- Reboot-safe: sandbox starts, gateway listens on `18789`, host client reconnects.
- Gateway crashes get restarted with backoff; logs via `journalctl --user -u openclaw-sbx`.
- Sandbox stays the single declared environment; no host gateway install.

### Negative Consequences

- Unit bakes in the checkout path (`%h/Documents/Projects/openclaw-sandbox`);
  adjust `WorkingDirectory` if the repo moves.
- Needs user lingering enabled, otherwise start waits for first login.
- If the sandbox is ever removed (`sbx env rm`), first start recreates and
  re-runs `postCreate` provisioning (Ollama wiring) before the gateway is up.
