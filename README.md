# ReaForm

ReaForm is an early Lua foundation for a ruleset-driven music system. The current repository implements a small core of generic contracts, shared engine entry points, placeholder rulesets, and tests that demonstrate the project is not counterpoint-first.

This repository does not yet match the full architecture described in the project lockfile. It is a smaller implementation that establishes the direction: the engine stays generic, and each ruleset defines its own musical meaning.

## Current Status

Implemented today:

- Generic core contracts for `MusicalObject`, `Constraint`, `Transformation`, and `RuleSet`
- Shared engine entry points for generation and evaluation
- Placeholder rulesets for counterpoint, serialism, neo-Riemannian work, and custom extensions
- A small test suite proving cross-ruleset behavior through shared APIs

Not implemented yet:

- The full registry-heavy architecture from the lockfile
- Profiles, persistence, relationship graphs, formal evaluation context/result objects, and broader engine services
- UI, orchestration, and advanced generation or analysis workflows

## Repository Layout

```text
reaform/
  core/       core contracts and validation entry points
  engine/     generic generation and evaluation entry points
  rulesets/   placeholder domain-specific rulesets
  tests/      lightweight contract and behavior tests
  utils/      shared validation and result helpers
```

## Running Tests

From the repository root:

```powershell
lua reaform/tests/runner.lua
```

The test runner executes the contract suite and the cross-ruleset behavior suite.

## Documentation

- [Architecture](docs/architecture.md)
- [Status Against Lockfile](docs/status-against-lockfile.md)
- [Ruleset Authoring](docs/ruleset-authoring.md)
- [Testing and Contributing](docs/testing-and-contributing.md)
- [Glossary](docs/glossary.md)

## Project Direction

The governing idea is simple: ReaForm is ruleset-driven. The shared engine does not define what counts as a line, row, triad, or valid transformation. Those meanings come from the active ruleset.

Counterpoint is intentionally only one ruleset among several examples in this repository. Its presence should not shape generic engine concepts, public terminology, or future shared-core contracts.
