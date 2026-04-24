# Architecture

## Overview

The current ReaForm repository is a small, ruleset-driven skeleton. It establishes generic contracts and shared execution flow without implementing the larger lockfile architecture yet.

Today the codebase is organized around five areas:

- `reaform/core/`: contract validation, canonical schema normalization, and in-memory registries
- `reaform/contracts/`: formal evaluation context and evaluation result contracts
- `reaform/engine/`: shared entry points plus small evaluation dispatch helpers
- `reaform/rulesets/`: domain-specific example rulesets
- `reaform/tests/`: contract and behavior coverage
- `reaform/utils/`: validation and result helpers used across the repository

## Core Contracts

### `MusicalObject`

Defined in `reaform/core/musical_object.lua`.

Current required fields:

- `id`
- `type`
- `properties`
- `relationships`

Current public interface:

- `MusicalObject.validate(candidate)`
- `MusicalObject.create(payload)`
- `MusicalObject.normalize(payload)`

This remains intentionally generic, but the repository now includes a canonical normalization layer that can map the legacy object shape onto a richer internal structure with provenance, timestamps, ruleset scope, parent and child links, and version metadata. The public legacy shape remains supported for compatibility.

### `Constraint`

Defined in `reaform/core/constraint.lua`.

Current required fields:

- `id`
- `description`
- `applicable_object_types`
- `evaluation_function`

Current public interface:

- `Constraint.validate(candidate)`
- `Constraint.evaluate(constraint, context)`

`Constraint.evaluate` validates the contract, invokes the ruleset-supplied evaluation function with `pcall`, and normalizes the result into a `Result` object containing `passed` and `metadata`.

### `Transformation`

Defined in `reaform/core/transformation.lua`.

Current required fields:

- `id`
- `input_types`
- `output_types`
- `transform_function`

Current public interface:

- `Transformation.validate(candidate)`
- `Transformation.apply(transformation, input, context)`

The shared core does not decide whether a transformation is musically valid. It only validates the contract and executes the supplied transform function.

### `RuleSet`

Defined in `reaform/core/ruleset.lua`.

Current required fields:

- `id`
- `name`
- `domain`
- `object_types`
- `constraints`
- `transformations`
- `generator_strategy`
- `evaluation_strategy`

Current public interface:

- `RuleSet.validate(candidate)`
- `RuleSet.normalize(candidate)`

`RuleSet.validate` also validates nested constraints and transformations. Unknown fields are allowed and preserved with warnings, which leaves room for future growth without forcing the current engine to know every future ruleset capability.

The repository also includes in-memory registries for:

- objects
- relationships
- analyses
- rulesets
- profiles

These are intentionally minimal and exist to establish the lockfile-aligned seams without introducing persistence or orchestration yet.

## Shared Engine Flow

### Generation

Defined in `reaform/engine/generator.lua`.

Current public interface:

- `Generator.generate(ruleset, context)`

Flow:

1. Normalize the supplied ruleset.
2. Invoke the ruleset's `generator_strategy` through a shared strategy dispatcher.
3. Return a shared `Result` wrapper containing `ruleset_id` and the generated payload.

The engine does not interpret musical semantics itself. It delegates candidate meaning to the ruleset strategy.

### Evaluation

Defined in `reaform/engine/evaluator.lua`.

Current public interface:

- `Evaluator.evaluate(ruleset, context)`

Flow:

1. Normalize the supplied ruleset.
2. Create a formal `EvaluationContext`.
3. Evaluate each ruleset constraint through a dedicated shared constraint evaluator path.
4. Invoke the ruleset's `evaluation_strategy` with the original context, formal context, and normalized constraint outcomes.
5. Normalize the output into a formal `EvaluationResult`.

This is the current proof that rulesets share engine services while still defining their own domain behavior.

## Utilities

### `Validation`

Defined in `reaform/utils/validation.lua`.

Provides:

- warning and error record constructors
- table and array checks
- deep-copy helper for plain tables

### `Result`

Defined in `reaform/utils/result.lua`.

Provides:

- `Result.ok(data, warnings)`
- `Result.fail(errors, warnings, data)`
- `Result.merge_warnings(...)`

These helpers give the current repository a consistent success and failure shape across core and engine modules.

## Rulesets

The repository currently includes these example rulesets:

- `counterpoint/species_1.lua`
- `serialism/basic_row.lua`
- `neo_riemannian/basic_triads.lua`
- `schenkerian/basic_reduction.lua`
- `custom/dummy.lua`

They are placeholders, not full implementations of those domains. Their main architectural purpose is to prove that the same shared engine can host multiple musical systems without hardcoding one of them into the core.

## Architectural Boundaries

The current repository already reinforces several important boundaries:

- Shared engine code does not define counterpoint-specific required concepts.
- Rulesets carry domain-specific types and behavior.
- Contract validation lives in shared modules, not inside individual rulesets.
- Tests check that non-counterpoint rulesets operate through the same generic entry points.

For the larger architecture that the project intends to reach, see [Status Against Lockfile](status-against-lockfile.md).
