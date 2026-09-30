# AGENTS.md

## Version control

- Use atomic Conventional Commits; ≤72 chars
- Explain the why in the body whenever a commit needs justification: bug fixes
  (symptom + root cause + why this fix), refactors, renames, sequencing changes.
  2–4 sentences. Omit the how - the diff shows it.
- Use Git flow for branches
- Never commit without explicit approval

## Docs

README.md and docs are for humans; AGENTS.md and skills are for coding agents

## Decisions

Non-trivial choices (stack, protocol, workflow) MUST be recorded as MADR records
in `docs/decisions/` (`NNNN-slug.md`); overturns note "supersedes `NNNN-…`" in
prose. Load the `adr` skill for the template and numbering when available.
