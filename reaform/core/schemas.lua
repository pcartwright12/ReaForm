local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")
local Ids = require("reaform.core.ids")

local Schemas = {}
local CURRENT_RULESET_SERIALIZATION_VERSION = 2

local EVALUATION_CLASSIFICATIONS = {
    "hard_failure",
    "soft_warning",
    "advisory_notice",
    "pass",
}

local function normalize_legacy_relationships(value)
    if not Validation.is_array(value) then
        return {}
    end

    local relationships = {}
    for _, relationship in ipairs(value) do
        if type(relationship) == "table" then
            relationships[#relationships + 1] = Validation.copy_table(relationship)
        end
    end
    return relationships
end

local function sanitize_constraint_for_persistence(constraint)
    local persisted = Validation.copy_table(constraint)
    persisted.evaluation_function = nil
    persisted.has_evaluation_function = type(constraint and constraint.evaluation_function) == "function"
    return persisted
end

local function sanitize_transform_for_persistence(transform)
    local persisted = Validation.copy_table(transform)
    persisted.transform_function = nil
    persisted.has_transform_function = type(transform and transform.transform_function) == "function"
    return persisted
end

local function is_plain_table(value)
    return Validation.is_table(value) and (next(value) == nil or not Validation.is_array(value))
end

local function validate_optional_array_field(payload, field_name, code, message)
    local value = payload[field_name]
    if value ~= nil and not Validation.is_array(value) then
        return Validation.error(code, message, field_name, { received_type = type(value) })
    end
    return nil
end

local function validate_optional_table_field(payload, field_name, code, message)
    local value = payload[field_name]
    if value ~= nil and not is_plain_table(value) then
        return Validation.error(code, message, field_name, { received_type = type(value) })
    end
    return nil
end

local function validate_analysis_lenses(lenses)
    for index, lens in ipairs(lenses) do
        if not is_plain_table(lens) then
            return Validation.error(
                "schemas.ruleset.invalid_analysis_lens",
                "RuleSet analysis_lenses entries must be tables.",
                "analysis_lenses",
                { index = index, received_type = type(lens) }
            )
        end

        if not Validation.is_non_empty_string(lens.id) then
            return Validation.error(
                "schemas.ruleset.invalid_analysis_lens_id",
                "RuleSet analysis_lenses entries must have non-empty ids.",
                "analysis_lenses",
                { index = index }
            )
        end

        if lens.name ~= nil and not Validation.is_non_empty_string(lens.name) then
            return Validation.error(
                "schemas.ruleset.invalid_analysis_lens_name",
                "RuleSet analysis_lenses entry names must be non-empty strings when provided.",
                "analysis_lenses",
                { index = index }
            )
        end

        if lens.target_object_types ~= nil and not Validation.is_string_array(lens.target_object_types) then
            return Validation.error(
                "schemas.ruleset.invalid_analysis_lens_targets",
                "RuleSet analysis_lenses target_object_types must be a string array when provided.",
                "analysis_lenses",
                { index = index }
            )
        end
    end

    return nil
end

local function validate_profile_rules(rule_entries, field_name)
    for index, entry in ipairs(rule_entries) do
        if not is_plain_table(entry) then
            return Validation.error(
                "schemas.profile.invalid_rule_entry",
                "Profile rule entries must be tables.",
                field_name,
                { index = index, received_type = type(entry) }
            )
        end

        if entry.id ~= nil and not Validation.is_non_empty_string(entry.id) then
            return Validation.error(
                "schemas.profile.invalid_rule_entry_id",
                "Profile rule entry ids must be non-empty strings when provided.",
                field_name,
                { index = index }
            )
        end
    end

    return nil
end

function Schemas.normalize_object(payload)
    if not Validation.is_table(payload) then
        return Result.fail({
            Validation.error(
                "schemas.object.not_table",
                "Object payload must be a table.",
                nil,
                { received_type = type(payload) }
            ),
        })
    end

    local timestamp = payload.updated_at or payload.created_at or Ids.timestamp()
    local object_type = payload.object_type or payload.type
    local domain_payload = Validation.copy_table(payload.domain_payload or payload.properties or {})
    local relationships = normalize_legacy_relationships(payload.relationships)

    local normalized = {
        id = payload.id or Ids.generate("object"),
        object_type = object_type,
        source = payload.source or "unknown",
        ruleset_scope = payload.ruleset_scope,
        tags = Validation.ensure_array(payload.tags),
        metadata = Validation.copy_table(payload.metadata or {}),
        domain_payload = domain_payload,
        derived_analyses = Validation.ensure_array(payload.derived_analyses),
        relationships = relationships,
        parent_ids = Validation.ensure_array(payload.parent_ids),
        child_ids = Validation.ensure_array(payload.child_ids),
        transformations_applied = Validation.ensure_array(payload.transformations_applied),
        confidence = payload.confidence,
        ambiguities = Validation.ensure_array(payload.ambiguities),
        created_by_module = payload.created_by_module or "unknown",
        created_at = payload.created_at or timestamp,
        updated_at = payload.updated_at or timestamp,
        version = payload.version or 1,
        notes = Validation.ensure_array(payload.notes),

        -- Compatibility aliases for existing call sites and tests.
        type = object_type,
        properties = domain_payload,
    }

    if not Validation.is_non_empty_string(normalized.object_type) then
        return Result.fail({
            Validation.error(
                "schemas.object.missing_type",
                "Object type is required.",
                "object_type",
                nil
            ),
        })
    end

    if not Validation.is_non_empty_string(normalized.id) then
        return Result.fail({
            Validation.error(
                "schemas.object.invalid_id",
                "Object id must be a non-empty string.",
                "id",
                nil
            ),
        })
    end

    return Result.ok(normalized)
end

function Schemas.to_legacy_object(payload)
    local normalized = Schemas.normalize_object(payload)
    if not normalized.ok then
        return normalized
    end

    return Result.ok({
        id = normalized.data.id,
        type = normalized.data.object_type,
        properties = Validation.copy_table(normalized.data.domain_payload),
        relationships = normalize_legacy_relationships(normalized.data.relationships),
    }, normalized.warnings)
end

function Schemas.normalize_ruleset(payload)
    if not Validation.is_table(payload) then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.not_table",
                "RuleSet payload must be a table.",
                nil,
                { received_type = type(payload) }
            ),
        })
    end

    local raw_array_fields = {
        {
            field = "supported_relationship_types",
            code = "schemas.ruleset.invalid_supported_relationship_types",
            message = "RuleSet supported_relationship_types must be an array when provided.",
        },
        {
            field = "rule_groups",
            code = "schemas.ruleset.invalid_rule_groups",
            message = "RuleSet rule_groups must be an array when provided.",
        },
        {
            field = "constraints",
            code = "schemas.ruleset.invalid_constraints",
            message = "RuleSet constraints must be an array.",
        },
        {
            field = "analysis_lenses",
            code = "schemas.ruleset.invalid_analysis_lenses",
            message = "RuleSet analysis_lenses must be an array when provided.",
        },
        {
            field = "scoring_models",
            code = "schemas.ruleset.invalid_scoring_models",
            message = "RuleSet scoring_models must be an array when provided.",
        },
        {
            field = "validation_modes",
            code = "schemas.ruleset.invalid_validation_modes",
            message = "RuleSet validation_modes must be an array when provided.",
        },
        {
            field = "default_profiles",
            code = "schemas.ruleset.invalid_default_profiles",
            message = "RuleSet default_profiles must be an array when provided.",
        },
    }
    for _, entry in ipairs(raw_array_fields) do
        local issue = validate_optional_array_field(payload, entry.field, entry.code, entry.message)
        if issue ~= nil then
            return Result.fail({ issue })
        end
    end

    local raw_table_fields = {
        {
            field = "ontology",
            code = "schemas.ruleset.invalid_ontology",
            message = "RuleSet ontology must be a table when provided.",
        },
        {
            field = "generation_strategies",
            code = "schemas.ruleset.invalid_generation_strategies",
            message = "RuleSet generation_strategies must be a table when provided.",
        },
    }
    for _, entry in ipairs(raw_table_fields) do
        local issue = validate_optional_table_field(payload, entry.field, entry.code, entry.message)
        if issue ~= nil then
            return Result.fail({ issue })
        end
    end

    local supported_object_types = Validation.ensure_array(payload.supported_object_types or payload.object_types)
    local transforms = Validation.ensure_array(payload.transforms or payload.transformations)
    local generation_strategy = payload.generator_strategy

    if type(generation_strategy) ~= "function" then
        local strategies = payload.generation_strategies
        if Validation.is_table(strategies) and type(strategies.default) == "function" then
            generation_strategy = strategies.default
        end
    end

    local normalized = {
        id = payload.id,
        name = payload.name,
        version = payload.version or 1,
        description = payload.description or "",
        domain = payload.domain,
        ontology = Validation.copy_table(payload.ontology or { domain = payload.domain }),
        supported_object_types = supported_object_types,
        supported_relationship_types = Validation.ensure_array(payload.supported_relationship_types),
        rule_groups = Validation.ensure_array(payload.rule_groups),
        constraints = Validation.ensure_array(payload.constraints),
        transforms = transforms,
        analysis_lenses = Validation.ensure_array(payload.analysis_lenses),
        generation_strategies = Validation.copy_table(payload.generation_strategies or { default = generation_strategy }),
        scoring_models = Validation.ensure_array(payload.scoring_models),
        validation_modes = Validation.ensure_array(payload.validation_modes),
        default_profiles = Validation.ensure_array(payload.default_profiles),
        serialization_version = payload.serialization_version or CURRENT_RULESET_SERIALIZATION_VERSION,
        module_path = payload.module_path,
        evaluation_strategy = payload.evaluation_strategy,
        generator_strategy = generation_strategy,

        -- Compatibility aliases.
        object_types = supported_object_types,
        transformations = transforms,
    }

    if not Validation.is_non_empty_string(normalized.id) then
        return Result.fail({
            Validation.error("schemas.ruleset.invalid_id", "RuleSet id is required.", "id", nil),
        })
    end

    if not Validation.is_non_empty_string(normalized.name) then
        return Result.fail({
            Validation.error("schemas.ruleset.invalid_name", "RuleSet name is required.", "name", nil),
        })
    end

    if not Validation.is_non_empty_string(normalized.domain) then
        return Result.fail({
            Validation.error("schemas.ruleset.invalid_domain", "RuleSet domain is required.", "domain", nil),
        })
    end

    if payload.module_path ~= nil and not Validation.is_non_empty_string(payload.module_path) then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.invalid_module_path",
                "RuleSet module_path must be a non-empty string when provided.",
                "module_path",
                nil
            ),
        })
    end

    if not Validation.is_number(normalized.version) or normalized.version < 1 then
        return Result.fail({
            Validation.error("schemas.ruleset.invalid_version", "RuleSet version must be a positive number.", "version", nil),
        })
    end

    if not Validation.is_number(normalized.serialization_version) or normalized.serialization_version < 1 then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.invalid_serialization_version",
                "RuleSet serialization_version must be a positive number.",
                "serialization_version",
                nil
            ),
        })
    end

    if not Validation.is_string_array(normalized.supported_object_types) then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.invalid_object_types",
                "RuleSet supported_object_types must be a string array.",
                "supported_object_types",
                nil
            ),
        })
    end

    if not Validation.is_array(normalized.constraints) then
        return Result.fail({
            Validation.error("schemas.ruleset.invalid_constraints", "RuleSet constraints must be an array.", "constraints", nil),
        })
    end

    if not Validation.is_array(normalized.transforms) then
        return Result.fail({
            Validation.error("schemas.ruleset.invalid_transforms", "RuleSet transforms must be an array.", "transforms", nil),
        })
    end

    if normalized.supported_relationship_types ~= nil and not Validation.is_string_array(normalized.supported_relationship_types) then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.invalid_supported_relationship_types_values",
                "RuleSet supported_relationship_types must be a string array when provided.",
                "supported_relationship_types",
                nil
            ),
        })
    end

    if normalized.validation_modes ~= nil and not Validation.is_string_array(normalized.validation_modes) then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.invalid_validation_modes_values",
                "RuleSet validation_modes must be a string array when provided.",
                "validation_modes",
                nil
            ),
        })
    end

    local analysis_lens_issue = validate_analysis_lenses(normalized.analysis_lenses)
    if analysis_lens_issue ~= nil then
        return Result.fail({ analysis_lens_issue })
    end

    if type(normalized.generator_strategy) ~= "function" then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.invalid_generator_strategy",
                "RuleSet generator_strategy is required.",
                "generator_strategy",
                nil
            ),
        })
    end

    if type(normalized.evaluation_strategy) ~= "function" then
        return Result.fail({
            Validation.error(
                "schemas.ruleset.invalid_evaluation_strategy",
                "RuleSet evaluation_strategy is required.",
                "evaluation_strategy",
                nil
            ),
        })
    end

    return Result.ok(normalized)
