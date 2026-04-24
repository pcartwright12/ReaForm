# ReaForm Development Log

## 2026-04-24T07:26:22-05:00

- Files changed: none
- Summary of change: completed repository review across README, architecture/status/authoring/testing docs, core modules, engine modules, rulesets, and tests; confirmed the documented `lua reaform/tests/runner.lua` command is the intended validation entry point.
- Validation command run: `lua reaform/tests/runner.lua`
- Result: failed at shell boundary because `lua` is not installed or not available on `PATH` in this environment.
- Status:
  - [x] Repository review completed.
  - [x] Validation entry point identified.
  - [ ] Runtime validation unblocked.
- Outstanding:
  - [ ] Install or expose a Lua interpreter on `PATH`.
  - [ ] Run the repository test runner successfully.
- Next step:
  - [x] Implement compatibility seams, minimal registries, formal evaluation contracts, and expanded tests while documenting the blocker.

## 2026-04-24T07:40:00-05:00

- Files changed:
  - `reaform/core/ids.lua`
  - `reaform/core/schemas.lua`
  - `reaform/core/object_registry.lua`
  - `reaform/core/relationship_graph.lua`
  - `reaform/core/analysis_registry.lua`
  - `reaform/core/ruleset_registry.lua`
  - `reaform/core/profile_registry.lua`
  - `reaform/core/musical_object.lua`
  - `reaform/core/ruleset.lua`
  - `reaform/contracts/evaluation_context.lua`
  - `reaform/contracts/evaluation_result.lua`
  - `reaform/engine/evaluation_classifier.lua`
  - `reaform/engine/constraint_evaluator.lua`
  - `reaform/engine/strategy_dispatcher.lua`
  - `reaform/engine/generator.lua`
  - `reaform/engine/evaluator.lua`
  - `reaform/rulesets/schenkerian/basic_reduction.lua`
  - `reaform/tests/test_foundation.lua`
  - `reaform/tests/runner.lua`
  - `README.md`
  - `docs/architecture.md`
  - `docs/status-against-lockfile.md`
  - `docs/ruleset-authoring.md`
  - `docs/testing-and-contributing.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: added compatibility-oriented canonical schema normalization, minimal in-memory registries, formal evaluation context/result contracts, shared evaluator/generator dispatch seams, the missing Schenkerian placeholder ruleset, a new foundation test suite, and updated current-state documentation.
- Validation command run: `rg -n "EvaluationContext|EvaluationResult|ObjectRegistry|RuleSetRegistry|ProfileRegistry|schenkerian" reaform README.md docs`
- Result: passed; confirmed new modules, tests, ruleset, and docs are wired into the repository.
- Status:
  - [x] Canonical schema normalization added.
  - [x] In-memory registries added.
  - [x] Formal evaluation context/result contracts added.
  - [x] Shared evaluator/generator dispatch seams added.
  - [x] Schenkerian placeholder ruleset added.
  - [x] Foundation test suite added.
  - [x] Current-state docs updated.
  - [ ] Runtime Lua test suite executed.
- Outstanding:
  - [ ] Verify syntax/runtime correctness with the Lua test runner.
  - [ ] Record final command-discovery evidence for the runtime blocker.
- Next step:
  - [x] Perform final static sanity checks, then re-run command-discovery evidence and record the final blocker state.

## 2026-04-24T07:44:00-05:00

- Files changed:
  - `README.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: recorded final static verification results and clarified the runner coverage in the README.
- Validation command run: `rg -n "cantus|species|counterpoint|consonance|dissonance|against" reaform/core reaform/engine`
- Result: passed with no matches in shared core or engine code.
- Status:
  - [x] Shared-layer banned-term scan completed.
  - [x] Shared core and engine remained ruleset-generic in the static scan.
  - [ ] Lua runtime available in shell environment.
- Outstanding:
  - [ ] Install or expose a Lua interpreter.
  - [ ] Run `lua reaform/tests/runner.lua`.
- Next step:
  - [ ] Install or expose a Lua interpreter and run `lua reaform/tests/runner.lua`.

## 2026-04-24T07:44:10-05:00

- Files changed:
  - `DEVELOPMENT_LOG.md`
- Summary of change: recorded runtime command-discovery evidence after implementation.
- Validation command run: PowerShell `Get-Command` scan for `lua`, `luajit`, `lua54`, `lua53`, and `lua52`
- Result: passed; confirmed `lua-not-found`.
- Status:
  - [x] Command-discovery scan completed.
  - [x] Missing Lua runtime confirmed.
  - [ ] Repository runtime tests executed.
- Outstanding:
  - [ ] Make any supported Lua interpreter available in the shell.
  - [ ] Rerun the repository test runner immediately after Lua becomes available.
