local Schemas = require("reaform.core.schemas")
local Ids = require("reaform.core.ids")
local ObjectRegistry = require("reaform.core.object_registry")
local RelationshipGraph = require("reaform.core.relationship_graph")
local AnalysisRegistry = require("reaform.core.analysis_registry")
local RuleSetRegistry = require("reaform.core.ruleset_registry")
local ProfileRegistry = require("reaform.core.profile_registry")
local TransformRegistry = require("reaform.core.transform_registry")
local Persistence = require("reaform.core.persistence")
local SessionWorkflow = require("reaform.workflows.session_workflow")
local EvaluationContext = require("reaform.contracts.evaluation_context")
local EvaluationResult = require("reaform.contracts.evaluation_result")
local EvaluationClassifier = require("reaform.engine.evaluation_classifier")
local Generator = require("reaform.engine.generator")
local Evaluator = require("reaform.engine.evaluator")
local ReaForm = require("main")
local ReaperGuiMain = require("reaper.gui_main")

local serialism = ReaForm.load_ruleset("serialism")
local schenkerian = ReaForm.load_ruleset("schenkerian")

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
    TransformRegistry.reset()

    ReaForm.reset_state()
    local registered_builtins = ReaForm.register_builtin_rulesets()
    assert_true(registered_builtins.ok and registered_builtins.data.count == 5, "main should bootstrap built-in rulesets")
    local exported_from_main = ReaForm.export_project({ purpose = "main-bootstrap-test" })
    assert_true(exported_from_main.ok and #exported_from_main.data.rulesets == 5, "main should export project snapshots through the orchestration surface")
    test_count = test_count + 1

    local workflow_created = SessionWorkflow.create({
        reset_state = true,
        bootstrap_builtins = true,
    })
    assert_true(workflow_created.ok, "session workflow should initialize")
    local workflow = workflow_created.data
    local workflow_rulesets = workflow.list_rulesets()
    assert_true(workflow_rulesets.ok and #workflow_rulesets.data == 5, "session workflow should list registered rulesets")
    local workflow_selected = workflow.select_ruleset("serialism")
    assert_true(workflow_selected.ok and workflow_selected.data.active_ruleset_id == serialism.id, "session workflow should select the active ruleset")
    local workflow_transforms = workflow.list_transforms()
    assert_true(workflow_transforms.ok and #workflow_transforms.data == 2, "session workflow should expose active ruleset transforms")
    local workflow_generated = workflow.generate({})
    assert_true(workflow_generated.ok and workflow_generated.data.generated_object.type == "ToneRow", "session workflow should generate via the active ruleset")
    local workflow_evaluated = workflow.evaluate({})
    assert_true(workflow_evaluated.ok and workflow_evaluated.data.evaluation.evaluation.classification == "pass", "session workflow should evaluate the last generated object by default")
    local workflow_transformed = workflow.apply_transform("serial.retrograde")
    assert_true(workflow_transformed.ok and workflow_transformed.data.transformed_object.type == "ToneRow", "session workflow should apply transforms against the last generated object")
    local workflow_objects = workflow.list_objects()
    assert_true(workflow_objects.ok and #workflow_objects.data >= 2, "session workflow should expose current objects for GUI display")
    local workflow_snapshot = workflow.get_state_snapshot()
    assert_true(workflow_snapshot.ok and workflow_snapshot.data.active_ruleset_id == serialism.id, "session workflow should retain active session state")
    assert_true(workflow_snapshot.data.last_generated_object ~= nil, "session workflow should retain the last generated or transformed object")
    assert_true(workflow_snapshot.data.last_evaluation ~= nil, "session workflow should retain the last evaluation")
    test_count = test_count + 1

    local gui_app_created = ReaperGuiMain.create_app({
        reset_state = true,
        bootstrap_builtins = true,
    })
    assert_true(gui_app_created.ok, "REAPER GUI app should be creatable outside REAPER for smoke coverage")
    assert_true(type(gui_app_created.data.loop) == "function", "REAPER GUI app should expose a loop function")
    assert_true(type(gui_app_created.data.generate) == "function", "REAPER GUI app should expose generate action wiring")
    test_count = test_count + 1

    ReaForm.reset_state()

    local registered_from_main = ReaForm.register_ruleset("serialism")
    assert_true(registered_from_main.ok, "main should register rulesets through the shared registry surface")
    RuleSetRegistry.reset()
    TransformRegistry.reset()
    AnalysisRegistry.reset()
    test_count = test_count + 1

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

    local stored_transform = TransformRegistry.get_transform("serial.retrograde")
    assert_true(stored_transform.ok and stored_transform.data.ruleset_id == serialism.id, "transform registry should register ruleset transforms")
    local stored_lenses = AnalysisRegistry.list_lenses({ ruleset_id = serialism.id })
    assert_true(stored_lenses.ok and #stored_lenses.data == 1, "analysis registry should register ruleset lenses")
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

    local temp_project_path = Ids.generate("project_state") .. ".json"
    local saved_project = Persistence.save_project(temp_project_path, { purpose = "foundation-test" })
    assert_true(saved_project.ok, "persistence should save project state")
    local loaded_project = Persistence.load_project(temp_project_path)
    assert_true(loaded_project.ok, "persistence should load project state")
    assert_true(loaded_project.data.schema_version == 2, "project persistence should preserve current schema version")
    assert_true(#loaded_project.data.objects == 1, "project persistence should round-trip objects")
    assert_true(#loaded_project.data.rulesets == 1, "project persistence should round-trip ruleset state")
    assert_true(type(loaded_project.data.migration_history) == "table", "project persistence should include migration history array in current snapshots")
    test_count = test_count + 1

    ObjectRegistry.reset()
    RelationshipGraph.reset()
    AnalysisRegistry.reset()
    RuleSetRegistry.reset()
    ProfileRegistry.reset()
    TransformRegistry.reset()

    local restored_project = ReaForm.import_project(loaded_project.data)
    assert_true(restored_project.ok, "persistence should import project state into registries")
    assert_true(restored_project.data.imported.objects == 1, "project import should restore objects")
    assert_true(restored_project.data.imported.rulesets == 1, "project import should restore rulesets")
    assert_true(#restored_project.data.migration_history == 0, "current-version project imports should preserve empty migration history")
    local restored_object = ObjectRegistry.get_object("registry_object")
    assert_true(restored_object.ok and restored_object.data.ruleset_scope == "custom", "project import should restore object state")
    local restored_ruleset = RuleSetRegistry.get_ruleset(serialism.id)
    assert_true(restored_ruleset.ok and type(restored_ruleset.data.generator_strategy) == "function", "project import should restore executable rulesets when module_path exists")
    local restored_transform = TransformRegistry.get_transform("serial.retrograde")
    assert_true(restored_transform.ok and type(restored_transform.data.transform_function) == "function", "project import should restore executable transforms from live rulesets")
    local restored_lens = AnalysisRegistry.get_lens("serial.row_form")
    assert_true(restored_lens.ok and restored_lens.data.ruleset_id == serialism.id, "project import should restore analysis lenses")
    test_count = test_count + 1

    local temp_ruleset_path = Ids.generate("ruleset_state") .. ".json"
    local saved_ruleset_state = Persistence.save_ruleset(temp_ruleset_path, serialism)
    assert_true(saved_ruleset_state.ok, "persistence should save ruleset state")
    local loaded_ruleset_state = Persistence.load_ruleset(temp_ruleset_path)
    assert_true(loaded_ruleset_state.ok, "persistence should load ruleset state")
    assert_true(loaded_ruleset_state.data.module_path == serialism.module_path, "ruleset persistence should preserve module path")
    assert_true(loaded_ruleset_state.data.serialization_version == 2, "ruleset persistence should preserve current serialization version")
    test_count = test_count + 1

    local temp_profile_path = Ids.generate("profile_state") .. ".json"
    local saved_profile_state = Persistence.save_profile(temp_profile_path, {
        id = "serial.persistence",
        active_ruleset_id = serialism.id,
        version = 3,
    })
    assert_true(saved_profile_state.ok, "persistence should save profile state")
    local loaded_profile_state = Persistence.load_profile(temp_profile_path)
    assert_true(loaded_profile_state.ok, "persistence should load profile state")
    assert_true(loaded_profile_state.data.version == 3, "profile persistence should preserve version")
    assert_true(loaded_profile_state.data.active_ruleset_id == serialism.id, "profile persistence should preserve ruleset references")
    assert_true(#loaded_profile_state.warnings >= 1 and loaded_profile_state.warnings[1].code == "persistence.profile.version_passthrough", "profile persistence should warn when preserving higher profile versions without migration dispatch")
    test_count = test_count + 1

    local fallback_snapshot = {
        schema_version = 1,
        rulesets = {
            {
                id = "persisted.only",
                name = "Persisted Only",
                domain = "custom",
                object_types = { "Artifact" },
                constraints = {},
                transformations = {},
                transforms = {},
                analysis_lenses = {
                    { id = "persisted.lens", name = "Persisted Lens", ruleset_id = "persisted.only" },
                },
                serialization_version = 1,
            },
        },
        transforms = {
            {
                id = "persisted.transform",
                ruleset_id = "persisted.only",
                input_types = { "Artifact" },
                output_types = { "Artifact" },
                has_transform_function = false,
            },
        },
        analysis_lenses = {
            { id = "persisted.lens", name = "Persisted Lens", ruleset_id = "persisted.only" },
        },
    }
    local fallback_import = Persistence.import_project_state(fallback_snapshot, {
        reset_registries = true,
        load_ruleset_modules = false,
    })
    assert_true(fallback_import.ok, "project import should support persisted-only ruleset state")
    local fallback_ruleset = RuleSetRegistry.get_ruleset("persisted.only")
    assert_true(fallback_ruleset.ok and fallback_ruleset.data.serialization_version == 2, "persisted-only rulesets should migrate and restore metadata")
    assert_true(#fallback_import.warnings >= 1, "persisted-only ruleset import should emit migration warning when upgrading old serialization state")
    local fallback_ruleset_description = RuleSetRegistry.describe_ruleset("persisted.only")
    assert_true(fallback_ruleset_description.ok and fallback_ruleset_description.data.executable == false, "persisted-only rulesets should expose non-executable state")
    local fallback_generation = Generator.generate(fallback_ruleset.data, {})
    assert_true(not fallback_generation.ok and fallback_generation.errors[1].code == "ruleset.not_executable", "persisted-only rulesets should fail generation clearly")
    local fallback_evaluation = Evaluator.evaluate(fallback_ruleset.data, {})
    assert_true(not fallback_evaluation.ok and fallback_evaluation.errors[1].code == "ruleset.not_executable", "persisted-only rulesets should fail evaluation clearly")
    local fallback_transform = TransformRegistry.get_transform("persisted.transform")
    assert_true(fallback_transform.ok and fallback_transform.data.ruleset_id == "persisted.only", "persisted-only transforms should restore metadata")
    local fallback_transform_description = TransformRegistry.describe_transform("persisted.transform")
    assert_true(fallback_transform_description.ok and fallback_transform_description.data.executable == false, "persisted-only transforms should expose non-executable state")
    local fallback_transform_apply = require("reaform.core.transformation").apply(fallback_transform.data, {}, {})
    assert_true(not fallback_transform_apply.ok and fallback_transform_apply.errors[1].code == "transformation.not_executable", "persisted-only transforms should fail execution clearly")
    local described_from_main = ReaForm.describe_ruleset("persisted.only")
    assert_true(described_from_main ~= nil and described_from_main.execution_state == "persisted_metadata", "main should expose persisted-only ruleset execution state")
    local resolved_persisted = ReaForm.resolve_ruleset("persisted.only")
    assert_true(resolved_persisted.ok and resolved_persisted.data.execution_state == "persisted_metadata", "main should resolve persisted-only imported rulesets from the registry")
    test_count = test_count + 1

    local migrated_project = Persistence.migrate_project_state({
        schema_version = 1,
        rulesets = {},
    })
    assert_true(migrated_project.ok and migrated_project.data.schema_version == 2, "project migration should upgrade schema version 1 to 2")
    assert_true(type(migrated_project.data.migration_history) == "table" and #migrated_project.data.migration_history == 1, "project migration should record migration history")
    assert_true(#migrated_project.warnings >= 1 and migrated_project.warnings[1].code == "persistence.project.migrated_v1_to_v2", "project migration should report v1 to v2 upgrade")
    test_count = test_count + 1

    local migrated_ruleset = Persistence.migrate_ruleset_state({
        id = "legacy.ruleset",
        name = "Legacy RuleSet",
        domain = "custom",
        object_types = { "Artifact" },
        constraints = {},
        transformations = {
            {
                id = "legacy.transform",
                input_types = { "Artifact" },
                output_types = { "Artifact" },
                has_transform_function = false,
            },
        },
        serialization_version = 1,
    })
    assert_true(migrated_ruleset.ok and migrated_ruleset.data.serialization_version == 2, "ruleset migration should upgrade serialization version 1 to 2")
    assert_true(type(migrated_ruleset.data.transforms) == "table" and #migrated_ruleset.data.transforms == 1, "ruleset migration should canonicalize transforms array")
    assert_true(type(migrated_ruleset.data.transformations) == "table" and #migrated_ruleset.data.transformations == 1, "ruleset migration should preserve compatibility transformations alias")
    assert_true(#migrated_ruleset.warnings >= 1 and migrated_ruleset.warnings[1].code == "persistence.ruleset.migrated_v1_to_v2", "ruleset migration should report v1 to v2 upgrade")
    test_count = test_count + 1

    local future_project_import = Persistence.import_project_state({
        schema_version = 99,
    }, {
        reset_registries = false,
    })
    assert_true(not future_project_import.ok and future_project_import.errors[1].code == "persistence.unsupported_project_schema_version", "project import should reject unsupported future schema versions")
    test_count = test_count + 1

    local future_ruleset_path = Ids.generate("future_ruleset_state") .. ".json"
    local future_ruleset_handle = assert(io.open(future_ruleset_path, "w"))
    future_ruleset_handle:write('{"id":"future.ruleset","name":"Future RuleSet","domain":"custom","object_types":["Artifact"],"constraints":[],"transformations":[],"has_generator_strategy":false,"has_evaluation_strategy":false,"serialization_version":99}')
    future_ruleset_handle:close()
    local future_ruleset_load = Persistence.load_ruleset(future_ruleset_path)
    assert_true(not future_ruleset_load.ok and future_ruleset_load.errors[1].code == "persistence.unsupported_ruleset_serialization_version", "ruleset load should reject unsupported future serialization versions")
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
