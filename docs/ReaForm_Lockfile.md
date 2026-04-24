# ReaForm Ruleset-Agnostic Lockfile / Codex Initial Prompt

You are working on a new REAPER Lua project called **ReaForm**.

Read this lockfile/spec carefully before making changes.

Your task is **not** to build the full application.

Your task is to create the initial ReaForm project foundation with a clean architecture that supports arbitrary compositional and analytical rule systems.

ReaForm must not inherit ReaFux's counterpoint-first mental model. Counterpoint may exist as one supported ruleset, but it must not define the engine, object model, workflow model, or terminology of the whole application.

---

## Primary Goal

Create a Phase 1 foundation for ReaForm focused on:

1. Shared Core
2. Canonical object schemas
3. Ruleset registry
4. Rule / constraint / transformation contracts
5. Object registry
6. Relationship graph
7. Analysis registry
8. Profile registry
9. Basic persistence
10. Initial engine contracts
11. Minimal test scaffolding

Do not implement the full UI.  
Do not implement orchestration.  
Do not implement advanced generation.  
Do not port old ReaFux behavior.  
Do not hardcode species counterpoint assumptions.

---

## Naming

Use `ReaForm`, not `ReaFux`, in all new files, comments, namespaces, and user-facing strings.

Do not use counterpoint-specific names for generic engine concepts.

Bad generic names:

- `cantus`
- `species`
- `counterpoint`
- `consonance`
- `dissonance`
- `voice_leading`
- `exercise`

These names may appear only inside a counterpoint-specific ruleset, fixture, or compatibility adapter.

---

## Core Architectural Principle

ReaForm is **ruleset-driven**, not counterpoint-driven, exercise-driven, profile-driven, or UI-driven.

A **RuleSet** defines the musical or analytical ontology, permitted object types, constraints, transformations, analysis lenses, generation strategies, scoring rules, validation behavior, and result semantics for a given compositional system.

Counterpoint, serialism, neo-Riemannian transformation, Schenkerian reduction, orchestration, sketch development, and custom user systems must all be expressible as rulesets using the same core contracts.

The engine must not assume species, cantus, voices, intervals, consonance, dissonance, tonal hierarchy, Roman numerals, rows, set classes, triads, prolongation, or exercise type unless those assumptions are supplied by the active ruleset.

In short:

```text
The engine knows nothing about music by default.
The active ruleset tells the engine what musical objects mean and what operations are legal.
```

---

## Required Architecture

```text
reaform/
  core/
    ids.lua
    schemas.lua
    validation.lua
    object_registry.lua
    relationship_graph.lua
    analysis_registry.lua
    ruleset_registry.lua
    profile_registry.lua
    persistence.lua

  engine/
    evaluation_classifier.lua
    rule_evaluator.lua
    constraint_evaluator.lua
    candidate_ranker.lua
    generation_engine.lua
    transform_engine.lua
    analysis_engine.lua
    development_engine.lua
    strategy_dispatcher.lua

  contracts/
    ruleset_contract.lua
    rule_contract.lua
    constraint_contract.lua
    transform_contract.lua
    analysis_contract.lua
    generation_contract.lua
    evaluation_context.lua
    evaluation_result.lua
    operation_result.lua

  modules/
    material_generator.lua
    material_ingestor.lua
    material_inspector.lua
    material_lab.lua
    sketch_lab.lua
    reduction_lab.lua
    transformation_lab.lua

  rulesets/
    counterpoint/
      ruleset.lua
      profiles/
        cantus_strict.lua
        species1_strict.lua
        species2_strict.lua
        species3_strict.lua
        species4_strict.lua
        species5_strict.lua
        hybrid_relaxed.lua
      rules/
      constraints/
      transforms/
      generators/
      analyses/

    serialism/
      ruleset.lua
      profiles/
        twelve_tone_basic.lua
        aggregate_completion.lua
      rules/
      constraints/
      transforms/
      generators/
      analyses/

    neo_riemannian/
      ruleset.lua
      profiles/
        triadic_transformations.lua
      rules/
      constraints/
      transforms/
      generators/
      analyses/

    schenkerian/
      ruleset.lua
      profiles/
        foreground_reduction.lua
        middleground_reduction.lua
      rules/
      constraints/
      transforms/
      generators/
      analyses/

    custom/
      ruleset.lua
      profiles/
        free_custom.lua
      rules/
      constraints/
      transforms/
      generators/
      analyses/

  tests/
    fixtures/
    unit/
    integration/

  main.lua
```

---

## Design Rules

