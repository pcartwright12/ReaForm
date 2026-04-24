# ReaForm Development Plan

## Current State Summary

ReaForm currently consists of a generic Lua shared core, a small shared engine, placeholder rulesets, and a custom test runner. The repository now includes compatibility-oriented canonical schema normalization and minimal in-memory registries so the codebase can grow toward the lockfile without breaking the existing `MusicalObject`, `RuleSet`, `Generator`, and `Evaluator` entry points.

Main modules and responsibilities:

- `main.lua`: top-level entry surface for shared loading, orchestration helpers, and services
- `reaform/core/`: shared object/ruleset contracts, canonical schema normalization, IDs, and in-memory registries
- `reaform/contracts/`: formal evaluation context and evaluation result contracts
- `reaform/engine/`: generic generation/evaluation flow and small dispatch/classification helpers
- `reaform/rulesets/`: placeholder domain rulesets with directory-level wrapper entry points for counterpoint, serialism, neo-Riemannian work, Schenkerian reduction, and custom extension
- `reaform/tests/`: contract, behavior, and foundation-level architectural coverage

Current working features:

- generic object, constraint, transformation, and ruleset validation
- top-level ruleset loading and orchestration through `main.lua`
- shared generation and evaluation entry points across multiple rulesets
- canonical normalization for legacy object/ruleset inputs
- in-memory registries for objects, relationships, analyses, rulesets, and profiles
- formal evaluation context/result normalization

Obvious gaps:

- migration and richer orchestration behavior beyond the new JSON-safe persistence save/load/import helpers
- broader engine split from the lockfile
- ruleset packaging with profiles/rules/transforms/analyses subtrees
- deeper analysis-lens and transform semantics beyond the new registration seams
- default `lua` command availability on `PATH`

## Documentation Alignment Matrix

| Requirement / feature | Source | Current status | Implementation notes | Risk |
| --- | --- | --- | --- | --- |
| Ruleset-driven generic shared core | `README.md`, `docs/architecture.md`, lockfile core principle | Complete | Shared engine still delegates musical meaning to rulesets. | Low |
| Legacy `MusicalObject` contract remains stable | `docs/architecture.md`, existing tests | Complete | Kept public legacy shape and added canonical normalization behind it. | Low |
| Canonical object/profile/evaluation schemas | `docs/ReaForm_Lockfile.md` | Partial | Added normalization helpers, formal evaluation contracts, and stricter validation for several optional ruleset/profile fields, but not full schema enforcement for every future field. | Medium |
| Shared registries for objects/relationships/analyses/rulesets/profiles | `docs/ReaForm_Lockfile.md` | Partial | Added minimal in-memory registries with thin APIs plus transform and analysis-lens registration seams. | Medium |
| Formal evaluation context/result objects | `docs/ReaForm_Lockfile.md` | Partial | Added contracts and evaluator integration; generator/transform contracts remain smaller than target. | Medium |
| Schenkerian placeholder ruleset | `docs/ReaForm_Lockfile.md`, `docs/status-against-lockfile.md` | Complete | Added minimal placeholder using shared APIs only. | Low |
| Persistence boundary | `docs/ReaForm_Lockfile.md` | Partial | Added JSON-safe save/load helpers, project-state import into live registries, a top-level orchestration facade for reset/import/export flows, and explicit migration notes, but not implemented migration dispatch/support yet. | Medium |
| Broader engine decomposition | `docs/ReaForm_Lockfile.md` | Partial | Added classifier/dispatcher/constraint evaluator plus a small top-level `main.lua` orchestration surface for common run flows. | Medium |
| Anti-counterpoint regression coverage | lockfile explicit anti-regression rules | Partial | Added static and runtime coverage for shared core/engine source and multi-ruleset tests. | Medium |
| Repository validation command works in local environment | `README.md`, `docs/testing-and-contributing.md` | Partial | Validation succeeds with a workspace-local Lua 5.4 runtime; the plain `lua` command still depends on `PATH`. | Medium |
| Host-independent top-level script loading | REAPER execution, `main.lua`, `reaform/tests/runner.lua` | Complete | Top-level scripts now resolve Lua modules relative to their own file location instead of the host process working directory. | Low |

## Development Phases

