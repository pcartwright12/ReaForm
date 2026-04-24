local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")
local Constraint = require("reaform.core.constraint")
local Transformation = require("reaform.core.transformation")

local RuleSet = {}

local REQUIRED_FIELDS = {
    id = "string",
    name = "string",
    domain = "string",
    object_types = "table",
    constraints = "table",
    transformations = "table",
    generator_strategy = "function",
    evaluation_strategy = "function",
}

local function collect_unknown_fields(candidate)
    local warnings = {}
    for key, value in pairs(candidate) do
        if REQUIRED_FIELDS[key] == nil then
            warnings[#warnings + 1] = Validation.warning(
                "ruleset.unknown_field",
                "Unknown RuleSet field is allowed and preserved.",
                key,
                { value_type = type(value) }
            )
        end
    end
    return warnings
end

function RuleSet.validate(candidate)
    local errors = {}
    local warnings = {}

    if not Validation.is_table(candidate) then
        errors[#errors + 1] = Validation.error(
            "ruleset.not_table",
            "RuleSet must be a table.",
            nil,
            { received_type = type(candidate) }
        )
        return Result.fail(errors, warnings)
    end

    for field, expected_type in pairs(REQUIRED_FIELDS) do
        local value = candidate[field]
        if value == nil then
            errors[#errors + 1] = Validation.error(
                "ruleset.missing_field",
                "Missing required RuleSet field.",
                field,
                { expected_type = expected_type }
            )
        elseif type(value) ~= expected_type then
            errors[#errors + 1] = Validation.error(
                "ruleset.invalid_type",
                "Invalid field type on RuleSet.",
                field,
                { expected_type = expected_type, received_type = type(value) }
            )
        end
    end

    if candidate.object_types ~= nil and not Validation.is_array(candidate.object_types) then
        errors[#errors + 1] = Validation.error(
            "ruleset.invalid_object_types",
            "RuleSet object_types must be an array.",
            "object_types",
            nil
        )
    end

    if candidate.constraints ~= nil and not Validation.is_array(candidate.constraints) then
        errors[#errors + 1] = Validation.error(
            "ruleset.invalid_constraints",
            "RuleSet constraints must be an array.",
            "constraints",
            nil
        )
    elseif Validation.is_array(candidate.constraints) then
        for index, constraint in ipairs(candidate.constraints) do
            local check = Constraint.validate(constraint)
            if not check.ok then
                errors[#errors + 1] = Validation.error(
                    "ruleset.invalid_constraint",
                    "RuleSet includes an invalid Constraint.",
                    "constraints",
                    { index = index, issues = check.errors }
                )
            end
        end
    end

    if candidate.transformations ~= nil and not Validation.is_array(candidate.transformations) then
        errors[#errors + 1] = Validation.error(
            "ruleset.invalid_transformations",
            "RuleSet transformations must be an array.",
            "transformations",
            nil
        )
    elseif Validation.is_array(candidate.transformations) then
        for index, transformation in ipairs(candidate.transformations) do
            local check = Transformation.validate(transformation)
            if not check.ok then
                errors[#errors + 1] = Validation.error(
                    "ruleset.invalid_transformation",
                    "RuleSet includes an invalid Transformation.",
                    "transformations",
                    { index = index, issues = check.errors }
                )
            end
        end
    end

    warnings = collect_unknown_fields(candidate)

    if #errors > 0 then
        return Result.fail(errors, warnings)
    end

    return Result.ok(Validation.copy_table(candidate), warnings)
end

function RuleSet.normalize(candidate)
    local validation = RuleSet.validate(candidate)
    if not validation.ok then
        return validation
    end

    local normalized = validation.data
    normalized.constraints = normalized.constraints or {}
    normalized.transformations = normalized.transformations or {}

    return Result.ok(normalized, validation.warnings)
end

return RuleSet
