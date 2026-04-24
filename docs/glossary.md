# Glossary

## RuleSet

A Lua module table that defines domain-specific behavior for a musical system. In the current repository, a ruleset declares object types, constraints, transformations, and generator and evaluation strategies.

## MusicalObject

The current generic object contract used by the repository. Today it contains only `id`, `type`, `properties`, and `relationships`. This is smaller than the canonical object schema described in the lockfile.

## Constraint

A ruleset-supplied condition evaluated through shared core code. Constraints currently declare the object types they apply to and provide an `evaluation_function`.

## Transformation

A ruleset-supplied operation that maps one object to another. The shared core validates the transformation contract and executes the transform function, but it does not define domain legality on its own.

## Generator Strategy

A ruleset hook used by `Generator.generate` to produce a candidate object or structure for that ruleset's domain.

## Evaluation Strategy

A ruleset hook used by `Evaluator.evaluate` after shared constraint execution. It receives the current context and normalized constraint outcomes and decides the evaluation result for the ruleset.

## Result

The common success and failure wrapper returned by the current shared modules. It carries `ok`, `data`, `errors`, and `warnings`.

## Ruleset-Driven

The project principle that the engine stays generic and the active ruleset defines musical meaning. ReaForm should not assume that all work is counterpoint, serialism, triadic transformation, or any other single domain.

## Lockfile Target

The broader intended architecture described in `C:/Users/pccar/Downloads/ReaForm_Lockfile.md`. The current repository only implements part of that target, so contributors should distinguish between present behavior and future design goals.