- Next step:
  - [ ] Rerun the repository test runner immediately after Lua becomes available.

## 2026-04-24T07:46:01.0209812-05:00

- Files changed:
  - `.github/copilot-instructions.md`
  - `docs/testing-and-contributing.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: added a mandatory policy requiring AI-driven repository edits to update both `DEVELOPMENT_PLAN.md` and `DEVELOPMENT_LOG.md` in the same change set, and added matching contributor workflow guidance.
- Validation command run: PowerShell `Select-String` over `.github/copilot-instructions.md`, `docs/testing-and-contributing.md`, and `DEVELOPMENT_PLAN.md` for policy headings.
- Result: passed; confirmed policy entries exist in all expected files.
- Status:
  - [x] Repository-level AI instruction added.
  - [x] Contributor workflow rule added.
  - [x] Development plan updated with policy task.
  - [x] Development log updated with policy rollout.
- Outstanding:
  - [ ] Enforce this policy in PR review/checklist process if stricter automation is desired.
- Next step:
  - [ ] Optionally add a CI or pre-commit check that verifies both tracking files are modified whenever repository files change.

## 2026-04-24T08:19:32.4440987-05:00

- Files changed:
  - `reaform/core/schemas.lua`
  - `reaform/core/analysis_registry.lua`
  - `reaform/core/relationship_graph.lua`
  - `reaform/core/ruleset.lua`
  - `reaform/core/ruleset_registry.lua`
  - `reaform/core/transform_registry.lua`
  - `reaform/core/persistence.lua`
  - `reaform/rulesets/counterpoint/species_1.lua`
  - `reaform/rulesets/serialism/basic_row.lua`
  - `reaform/rulesets/neo_riemannian/basic_triads.lua`
  - `reaform/rulesets/schenkerian/basic_reduction.lua`
  - `reaform/rulesets/custom/dummy.lua`
  - `reaform/tests/test_foundation.lua`
  - `reaform/tests/runner.lua`
  - `README.md`
  - `docs/status-against-lockfile.md`
  - `docs/testing-and-contributing.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: added transform registration and analysis-lens registration seams, introduced JSON-safe persistence helpers for project/ruleset/profile state, annotated placeholder rulesets with module paths and analysis lenses, expanded foundation tests for persistence round-trips, and fixed a Lua 5.4 runner bug where the last `require(...)` in the suite list expanded an extra return value into a bogus fourth suite entry.
- Validation command run: `.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua`
- Result: passed; all three suites ran successfully with 23 total tests.
- Status:
  - [x] Workspace-local Lua 5.4 runtime downloaded and used for validation.
  - [x] Transform registration seams added.
  - [x] Analysis-lens registration seams added.
  - [x] JSON-safe persistence helpers added.
  - [x] Persistence and registration coverage added to the foundation suite.
  - [x] Runtime runner bug fixed for Lua 5.4.
- Outstanding:
  - [ ] Add restoration/import helpers if saved project state should repopulate registries instead of only round-tripping as persisted data.
  - [ ] Tighten schema validation and broader packaging work from the remaining plan items.
- Next step:
  - [ ] Continue with `main.lua` and/or ruleset packaging and restoration work.

## 2026-04-24T08:19:32.4440987-05:00 (follow-up)

- Files changed:
  - `.gitignore`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: formalized the workspace-local Lua runtime as an ignored local convenience by adding `.tools/` and transient persistence-test artifacts to `.gitignore`, which keeps runtime validation local without turning the downloaded interpreter into a repository dependency.
- Validation command run: `git status --short`
- Result: passed; `.tools/` no longer appears as an untracked repository change after adding ignore rules.
- Status:
  - [x] Local Lua runtime policy decided.
  - [x] Workspace-local tooling ignored from source control.
- Outstanding:
  - [ ] Add restoration/import helpers if saved project state should repopulate registries instead of only round-tripping as persisted data.
  - [ ] Tighten schema validation and broader packaging work from the remaining plan items.
- Next step:
  - [ ] Continue with `main.lua` and/or ruleset packaging and restoration work.

## 2026-04-24T11:06:15.1735792-05:00