end

function Schemas.normalize_profile(payload)
    if not Validation.is_table(payload) then
        return Result.fail({
            Validation.error(
                "schemas.profile.not_table",
                "Profile payload must be a table.",
                nil,
                { received_type = type(payload) }
            ),
        })
    end

    local raw_array_fields = {
        {
            field = "rule_groups",
            code = "schemas.profile.invalid_rule_groups",
            message = "Profile rule_groups must be an array when provided.",
        },
        {
            field = "rules",
            code = "schemas.profile.invalid_rules",
            message = "Profile rules must be an array when provided.",
        },
        {
            field = "constraints",
            code = "schemas.profile.invalid_constraints",
            message = "Profile constraints must be an array when provided.",
        },
    }
    for _, entry in ipairs(raw_array_fields) do
        local issue = validate_optional_array_field(payload, entry.field, entry.code, entry.message)
        if issue ~= nil then
            return Result.fail({ issue })
        end
    end

    local raw_table_fields = {
        {
            field = "transform_settings",
            code = "schemas.profile.invalid_transform_settings",
            message = "Profile transform_settings must be a table when provided.",
        },
        {
            field = "generation_strategy_settings",
            code = "schemas.profile.invalid_generation_strategy_settings",
            message = "Profile generation_strategy_settings must be a table when provided.",
        },
        {
            field = "analysis_lens_settings",
            code = "schemas.profile.invalid_analysis_lens_settings",
            message = "Profile analysis_lens_settings must be a table when provided.",
        },
        {
            field = "metadata",
            code = "schemas.profile.invalid_metadata",
            message = "Profile metadata must be a table when provided.",
        },
    }
    for _, entry in ipairs(raw_table_fields) do
        local issue = validate_optional_table_field(payload, entry.field, entry.code, entry.message)
        if issue ~= nil then
            return Result.fail({ issue })
        end
    end

    local normalized = {
        id = payload.id or Ids.generate("profile"),
        name = payload.name or payload.id or "Unnamed Profile",
        active_ruleset_id = payload.active_ruleset_id or payload.ruleset_id,
        rule_groups = Validation.ensure_array(payload.rule_groups),
        rules = Validation.ensure_array(payload.rules),
        constraints = Validation.ensure_array(payload.constraints),
        transform_settings = Validation.copy_table(payload.transform_settings or {}),
        generation_strategy_settings = Validation.copy_table(payload.generation_strategy_settings or {}),
        analysis_lens_settings = Validation.copy_table(payload.analysis_lens_settings or {}),
        version = payload.version or 1,
        metadata = Validation.copy_table(payload.metadata or {}),
    }

    if not Validation.is_non_empty_string(normalized.id) then
        return Result.fail({
            Validation.error("schemas.profile.invalid_id", "Profile id must be a non-empty string.", "id", nil),
        })
    end

    if not Validation.is_non_empty_string(normalized.active_ruleset_id) then
        return Result.fail({
            Validation.error(
                "schemas.profile.missing_ruleset_id",
                "Profile active_ruleset_id is required.",
                "active_ruleset_id",
                nil
            ),
        })
    end

    if not Validation.is_non_empty_string(normalized.name) then
        return Result.fail({
            Validation.error("schemas.profile.invalid_name", "Profile name must be a non-empty string.", "name", nil),
        })
    end

    if not Validation.is_number(normalized.version) or normalized.version < 1 then
        return Result.fail({
            Validation.error("schemas.profile.invalid_version", "Profile version must be a positive number.", "version", nil),
        })
    end

    local rules_issue = validate_profile_rules(normalized.rules, "rules")
    if rules_issue ~= nil then
        return Result.fail({ rules_issue })
    end

    local constraints_issue = validate_profile_rules(normalized.constraints, "constraints")
    if constraints_issue ~= nil then
        return Result.fail({ constraints_issue })
    end

    return Result.ok(normalized)