### Phase 0: Safety And Validation

- Status:
  - [x] Preserve current public entry points and legacy shapes.
  - [x] Expand architecture tests before deeper refactors.
  - [x] Record runtime validation blockers and exact command results.
  - [x] Unblock runtime Lua validation with a workspace-local interpreter.

### Phase 1: Core Model Alignment

- Status:
  - [x] Introduce canonical schema normalization for objects, rulesets, profiles, and evaluation payloads.
  - [x] Add in-memory registries for objects, relationships, analyses, rulesets, and profiles.
  - [x] Keep shared APIs thin and compatibility-oriented.
  - [x] Add minimal persistence-backed storage for project, ruleset, and profile state.

### Phase 2: Engine Contract Alignment

- Status:
  - [x] Continue decomposing evaluation/generation internals where immediately useful.
  - [x] Extend formal result classification and shared strategy dispatch.
  - [x] Add transform registration seams.
  - [x] Add analysis registration seams beyond the minimal record registry boundary.

### Phase 3: Persistence And Packaging

- Status:
  - [x] Add versioned persistence for project, ruleset, and profile state.
  - [x] Gradually expand ruleset packaging structure without cosmetic churn.
  - [x] Add serialization coverage.
  - [x] Add project-state restore/import helpers.
  - [x] Add migration notes.

### Phase 4: Validation And Polish

- Status:
  - [x] Improve test breadth with runtime persistence and registration coverage.
  - [ ] Reconcile remaining doc/code drift.
  - [x] Tighten acceptance coverage for registries, persistence, and multi-ruleset loading.

## Task Breakdown

### Task 0: AI Edit-Tracking Policy

- Goal: ensure all AI-driven repository edits keep planning and logging artifacts synchronized.
- Affected files: `.github/copilot-instructions.md`, `docs/testing-and-contributing.md`, `DEVELOPMENT_PLAN.md`, `DEVELOPMENT_LOG.md`
- Implementation steps:
  - [x] Add repository-level Copilot instruction requiring plan/log updates for every AI edit.
  - [x] Add contributor-facing rule in testing/contributing guidance.
  - [x] Record the policy rollout in the development log.
- Tests or validation: static review of policy text and cross-file consistency.
- Acceptance criteria: rule is documented in both AI instructions and contributor workflow docs.
- Dependencies: none.
- Rollback notes: remove policy sections if project governance changes.

### Task 1: Plan And Log Artifacts

- Goal: capture the repository audit, phase ordering, and validation history in-repo.
- Affected files: `DEVELOPMENT_PLAN.md`, `DEVELOPMENT_LOG.md`
- Implementation steps:
  - [x] Summarize current architecture.
  - [x] Build alignment matrix.
  - [x] Record command evidence and blockers.
- Tests or validation: static document review.
- Acceptance criteria: both files exist and reflect current code.
- Dependencies: repository audit.
- Rollback notes: none.

### Task 2: Compatibility-Oriented Canonical Schemas

- Goal: add richer internal normalization without breaking legacy public shapes.
- Affected files: `reaform/core/schemas.lua`, `reaform/core/musical_object.lua`, `reaform/core/ruleset.lua`, `reaform/core/ids.lua`
- Implementation steps:
  - [x] Normalize legacy objects into canonical structures.
  - [x] Normalize legacy rulesets into canonical structures.
  - [x] Preserve compatibility aliases.
  - [x] Add evaluation context/result normalization.
- Tests or validation: foundation tests for legacy normalization and formal evaluation payloads.
- Acceptance criteria: existing object/ruleset entry points still work and new normalization helpers exist.
- Dependencies: shared validation helpers.
- Rollback notes: remove new helpers and revert public modules if compatibility regresses.

### Task 3: Minimal Shared Registries

- Goal: provide lockfile-aligned seams for stored shared state.
- Affected files: `reaform/core/object_registry.lua`, `reaform/core/relationship_graph.lua`, `reaform/core/analysis_registry.lua`, `reaform/core/ruleset_registry.lua`, `reaform/core/profile_registry.lua`
- Implementation steps:
  - [x] Add in-memory object registry APIs.
  - [x] Add relationship registry APIs.
  - [x] Add analysis registry APIs.
  - [x] Add ruleset registry APIs.
  - [x] Add profile registry APIs.