- Shared Core owns all canonical schemas.
- Rulesets define domain-specific musical meaning.
- Modules must not invent private versions of shared objects.
- All created objects must have stable IDs, version fields, timestamps, provenance fields, and relationship fields.
- All generated, transformed, analyzed, or imported material must pass through Shared Core.
- Rule evaluation must route through shared engine services.
- Constraint evaluation must be ruleset-provided, not engine-hardcoded.
- Transform semantics must be ruleset-provided, not engine-hardcoded.
- Analysis semantics must be ruleset-provided, not engine-hardcoded.
- No destructive transformation by default.
- Profiles are editable parameter configurations within or across rulesets, not hardcoded doctrines.
- Counterpoint-specific assumptions must live only under `rulesets/counterpoint/`.
- The engine must operate on declared contracts, not on species/exercise shortcuts.

---

## Core Concept Model

### RuleSet

A `RuleSet` is the sovereign object for domain behavior.

A ruleset must define:

- `id`
- `name`
- `version`
- `description`
- `ontology`
- `supported_object_types`
- `supported_relationship_types`
- `rule_groups`
- `constraints`
- `transforms`
- `analysis_lenses`
- `generation_strategies`
- `scoring_models`
- `validation_modes`
- `default_profiles`
- `serialization_version`

Example categories:

- Counterpoint ruleset: intervals, voice relationships, consonance/dissonance, species profiles.
- Serialism ruleset: row forms, aggregates, combinatoriality, transformations, registral rules.
- Neo-Riemannian ruleset: triads, transformations, parsimonious motion, graph traversal.
- Schenkerian ruleset: structural levels, prolongation, reduction, foreground/middleground/background relationships.
- Custom ruleset: user-declared constraints and transformations.

### Profile

A `Profile` is a parameterized configuration for a ruleset.

A profile may choose rule weights, severities, enabled/disabled constraints, generation preferences, and analysis settings.

A profile must not define the whole musical ontology by itself.

### Rule

A `Rule` defines a named evaluable behavior within a ruleset.

Rules may be used for:

- validation
- generation pruning
- scoring
- transformation legality
- analysis labeling
- advisory feedback

### Constraint

A `Constraint` defines a condition over one or more objects, relationships, operations, or analysis states.

Constraints must support:

- hard constraints
- soft constraints
- advisory constraints
- weighted preferences
- context-sensitive applicability

### Transform

A `Transform` defines an operation that maps one object or object graph to another.

Transforms must support examples such as:

- inversion
- retrograde
- transposition
- augmentation
- diminution
- fragmentation
- elaboration
- reduction
- orchestration
- neo-Riemannian P/L/R-style transformations
- serial row operations
- custom user transformations

The engine must not know which transforms are musically valid unless the active ruleset provides them.

### Analysis Lens

An `AnalysisLens` defines a way of interpreting material.

Examples:

- intervallic analysis
- set-class analysis
- row-form analysis
- transformational graph analysis
- reduction-layer analysis
- harmonic function analysis
- motivic analysis
- orchestration analysis

An analysis is not necessarily a validation rule.

### Generation Strategy

A `GenerationStrategy` defines how candidates are proposed, expanded, pruned, ranked, and accepted.

The engine may provide generic search mechanics, but the ruleset must define domain-specific candidate meaning and legality.

Supported generic search mechanisms may include:

- random generation
- weighted choice
- backtracking
- beam search
- graph traversal
- constraint solving
- mutation / variation
- staged construction

No generation strategy may assume counterpoint unless loaded from the counterpoint ruleset.

---

## Implement Now

### Base Object Schema

Include:

- id
- object_type
- source
- ruleset_scope
- tags
- metadata
- domain_payload
- derived_analyses
- relationships
- parent_ids
- child_ids
- transformations_applied
- confidence
- ambiguities
- created_by_module
- created_at
- updated_at
- version
- notes

### MVP Object Types

Implement the generic object type system first:

- Material
- Event
- EventSequence
- Line
- Phrase
- Cell
- Motif
- Collection
- Set
- Harmony
- Graph
- ReductionLayer
- AnalysisLayer
- Variation
- TransformationOperation
- GenerationOperation
- DevelopmentOperation

Object types must be extensible by rulesets.

For example:

- Counterpoint may define `Voice`, `Cantus`, or `SpeciesLine` under its ruleset ontology.
- Serialism may define `Row`, `RowForm`, `Aggregate`, or `Hexachord`.
- Neo-Riemannian rules may define `Triad`, `Region`, or `TransformationPath`.
- Schenkerian rules may define `StructuralTone`, `Prolongation`, or `UrlinieLayer`.

Do not bake these specialized concepts into Shared Core.

### Relationship Model

Support generic relationships first:

- derived_from
- variation_of
- contains
- contained_by
- segments_into
- elaborates
- reduces
- continues
- contrasts_with
- shares_material_with
- references
- accompanies
- doubles
- realizes
- orchestrates
- transforms_to
- transforms_from
- analyzes_as
- depends_on
- uses_ruleset
- uses_profile
- constrained_by
- generated_by

