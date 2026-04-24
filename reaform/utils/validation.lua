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

function Validation.is_number(value)
    return type(value) == "number"
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

function Validation.is_string_array(value)
    if not Validation.is_array(value) then
        return false
    end

    for _, item in ipairs(value) do
        if type(item) ~= "string" or item == "" then
            return false
        end
    end

    return true
end

function Validation.ensure_array(value)
    if Validation.is_array(value) then
        return Validation.copy_table(value)
    end

    return {}
end

function Validation.matches_enum(value, allowed_values)
    if type(value) ~= "string" or type(allowed_values) ~= "table" then
        return false
    end

    for _, candidate in ipairs(allowed_values) do
        if value == candidate then
            return true
        end
    end

    return false
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
