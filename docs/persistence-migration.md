# Persistence Migration Notes

This document defines the current migration story for persisted ReaForm data. The repository now includes first-pass migration dispatch for project snapshots and persisted ruleset state, including explicit `v1 -> v2` upgrade steps.

The goal of these notes is to keep future persistence work coherent and to make the current behavior explicit.

## Current Version Fields

The repository currently persists three top-level version markers:

- project snapshots use `schema_version`
- persisted rulesets use `serialization_version`
- persisted profiles use `version`

Related domain objects also carry `version` fields inside normalized schemas, but those are object/profile/ruleset model fields rather than import-dispatch fields.

Current defaults in code:

- project snapshots default to `schema_version = 2`
- rulesets default to `serialization_version = 2`
- rulesets also default to `version = 1`
- profiles default to `version = 1`

## Current Runtime Behavior

Current behavior:

- `Persistence.save_project(...)` writes project snapshots with `schema_version = 2`
- `Persistence.load_project(...)` decodes JSON and dispatches through project migration validation
- `Persistence.import_project_state(...)` dispatches through project migration validation before registry import
- `Persistence.save_ruleset(...)` writes whatever `serialization_version` the normalized ruleset declares
- `Persistence.load_ruleset(...)` dispatches through ruleset-state migration validation before returning data
- `Persistence.save_profile(...)` writes whatever `version` the normalized profile declares
- `Persistence.load_profile(...)` validates profile versions and preserves higher profile versions with a passthrough warning because profile-specific migration dispatch is not yet implemented
- persisted-only imported rulesets and transforms remain metadata artifacts with explicit non-executable state when live hooks are unavailable

This means project and ruleset version fields are now used both to upgrade older supported payloads and to reject unsupported future payloads, while profile versions are currently preserved as model metadata until a stricter profile serialization boundary exists.

## Policy For Future Migration Work

When migration logic expands beyond the current version `2` boundary, it should follow these rules:

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

## Implemented Upgrade Steps

Current stepwise migrations:

- project snapshots: `schema_version 1 -> 2`
- persisted rulesets: `serialization_version 1 -> 2`

Current `v1 -> v2` behavior:

- project snapshots gain canonical root collection arrays plus `migration_history`
- persisted rulesets gain canonical `transforms` plus compatibility `transformations`, normalized `analysis_lenses`, and explicit strategy-presence flags

## Current Repository Status

What exists now:

- explicit migration helpers exist for project, ruleset, and profile persisted state
- project and ruleset loads migrate `v1 -> v2`
- project and ruleset loads reject unsupported future versions
- profile loads validate positive versions and preserve higher values with warnings
- persistence round-trips preserve version markers
- import works for current known payload shapes

What still needs implementation:

- additional stepwise migration functions for future schema/version bumps
- stricter profile-state migration dispatch or a dedicated profile serialization field
- migration-specific tests
