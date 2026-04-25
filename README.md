# ReaForm

ReaForm is an early Lua foundation for a ruleset-driven music system. The current repository implements a small core of generic contracts, shared engine entry points, placeholder rulesets, and tests that demonstrate the project is not counterpoint-first.

This repository does not yet match the full architecture described in the project lockfile. It is a smaller implementation that establishes the direction: the engine stays generic, and each ruleset defines its own musical meaning.

## Current Status

Implemented today:

- Generic core contracts for `MusicalObject`, `Constraint`, `Transformation`, and `RuleSet`
- Canonical schema normalization helpers and in-memory registries for objects, relationships, analyses, rulesets, and profiles
- Transform registration and analysis-lens registration seams driven from saved rulesets
- JSON-safe persistence helpers for project, ruleset, and profile state
- Project-state import helpers that repopulate live registries from saved snapshots
- A top-level `main.lua` entry surface for loading rulesets, resetting state, import/export, and direct generate/evaluate/transform orchestration
- A workflow/controller layer in `reaform/workflows/session_workflow.lua` for GUI-safe actions and session state
- A minimal REAPER GUI entry script at `reaper/gui_main.lua` for ruleset selection, generate/evaluate/transform actions, and output inspection
- Script-relative module path setup so `main.lua` and the test runner can execute under hosts like REAPER without requiring the repo root as the process working directory
- Version-aware persistence migration dispatch for project snapshots and persisted ruleset state, including real `v1 -> v2` upgrades and clear rejection of unsupported future versions
- Directory-level `ruleset.lua` wrappers for the placeholder ruleset families
- Stricter ruleset/profile schema validation for optional arrays, settings tables, versions, and analysis-lens entries
- Formal execution-state tracking for persisted-only rulesets and transforms, with clear non-executable runtime failures
- Formal `EvaluationContext` and `EvaluationResult` contracts for shared evaluation flow
- Shared engine entry points for generation and evaluation
- Placeholder rulesets for counterpoint, serialism, neo-Riemannian work, Schenkerian reduction, and custom extensions
- A small test suite proving cross-ruleset behavior, packaging entry points, persistence round-trips, and the new lockfile-alignment seams

Not implemented yet:

- Module-layer workflows and the broader multi-engine architecture from the lockfile
- Richer REAPER GUI presentation and UX refinement beyond the first interactive loop
- Advanced generation or analysis workflows

## Repository Layout

```text
main.lua        top-level shared entry surface and orchestration facade
reaform/
  core/       core contracts and validation entry points
  engine/     generic generation and evaluation entry points
  rulesets/   placeholder domain-specific rulesets with directory-level wrappers
  tests/      lightweight contract and behavior tests
  utils/      shared validation and result helpers
  workflows/  GUI-safe workflow/controller modules
reaper/        minimal REAPER-hosted GUI entry scripts
```

## Running Tests

From the repository root:

```powershell
lua reaform/tests/runner.lua
```

If `lua` is not on `PATH`, a local workspace runtime can also be used:

```powershell
.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua
```

The test runner executes the contract suite, the cross-ruleset behavior suite, and the foundation suite for canonical schema normalization, stricter ruleset/profile validation, registries, persistence save/load/import behavior, evaluation contracts, and shared-layer anti-regression checks.

## Documentation

- [Architecture](docs/architecture.md)
- [Status Against Lockfile](docs/status-against-lockfile.md)
- [Ruleset Authoring](docs/ruleset-authoring.md)
- [Testing and Contributing](docs/testing-and-contributing.md)
- [Persistence Migration Notes](docs/persistence-migration.md)
- [Interactive Loop Plan](docs/interactive-loop-plan.md)
- [Glossary](docs/glossary.md)
- [Development Plan](DEVELOPMENT_PLAN.md)
- [Development Log](DEVELOPMENT_LOG.md)

## Project Direction

The governing idea is simple: ReaForm is ruleset-driven. The shared engine does not define what counts as a line, row, triad, or valid transformation. Those meanings come from the active ruleset.

Counterpoint is intentionally only one ruleset among several examples in this repository. Its presence should not shape generic engine concepts, public terminology, or future shared-core contracts.
