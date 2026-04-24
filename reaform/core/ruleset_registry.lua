local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local RuleSet = require("reaform.core.ruleset")
local TransformRegistry = require("reaform.core.transform_registry")
local AnalysisRegistry = require("reaform.core.analysis_registry")

local RuleSetRegistry = {
    _rulesets = {},
}

function RuleSetRegistry.reset()
    RuleSetRegistry._rulesets = {}
end

function RuleSetRegistry.save_ruleset(ruleset)
    local normalized = RuleSet.normalize(ruleset)
    if not normalized.ok then
        return normalized
    end

    local stored_ruleset = Validation.copy_table(normalized.data)
    stored_ruleset.execution_state = "executable"
    stored_ruleset.execution_error = nil
    RuleSetRegistry._rulesets[stored_ruleset.id] = stored_ruleset
    local transform_result = TransformRegistry.register_ruleset_transforms(normalized.data)
    if not transform_result.ok then
        return transform_result
    end

    local lens_result = AnalysisRegistry.register_ruleset_lenses(normalized.data)
    if not lens_result.ok then
        return lens_result
    end

    return Result.ok(
        Validation.copy_table(stored_ruleset),
        Result.merge_warnings(normalized.warnings, transform_result.warnings, lens_result.warnings)
    )
end

function RuleSetRegistry.import_ruleset_state(ruleset_state)
    if not Validation.is_table(ruleset_state) then
        return Result.fail({
            Validation.error("ruleset.invalid_state", "Persisted RuleSet state must be a table.", nil, nil),
        })
    end

    if not Validation.is_non_empty_string(ruleset_state.id) then
        return Result.fail({
            Validation.error("ruleset.invalid_state_id", "Persisted RuleSet id is required.", "id", nil),
        })
    end

    local stored = Validation.copy_table(ruleset_state)
    stored.execution_state = stored.execution_state or "persisted_metadata"
    stored.execution_error = stored.execution_error or "missing_live_hooks"
    RuleSetRegistry._rulesets[stored.id] = stored

    local warnings = {}
    if type(stored.generator_strategy) ~= "function" or type(stored.evaluation_strategy) ~= "function" then
        warnings[#warnings + 1] = Validation.warning(
            "ruleset.imported_without_executable_hooks",
            "Persisted RuleSet state was imported without executable hooks.",
            "module_path",
            { ruleset_id = stored.id }
        )
    end

    return Result.ok(Validation.copy_table(stored), warnings)
end

function RuleSetRegistry.describe_ruleset(id)
    local ruleset = RuleSetRegistry._rulesets[id]
    if ruleset == nil then
        return Result.fail({})
    end

    return Result.ok({
        id = ruleset.id,
        module_path = ruleset.module_path,
        execution_state = RuleSet.get_execution_state(ruleset),
        executable = RuleSet.is_executable(ruleset),
        execution_error = ruleset.execution_error,
    })
end

function RuleSetRegistry.get_ruleset(id)
    local ruleset = RuleSetRegistry._rulesets[id]
    if ruleset == nil then
        return Result.fail({})
    end

    return Result.ok(Validation.copy_table(ruleset))
end

function RuleSetRegistry.list_rulesets(filter)
    local matches = {}
    for _, ruleset in pairs(RuleSetRegistry._rulesets) do
        local include = true
        if filter and filter.domain ~= nil and ruleset.domain ~= filter.domain then
            include = false
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(ruleset)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

function RuleSetRegistry.validate_ruleset(ruleset)
    return RuleSet.validate(ruleset)
end

return RuleSetRegistry
