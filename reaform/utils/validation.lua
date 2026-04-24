local Validation = {}

function Validation.warning(code, message, field, details)
    return {
        code = code,
        message = message,
        field = field,
        details = details,
        severity = "warning",
    }
end

function Validation.error(code, message, field, details)
    return {
        code = code,
        message = message,
        field = field,
        details = details,
        severity = "error",
    }
end

function Validation.is_non_empty_string(value)
    return type(value) == "string" and value ~= ""
end

function Validation.is_table(value)
    return type(value) == "table"
end

function Validation.is_array(value)
    if type(value) ~= "table" then
        return false
    end

    local count = 0
    for key, _ in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then
            return false
        end
        count = count + 1
    end

    for index = 1, count do
        if value[index] == nil then
            return false
        end
    end

    return true
end

function Validation.copy_table(value)
    if type(value) ~= "table" then
        return value
    end

    local out = {}
    for key, v in pairs(value) do
        if type(v) == "table" then
            out[key] = Validation.copy_table(v)
        else
            out[key] = v
        end
    end
    return out
end

return Validation
