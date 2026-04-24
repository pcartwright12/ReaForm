local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")
local Constraint = require("reaform.core.constraint")
local Transformation = require("reaform.core.transformation")
local Schemas = require("reaform.core.schemas")

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

local ALLOWED_EXTENSION_FIELDS = {
    version = true,
    description = true,
    ontology = true,
    supported_object_types = true,
    supported_relationship_types = true,
    rule_groups = true,
    transforms = true,
    analysis_lenses = true,
    generation_strategies = true,
    scoring_models = true,
    validation_modes = true,
    default_profiles = true,
    serialization_version = true,
}

local function collect_unknown_fields(candidate)
    local warnings = {}
    for key, value in pairs(candidate) do
        if REQUIRED_FIELDS[key] == nil and not ALLOWED_EXTENSION_FIELDS[key] then
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

    local normalized = Schemas.normalize_ruleset(candidate)
    if not normalized.ok then
        return Result.fail(normalized.errors, normalized.warnings)
    end

    for field, expected_type in pairs(REQUIRED_FIELDS) do
        local value = normalized.data[field]
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

    for index, constraint in ipairs(normalized.data.constraints) do
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

    for index, transformation in ipairs(normalized.data.transformations) do
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

    warnings = collect_unknown_fields(candidate)

    if #errors > 0 then
        return Result.fail(errors, warnings)
    end

    return Result.ok(Validation.copy_table(normalized.data), warnings)
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
