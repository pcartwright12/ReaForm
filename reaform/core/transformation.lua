local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")

local Transformation = {}

local REQUIRED_FIELDS = {
    id = "string",
    input_types = "table",
    output_types = "table",
    transform_function = "function",
}

function Transformation.validate(candidate)
    local errors = {}

    if not Validation.is_table(candidate) then
        errors[#errors + 1] = Validation.error(
            "transformation.not_table",
            "Transformation must be a table.",
            nil,
            { received_type = type(candidate) }
        )
        return Result.fail(errors)
    end

    for field, expected_type in pairs(REQUIRED_FIELDS) do
        local value = candidate[field]
        if value == nil then
            errors[#errors + 1] = Validation.error(
                "transformation.missing_field",
                "Missing required Transformation field.",
                field,
                { expected_type = expected_type }
            )
        elseif type(value) ~= expected_type then
            errors[#errors + 1] = Validation.error(
                "transformation.invalid_type",
                "Invalid field type on Transformation.",
                field,
                { expected_type = expected_type, received_type = type(value) }
            )
        end
    end

    if candidate.input_types ~= nil and not Validation.is_array(candidate.input_types) then
        errors[#errors + 1] = Validation.error(
            "transformation.invalid_input_types",
            "Transformation input_types must be an array.",
            "input_types",
            nil
        )
    end

    if candidate.output_types ~= nil and not Validation.is_array(candidate.output_types) then
        errors[#errors + 1] = Validation.error(
            "transformation.invalid_output_types",
            "Transformation output_types must be an array.",
            "output_types",
            nil
        )
    end

    if #errors > 0 then
        return Result.fail(errors)
    end

    return Result.ok(candidate)
end

function Transformation.apply(transformation, input, context)
    local validation = Transformation.validate(transformation)
    if not validation.ok then
        return Result.fail(validation.errors, validation.warnings)
    end

    local ok, transformed, metadata = pcall(transformation.transform_function, input, context)
    if not ok then
        return Result.fail({
            Validation.error(
                "transformation.execution_error",
                "Transformation transform_function raised an error.",
                "transform_function",
                { reason = transformed }
            ),
        })
    end

    return Result.ok({
        transformation_id = transformation.id,
        output = transformed,
        metadata = type(metadata) == "table" and metadata or {},
    })
end

return Transformation
