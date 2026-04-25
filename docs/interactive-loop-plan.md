# Interactive Loop Plan

This document reprioritizes the next development slices around a minimal interactive loop so ReaForm behavior can be directed and tested firsthand through a GUI.

The goal is not to build the full application boundary yet. The goal is to create the thinnest useful loop between:

- selecting a ruleset
- running generate/evaluate/transform actions
- inspecting the resulting objects and evaluation output
- iterating on the user experience from real interaction

## Why This Is The Current Priority

The repository now has:

- a shared core
- ruleset loading and orchestration through `main.lua`
- registries and persistence
- basic migration support for persisted project/ruleset state
- runtime tests for shared behavior

What it still does not have is a user-facing interaction loop. Without that layer, the user cannot:

- steer the experience directly
- inspect generated/evaluated results in context
- validate whether the current action model feels correct
- make informed UX decisions from firsthand use

Because of that, the next highest-value work is a minimal interactive loop rather than deeper persistence/profile migration work.

## Reprioritized Next Slices

1. Build a tiny workflow layer above `main.lua`.
2. Build a minimal REAPER GUI script on top of that workflow layer.
3. Add session state for the GUI so interactions persist across clicks.
4. After the loop exists, continue deeper persistence/profile migration work as needed.

## Slice 1: Workflow Layer Above `main.lua`

Create a small workflow or service module above `main.lua` that exposes stable user actions without leaking raw registry details into the GUI.

Suggested module location:

- `reaform/workflows/session_workflow.lua`

Suggested responsibilities:

- list rulesets
- select active ruleset
- generate
- evaluate
- apply transform
- list current objects/results

Suggested action surface:

- `list_rulesets()`
- `select_ruleset(ruleset_id_or_name)`
- `get_active_ruleset()`
- `generate(context)`
- `evaluate(context)`
- `list_transforms()`
- `apply_transform(transform_id, input, context)`
- `list_objects()`
- `get_last_generated_object()`
- `get_last_evaluation()`
- `get_last_error()`

Design constraints:

- keep GUI-facing calls stable and narrow
- use `main.lua` for orchestration instead of bypassing it
- return `Result`-shaped responses consistently
- avoid embedding REAPER GUI code into the workflow layer

Acceptance criteria:

- GUI code can perform the main user actions without direct registry manipulation
- active ruleset selection is centralized in one workflow/controller boundary
- last action outputs are queryable for display

Current status:

- implemented in `reaform/workflows/session_workflow.lua`
- includes active ruleset selection, generate/evaluate/transform actions, object listing, last result capture, and session snapshots

## Slice 2: Minimal REAPER GUI Script

Create a minimal REAPER-hosted GUI script that exercises the workflow layer rather than calling rulesets directly.

Suggested entry script:

- `reaper/gui_main.lua`

First screen should only include:

- ruleset selector
- generate button
- evaluate button
- transform selector/button
- output panel for generated object, evaluation result, and errors

Initial UX goal:

- pick a ruleset
- click generate
- inspect generated material
- click evaluate
- inspect evaluation result
- choose and apply a transform
- inspect the updated output and any errors

Design constraints:

- keep the first screen intentionally small
- favor inspectability over visual polish
- show raw but readable structured results before designing richer presentation
- make errors visible in the same output area rather than hiding them

Acceptance criteria:

- user can complete one generate/evaluate/transform loop from the GUI
- current active ruleset is visible
- last result or last error is always visible after an action

Current status:

- implemented in `reaper/gui_main.lua`
- includes ruleset cycling, generate/evaluate actions, transform cycling/application, and an output panel for results/errors

## Slice 3: Session State For The GUI

Add a small in-memory controller so the GUI remembers the current session between interactions.

Minimum remembered state:

- active ruleset
- last generated object
- last evaluation
- available transforms for current ruleset

Suggested ownership:

- session state should live in the workflow/controller layer, not directly in UI widgets

Suggested controller responsibilities:

- initialize default ruleset list
- update active ruleset selection
- cache outputs from generate/evaluate/transform actions
- provide a read-only snapshot for GUI rendering

Acceptance criteria:

- user does not lose the last generated object after clicking evaluate
- transform choices update when the active ruleset changes
- GUI redraws are driven from controller state, not recomputation on every paint

Current status:

- implemented at the workflow/controller layer for active ruleset, last generated object, last evaluation, last error, and available transforms

## Suggested Build Order

1. Implement the workflow/controller module with tests.
2. Implement a minimal REAPER GUI script that can render and trigger the workflow actions.
3. Add session-state-backed output display and transform availability updates.
4. Iterate on UX after firsthand testing.
5. Resume deeper persistence/profile migration work after the interaction loop exists.

Updated progress:

1. Workflow/controller module with tests: complete
2. Minimal REAPER GUI script: complete
3. Session-state-backed output and transform availability updates: partially complete through the workflow/controller plus first GUI output panel
4. Next priority: iterate on UX after firsthand testing

## Testing Expectations

Before the GUI exists:

- add tests for the workflow/controller action surface
- verify ruleset selection, generate, evaluate, and transform behavior through the workflow layer
- verify session state updates after each action

After the GUI exists:

- perform manual REAPER-hosted smoke tests for the main loop
- confirm that visible output changes after each action
- confirm error states remain inspectable

## Out Of Scope For The First GUI Slice

The first interactive loop should not try to solve:

- full project management UX
- advanced layout or theme polish
- persistence editing UX
- multi-window workflows
- deep analysis visualization
- full profile editing

The target is a thin but usable loop for directing UX and testing results firsthand.
