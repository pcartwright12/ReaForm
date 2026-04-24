# ReaForm Development Plan

## Current State Summary

ReaForm currently consists of a generic Lua shared core, a small shared engine, placeholder rulesets, and a custom test runner. The repository now includes compatibility-oriented canonical schema normalization and minimal in-memory registries so the codebase can grow toward the lockfile without breaking the existing `MusicalObject`, `RuleSet`, `Generator`, and `Evaluator` entry points.

Main modules and responsibilities:

- `reaform/core/`: shared object/ruleset contracts, canonical schema normalization, IDs, and in-memory registries
- `reaform/contracts/`: formal evaluation context and evaluation result contracts
- `reaform/engine/`: generic generation/evaluation flow and small dispatch/classification helpers
- `reaform/rulesets/`: placeholder domain rulesets for counterpoint, serialism, neo-Riemannian work, Schenkerian reduction, and custom extension
- `reaform/tests/`: contract, behavior, and foundation-level architectural coverage

Current working features:

- generic object, constraint, transformation, and ruleset validation
- shared generation and evaluation entry points across multiple rulesets
- canonical normalization for legacy object/ruleset inputs
- in-memory registries for objects, relationships, analyses, rulesets, and profiles
- formal evaluation context/result normalization

Obvious gaps:

- persistence and versioned project save/load boundaries
- broader engine split from the lockfile
- ruleset packaging with profiles/rules/transforms/analyses subtrees
- analysis-lens and transform registration beyond minimal seams
- executable runtime validation in this environment because `lua` is not installed on `PATH`

## Documentation Alignment Matrix

| Requirement / feature | Source | Current status | Implementation notes | Risk |
| --- | --- | --- | --- | --- |
| Ruleset-driven generic shared core | `README.md`, `docs/architecture.md`, lockfile core principle | Complete | Shared engine still delegates musical meaning to rulesets. | Low |
| Legacy `MusicalObject` contract remains stable | `docs/architecture.md`, existing tests | Complete | Kept public legacy shape and added canonical normalization behind it. | Low |
| Canonical object/profile/evaluation schemas | `docs/ReaForm_Lockfile.md` | Partial | Added normalization helpers and formal evaluation contracts, but not full schema enforcement for every future field. | Medium |
| Shared registries for objects/relationships/analyses/rulesets/profiles | `docs/ReaForm_Lockfile.md` | Partial | Added minimal in-memory registries with thin APIs; no persistence yet. | Medium |
| Formal evaluation context/result objects | `docs/ReaForm_Lockfile.md` | Partial | Added contracts and evaluator integration; generator/transform contracts remain smaller than target. | Medium |
| Schenkerian placeholder ruleset | `docs/ReaForm_Lockfile.md`, `docs/status-against-lockfile.md` | Complete | Added minimal placeholder using shared APIs only. | Low |
| Persistence boundary | `docs/ReaForm_Lockfile.md` | Missing | Deferred until after core seams stabilize. | High |
| Broader engine decomposition | `docs/ReaForm_Lockfile.md` | Partial | Added classifier/dispatcher/constraint evaluator only where immediately useful. | Medium |
| Anti-counterpoint regression coverage | lockfile explicit anti-regression rules | Partial | Added static coverage for shared core/engine source and multi-ruleset tests; still blocked from runtime execution locally. | Medium |
| Repository validation command works in local environment | `README.md`, `docs/testing-and-contributing.md` | Conflicting | `lua reaform/tests/runner.lua` is documented correctly but fails here because `lua` is unavailable. | High |

## Development Phases

### Phase 0: Safety And Validation

- Preserve current public entry points and legacy shapes.
- Expand architecture tests before deeper refactors.
- Record runtime validation blockers and exact command results.

### Phase 1: Core Model Alignment

- Introduce canonical schema normalization for objects, rulesets, profiles, and evaluation payloads.
- Add in-memory registries for objects, relationships, analyses, rulesets, and profiles.
- Keep shared APIs thin and compatibility-oriented.

### Phase 2: Engine Contract Alignment

- Continue decomposing evaluation/generation internals only where clear value exists.
- Extend formal result classification and shared strategy dispatch.
- Add transform and analysis registration seams without hardcoding domain semantics.

### Phase 3: Persistence And Packaging

- Add versioned persistence for project, ruleset, and profile state.
- Gradually expand ruleset packaging structure without cosmetic churn.
- Add serialization coverage and migration notes.

### Phase 4: Validation And Polish

- Improve test breadth once a Lua runtime is available in the environment.
- Reconcile remaining doc/code drift.
- Tighten acceptance coverage for registries, persistence, and multi-ruleset loading.

## Task Breakdown

### Task 1: Plan And Log Artifacts

- Goal: capture the repository audit, phase ordering, and validation history in-repo.
- Affected files: `DEVELOPMENT_PLAN.md`, `DEVELOPMENT_LOG.md`
- Implementation steps: summarize current architecture, build alignment matrix, record command evidence and blockers.
- Tests or validation: static document review.
- Acceptance criteria: both files exist and reflect current code.
- Dependencies: repository audit.
- Rollback notes: none.