- Files changed:
  - `reaform/core/ruleset_registry.lua`
  - `reaform/core/transform_registry.lua`
  - `reaform/core/persistence.lua`
  - `reaform/tests/test_foundation.lua`
  - `README.md`
  - `docs/status-against-lockfile.md`
  - `docs/testing-and-contributing.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: added project-state import into live registries, including executable ruleset restoration through `module_path` when available and persisted-only fallback import paths for rulesets and transforms when executable hooks are absent; expanded the foundation suite to verify both live-module restore and persisted-only metadata restore behavior.
- Validation command run: `.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua`
- Result: passed; all three suites ran successfully with 25 total tests.
- Status:
  - [x] Project-state import added.
  - [x] Executable ruleset restoration from persisted `module_path` added.
  - [x] Persisted-only fallback import for rulesets/transforms added.
  - [x] Restore/import coverage added to the foundation suite.
- Outstanding:
  - [ ] Decide whether persisted-only imported rulesets need a formal non-executable state marker/API beyond warning-based metadata import.
  - [ ] Tighten schema validation and broader packaging work from the remaining plan items.
- Next step:
  - [ ] Continue with `main.lua` and/or ruleset packaging work, then revisit migration notes and persisted-only ruleset ergonomics.

## 2026-04-24T11:06:15.1735792-05:00 (packaging follow-up)

- Files changed:
  - `main.lua`
  - `reaform/rulesets/counterpoint/ruleset.lua`
  - `reaform/rulesets/serialism/ruleset.lua`
  - `reaform/rulesets/neo_riemannian/ruleset.lua`
  - `reaform/rulesets/schenkerian/ruleset.lua`
  - `reaform/rulesets/custom/ruleset.lua`
  - `reaform/rulesets/counterpoint/species_1.lua`
  - `reaform/rulesets/serialism/basic_row.lua`
  - `reaform/rulesets/neo_riemannian/basic_triads.lua`
  - `reaform/rulesets/schenkerian/basic_reduction.lua`
  - `reaform/rulesets/custom/dummy.lua`
  - `reaform/tests/test_behavior.lua`
  - `reaform/tests/test_foundation.lua`
  - `README.md`
  - `docs/architecture.md`
  - `docs/ruleset-authoring.md`
  - `docs/status-against-lockfile.md`
  - `docs/testing-and-contributing.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: added a small top-level `main.lua` entry surface, introduced directory-level `ruleset.lua` wrappers for the placeholder ruleset families, switched placeholder `module_path` values to the wrapper-based load paths, updated tests to exercise `main.lua` loading/registration, and refreshed repository docs to describe the new packaging boundary.
- Validation command run: `.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua`
- Result: passed; all three suites ran successfully with 27 total tests.
- Status:
  - [x] Top-level `main.lua` entry surface added.
  - [x] Directory-level ruleset wrapper modules added.
  - [x] Ruleset persistence now points at wrapper-based `module_path` values.
  - [x] Packaging entry points covered in runtime tests.
- Outstanding:
  - [ ] Decide whether the new `main.lua` surface should stay as a thin loader or start absorbing more lockfile-facing application wiring.
  - [ ] Tighten schema validation and persisted-only ruleset ergonomics from the remaining plan items.
- Next step:
  - [ ] Revisit schema validation and the non-executable persisted-ruleset API, then decide how much more responsibility `main.lua` should own.

## 2026-04-24T13:43:36.9793428-05:00

- Files changed:
  - `reaform/core/schemas.lua`
  - `reaform/tests/test_contracts.lua`
  - `README.md`
  - `docs/ruleset-authoring.md`
  - `docs/testing-and-contributing.md`
  - `docs/status-against-lockfile.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: tightened ruleset/profile schema validation beyond normalization defaults by rejecting malformed optional arrays, malformed settings tables, invalid version/module-path values, and malformed analysis-lens entries; added contract tests covering those failure cases and fixed the empty-JSON-object edge case so persisted profile/settings tables still round-trip through restore/import.
- Validation command run: `.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua`
- Result: passed; all three suites ran successfully with 31 total tests.
- Status:
  - [x] Ruleset/profile schema validation tightened.
  - [x] Contract tests added for malformed optional schema fields.
  - [x] Persistence round-trip compatibility preserved for empty JSON object settings.
- Outstanding:
  - [ ] Decide whether persisted-only imported rulesets should gain a formal non-executable state marker/API beyond warning-based metadata import.
  - [ ] Decide whether the new `main.lua` surface should stay as a thin loader or start absorbing more lockfile-facing application wiring.
- Next step:
  - [ ] Revisit the persisted-only ruleset API and the ownership boundary of `main.lua`.

## 2026-04-24T14:08:37.9036356-05:00

- Files changed:
  - `reaform/core/ruleset.lua`
  - `reaform/core/ruleset_registry.lua`
  - `reaform/core/transform_registry.lua`
  - `reaform/core/transformation.lua`
  - `reaform/core/persistence.lua`
  - `reaform/engine/generator.lua`
  - `reaform/engine/evaluator.lua`
  - `main.lua`
  - `reaform/tests/test_behavior.lua`
  - `reaform/tests/test_foundation.lua`
  - `README.md`
  - `docs/ruleset-authoring.md`
  - `docs/testing-and-contributing.md`
  - `docs/status-against-lockfile.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: formalized persisted-only imported rulesets and transforms as a first-class non-executable state, added registry and top-level inspection helpers for execution status, and changed generation/evaluation/transformation execution paths to fail with explicit `ruleset.not_executable` and `transformation.not_executable` errors instead of generic missing-hook failures.
