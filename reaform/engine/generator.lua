local RuleSet = require("reaform.core.ruleset")
local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")

local Generator = {}

function Generator.generate(ruleset, context)
    local checked = RuleSet.normalize(ruleset)
    if not checked.ok then
        return Result.fail(checked.errors, checked.warnings)
    end

    local ok, generated = pcall(checked.data.generator_strategy, context or {})
    if not ok then
        return Result.fail({
            Validation.error(
                "generator.execution_error",
                "RuleSet generator_strategy raised an error.",
                "generator_strategy",
                { reason = generated, ruleset_id = checked.data.id }
            ),
        }, checked.warnings)
    end

    return Result.ok({
        ruleset_id = checked.data.id,
        generated = generated,
    }, checked.warnings)
end

return Generator