### Task 2: Compatibility-Oriented Canonical Schemas

- Goal: add richer internal normalization without breaking legacy public shapes.
- Affected files: `reaform/core/schemas.lua`, `reaform/core/musical_object.lua`, `reaform/core/ruleset.lua`, `reaform/core/ids.lua`
- Implementation steps: normalize legacy objects/rulesets into canonical structures, preserve compatibility aliases, add evaluation context/result normalization.
- Tests or validation: foundation tests for legacy normalization and formal evaluation payloads.
- Acceptance criteria: existing object/ruleset entry points still work and new normalization helpers exist.
- Dependencies: shared validation helpers.
- Rollback notes: remove new helpers and revert public modules if compatibility regresses.

### Task 3: Minimal Shared Registries

- Goal: provide lockfile-aligned seams for stored shared state.
- Affected files: `reaform/core/object_registry.lua`, `reaform/core/relationship_graph.lua`, `reaform/core/analysis_registry.lua`, `reaform/core/ruleset_registry.lua`, `reaform/core/profile_registry.lua`
- Implementation steps: add in-memory create/get/update/list style APIs with schema-backed normalization.
- Tests or validation: foundation tests covering create/query/update flows.
- Acceptance criteria: thin registry APIs exist and round-trip their stored values in memory.
- Dependencies: canonical schemas.
- Rollback notes: safe to remove if a different registry boundary is chosen later because no persistence is introduced yet.

### Task 4: Formal Evaluation Seams

- Goal: move evaluator internals toward declared contracts without changing ruleset semantics.
- Affected files: `reaform/contracts/evaluation_context.lua`, `reaform/contracts/evaluation_result.lua`, `reaform/engine/evaluator.lua`, `reaform/engine/evaluation_classifier.lua`, `reaform/engine/constraint_evaluator.lua`, `reaform/engine/strategy_dispatcher.lua`, `reaform/engine/generator.lua`
- Implementation steps: formalize evaluation context/result creation, add classifier/dispatcher helpers, keep current ruleset hooks intact.
- Tests or validation: behavior and foundation coverage for classification and Schenkerian execution.
- Acceptance criteria: evaluator returns normalized evaluation data while current rulesets still use the same shared APIs.
- Dependencies: canonical schemas.
- Rollback notes: revert evaluator/generator internals only; public API remains small.

### Task 5: Placeholder Completeness And Anti-Regression Tests

- Goal: complete missing placeholder coverage and lock in non-counterpoint assumptions.
- Affected files: `reaform/rulesets/schenkerian/basic_reduction.lua`, `reaform/tests/test_foundation.lua`, `reaform/tests/runner.lua`
- Implementation steps: add Schenkerian placeholder, add registry/contract tests, add static shared-layer anti-regression checks.
- Tests or validation: repository test runner once Lua is available; static review now.
- Acceptance criteria: new ruleset and suite are present and integrated into the runner.
- Dependencies: shared evaluator and generator.
- Rollback notes: low risk; placeholder and tests can be removed independently if they prove incompatible.

## Risk Register

- Undocumented behavior in current rulesets: canonical normalization may reveal assumptions that were previously implicit. Mitigation: keep compatibility aliases and avoid changing ruleset payloads directly.
- UI regressions: none in this phase because no UI exists. Residual risk is low.
- Data migration risk: future persistence work will need an explicit migration story because the public legacy object shape and canonical shape now coexist. Mitigation: keep conversion seams explicit.
- Broken compatibility: evaluator/generator internals now normalize more data. Mitigation: preserve current entry points and rule hook signatures.
- Test gaps: runtime execution is blocked by missing `lua`, so syntax/runtime regressions remain possible. Mitigation: document blocker and keep changes incremental.
- Documentation conflict: some docs describe the pre-registry skeleton while the lockfile describes a larger target. Mitigation: update current-state docs only where code now changed and keep future-facing language explicit.

## Immediate Next Actions

1. Restore executable validation by installing or exposing a Lua interpreter on `PATH`.
2. Add minimal persistence helpers for project, ruleset, and profile state.
3. Expand tests to cover persistence round-trips and ruleset/profile serialization versions.
4. Add transform registration and analysis-lens registration seams.
5. Introduce a small `main.lua` or equivalent shared entry surface if the repo wants a lockfile-style top-level boundary.
6. Decide whether ruleset directories should start gaining `ruleset.lua` wrappers now or wait until persistence/registry loading is in place.
7. Tighten ruleset/profile schema validation beyond normalization defaults.
8. Re-run and record the full Lua suite once runtime is available.

## Assumptions And Defaults

- The lockfile remains the target architecture, but the repository should reach it incrementally and without large rewrites.
- Legacy public shapes remain supported until explicit migration work is planned.
- In-memory registries are the correct first step before persistence.
- No UI, orchestration, or advanced domain behavior is introduced in this phase.
- Validation remains partially blocked until a Lua interpreter is available in the local environment.
