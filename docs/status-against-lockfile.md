# Status Against Lockfile

This document compares the current repository to the attached project lockfile. It is intentionally explicit: the repository is an early subset of the target architecture, not a completed implementation of that spec.

## Summary

The lockfile describes a much broader Phase 1 foundation with registries, richer schemas, more engine services, persistence, profiles, placeholder rulesets for more domains, and broader tests. The current repository implements a smaller proof-of-direction centered on four generic contracts, two engine entry points, and a few placeholder rulesets.

## Implemented Now

- Ruleset-driven repository direction rather than counterpoint-first architecture
- Generic `MusicalObject` contract
- Generic `Constraint` contract and shared constraint execution path
- Generic `Transformation` contract and shared transformation execution path
- Generic `RuleSet` contract with nested validation for constraints and transformations
- Shared generation entry point via `Generator.generate`
- Shared evaluation entry point via `Evaluator.evaluate`
- Placeholder rulesets for:
  - counterpoint
  - serialism
  - neo-Riemannian work
  - custom extensions
- Tests proving:
  - core contracts validate data
  - shared APIs work across multiple rulesets
  - non-counterpoint rulesets do not require counterpoint engine concepts

## Partially Represented

These lockfile goals are present in reduced or incomplete form:

- Shared core:
  Present, but limited to a few contracts instead of the broader core module set.
- Canonical object schemas:
  Present only as the small `MusicalObject` schema with `id`, `type`, `properties`, and `relationships`.
- Rule and transformation contracts:
  Present for constraints, transformations, and rulesets, but not split into the full contract files named in the lockfile.
- Initial engine contracts:
  Present only through the current generator and evaluator entry points.
- Minimal test scaffolding:
  Present, but smaller than the lockfile test layout and coverage list.
- Multiple ruleset examples:
  Present, but with fewer domains and much lighter placeholder content than the target structure.

## Not Yet Implemented

The following lockfile targets are not implemented in the current repository:

- `ids.lua`
- `schemas.lua`
- `object_registry.lua`
- `relationship_graph.lua`
- `analysis_registry.lua`
- `ruleset_registry.lua`
- `profile_registry.lua`
- `persistence.lua`
- `evaluation_classifier.lua`
- `rule_evaluator.lua`
- `constraint_evaluator.lua`
- `candidate_ranker.lua`
- `generation_engine.lua`
- `transform_engine.lua`
- `analysis_engine.lua`
- `development_engine.lua`
- `strategy_dispatcher.lua`
- Formal contract modules for:
  - rule contract
  - transform contract
  - analysis contract
  - generation contract
  - evaluation context
  - evaluation result
  - operation result
- Modules layer such as:
  - material generator
  - material ingestor
  - material inspector
  - material lab
  - sketch lab
  - reduction lab
  - transformation lab
- Profiles and profile loading
- Basic persistence and versioned schema save/load boundaries
- Relationship graph semantics beyond raw object relationship tables
- Analysis registry and analysis lens infrastructure
- Placeholder `schenkerian` ruleset
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

The current `MusicalObject` only contains:

- `id`
- `type`
- `properties`
- `relationships`

### Engine Delta

The lockfile envisions a broader engine with separated evaluators, ranking, transformation, analysis, development, and dispatch services. The current engine has only:

- `Generator.generate`
- `Evaluator.evaluate`

These are useful entry points, but they are not yet the full engine skeleton described in the spec.

### Registry And Persistence Delta

The lockfile depends heavily on registries and versioned persistence boundaries. None of those systems exist yet in the current repository.

### Ruleset And Profile Delta

The current `RuleSet` contract includes:

- metadata fields
- declared object types
- constraints
- transformations
- generation strategy
- evaluation strategy

The lockfile expects much broader capability declarations, profiles, analysis lenses, scoring models, validation modes, serialization versions, and profile-specific behavior. Those concepts are not yet first-class in the codebase.

### Test Delta

The current tests cover contract validation and basic shared-engine behavior. They do not yet cover:

- ruleset registries
- profile loading
- provenance tracking
- transform registration
- analysis lens registration
- persistence behavior
- Schenkerian placeholder loading
- lockfile-level anti-regression coverage in full detail

## Current Direction Still Matches The Lockfile

Even though the repository is smaller than the target spec, several core intentions do match:

- shared code stays generic
- rulesets define domain-specific meaning
- serialism and neo-Riemannian examples can run without counterpoint dependencies
- counterpoint is treated as one ruleset, not the governing model for the whole application

That alignment matters because it means the current repository is directionally correct, even if it is far from the full Phase 1 target.

## Future-Facing APIs From The Lockfile

The lockfile names several APIs that are not implemented yet and should be documented only as future-facing goals, not current interfaces:

- `create_object(type, payload)`
- `get_object(id)`
- `update_object(id, patch)`
- `list_objects(filter)`
- `create_relationship(type, from_id, to_id, metadata)`
- `get_relationships(filter)`
- `store_analysis(record)`
- `get_analyses(target_id, filter)`
- `get_ruleset(id)`
- `save_ruleset(ruleset)`
- `list_rulesets(filter)`
- `validate_ruleset(ruleset)`
- `get_profile(id)`
- `save_profile(profile)`
- `list_profiles(filter)`
- `create_evaluation_context(payload)`
- `evaluate(context)`
- `rank_candidates(context, candidates)`
- `apply_transform(transform_id, source_ids, options)`
- `generate(strategy_id, context)`

Contributors should treat these as architectural targets from the lockfile, not as capabilities already present in this repository.
