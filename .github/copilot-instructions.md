# ReaForm Copilot Instructions

## Mandatory Repo-Edit Tracking Rule

When an AI agent makes any repository edit (code, docs, tests, config, or tooling), it must update both tracking files in the same change set:

- `DEVELOPMENT_PLAN.md`
- `DEVELOPMENT_LOG.md`

Minimum required updates:

1. `DEVELOPMENT_PLAN.md`: reflect plan/status impact (new task, progress checkbox, risk, or next-step delta).
2. `DEVELOPMENT_LOG.md`: append a timestamped entry listing files changed, summary, validation run (or `not run`), and next step.

Pull requests or commits that change repository files without corresponding updates to both tracking files are considered incomplete.
