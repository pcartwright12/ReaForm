local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local Ids = require("reaform.core.ids")

local AnalysisRegistry = {
    _analyses = {},
    _lenses = {},
}

function AnalysisRegistry.reset()
    AnalysisRegistry._analyses = {}
    AnalysisRegistry._lenses = {}
end

function AnalysisRegistry.store_analysis(record)
    if not Validation.is_table(record) then
        return Result.fail({
            Validation.error("analysis.invalid_record", "Analysis record must be a table.", nil, nil),
        })
    end

    if not Validation.is_non_empty_string(record.target_id) then
        return Result.fail({
            Validation.error("analysis.missing_target_id", "Analysis target_id is required.", "target_id", nil),
        })
    end

    local stored = Validation.copy_table(record)
    stored.id = stored.id or Ids.generate("analysis")
    AnalysisRegistry._analyses[stored.id] = stored

    return Result.ok(Validation.copy_table(stored))
end

function AnalysisRegistry.get_analyses(target_id, filter)
    local matches = {}
    for _, analysis in pairs(AnalysisRegistry._analyses) do
        local include = analysis.target_id == target_id
        if include and filter and filter.lens_id ~= nil and analysis.lens_id ~= filter.lens_id then
            include = false
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(analysis)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

function AnalysisRegistry.list_analyses(filter)
    local matches = {}
    for _, analysis in pairs(AnalysisRegistry._analyses) do
        local include = true
        if filter and filter.target_id ~= nil and analysis.target_id ~= filter.target_id then
            include = false
        end
        if include and filter and filter.lens_id ~= nil and analysis.lens_id ~= filter.lens_id then
            include = false
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(analysis)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

function AnalysisRegistry.register_lens(ruleset_id, lens)
    if not Validation.is_non_empty_string(ruleset_id) then
        return Result.fail({
            Validation.error("analysis.invalid_ruleset_id", "Analysis lens ruleset_id is required.", "ruleset_id", nil),
        })
    end

    if not Validation.is_table(lens) then
        return Result.fail({
            Validation.error("analysis.invalid_lens", "Analysis lens must be a table.", nil, nil),
        })
    end

    if not Validation.is_non_empty_string(lens.id) then
        return Result.fail({
            Validation.error("analysis.invalid_lens_id", "Analysis lens id is required.", "id", nil),
        })
    end

    local stored = Validation.copy_table(lens)
    stored.ruleset_id = ruleset_id
    AnalysisRegistry._lenses[stored.id] = stored
    return Result.ok(Validation.copy_table(stored))
end

function AnalysisRegistry.register_ruleset_lenses(ruleset)
    if not Validation.is_table(ruleset) or not Validation.is_non_empty_string(ruleset.id) then
        return Result.fail({
            Validation.error("analysis.invalid_ruleset", "Ruleset with id is required to register lenses.", nil, nil),
        })
    end

    local stored = {}
    for _, lens in ipairs(Validation.ensure_array(ruleset.analysis_lenses)) do
        local registered = AnalysisRegistry.register_lens(ruleset.id, lens)
        if not registered.ok then
            return registered
        end
        stored[#stored + 1] = registered.data
    end

    return Result.ok(stored)
end

function AnalysisRegistry.get_lens(id)
    local lens = AnalysisRegistry._lenses[id]
    if lens == nil then
        return Result.fail({})
    end

    return Result.ok(Validation.copy_table(lens))
end

function AnalysisRegistry.list_lenses(filter)
    local matches = {}
    for _, lens in pairs(AnalysisRegistry._lenses) do
        local include = true
        if filter and filter.ruleset_id ~= nil and lens.ruleset_id ~= filter.ruleset_id then
            include = false
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(lens)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

return AnalysisRegistry
