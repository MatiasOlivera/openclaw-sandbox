# Build the sandbox on Docker Sandboxes (sbx) instead of raw Docker

- Status: accepted
- Deciders: matias
- Date: 2026-09-30

## Context and Problem Statement

We need a Docker sandbox that reproduces everything OpenClaw's Docker backend
does, while keeping explicit control of network egress, filesystem and device
access. The substrate choice determines how much isolation machinery we own
versus inherit.

## Decision Drivers

- Egress control must be per-host and auditable, not just on/off per network.
- Filesystem, resource and device controls must be declarative and reviewable
  in one file.
- Maintenance budget is one person; bespoke Docker plumbing must stay minimal.

## Considered Options

| Option       | Outcome                                                           | Cost                                  |
| ------------ | ----------------------------------------------------------------- | ------------------------------------- |
| sbx-based    | Won: proxy egress rules, declarative env file, owned by Docker    | Must accept engine-owned isolation    |
| Raw Docker   | Lost: exact flag parity but hand-rolled egress proxy and auditing | Ongoing custom plumbing to maintain   |
| Both with parity | Lost: two substrates to keep in agreement                    | Double build, test and drift surface  |

## Decision Outcome

Chosen option: **sbx-based**, because per-host allow/deny with method/path
rules plus a declarative environment file covers the stated controls with the
least owned machinery.

Rules: the sandbox is declared in `sbxenv.yaml`; raw `docker run` flags are
not used; gaps where sbx abstracts isolation (cap-drop, read-only root) are
documented, not reimplemented.

### Positive Consequences

- Egress, mounts, resources and lifecycle live in one reviewable file.
- Audit trail comes free via policy log and check commands.

### Negative Consequences

- No direct control of container flags; dependent on the sbx engine for
  cap-drop, read-only root and init posture.
