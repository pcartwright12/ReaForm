local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local Ids = require("reaform.core.ids")

local AnalysisRegistry = {
    _analyses = {},
}

function AnalysisRegistry.reset()
    AnalysisRegistry._analyses = {}
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

return AnalysisRegistry
