local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")

local MusicalObject = {}

local REQUIRED_FIELDS = {
    id = "string",
    type = "string",
    properties = "table",
    relationships = "table",
}

function MusicalObject.validate(candidate)
    local errors = {}

    if not Validation.is_table(candidate) then
        errors[#errors + 1] = Validation.error(
            "musical_object.not_table",
            "MusicalObject must be a table.",
            nil,
            { received_type = type(candidate) }
        )
        return Result.fail(errors)
    end

    for field, expected_type in pairs(REQUIRED_FIELDS) do
        local value = candidate[field]
        if value == nil then
            errors[#errors + 1] = Validation.error(
                "musical_object.missing_field",
                "Missing required MusicalObject field.",
                field,
                { expected_type = expected_type }
            )
        elseif type(value) ~= expected_type then
            errors[#errors + 1] = Validation.error(
                "musical_object.invalid_type",
                "Invalid field type on MusicalObject.",
                field,
                { expected_type = expected_type, received_type = type(value) }
            )
        end
    end

    if #errors > 0 then
        return Result.fail(errors)
    end

    return Result.ok(Validation.copy_table(candidate))
end

function MusicalObject.create(payload)
    local candidate = payload or {}

    local normalized = {
        id = candidate.id,
        type = candidate.type,
        properties = type(candidate.properties) == "table" and Validation.copy_table(candidate.properties) or {},
        relationships = type(candidate.relationships) == "table" and Validation.copy_table(candidate.relationships) or {},
    }

    return MusicalObject.validate(normalized)
end

return MusicalObject
