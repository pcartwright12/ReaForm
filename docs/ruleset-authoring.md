# Ruleset Authoring

## Purpose

This repository is organized around the idea that a ruleset supplies domain-specific musical meaning while the shared core and engine stay generic. A ruleset can describe counterpoint, serialism, neo-Riemannian transformations, or a custom domain without requiring the engine to hardcode those concepts.

## Current Packaging Shape

Each ruleset family now has a directory-level wrapper module:

- `reaform/rulesets/counterpoint/ruleset.lua`
- `reaform/rulesets/serialism/ruleset.lua`
- `reaform/rulesets/neo_riemannian/ruleset.lua`
- `reaform/rulesets/schenkerian/ruleset.lua`
- `reaform/rulesets/custom/ruleset.lua`

These wrappers currently forward to one placeholder implementation file inside the same directory. New work should prefer the directory-level wrapper as the stable load path.

The top-level repository entry surface in `main.lua` can also load these by family name through `ReaForm.load_ruleset(...)`, register them through `ReaForm.register_ruleset(...)`, or execute them through `ReaForm.generate(...)` and `ReaForm.evaluate(...)`.

## Current RuleSet Shape

Rulesets are plain Lua tables validated by `reaform/core/ruleset.lua`.

Required fields today:

- `id`
- `name`
- `domain`
- `object_types`
- `constraints`
- `transformations`
- `generator_strategy`
- `evaluation_strategy`

Unknown fields are allowed and preserved with warnings. That makes the current ruleset contract forward-compatible with planned expansion, but the repository now also validates several optional fields more strictly when they are present:

- `analysis_lenses` must be an array of tables with non-empty `id` values
- `validation_modes` and `supported_relationship_types` must be string arrays when provided
- `ontology` and `generation_strategies` must be tables when provided
- version fields must remain positive numbers

## Constraint Shape

Each entry in `constraints` must contain:

- `id`
- `description`
- `applicable_object_types`
- `evaluation_function`

The shared evaluator runs constraints through `Constraint.evaluate`, which expects the `evaluation_function` to return a table. In current practice that table usually includes:

- `passed`
- `metadata`
- optional `warnings`

## Transformation Shape

Each entry in `transformations` must contain:

- `id`
- `input_types`
- `output_types`
- `transform_function`

The shared transformation path validates the transformation contract and then executes the supplied function. The function is expected to return:

1. the transformed output object
2. optional metadata

## Strategy Hooks

### `generator_strategy`

`Generator.generate(ruleset, context)` calls the ruleset's `generator_strategy(context)`.

The generator can return any object shape, but the current rulesets return objects that match the existing `MusicalObject` structure:

- `id`
- `type`
- `properties`
- `relationships`

### `evaluation_strategy`

`Evaluator.evaluate(ruleset, context)` calls the ruleset's `evaluation_strategy(payload)`.

The payload currently contains:

- `context`
- `constraints`

`constraints` is the list of normalized constraint outcomes gathered through the shared constraint pipeline.

## Current Example Rulesets

### Counterpoint

`reaform/rulesets/counterpoint/ruleset.lua`

Demonstrates that counterpoint-specific object types and logic can live inside a ruleset while still using the shared generator and evaluator.

### Serialism

`reaform/rulesets/serialism/ruleset.lua`

Demonstrates a non-counterpoint ruleset with:

- a `ToneRow` object type
- a row-length constraint
- retrograde and inversion transformations

### Neo-Riemannian

`reaform/rulesets/neo_riemannian/ruleset.lua`

Demonstrates a transformational ruleset with:

- a `Triad` object type
- a quality-validity constraint
- `P`, `L`, and `R` style transformations

### Schenkerian

`reaform/rulesets/schenkerian/ruleset.lua`

Demonstrates a non-counterpoint analytical ruleset loading through the same wrapper model.

### Custom

`reaform/rulesets/custom/ruleset.lua`

Demonstrates the smallest pluggability case: a new ruleset can generate and evaluate through shared APIs without changing the engine.

## Authoring Guidance

- Keep generic concepts in shared modules and domain-specific meaning inside the ruleset.
- Do not introduce counterpoint-first terminology into the shared engine or utilities.
- Use `object_types` to declare domain-specific object names, but do not assume the core already knows their semantics.
- Return stable, predictable shapes from generator and transformation functions.
- Prefer ruleset-local terminology such as `ToneRow` or `Triad` only inside that ruleset and its tests.

## Current Limitations

Compared with the lockfile target, ruleset authoring is still missing:

- profiles
- analysis lenses
- scoring models
- validation modes
- serialization versions
- persistence-backed registry-based loading
- first-class rule, analysis, and generation contract modules

The repository now includes formal evaluation context/result contracts, a minimal ruleset registry boundary, directory-level wrapper modules, and a small `main.lua` orchestration surface, but rulesets are still simple module tables rather than the full capability-declaration system described in the spec.

Profiles are also validated more strictly than before: rules and constraints must be arrays when provided, profile setting blocks must be tables, and version/name data must be well-formed instead of being silently normalized away.

Persisted-only imported rulesets are now treated as a first-class non-executable state rather than failing only because hooks are missing. If a ruleset is restored from metadata without live `generator_strategy` and `evaluation_strategy` hooks, shared execution surfaces reject it with an explicit `ruleset.not_executable` error. Persisted-only transforms behave the same way with `transformation.not_executable`.
