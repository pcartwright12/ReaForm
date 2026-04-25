# Status Against Lockfile

This document compares the current repository to the attached project lockfile. It is intentionally explicit: the repository is an early subset of the target architecture, not a completed implementation of that spec.

## Summary

The lockfile describes a much broader Phase 1 foundation with registries, richer schemas, more engine services, persistence, profiles, placeholder rulesets for more domains, and broader tests. The current repository now includes the first persistence boundary, a small top-level `main.lua`, and directory-level ruleset wrappers, but it still remains a smaller proof-of-direction than the full spec.

## Implemented Now

- Ruleset-driven repository direction rather than counterpoint-first architecture
- Generic `MusicalObject` contract
- Generic `Constraint` contract and shared constraint execution path
- Generic `Transformation` contract and shared transformation execution path
- Generic `RuleSet` contract with nested validation for constraints and transformations
- Canonical schema normalization for objects, rulesets, profiles, evaluation contexts, and evaluation results
- In-memory registries for objects, relationships, analyses, rulesets, profiles, and transforms
- Analysis-lens registration driven from saved rulesets
- JSON-safe persistence helpers for project, ruleset, and profile state
- Version-aware migration dispatch for project snapshots and persisted ruleset state, including `v1 -> v2` upgrade steps
- Project-state import helpers that repopulate live registries from saved snapshots
- A small top-level `main.lua` orchestration surface
- A workflow/controller layer for GUI-safe ruleset selection, generate/evaluate/transform actions, object listing, and session state
- A minimal REAPER GUI entry script for the first interactive generate/evaluate/transform loop
- Directory-level `ruleset.lua` wrappers for the placeholder ruleset families
- Stricter schema validation for optional ruleset/profile fields that previously normalized malformed data away
- Formal non-executable execution state for persisted-only imported rulesets and transforms
- Shared generation entry point via `Generator.generate`
- Shared evaluation entry point via `Evaluator.evaluate`
- Formal `EvaluationContext` and `EvaluationResult` contracts wired into the shared evaluator
- Placeholder rulesets for:
  - counterpoint
  - serialism
  - neo-Riemannian work
  - schenkerian reduction
  - custom extensions
- Tests proving:
  - core contracts validate data
  - shared APIs work across multiple rulesets
  - wrapper-based ruleset loading through `main.lua`
  - persistence state round-trips
  - transform and analysis-lens registration
  - non-counterpoint rulesets do not require counterpoint engine concepts

## Partially Represented

These lockfile goals are present in reduced or incomplete form:

- Shared core:
  Present, and now includes first-pass registries and normalization helpers, but it is still smaller than the broader core module set from the lockfile.
- Canonical object schemas:
  Present through a compatibility-oriented normalization layer, and ruleset/profile validation is stricter than before, but not every lockfile schema field is enforced with rich domain validation yet.
- Rule and transformation contracts:
  Present for constraints, transformations, and rulesets, and now support persistence-safe transform declarations, but are not split into the full contract files named in the lockfile.
- Initial engine contracts:
  Present through the current generator and evaluator entry points plus formal evaluation context/result objects, but still far smaller than the full engine split named in the lockfile.
- Minimal test scaffolding:
  Present, but smaller than the lockfile test layout and coverage list.
- Multiple ruleset examples:
  Present, and now wrapped behind directory-level `ruleset.lua` entry points, but still with fewer domains and much lighter placeholder content than the target structure.
- Persistence boundary:
  Present for JSON-safe save/load, version-aware project/ruleset migration dispatch, real `v1 -> v2` upgrades, profile-version validation, and registry import of project, ruleset, and profile state, but still not yet a broader future-version migration layer.
- Top-level boundary:
  Present as a small `main.lua` orchestration facade with ruleset resolution, bootstrap, import/export, and shared generate/evaluate/transform helpers, but still much smaller than the lockfile's eventual application boundary.
