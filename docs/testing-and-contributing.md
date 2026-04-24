# Testing and Contributing

## Running Tests

From the repository root:

```powershell
lua reaform/tests/runner.lua
```

The runner loads:

- `reaform.tests.test_contracts`
- `reaform.tests.test_behavior`

It prints one line per suite and exits non-zero if a suite crashes.

## What The Current Tests Cover

### Contract Coverage

`reaform/tests/test_contracts.lua` checks:

- `MusicalObject` creation and required field validation
- `RuleSet` validation failure on incomplete definitions
- warning behavior for unknown `RuleSet` fields
- `Constraint.evaluate`
- `Transformation.apply`

### Behavior Coverage

`reaform/tests/test_behavior.lua` checks:

- serialism generation and evaluation through shared APIs
- neo-Riemannian transformation execution through shared APIs
- counterpoint generation and evaluation through shared APIs
- custom ruleset pluggability without engine modification

These tests are intentionally small, but they enforce the current architectural claim that the engine can host multiple domains without being rewritten around one of them.

## Contribution Expectations

- Preserve the ruleset-driven architecture.
- Keep shared modules generic.
- Do not move counterpoint-specific assumptions into `reaform/core/`, `reaform/engine/`, or `reaform/utils/`.
- When adding a ruleset, prefer proving compatibility through the shared APIs instead of adding special-case engine branches.
- When expanding contracts, document the difference between current implementation and lockfile target state.

## Naming Guidance

- Use `ReaForm` in project-facing documentation and new code.
- Avoid counterpoint-specific generic names in shared layers.
- Keep domain terms scoped to the ruleset that owns them.

## Suggested Contributor Workflow

1. Read the root `README.md`.
2. Read [Architecture](architecture.md) for the current code shape.
3. Read [Status Against Lockfile](status-against-lockfile.md) before implementing lockfile-driven work.
4. Update or add tests when changing shared contracts or engine flow.
5. Keep documentation aligned with actual file names and current behavior.
