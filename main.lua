local function get_script_directory()
    local source = debug.getinfo(1, "S").source
    if type(source) ~= "string" or source:sub(1, 1) ~= "@" then
        return "."
    end

    local script_path = source:sub(2)
    local normalized = script_path:gsub("\\", "/")
    local directory = normalized:match("^(.*)/[^/]+$")
    return directory or "."
end

local function prepend_package_path(base_directory)
    package.path = table.concat({
        base_directory .. "/?.lua",
        base_directory .. "/?/init.lua",
        "./?.lua",
        "./?/init.lua",
        package.path,
    }, ";")
end

prepend_package_path(get_script_directory())

local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local RuleSetRegistry = require("reaform.core.ruleset_registry")
local ObjectRegistry = require("reaform.core.object_registry")
local RelationshipGraph = require("reaform.core.relationship_graph")
local AnalysisRegistry = require("reaform.core.analysis_registry")
local ProfileRegistry = require("reaform.core.profile_registry")
local TransformRegistry = require("reaform.core.transform_registry")
local Persistence = require("reaform.core.persistence")
local Transformation = require("reaform.core.transformation")
local Generator = require("reaform.engine.generator")
local Evaluator = require("reaform.engine.evaluator")

local ReaForm = {}

local RULESET_MODULES = {
    counterpoint = "reaform.rulesets.counterpoint.ruleset",
    serialism = "reaform.rulesets.serialism.ruleset",
    neo_riemannian = "reaform.rulesets.neo_riemannian.ruleset",
    schenkerian = "reaform.rulesets.schenkerian.ruleset",
    custom = "reaform.rulesets.custom.ruleset",
}

function ReaForm.get_ruleset_module_map()
    local out = {}
    for key, value in pairs(RULESET_MODULES) do
        out[key] = value
    end
    return out
end

function ReaForm.load_ruleset(name_or_module_path)
    local module_path = RULESET_MODULES[name_or_module_path] or name_or_module_path
    return require(module_path)
end

local function make_resolution_error(code, message, field, metadata)
    return Result.fail({
        {
            code = code,
            message = message,
            field = field,
            severity = "error",
            metadata = metadata,
        },
    })
end

function ReaForm.resolve_ruleset(candidate)
    if Validation.is_table(candidate) then
        return Result.ok(candidate)
    end

    if not Validation.is_non_empty_string(candidate) then
        return make_resolution_error("main.invalid_ruleset_reference", "RuleSet reference must be a non-empty string or table.", "ruleset", {
            received_type = type(candidate),
        })
    end

    local registered = RuleSetRegistry.get_ruleset(candidate)
    if registered.ok then
        return registered
    end

    local module_path = RULESET_MODULES[candidate] or candidate
    local ok, loaded_or_error = pcall(require, module_path)
    if not ok then
        return make_resolution_error("main.ruleset_not_found", "RuleSet could not be resolved from registry or module path.", "ruleset", {
            ruleset_reference = candidate,
            module_path = module_path,
            reason = tostring(loaded_or_error),
        })
    end

    if type(loaded_or_error) ~= "table" then
        return make_resolution_error("main.ruleset_module_invalid", "Resolved RuleSet module must return a table.", "ruleset", {
            ruleset_reference = candidate,
            module_path = module_path,
            received_type = type(loaded_or_error),
        })
    end

    return Result.ok(loaded_or_error)
end

function ReaForm.resolve_transform(candidate)
    if Validation.is_table(candidate) then
        return Result.ok(candidate)
    end

    if not Validation.is_non_empty_string(candidate) then
        return make_resolution_error("main.invalid_transform_reference", "Transform reference must be a non-empty string or table.", "transform", {
            received_type = type(candidate),
        })
    end

    local registered = TransformRegistry.get_transform(candidate)
    if registered.ok then
        return registered
    end

    return make_resolution_error("main.transform_not_found", "Transform could not be resolved from the registry.", "transform", {
        transform_reference = candidate,
    })
end

function ReaForm.register_ruleset(name_or_module_path)
    return RuleSetRegistry.save_ruleset(ReaForm.load_ruleset(name_or_module_path))
end

function ReaForm.register_builtin_rulesets()
    local registered = {}
    local warnings = {}

    for name, _ in pairs(RULESET_MODULES) do
        local saved = ReaForm.register_ruleset(name)
        if not saved.ok then
            return saved
        end
        registered[#registered + 1] = saved.data.id
        warnings = Result.merge_warnings(warnings, saved.warnings)
    end

    table.sort(registered)
    return Result.ok({
        registered_ruleset_ids = registered,
        count = #registered,
    }, warnings)
end

function ReaForm.describe_ruleset(name_or_id)
    local module_path = RULESET_MODULES[name_or_id]
    if module_path ~= nil then
        local loaded = ReaForm.load_ruleset(name_or_id)
        return {
            id = loaded.id,
            module_path = loaded.module_path,
            execution_state = "executable",
            executable = true,
            execution_error = nil,
        }
    end

    local described = RuleSetRegistry.describe_ruleset(name_or_id)
    return described.ok and described.data or nil
end

function ReaForm.describe_transform(id)
    local described = TransformRegistry.describe_transform(id)
    return described.ok and described.data or nil
end

function ReaForm.reset_state()
    ObjectRegistry.reset()
    RelationshipGraph.reset()
    AnalysisRegistry.reset()
    RuleSetRegistry.reset()
    ProfileRegistry.reset()
    TransformRegistry.reset()
end

function ReaForm.export_project(metadata)
    return Persistence.export_project_state(metadata)
end

function ReaForm.import_project(project_or_path, options)
    if Validation.is_non_empty_string(project_or_path) then
        return Persistence.load_project_into_registries(project_or_path, options)
    end
    return Persistence.import_project_state(project_or_path, options)
end

function ReaForm.generate(ruleset_reference, context)
    local resolved = ReaForm.resolve_ruleset(ruleset_reference)
    if not resolved.ok then
        return resolved
    end

    return Generator.generate(resolved.data, context)
end

function ReaForm.evaluate(ruleset_reference, context)
    local resolved = ReaForm.resolve_ruleset(ruleset_reference)
    if not resolved.ok then
        return resolved
    end

    return Evaluator.evaluate(resolved.data, context)
end

function ReaForm.apply_transform(transform_reference, input, context)
    local resolved = ReaForm.resolve_transform(transform_reference)
    if not resolved.ok then
        return resolved
    end

    return Transformation.apply(resolved.data, input, context)
end

ReaForm.registries = {
    objects = ObjectRegistry,
    relationships = RelationshipGraph,
    analyses = AnalysisRegistry,
    rulesets = RuleSetRegistry,
    profiles = ProfileRegistry,
    transforms = TransformRegistry,
}

ReaForm.persistence = Persistence
ReaForm.generator = Generator
ReaForm.evaluator = Evaluator

return ReaForm
