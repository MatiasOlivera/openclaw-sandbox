# Default to open egress with audit instead of deny-by-default

- Status: accepted
- Deciders: matias
- Date: 2026-09-30

## Context and Problem Statement

The sandbox must reach the host Ollama instance, package registries and AI
provider APIs during normal work, while every destination stays restrictable
and every connection stays inspectable.

## Decision Drivers

- Local-first workflow: host Ollama and public registries must work without
  per-host allowlisting friction.
- Any destination must be deniable after the fact, with deny winning over
  allow.
- All egress decisions must leave an auditable trail.

## Considered Options

| Option       | Outcome                                                              | Cost                                        |
| ------------ | -------------------------------------------------------------------- | ------------------------------------------- |
| Open + audit | Won: zero-friction egress, deny rules and policy log cover control   | Weaker default than deny-all; relies on audit discipline |
| Balanced     | Lost: preset allowlist covers common hosts but still blocks host-local endpoints until allowed | Per-host exceptions anyway, less simplicity |
| Locked down  | Lost: strongest default but every new host needs an explicit rule    | Friction incompatible with exploratory use  |

## Decision Outcome

Chosen option: **Open + audit**, because the workload is exploratory and
local-first, and per-sandbox deny rules plus the policy log provide the
required control without allowlist friction.

Rules: global `**` allow; narrowing happens only via per-sandbox deny rules;
`scripts/audit-egress.sh` is the canonical audit command.

### Positive Consequences

- New hosts (registries, providers, host Ollama) work immediately.
- Restrictions are explicit, sandbox-scoped denies that override the default.

### Negative Consequences

- A malicious or compromised agent has egress until a deny rule exists;
  mitigation is audit discipline plus deny rules for known-bad destinations.
- If the posture ever needs to harden, migration to Balanced means
  allowlisting everything currently implicit.