- Validation command run: `.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua`
- Result: passed; all three suites ran successfully with 31 total tests.
- Status:
  - [x] Persisted-only ruleset non-executable state/API added.
  - [x] Persisted-only transform non-executable state/API added.
  - [x] Clear runtime failures added for non-executable metadata-only artifacts.
  - [x] Execution-state inspection exposed through registries and `main.lua`.
- Outstanding:
  - [ ] Decide whether the new `main.lua` surface should stay as a thin loader or start absorbing more lockfile-facing application wiring.
  - [ ] Continue reconciling any remaining doc/code drift and future migration notes.
- Next step:
  - [ ] Decide how much more responsibility `main.lua` should own.

## 2026-04-24T14:15:56.1285070-05:00

- Files changed:
  - `main.lua`
  - `reaform/tests/test_behavior.lua`
  - `reaform/tests/test_foundation.lua`
  - `README.md`
  - `docs/architecture.md`
  - `docs/ruleset-authoring.md`
  - `docs/status-against-lockfile.md`
  - `docs/testing-and-contributing.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: expanded `main.lua` from a thin loader into a small orchestration facade that can reset repository state, bootstrap built-in rulesets, resolve rulesets and transforms, import/export project snapshots, and run shared generate/evaluate/transform flows from one top-level surface; added runtime tests for the new orchestration helpers and updated docs to describe the new boundary.
- Validation command run: `.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua`
- Result: passed; all three suites ran successfully with 33 total tests.
- Status:
  - [x] `main.lua` ownership boundary decided in favor of a small orchestration facade.
  - [x] Top-level reset/bootstrap/resolve/import/export/run helpers added.
  - [x] Runtime coverage added for the new top-level orchestration surface.
- Outstanding:
  - [ ] Add migration notes.
  - [ ] Continue reconciling any remaining doc/code drift.
- Next step:
  - [ ] Add migration notes and clarify the persistence-version evolution story.

## 2026-04-24T15:48:48.4944937-05:00

- Files changed:
  - `main.lua`
  - `reaform/tests/runner.lua`
  - `README.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: fixed top-level Lua module loading so `main.lua` and the test runner prepend script-relative package paths instead of assuming the host process working directory is the repository root, which makes REAPER-hosted execution work without manual cwd setup.
- Validation command run: `.\.tools\lua-5.4.0\lua54.exe reaform/tests/runner.lua`
- Result: passed; all three suites ran successfully with 33 total tests.
- Status:
  - [x] Script-relative module loading added for `main.lua`.
  - [x] Script-relative module loading added for the test runner.
  - [x] REAPER-style non-repository cwd execution path handled at the top-level script boundary.
- Outstanding:
  - [ ] Add migration notes.
  - [ ] Continue reconciling any remaining doc/code drift.
- Next step:
  - [ ] Add migration notes and clarify the persistence-version evolution story.

## 2026-04-24T15:58:00-05:00

- Files changed:
  - `docs/persistence-migration.md`
  - `README.md`
  - `docs/status-against-lockfile.md`
  - `docs/testing-and-contributing.md`
  - `DEVELOPMENT_PLAN.md`
  - `DEVELOPMENT_LOG.md`
- Summary of change: added explicit persistence migration notes covering current version fields, current non-migrating runtime behavior, intended reject-vs-migrate policy, suggested future migration module layout, and testing expectations; updated repository docs and planning artifacts to treat migration notes as complete while leaving migration implementation itself as the next persistence slice.
- Validation command run: `rg -n "migration|schema_version|serialization_version" README.md docs DEVELOPMENT_PLAN.md DEVELOPMENT_LOG.md`
- Result: passed; confirmed the new migration-notes document and aligned references across the repository docs and planning files.
- Status:
  - [x] Persistence migration notes documented.
  - [x] Current non-migrating runtime behavior documented explicitly.
  - [x] Future reject-vs-migrate policy documented for project, ruleset, and profile state.
- Outstanding:
  - [ ] Implement version-aware persistence migration dispatch and rejection rules.
  - [ ] Continue reconciling any remaining doc/code drift.
- Next step:
  - [ ] Implement version-aware persistence migration dispatch and unsupported-version rejection behavior.
