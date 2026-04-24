local RuleSet = require("reaform.core.ruleset")
local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")
local StrategyDispatcher = require("reaform.engine.strategy_dispatcher")
local MusicalObject = require("reaform.core.musical_object")

local Generator = {}

function Generator.generate(ruleset, context)
    local executable = RuleSet.require_executable(ruleset, "generator_strategy")
    if not executable.ok then
        return executable
    end

    local checked = RuleSet.normalize(ruleset)
    if not checked.ok then
        return Result.fail(checked.errors, checked.warnings)
    end

    local dispatched = StrategyDispatcher.call(
        checked.data,
        "generator_strategy",
        context or {},
        "generator.execution_error",
        "RuleSet generator_strategy raised an error."
    )
    if not dispatched.ok then
        return Result.fail(dispatched.errors, Result.merge_warnings(checked.warnings, dispatched.warnings))
    end

    local generated = dispatched.data
    local object_check = MusicalObject.validate(generated)
    if object_check.ok then
        generated = object_check.data
    end

    return Result.ok({
        ruleset_id = checked.data.id,
        generated = generated,
    }, checked.warnings)
end

return Generator