- Interactive loop:
  Partially implemented; the workflow/controller layer and first REAPER GUI entry point now exist, and the next planned slice is to refine output presentation and interaction behavior on top of that loop.

## Not Yet Implemented

The following lockfile targets are not implemented in the current repository:

- `rule_evaluator.lua`
- `candidate_ranker.lua`
- `generation_engine.lua`
- `transform_engine.lua`
- `analysis_engine.lua`
- `development_engine.lua`
- Formal contract modules for:
  - rule contract
  - transform contract
  - analysis contract
  - generation contract
  - operation result
- Modules layer such as:
  - material generator
  - material ingestor
  - material inspector
  - material lab
  - sketch lab
  - reduction lab
  - transformation lab
- Relationship graph semantics beyond raw object relationship tables
- Broader ruleset directory structure with profiles, rules, constraints, transforms, generators, and analyses subdirectories

## Important Deltas

### Object Model Delta

The lockfile expects a richer canonical object schema with fields such as:

- `object_type`
- `source`
- `ruleset_scope`
- `tags`
- `metadata`
- `domain_payload`
- `derived_analyses`
- `parent_ids`
- `child_ids`
- `transformations_applied`
- `confidence`
- `ambiguities`
- `created_by_module`
- `created_at`
- `updated_at`
- `version`
- `notes`

The compatibility-facing `MusicalObject` API still only returns:

- `id`
- `type`
- `properties`
- `relationships`

Internally, the repository now normalizes those fields into a richer object model, but the legacy API remains the stable public surface for the current rulesets and tests.

### Engine Delta

The lockfile envisions a broader engine with separated evaluators, ranking, transformation, analysis, development, and dispatch services. The current engine has only:

- `Generator.generate`
- `Evaluator.evaluate`

These are useful entry points, but they are not yet the full engine skeleton described in the spec.

### Registry And Persistence Delta

The repository now has first-pass registries, transform and analysis-lens registration, JSON-safe persistence helpers, project-state import back into live registries, a top-level orchestration facade in `main.lua`, and explicit migration dispatch with real `v1 -> v2` upgrades for project/ruleset persisted data. What is still missing is further stepwise migration code for future schema bumps, richer module-layer workflows, and deeper relationship/analysis semantics.

The next practical priority is now the interactive loop UX: the workflow/controller layer and first REAPER GUI exist, so the next step is to improve presentation, rendering, and state-driven interaction behavior before more depth is added elsewhere.

### Ruleset And Profile Delta

The current `RuleSet` contract includes:

- metadata fields
- declared object types
- constraints
- transformations
- generation strategy
- evaluation strategy

The lockfile expects much broader capability declarations, profiles, analysis lenses, scoring models, validation modes, serialization versions, and profile-specific behavior. The repository now has directory-level ruleset wrappers, a small top-level loader, and a formal non-executable state for persisted-only imported rulesets, but those concepts are still not first-class in the full lockfile sense.

### Test Delta

The current tests cover contract validation, shared-engine behavior, persistence round-trips, persistence import, transform registration, analysis-lens registration, and shared-layer anti-regression checks. They do not yet cover:

- ruleset registries
- profile loading
- provenance tracking
- lockfile-level anti-regression coverage in full detail

## Current Direction Still Matches The Lockfile

Even though the repository is smaller than the target spec, several core intentions do match:

- shared code stays generic
- rulesets define domain-specific meaning
- serialism and neo-Riemannian examples can run without counterpoint dependencies
- counterpoint is treated as one ruleset, not the governing model for the whole application

That alignment matters because it means the current repository is directionally correct, even if it is far from the full Phase 1 target.

## Future-Facing APIs From The Lockfile

The lockfile names several APIs that are implemented in reduced form or still not implemented yet. Contributors should distinguish between the current repository surface and the broader target architecture:

- `rank_candidates(context, candidates)`
- `apply_transform(transform_id, source_ids, options)`
- `create_evaluation_context(payload)`
- `evaluate(context)`
- `generate(strategy_id, context)`