Relationship types must be extensible by rulesets.

Counterpoint may add relationship labels such as `against`, but those labels must not become universal engine assumptions.

### RuleSet Model

Implement:

- ruleset schema
- ruleset registry
- ruleset loading
- ruleset validation
- ruleset profile lookup
- ruleset capability declaration
- ruleset object type declaration
- ruleset relationship type declaration

### Profile Model

Implement:

- profile schema
- active ruleset reference
- rule groups
- rules with modes and weights
- constraints with severity and applicability
- transform settings
- generation strategy settings
- analysis lens settings

### Evaluation Context

Implement a formal `EvaluationContext` object.

It must include:

- active_ruleset_id
- active_profile_id
- target_object_ids
- relationship_scope
- operation_type
- operation_payload
- analysis_scope
- generation_state
- user_options
- runtime_metadata

Do not pass ad hoc option tables through evaluator internals.

### Evaluation Result

Implement a formal `EvaluationResult` object.

It must include:

- id
- context_id
- ruleset_id
- profile_id
- classification
- findings
- score
- passed
- failed_rule_ids
- warnings
- advisory_notices
- suggested_repairs
- metadata

### Evaluation Classifications

Support:

- hard_failure
- soft_warning
- advisory_notice
- pass

### Core APIs

```lua
create_object(type, payload)
get_object(id)
update_object(id, patch)
list_objects(filter)

create_relationship(type, from_id, to_id, metadata)
get_relationships(filter)

store_analysis(record)
get_analyses(target_id, filter)

get_ruleset(id)
save_ruleset(ruleset)
list_rulesets(filter)
validate_ruleset(ruleset)

get_profile(id)
save_profile(profile)
list_profiles(filter)

create_evaluation_context(payload)
evaluate(context)
rank_candidates(context, candidates)
apply_transform(transform_id, source_ids, options)
generate(strategy_id, context)
```

### Persistence

- JSON-serializable project state
- Versioned project schema
- Versioned ruleset schema
- Versioned profile schema
- Simple save/load boundary
- No UI blob format may be treated as domain authority

### Tests

Implement minimal tests for:

- Object creation
- Required fields validation
- Relationship creation
- Ruleset loading
- Ruleset validation
- Profile loading
- Evaluation classification
- Provenance tracking
- Transform registration
- Analysis lens registration
- Counterpoint assumptions blocked from Shared Core
- Serialism placeholder ruleset can load without counterpoint dependencies
- Neo-Riemannian placeholder ruleset can load without counterpoint dependencies
- Schenkerian placeholder ruleset can load without counterpoint dependencies

---

## Explicit Anti-Regression Rules

These are mandatory.

1. The core engine must not contain `species`, `cantus`, `counterpoint`, `consonance`, `dissonance`, or `against` as required concepts.
2. Counterpoint-specific files may exist only under `rulesets/counterpoint/` or tests explicitly scoped to that ruleset.
3. The default project must be empty and ruleset-neutral.
4. A new ruleset must be loadable without modifying engine code.
5. A ruleset may define its own ontology, but must conform to Shared Core contracts.
6. A profile may configure rules, but may not replace the ruleset contract.
7. Generation must ask the active ruleset how to propose, prune, rank, and validate candidates.
8. Analysis must ask the active ruleset what labels and structures mean.
9. Transform legality must come from the active ruleset.
10. Tests must prove that non-counterpoint rulesets can load and register capabilities.

---

## Do Not Do Yet

- UI (ReaImGui)
- Full orchestration
- Structural planning
- Advanced analysis
- Full counterpoint implementation
- Full serialism implementation
- Full neo-Riemannian implementation
- Full Schenkerian implementation
- Hardcoded species logic
- Private schemas in modules
- Legacy ReaFux compatibility migration
- Exercise-first workflow assumptions

---

## Deliverables

1. File structure created
2. Lua modules implemented
3. Ruleset contracts implemented
4. Placeholder rulesets created for counterpoint, serialism, neo-Riemannian, Schenkerian, and custom systems
5. Minimal tests
6. Summary of implementation
7. TODO list for next phase

---

## Success Criteria

ReaForm should have a stable, extensible foundation supporting:

- ruleset-driven generation
- ruleset-driven analysis
- ruleset-driven transformation
- material ingest
- material inspection
- material development
- profile-configured behavior
- provenance tracking
- arbitrary relationship graphs
- multiple musical/analytical systems without engine rewrites

Phase 1 succeeds only if counterpoint is clearly demoted to one ruleset among many.

Build the skeleton cleanly. Do not get clever.
