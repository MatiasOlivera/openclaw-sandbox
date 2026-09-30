# openclaw-sandbox
A Docker Sandbox for OpenClaw (sbx-based, Open + audit).

## Use
```sh
sbx env plan
sbx env create --auto-approve   # or: sbx env run
sbx env exec -- openclaw --version
./scripts/audit-egress.sh openclaw-sbx
sbx env rm --force              # = openclaw sandbox recreate --all
```

## Controls
- **Network egress (Open + audit):** global `**` allow (`sbx policy allow network '**'`);
  per-sandbox `localhost:11434` allow kept in `lifecycle.postCreate` as
  future-proofing. Narrow later with `sbx policy deny network --sandbox
  openclaw-sbx <host> [--method GET --path '/.../**']` (deny wins).
  Audit via `sbx policy ls --wide`, `sbx policy check network`, `sbx policy log`.
- **Filesystem:** single RW `workspace` (`sandbox-testing/`); env file stays
  outside it and is auto-bound RO. No `additionalWorkspaces`, no clone.
- **Rest:** `sandboxOptions` pins cpus/memory/display/skills/pullPolicy;
  `gpu: false` (host has no passthrough — flip to `true` where nvidia
  runtime exists); `ports` publishes CDP 9222 (loopback; Chromium ships
  via playwright-kit, CDP serves on demand); `lifecycle.postCreate` = OpenClaw
  `setupCommand` (Ollama wiring, idempotent); MCP/secrets attach per-run via
  `--static-mcp` / `secrets:` + `bindings:` when needed.

## OpenClaw parity notes
sbx engine owns cap-drop/read-only-root/init/no-new-privs internally — you
control the same outcomes via policy + template/kit + `sandboxOptions`,
not raw `docker run` flags.
