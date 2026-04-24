local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")

local Constraint = {}

local REQUIRED_FIELDS = {
    id = "string",
    description = "string",
    applicable_object_types = "table",
    evaluation_function = "function",
}

function Constraint.validate(candidate)
    local errors = {}

    if not Validation.is_table(candidate) then
        errors[#errors + 1] = Validation.error(
            "constraint.not_table",
            "Constraint must be a table.",
            nil,
            { received_type = type(candidate) }
        )
        return Result.fail(errors)
    end

    for field, expected_type in pairs(REQUIRED_FIELDS) do
        local value = candidate[field]
        if value == nil then
            errors[#errors + 1] = Validation.error(
                "constraint.missing_field",
                "Missing required Constraint field.",
                field,
                { expected_type = expected_type }
            )
        elseif type(value) ~= expected_type then
            errors[#errors + 1] = Validation.error(
                "constraint.invalid_type",
                "Invalid field type on Constraint.",
                field,
                { expected_type = expected_type, received_type = type(value) }
            )
        end
    end

    if candidate.applicable_object_types ~= nil and not Validation.is_array(candidate.applicable_object_types) then
        errors[#errors + 1] = Validation.error(
            "constraint.invalid_applicable_object_types",
            "Constraint applicable_object_types must be an array.",
            "applicable_object_types",
            nil
        )
    end

    if #errors > 0 then
        return Result.fail(errors)
    end

    return Result.ok(candidate)
end

function Constraint.evaluate(constraint, context)
    local validation = Constraint.validate(constraint)
    if not validation.ok then
        return Result.fail(validation.errors, validation.warnings)
    end

    local ok, eval_result = pcall(constraint.evaluation_function, context)
    if not ok then
        return Result.fail({
            Validation.error(
                "constraint.execution_error",
                "Constraint evaluation_function raised an error.",
                "evaluation_function",
                { reason = eval_result }
            ),
        })
    end

    if type(eval_result) ~= "table" then
        return Result.fail({
            Validation.error(
                "constraint.invalid_result",
                "Constraint evaluation_function must return a table.",
                "evaluation_function",
                { received_type = type(eval_result) }
            ),
        })
    end

    local passed = eval_result.passed == true
    local metadata = type(eval_result.metadata) == "table" and eval_result.metadata or {}
    local warnings = type(eval_result.warnings) == "table" and eval_result.warnings or {}

    return Result.ok({
        constraint_id = constraint.id,
        passed = passed,
        metadata = metadata,
    }, warnings)
end

return Constraint
