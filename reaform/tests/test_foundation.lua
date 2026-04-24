local Schemas = require("reaform.core.schemas")
local ObjectRegistry = require("reaform.core.object_registry")
local RelationshipGraph = require("reaform.core.relationship_graph")
local AnalysisRegistry = require("reaform.core.analysis_registry")
local RuleSetRegistry = require("reaform.core.ruleset_registry")
local ProfileRegistry = require("reaform.core.profile_registry")
local EvaluationContext = require("reaform.contracts.evaluation_context")
local EvaluationResult = require("reaform.contracts.evaluation_result")
local EvaluationClassifier = require("reaform.engine.evaluation_classifier")
local Generator = require("reaform.engine.generator")
local Evaluator = require("reaform.engine.evaluator")

local serialism = require("reaform.rulesets.serialism.basic_row")
local schenkerian = require("reaform.rulesets.schenkerian.basic_reduction")

local Tests = {}

local function assert_true(value, message)
    if not value then
        error(message or "expected true", 2)
    end
end

local function read_file(path)
    local handle = assert(io.open(path, "r"))
    local content = handle:read("*a")
    handle:close()
    return content
end

function Tests.run()
    local test_count = 0

    ObjectRegistry.reset()
    RelationshipGraph.reset()
    AnalysisRegistry.reset()
    RuleSetRegistry.reset()
    ProfileRegistry.reset()

    local normalized_object = Schemas.normalize_object({
        id = "legacy_material",
        type = "Material",
        properties = { value = 42 },
        relationships = {},
        created_by_module = "tests",
    })
    assert_true(normalized_object.ok, "legacy object should normalize")
    assert_true(normalized_object.data.object_type == "Material", "legacy type should map to object_type")
    assert_true(normalized_object.data.domain_payload.value == 42, "legacy properties should map to domain_payload")
    assert_true(type(normalized_object.data.created_at) == "string", "normalized object should add created_at")
    test_count = test_count + 1

    local created = ObjectRegistry.create_object("Material", {
        id = "registry_object",
        source = "test",
        properties = { token = "a" },
        relationships = {},
    })
    assert_true(created.ok, "object registry should create objects")
    local updated = ObjectRegistry.update_object("registry_object", {
        ruleset_scope = "custom",
    })
    assert_true(updated.ok, "object registry should update objects")
    local listed = ObjectRegistry.list_objects({ object_type = "Material" })
    assert_true(listed.ok and #listed.data == 1, "object registry should list objects by type")
    test_count = test_count + 1

    local relationship = RelationshipGraph.create_relationship("contains", "registry_object", "child_object", {
        reason = "test",
    })
    assert_true(relationship.ok, "relationship graph should create relationship")
    local relationships = RelationshipGraph.get_relationships({ from_id = "registry_object" })
    assert_true(relationships.ok and #relationships.data == 1, "relationship graph should query relationships")
    test_count = test_count + 1

    local stored_analysis = AnalysisRegistry.store_analysis({
        target_id = "registry_object",
        lens_id = "analysis.intervallic",
        metadata = { token = "x" },
    })
    assert_true(stored_analysis.ok, "analysis registry should store records")
    local analyses = AnalysisRegistry.get_analyses("registry_object", { lens_id = "analysis.intervallic" })
    assert_true(analyses.ok and #analyses.data == 1, "analysis registry should query analyses")
    test_count = test_count + 1

    local saved_ruleset = RuleSetRegistry.save_ruleset(serialism)
    assert_true(saved_ruleset.ok, "ruleset registry should save rulesets")
    local fetched_ruleset = RuleSetRegistry.get_ruleset(serialism.id)
    assert_true(fetched_ruleset.ok and fetched_ruleset.data.id == serialism.id, "ruleset registry should fetch rulesets")
    test_count = test_count + 1

    local saved_profile = ProfileRegistry.save_profile({
        id = "serial.basic",
        name = "Serial Basic",
        active_ruleset_id = serialism.id,
        constraints = {
            { id = "serial.row_length", severity = "hard" },
        },
    })
    assert_true(saved_profile.ok, "profile registry should save profiles")
    local fetched_profiles = ProfileRegistry.list_profiles({ active_ruleset_id = serialism.id })
    assert_true(fetched_profiles.ok and #fetched_profiles.data == 1, "profile registry should list profiles")
    test_count = test_count + 1

    local evaluation_context = EvaluationContext.create({
        active_ruleset_id = serialism.id,
        active_profile_id = "serial.basic",
        target_object_ids = { "registry_object" },
        user_options = { mode = "test" },
    })
    assert_true(evaluation_context.ok, "evaluation context should normalize")
    local evaluation_result = EvaluationResult.create({
        context_id = evaluation_context.data.id,
        ruleset_id = serialism.id,
        profile_id = "serial.basic",
        classification = "soft_warning",
        warnings = { { code = "warn" } },
        passed = true,
    })
    assert_true(evaluation_result.ok, "evaluation result should normalize")
    assert_true(EvaluationClassifier.classify({ warnings = { { code = "w" } }, passed = true }) == "soft_warning", "classifier should infer warning")
    test_count = test_count + 1

    local schenkerian_generated = Generator.generate(schenkerian, {
        seed_events = { "primary_tone" },
    })
    assert_true(schenkerian_generated.ok, "schenkerian ruleset should generate through shared API")
    local schenkerian_evaluated = Evaluator.evaluate(schenkerian, {
        target = schenkerian_generated.data.generated,
    })
    assert_true(schenkerian_evaluated.ok, "schenkerian ruleset should evaluate through shared API")
    assert_true(schenkerian_evaluated.data.evaluation.classification == "pass", "schenkerian evaluation should classify as pass")
    test_count = test_count + 1

    local core_file = read_file("reaform/core/musical_object.lua")
    local engine_file = read_file("reaform/engine/evaluator.lua")
    assert_true(not string.find(core_file, "cantus", 1, true), "shared core should not require cantus")
    assert_true(not string.find(core_file, "species", 1, true), "shared core should not require species")
    assert_true(not string.find(engine_file, "counterpoint", 1, true), "shared engine should not require counterpoint")
    test_count = test_count + 1

    return {
        name = "test_foundation",
        count = test_count,
    }
end

return Tests
