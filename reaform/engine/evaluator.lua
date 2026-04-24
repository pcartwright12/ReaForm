local RuleSet = require("reaform.core.ruleset")
local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")
local ConstraintEvaluator = require("reaform.engine.constraint_evaluator")
local StrategyDispatcher = require("reaform.engine.strategy_dispatcher")
local EvaluationContext = require("reaform.contracts.evaluation_context")
local EvaluationResult = require("reaform.contracts.evaluation_result")
local EvaluationClassifier = require("reaform.engine.evaluation_classifier")

local Evaluator = {}

function Evaluator.evaluate(ruleset, context)
    local executable = RuleSet.require_executable(ruleset, "evaluation_strategy")
    if not executable.ok then
        return executable
    end

    local checked = RuleSet.normalize(ruleset)
    if not checked.ok then
        return Result.fail(checked.errors, checked.warnings)
    end

    local context_input = context or {}
    local context_result = EvaluationContext.create({
        active_ruleset_id = checked.data.id,
        active_profile_id = context_input.active_profile_id or context_input.profile_id,
        target_object_ids = context_input.target_object_ids,
        target = context_input.target,
        relationship_scope = context_input.relationship_scope,
        operation_type = context_input.operation_type or "evaluation",
        operation_payload = context_input.operation_payload,
        analysis_scope = context_input.analysis_scope,
        generation_state = context_input.generation_state,
        user_options = context_input.user_options,
        runtime_metadata = context_input.runtime_metadata,
        raw_context = context_input,
    })
    if not context_result.ok then
        return Result.fail(context_result.errors, Result.merge_warnings(checked.warnings, context_result.warnings))
    end

    local constraint_outcomes = {}
    local merged_warnings = Result.merge_warnings(checked.warnings, context_result.warnings)

    for _, constraint in ipairs(checked.data.constraints) do
        local outcome = ConstraintEvaluator.evaluate(constraint, context_input)
        if not outcome.ok then
            return Result.fail(outcome.errors, Result.merge_warnings(merged_warnings, outcome.warnings))
        end

        constraint_outcomes[#constraint_outcomes + 1] = outcome.data
        merged_warnings = Result.merge_warnings(merged_warnings, outcome.warnings)
    end

    local dispatched = StrategyDispatcher.call(checked.data, "evaluation_strategy", {
        context = context_input,
        evaluation_context = context_result.data,
        constraints = constraint_outcomes,
    }, "evaluator.execution_error", "RuleSet evaluation_strategy raised an error.")
    if not dispatched.ok then
        return Result.fail(dispatched.errors, Result.merge_warnings(merged_warnings, dispatched.warnings))
    end

    local evaluation_payload = dispatched.data
    if type(evaluation_payload) ~= "table" then
        return Result.fail({
            Validation.error(
                "evaluator.invalid_result",
                "RuleSet evaluation_strategy must return a table.",
                "evaluation_strategy",
                { received_type = type(evaluation_payload), ruleset_id = checked.data.id }
            ),
        }, merged_warnings)
    end

    evaluation_payload.classification = EvaluationClassifier.classify(evaluation_payload)
    local normalized_result = EvaluationResult.create({
        context_id = context_result.data.id,
        ruleset_id = checked.data.id,
        profile_id = context_result.data.active_profile_id,
        classification = evaluation_payload.classification,
        findings = evaluation_payload.findings,
        score = evaluation_payload.score or 0,
        passed = evaluation_payload.passed ~= false,
        failed_rule_ids = evaluation_payload.failed_rule_ids,
        warnings = evaluation_payload.warnings,
        advisory_notices = evaluation_payload.advisory_notices,
        suggested_repairs = evaluation_payload.suggested_repairs,
        metadata = evaluation_payload.metadata or {},
    })
    if not normalized_result.ok then
        return Result.fail(normalized_result.errors, Result.merge_warnings(merged_warnings, normalized_result.warnings))
    end

    return Result.ok({
        ruleset_id = checked.data.id,
        context = context_result.data,
        constraints = constraint_outcomes,
        evaluation = normalized_result.data,
        evaluation_payload = evaluation_payload,
    }, Result.merge_warnings(merged_warnings, normalized_result.warnings))
end

return Evaluator
