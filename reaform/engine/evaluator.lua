local RuleSet = require("reaform.core.ruleset")
local Constraint = require("reaform.core.constraint")
local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")

local Evaluator = {}

function Evaluator.evaluate(ruleset, context)
    local checked = RuleSet.normalize(ruleset)
    if not checked.ok then
        return Result.fail(checked.errors, checked.warnings)
    end

    local constraint_outcomes = {}
    local merged_warnings = Result.merge_warnings(checked.warnings)

    for _, constraint in ipairs(checked.data.constraints) do
        local outcome = Constraint.evaluate(constraint, context or {})
        if not outcome.ok then
            return Result.fail(outcome.errors, Result.merge_warnings(merged_warnings, outcome.warnings))
        end

        constraint_outcomes[#constraint_outcomes + 1] = outcome.data
        merged_warnings = Result.merge_warnings(merged_warnings, outcome.warnings)
    end

    local ok, evaluation_result = pcall(checked.data.evaluation_strategy, {
        context = context or {},
        constraints = constraint_outcomes,
    })

    if not ok then
        return Result.fail({
            Validation.error(
                "evaluator.execution_error",
                "RuleSet evaluation_strategy raised an error.",
                "evaluation_strategy",
                { reason = evaluation_result, ruleset_id = checked.data.id }
            ),
        }, merged_warnings)
    end

    return Result.ok({
        ruleset_id = checked.data.id,
        constraints = constraint_outcomes,
        evaluation = evaluation_result,
    }, merged_warnings)
end

return Evaluator