- Tests or validation: foundation tests covering create/query/update flows.
- Acceptance criteria: thin registry APIs exist and round-trip their stored values in memory.
- Dependencies: canonical schemas.
- Rollback notes: safe to remove if a different registry boundary is chosen later because no persistence is introduced yet.

### Task 4: Formal Evaluation Seams

- Goal: move evaluator internals toward declared contracts without changing ruleset semantics.
- Affected files: `reaform/contracts/evaluation_context.lua`, `reaform/contracts/evaluation_result.lua`, `reaform/engine/evaluator.lua`, `reaform/engine/evaluation_classifier.lua`, `reaform/engine/constraint_evaluator.lua`, `reaform/engine/strategy_dispatcher.lua`, `reaform/engine/generator.lua`
- Implementation steps:
  - [x] Formalize evaluation context creation.
  - [x] Formalize evaluation result creation.
  - [x] Add classifier helper.
  - [x] Add dispatcher helper.
  - [x] Keep current ruleset hooks intact.
- Tests or validation: behavior and foundation coverage for classification and Schenkerian execution.
- Acceptance criteria: evaluator returns normalized evaluation data while current rulesets still use the same shared APIs.
- Dependencies: canonical schemas.
- Rollback notes: revert evaluator/generator internals only; public API remains small.

### Task 5: Placeholder Completeness And Anti-Regression Tests

- Goal: complete missing placeholder coverage and lock in non-counterpoint assumptions.
- Affected files: `reaform/rulesets/schenkerian/basic_reduction.lua`, `reaform/tests/test_foundation.lua`, `reaform/tests/runner.lua`
- Implementation steps:
  - [x] Add Schenkerian placeholder.
  - [x] Add registry and contract tests.
  - [x] Add static shared-layer anti-regression checks.
  - [x] Execute the repository test runner with a Lua runtime.
- Tests or validation: repository test runner with a workspace-local Lua 5.4 runtime.
- Acceptance criteria: new ruleset and suite are present and integrated into the runner.
- Dependencies: shared evaluator and generator.
- Rollback notes: low risk; placeholder and tests can be removed independently if they prove incompatible.

## Risk Register

- Undocumented behavior in current rulesets: canonical normalization may reveal assumptions that were previously implicit. Mitigation: keep compatibility aliases and avoid changing ruleset payloads directly.
- UI regressions: none in this phase because no UI exists. Residual risk is low.
- Data migration risk: future persistence work will need an explicit migration story because the public legacy object shape and canonical shape now coexist. Mitigation: keep conversion seams explicit.
- Broken compatibility: evaluator/generator internals now normalize more data. Mitigation: preserve current entry points and rule hook signatures.
- Test gaps: runtime execution now works with a workspace-local interpreter, but the default `lua` command still depends on local environment setup. Mitigation: keep the documented fallback command and consider checked-in tooling policy later.
- Documentation conflict: some docs describe the pre-registry skeleton while the lockfile describes a larger target. Mitigation: update current-state docs only where code now changed and keep future-facing language explicit.

## Immediate Next Actions

- [x] Treat the workspace-local Lua runtime as an ignored local convenience rather than a committed repository dependency.
- [x] Introduce a small `main.lua` shared entry surface.
- [x] Start the ruleset packaging transition with directory-level `ruleset.lua` wrappers.
- [x] Tighten ruleset/profile schema validation beyond normalization defaults.
- [x] Give persisted-only imported rulesets/transforms a formal non-executable state/API.
- [x] Expand `main.lua` from a thin loader into a small orchestration facade for common repository flows.
- [x] Add migration notes.
- [ ] Implement version-aware persistence migration dispatch and rejection rules.

## Assumptions And Defaults

- The lockfile remains the target architecture, but the repository should reach it incrementally and without large rewrites.
- Legacy public shapes remain supported until explicit migration work is planned.
- In-memory registries are the correct first step before persistence.
- No UI or advanced domain behavior is introduced in this phase; current orchestration remains a small top-level facade rather than a full module layer.
- Validation now works through a workspace-local Lua 5.4 runtime even when `lua` is not on `PATH`.
