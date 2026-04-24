# Architecture

## Overview

The current ReaForm repository is a small, ruleset-driven skeleton. It establishes generic contracts and shared execution flow without implementing the larger lockfile architecture yet.

Today the codebase is organized around five areas:

- `reaform/core/`: contract validation and normalization for core domain objects
- `reaform/engine/`: shared entry points for generation and evaluation
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

This is intentionally generic, but it is much smaller than the canonical object schema described in the lockfile. Fields such as provenance, timestamps, ruleset scope, analyses, parent and child links, and version metadata are not implemented yet.

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

## Shared Engine Flow

### Generation

Defined in `reaform/engine/generator.lua`.

Current public interface:

- `Generator.generate(ruleset, context)`

Flow:

1. Normalize the supplied ruleset.
2. Invoke the ruleset's `generator_strategy`.
3. Return a shared `Result` wrapper containing `ruleset_id` and the generated payload.

The engine does not interpret musical semantics itself. It delegates candidate meaning to the ruleset strategy.

### Evaluation

Defined in `reaform/engine/evaluator.lua`.

Current public interface:

- `Evaluator.evaluate(ruleset, context)`

Flow:

1. Normalize the supplied ruleset.
2. Evaluate each ruleset constraint through the shared `Constraint.evaluate` path.
3. Invoke the ruleset's `evaluation_strategy` with the original context and normalized constraint outcomes.
4. Return a shared `Result` wrapper containing `ruleset_id`, constraint outcomes, and evaluation output.

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
- `custom/dummy.lua`

They are placeholders, not full implementations of those domains. Their main architectural purpose is to prove that the same shared engine can host multiple musical systems without hardcoding one of them into the core.

## Architectural Boundaries

The current repository already reinforces several important boundaries:

- Shared engine code does not define counterpoint-specific required concepts.
- Rulesets carry domain-specific types and behavior.
- Contract validation lives in shared modules, not inside individual rulesets.
- Tests check that non-counterpoint rulesets operate through the same generic entry points.

For the larger architecture that the project intends to reach, see [Status Against Lockfile](status-against-lockfile.md).
