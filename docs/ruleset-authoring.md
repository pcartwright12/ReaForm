# Ruleset Authoring

## Purpose

This repository is organized around the idea that a ruleset supplies domain-specific musical meaning while the shared core and engine stay generic. A ruleset can describe counterpoint, serialism, neo-Riemannian transformations, or a custom domain without requiring the engine to hardcode those concepts.

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

Unknown fields are allowed and preserved with warnings. That makes the current ruleset contract forward-compatible with planned expansion, but only the fields above are enforced today.

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

`reaform/rulesets/counterpoint/species_1.lua`

Demonstrates that counterpoint-specific object types and logic can live inside a ruleset while still using the shared generator and evaluator.

### Serialism

`reaform/rulesets/serialism/basic_row.lua`

Demonstrates a non-counterpoint ruleset with:

- a `ToneRow` object type
- a row-length constraint
- retrograde and inversion transformations

### Neo-Riemannian

`reaform/rulesets/neo_riemannian/basic_triads.lua`

Demonstrates a transformational ruleset with:

- a `Triad` object type
- a quality-validity constraint
- `P`, `L`, and `R` style transformations

### Custom

`reaform/rulesets/custom/dummy.lua`

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
- registry-based loading
- formal evaluation context and evaluation result contracts
- first-class rule, analysis, and generation contract modules

That means rulesets today are simple module tables, not yet the full capability-declaration system described in the spec.
