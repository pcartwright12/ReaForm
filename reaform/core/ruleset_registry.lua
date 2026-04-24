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

    RuleSetRegistry._rulesets[normalized.data.id] = Validation.copy_table(normalized.data)
    local transform_result = TransformRegistry.register_ruleset_transforms(normalized.data)
    if not transform_result.ok then
        return transform_result
    end

    local lens_result = AnalysisRegistry.register_ruleset_lenses(normalized.data)
    if not lens_result.ok then
        return lens_result
    end

    return Result.ok(
        Validation.copy_table(normalized.data),
        Result.merge_warnings(normalized.warnings, transform_result.warnings, lens_result.warnings)
    )
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