end

function Schemas.serialize_ruleset_state(payload)
    local normalized = Schemas.normalize_ruleset(payload)
    if not normalized.ok then
        return normalized
    end

    local ruleset = Validation.copy_table(normalized.data)
    ruleset.generator_strategy = nil
    ruleset.evaluation_strategy = nil
    ruleset.generation_strategies = {}
    ruleset.constraints = {}
    ruleset.transforms = {}
    ruleset.transformations = ruleset.transforms
    ruleset.analysis_lenses = Validation.ensure_array(normalized.data.analysis_lenses)
    ruleset.has_generator_strategy = type(normalized.data.generator_strategy) == "function"
    ruleset.has_evaluation_strategy = type(normalized.data.evaluation_strategy) == "function"

    for _, constraint in ipairs(normalized.data.constraints) do
        ruleset.constraints[#ruleset.constraints + 1] = sanitize_constraint_for_persistence(constraint)
    end

    for _, transform in ipairs(normalized.data.transforms) do
        ruleset.transforms[#ruleset.transforms + 1] = sanitize_transform_for_persistence(transform)
    end

    return Result.ok(ruleset, normalized.warnings)
end

function Schemas.serialize_profile_state(payload)
    return Schemas.normalize_profile(payload)
end

function Schemas.serialize_transform_state(payload)
    local persisted = sanitize_transform_for_persistence(payload or {})
    if not Validation.is_non_empty_string(persisted.id) then
        return Result.fail({
            Validation.error("schemas.transform.invalid_id", "Transform id is required.", "id", nil),
        })
    end

    return Result.ok(persisted)
end

function Schemas.normalize_evaluation_context(payload)
    if not Validation.is_table(payload) then
        return Result.fail({
            Validation.error(
                "schemas.evaluation_context.not_table",
                "EvaluationContext payload must be a table.",
                nil,
                { received_type = type(payload) }
            ),
        })
    end

    local target_object_ids = Validation.ensure_array(payload.target_object_ids)
    if #target_object_ids == 0 and type(payload.target) == "table" and Validation.is_non_empty_string(payload.target.id) then
        target_object_ids[1] = payload.target.id
    end

    local normalized = {
        id = payload.id or Ids.generate("evaluation_context"),
        active_ruleset_id = payload.active_ruleset_id or payload.ruleset_id,
        active_profile_id = payload.active_profile_id or payload.profile_id,
        target_object_ids = target_object_ids,
        relationship_scope = Validation.copy_table(payload.relationship_scope or {}),
        operation_type = payload.operation_type or "evaluation",
        operation_payload = Validation.copy_table(payload.operation_payload or {}),
        analysis_scope = Validation.copy_table(payload.analysis_scope or {}),
        generation_state = Validation.copy_table(payload.generation_state or {}),
        user_options = Validation.copy_table(payload.user_options or {}),
        runtime_metadata = Validation.copy_table(payload.runtime_metadata or {}),
        raw_context = Validation.copy_table(payload.raw_context or payload),
    }

    if not Validation.is_non_empty_string(normalized.active_ruleset_id) then
        return Result.fail({
            Validation.error(
                "schemas.evaluation_context.missing_ruleset_id",
                "EvaluationContext active_ruleset_id is required.",
                "active_ruleset_id",
                nil
            ),
        })
    end

    return Result.ok(normalized)
end

function Schemas.normalize_evaluation_result(payload)
    if not Validation.is_table(payload) then
        return Result.fail({
            Validation.error(
                "schemas.evaluation_result.not_table",
                "EvaluationResult payload must be a table.",
                nil,
                { received_type = type(payload) }
            ),
        })
    end

    local normalized = {
        id = payload.id or Ids.generate("evaluation_result"),
        context_id = payload.context_id,
        ruleset_id = payload.ruleset_id,
        profile_id = payload.profile_id,
        classification = payload.classification or "pass",
        findings = Validation.ensure_array(payload.findings),
        score = payload.score or 0,
        passed = payload.passed == true,
        failed_rule_ids = Validation.ensure_array(payload.failed_rule_ids),
        warnings = Validation.ensure_array(payload.warnings),
        advisory_notices = Validation.ensure_array(payload.advisory_notices),
        suggested_repairs = Validation.ensure_array(payload.suggested_repairs),
        metadata = Validation.copy_table(payload.metadata or {}),
    }

    if not Validation.matches_enum(normalized.classification, EVALUATION_CLASSIFICATIONS) then
        return Result.fail({
            Validation.error(
                "schemas.evaluation_result.invalid_classification",
                "EvaluationResult classification is invalid.",
                "classification",
                { allowed = EVALUATION_CLASSIFICATIONS }
            ),
        })
    end

    return Result.ok(normalized)
end

return Schemas
