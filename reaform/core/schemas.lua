local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")
local Ids = require("reaform.core.ids")

local Schemas = {}

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
        serialization_version = payload.serialization_version or 1,
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

    return Result.ok(normalized)
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
