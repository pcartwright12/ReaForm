local Result = {}

local function shallow_copy(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}
    for key, v in pairs(value) do
        out[key] = v
    end
    return out
end

function Result.ok(data, warnings)
    return {
        ok = true,
        data = data,
        errors = {},
        warnings = warnings or {},
    }
end

function Result.fail(errors, warnings, data)
    return {
        ok = false,
        data = data,
        errors = errors or {},
        warnings = warnings or {},
    }
end

function Result.merge_warnings(...)
    local merged = {}
    for index = 1, select("#", ...) do
        local list = select(index, ...)
        if type(list) == "table" then
            for _, item in ipairs(list) do
                merged[#merged + 1] = shallow_copy(item)
            end
        end
    end
    return merged
end

return Result
