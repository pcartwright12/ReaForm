# Persistence Migration Notes

This document defines the current migration story for persisted ReaForm data. It is intentionally modest: the repository has version fields and persistence helpers today, but it does not yet implement automated migration functions.

The goal of these notes is to keep future persistence work coherent and to make the current behavior explicit.

## Current Version Fields

The repository currently persists three top-level version markers:

- project snapshots use `schema_version`
- persisted rulesets use `serialization_version`
- persisted profiles use `version`

Related domain objects also carry `version` fields inside normalized schemas, but those are object/profile/ruleset model fields rather than import-dispatch fields.

Current defaults in code:

- project snapshots default to `schema_version = 1`
- rulesets default to `serialization_version = 1`
- rulesets also default to `version = 1`
- profiles default to `version = 1`

## Current Runtime Behavior

Today the repository does not perform version branching or automated migrations during load/import.

Current behavior:

- `Persistence.save_project(...)` writes project snapshots with `schema_version = 1`
- `Persistence.load_project(...)` decodes JSON but does not validate snapshot versions
- `Persistence.import_project_state(...)` accepts snapshots without checking `schema_version`
- `Persistence.save_ruleset(...)` writes whatever `serialization_version` the normalized ruleset declares
- `Persistence.save_profile(...)` writes whatever `version` the normalized profile declares
- persisted-only imported rulesets and transforms remain metadata artifacts with explicit non-executable state when live hooks are unavailable

This means version fields are preserved, but they are not yet used to reject, migrate, or branch import logic.

## Policy For Future Migration Work

When migration logic is added, it should follow these rules:

1. Project snapshot migration is keyed by `schema_version`.
2. Persisted ruleset-state migration is keyed by `serialization_version`.
3. Profile-state migration is keyed by `version` unless a distinct serialization field is introduced later.
4. Migration must happen before registry import or executable-module fallback decisions.
5. Migration functions must be pure data transforms. They should not mutate live registries directly.
6. Migration should preserve persisted-only execution metadata when a ruleset or transform cannot be restored as executable.
7. Unknown future versions should fail clearly rather than being silently imported.

## Reject Vs Migrate Rules

The intended decision rule is:

- older supported payload version: migrate forward, then import
- current payload version: import directly
- missing version field on legacy payload: treat as version `1` only when that is explicitly documented as safe
- newer unknown payload version: reject with a version-specific persistence error
- structurally invalid payload at any version: reject without attempting migration

This keeps migrations explicit and avoids silently importing snapshots that may have lost meaning.

## Suggested Module Layout

When automated migration is implemented, keep it separate from the current read/write helpers.

Suggested layout:

- `reaform/core/migrations/project.lua`
- `reaform/core/migrations/ruleset.lua`
- `reaform/core/migrations/profile.lua`

Suggested responsibilities:

- read current payload version
- step payload forward one version at a time
- return migrated data plus warnings when compatibility shims were applied
- fail with explicit errors on unsupported future versions

`reaform/core/persistence.lua` should stay responsible for file IO and import orchestration, while migration modules handle version evolution.

## Persisted-Only Artifact Policy

Persisted-only imported artifacts need stable migration behavior too.

Rules:

- `execution_state = "persisted_metadata"` must survive migration unless a live module restore succeeds later
- `execution_error` should be preserved when still applicable
- migration must not synthesize executable hooks
- transform and analysis metadata should remain importable even when executable restoration is impossible

This preserves the distinction between "known metadata" and "runnable artifact."

## Testing Expectations

When migration logic is added, minimum tests should cover:

- import of current-version project snapshots
- import of legacy version `1` snapshots after a later schema bump
- rejection of unknown future `schema_version`
- ruleset-state migration across at least one `serialization_version` increment
- profile-state migration across at least one `version` increment
- preservation of persisted-only non-executable state through migration

## Current Repository Status

These notes document intended behavior. They do not mean migration is implemented yet.

What exists now:

- version fields are present and validated where relevant
- persistence round-trips preserve version markers
- import works for current known payload shapes

What still needs implementation:

- explicit migration helpers
- version dispatch during import
- rejection of unsupported future payload versions
- migration-specific tests
