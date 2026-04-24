local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local Ids = require("reaform.core.ids")
local Schemas = require("reaform.core.schemas")
local ObjectRegistry = require("reaform.core.object_registry")
local RelationshipGraph = require("reaform.core.relationship_graph")
local AnalysisRegistry = require("reaform.core.analysis_registry")
local RuleSetRegistry = require("reaform.core.ruleset_registry")
local ProfileRegistry = require("reaform.core.profile_registry")
local TransformRegistry = require("reaform.core.transform_registry")

local Persistence = {}

local function load_ruleset_module(module_path)
    if not Validation.is_non_empty_string(module_path) then
        return Result.fail({
            { code = "persistence.missing_module_path", message = "Persisted RuleSet state does not declare a module_path.", field = "module_path", severity = "error" },
        })
    end

    local ok, loaded_or_error = pcall(require, module_path)
    if not ok then
        return Result.fail({
            { code = "persistence.module_load_failed", message = tostring(loaded_or_error), field = "module_path", severity = "error" },
        })
    end

    if type(loaded_or_error) ~= "table" then
        return Result.fail({
            { code = "persistence.module_invalid", message = "Loaded RuleSet module must return a table.", field = "module_path", severity = "error" },
        })
    end

    return Result.ok(loaded_or_error)
end

local function escape_string(value)
    return value
        :gsub("\\", "\\\\")
        :gsub("\"", "\\\"")
        :gsub("\b", "\\b")
        :gsub("\f", "\\f")
        :gsub("\n", "\\n")
        :gsub("\r", "\\r")
        :gsub("\t", "\\t")
        :gsub("[%z\1-\31]", function(char)
            return string.format("\\u%04x", string.byte(char))
        end)
end

local function encode_json(value, seen)
    local value_type = type(value)
    if value == nil then
        return "null"
    end
    if value_type == "string" then
        return "\"" .. escape_string(value) .. "\""
    end
    if value_type == "number" or value_type == "boolean" then
        return tostring(value)
    end
    if value_type ~= "table" then
        error("unsupported JSON type: " .. value_type)
    end

    if seen[value] then
        error("cyclic table in JSON encoding")
    end
    seen[value] = true

    local parts = {}
    if Validation.is_array(value) then
        for index, item in ipairs(value) do
            parts[index] = encode_json(item, seen)
        end
        seen[value] = nil
        return "[" .. table.concat(parts, ",") .. "]"
    end

    local keys = {}
    for key, _ in pairs(value) do
        if type(key) ~= "string" then
            error("JSON object keys must be strings")
        end
        keys[#keys + 1] = key
    end
    table.sort(keys)

    for index, key in ipairs(keys) do
        parts[index] = encode_json(key, seen) .. ":" .. encode_json(value[key], seen)
    end

    seen[value] = nil
    return "{" .. table.concat(parts, ",") .. "}"
end

local function decode_error(position, message)
    error(string.format("json decode error at %d: %s", position, message))
end

local function skip_whitespace(input, position)
    local length = #input
    while position <= length do
        local char = input:sub(position, position)
        if char ~= " " and char ~= "\n" and char ~= "\r" and char ~= "\t" then
            break
        end
        position = position + 1
    end
    return position
end

local function parse_string(input, position)
    position = position + 1
    local output = {}
    local length = #input

    while position <= length do
        local char = input:sub(position, position)
        if char == "\"" then
            return table.concat(output), position + 1
        end
        if char == "\\" then
            local escaped = input:sub(position + 1, position + 1)
            if escaped == "\"" or escaped == "\\" or escaped == "/" then
                output[#output + 1] = escaped
                position = position + 2
            elseif escaped == "b" then
                output[#output + 1] = "\b"
                position = position + 2
            elseif escaped == "f" then
                output[#output + 1] = "\f"
                position = position + 2
            elseif escaped == "n" then
                output[#output + 1] = "\n"
                position = position + 2
            elseif escaped == "r" then
                output[#output + 1] = "\r"
                position = position + 2
            elseif escaped == "t" then
                output[#output + 1] = "\t"
                position = position + 2
            elseif escaped == "u" then
                local hex = input:sub(position + 2, position + 5)
                if #hex ~= 4 or not hex:match("^[0-9a-fA-F]+$") then
                    decode_error(position, "invalid unicode escape")
                end
                local code = tonumber(hex, 16)
                if code <= 255 then
                    output[#output + 1] = string.char(code)
                else
                    output[#output + 1] = "?"
                end
                position = position + 6
            else
                decode_error(position, "invalid escape sequence")
            end
        else
            output[#output + 1] = char
            position = position + 1
        end
    end

    decode_error(position, "unterminated string")
end

local function parse_number(input, position)
    local start_position = position
    local length = #input
    while position <= length do
        local char = input:sub(position, position)
        if not char:match("[%d%+%-%.eE]") then
            break
        end
        position = position + 1
    end

    local value = tonumber(input:sub(start_position, position - 1))
    if value == nil then
        decode_error(start_position, "invalid number")
    end
    return value, position
end

local parse_value

local function parse_array(input, position)
    local output = {}
    position = position + 1
    position = skip_whitespace(input, position)
    if input:sub(position, position) == "]" then
        return output, position + 1
    end

    while true do
        local value
        value, position = parse_value(input, position)
        output[#output + 1] = value
        position = skip_whitespace(input, position)

        local char = input:sub(position, position)
        if char == "]" then
            return output, position + 1
        end
        if char ~= "," then
            decode_error(position, "expected ',' or ']'")
        end
        position = skip_whitespace(input, position + 1)
    end
end

local function parse_object(input, position)
    local output = {}
    position = position + 1
    position = skip_whitespace(input, position)
    if input:sub(position, position) == "}" then
        return output, position + 1
    end

    while true do
        if input:sub(position, position) ~= "\"" then
            decode_error(position, "expected object key")
        end

        local key
        key, position = parse_string(input, position)
        position = skip_whitespace(input, position)
        if input:sub(position, position) ~= ":" then
            decode_error(position, "expected ':'")
        end
        position = skip_whitespace(input, position + 1)

        local value
        value, position = parse_value(input, position)
        output[key] = value
        position = skip_whitespace(input, position)

        local char = input:sub(position, position)
        if char == "}" then
            return output, position + 1
        end
        if char ~= "," then
            decode_error(position, "expected ',' or '}'")
        end
        position = skip_whitespace(input, position + 1)
    end
end

parse_value = function(input, position)
    position = skip_whitespace(input, position)
    local char = input:sub(position, position)
    if char == "\"" then
        return parse_string(input, position)
    end
    if char == "{" then
        return parse_object(input, position)
    end
    if char == "[" then
        return parse_array(input, position)
    end
    if char == "-" or char:match("%d") then
        return parse_number(input, position)
    end
    if input:sub(position, position + 3) == "true" then
        return true, position + 4
    end
    if input:sub(position, position + 4) == "false" then
        return false, position + 5
    end
    if input:sub(position, position + 3) == "null" then
        return nil, position + 4
    end

    decode_error(position, "unexpected token")
end

local function decode_json(input)
    if type(input) ~= "string" then
        error("json input must be a string")
    end

    local value, position = parse_value(input, 1)
    position = skip_whitespace(input, position)
    if position <= #input then
        decode_error(position, "trailing content")
    end
    return value
end

local function read_file(path)
    local handle = io.open(path, "r")
    if handle == nil then
        return nil
    end
    local content = handle:read("*a")
    handle:close()
    return content
end

local function write_file(path, content)
    local handle = io.open(path, "w")
    if handle == nil then
        return false
    end
    handle:write(content)
    handle:close()
    return true
end

function Persistence.serialize_ruleset_state(ruleset)
    return Schemas.serialize_ruleset_state(ruleset)
end

function Persistence.serialize_profile_state(profile)
    return Schemas.serialize_profile_state(profile)
end

function Persistence.export_project_state(metadata)
    local objects = ObjectRegistry.list_objects()
    local relationships = RelationshipGraph.get_relationships()
    local analyses = AnalysisRegistry.list_analyses()
    local rulesets = RuleSetRegistry.list_rulesets()
    local profiles = ProfileRegistry.list_profiles()
    local transforms = TransformRegistry.list_transforms()
    local analysis_lenses = AnalysisRegistry.list_lenses()

    local snapshot = {
        schema_version = 1,
        exported_at = Ids.timestamp(),
        metadata = Validation.copy_table(metadata or {}),
        objects = objects.data or {},
        relationships = relationships.data or {},
        analyses = analyses.data or {},
        profiles = profiles.data or {},
        transforms = {},
        analysis_lenses = analysis_lenses.data or {},
        rulesets = {},
    }

    for _, ruleset in ipairs(rulesets.data or {}) do
        local persisted = Persistence.serialize_ruleset_state(ruleset)
        if not persisted.ok then
            return persisted
        end
        snapshot.rulesets[#snapshot.rulesets + 1] = persisted.data
    end

    for _, transform in ipairs(transforms.data or {}) do
        local persisted = Schemas.serialize_transform_state(transform)
        if not persisted.ok then
            return persisted
        end
        snapshot.transforms[#snapshot.transforms + 1] = persisted.data
    end

    return Result.ok(snapshot)
end

function Persistence.save_project(path, metadata)
    local snapshot = Persistence.export_project_state(metadata)
    if not snapshot.ok then
        return snapshot
    end

    local ok, encoded_or_error = pcall(encode_json, snapshot.data, {})
    if not ok then
        return Result.fail({
            { code = "persistence.encode_failed", message = tostring(encoded_or_error), severity = "error" },
        })
    end

    if not write_file(path, encoded_or_error) then
        return Result.fail({
            { code = "persistence.write_failed", message = "Failed to write project file.", field = "path", severity = "error" },
        })
    end

    return Result.ok({
        path = path,
        schema_version = snapshot.data.schema_version,
    })
end

function Persistence.load_project(path)
    local content = read_file(path)
    if content == nil then
        return Result.fail({
            { code = "persistence.read_failed", message = "Failed to read project file.", field = "path", severity = "error" },
        })
    end

    local ok, decoded_or_error = pcall(decode_json, content)
    if not ok then
        return Result.fail({
            { code = "persistence.decode_failed", message = tostring(decoded_or_error), severity = "error" },
        })
    end

    return Result.ok(decoded_or_error)
end

function Persistence.import_project_state(snapshot, options)
    if not Validation.is_table(snapshot) then
        return Result.fail({
            { code = "persistence.invalid_snapshot", message = "Project snapshot must be a table.", severity = "error" },
        })
    end

    local import_options = Validation.copy_table(options or {})
    local reset_registries = import_options.reset_registries ~= false
    local load_ruleset_modules = import_options.load_ruleset_modules ~= false
    local warnings = {}

    if reset_registries then
        ObjectRegistry.reset()
        RelationshipGraph.reset()
        AnalysisRegistry.reset()
        RuleSetRegistry.reset()
        ProfileRegistry.reset()
        TransformRegistry.reset()
    end

    local imported_counts = {
        objects = 0,
        relationships = 0,
        analyses = 0,
        rulesets = 0,
        profiles = 0,
        transforms = 0,
        analysis_lenses = 0,
    }

    for _, ruleset_state in ipairs(Validation.ensure_array(snapshot.rulesets)) do
        local imported_result = nil

        if load_ruleset_modules and Validation.is_non_empty_string(ruleset_state.module_path) then
            local loaded_module = load_ruleset_module(ruleset_state.module_path)
            if loaded_module.ok then
                imported_result = RuleSetRegistry.save_ruleset(loaded_module.data)
            else
                ruleset_state.execution_state = "persisted_metadata"
                ruleset_state.execution_error = loaded_module.errors[1] and loaded_module.errors[1].code or "module_load_failed"
                warnings = Result.merge_warnings(warnings, {
                    Validation.warning(
                        "persistence.ruleset_module_fallback",
                        "Failed to load live RuleSet module; importing persisted RuleSet state instead.",
                        "module_path",
                        { ruleset_id = ruleset_state.id, module_path = ruleset_state.module_path, reason = loaded_module.errors[1] and loaded_module.errors[1].message }
                    ),
                })
            end
        end

        if imported_result == nil then
            imported_result = RuleSetRegistry.import_ruleset_state(ruleset_state)
        end

        if not imported_result.ok then
            return imported_result
        end

        warnings = Result.merge_warnings(warnings, imported_result.warnings)
        imported_counts.rulesets = imported_counts.rulesets + 1
    end

    for _, object_state in ipairs(Validation.ensure_array(snapshot.objects)) do
        local imported = ObjectRegistry.create_object(object_state.object_type or object_state.type, object_state)
        if not imported.ok then
            return imported
        end
        warnings = Result.merge_warnings(warnings, imported.warnings)
        imported_counts.objects = imported_counts.objects + 1
    end

    for _, relationship_state in ipairs(Validation.ensure_array(snapshot.relationships)) do
        local imported = RelationshipGraph.store_relationship(relationship_state)
        if not imported.ok then
            return imported
        end
        warnings = Result.merge_warnings(warnings, imported.warnings)
        imported_counts.relationships = imported_counts.relationships + 1
    end

    for _, analysis_state in ipairs(Validation.ensure_array(snapshot.analyses)) do
        local imported = AnalysisRegistry.store_analysis(analysis_state)
        if not imported.ok then
            return imported
        end
        warnings = Result.merge_warnings(warnings, imported.warnings)
        imported_counts.analyses = imported_counts.analyses + 1
    end

    for _, profile_state in ipairs(Validation.ensure_array(snapshot.profiles)) do
        local imported = ProfileRegistry.save_profile(profile_state)
        if not imported.ok then
            return imported
        end
        warnings = Result.merge_warnings(warnings, imported.warnings)
        imported_counts.profiles = imported_counts.profiles + 1
    end

    for _, transform_state in ipairs(Validation.ensure_array(snapshot.transforms)) do
        local existing = TransformRegistry.get_transform(transform_state.id)
        if not existing.ok then
            local imported = TransformRegistry.import_transform_state(transform_state)
            if not imported.ok then
                return imported
            end
            warnings = Result.merge_warnings(warnings, imported.warnings)
            imported_counts.transforms = imported_counts.transforms + 1
        end
    end

    for _, lens_state in ipairs(Validation.ensure_array(snapshot.analysis_lenses)) do
        local existing = AnalysisRegistry.get_lens(lens_state.id)
        if not existing.ok then
            local imported = AnalysisRegistry.register_lens(lens_state.ruleset_id, lens_state)
            if not imported.ok then
                return imported
            end
            warnings = Result.merge_warnings(warnings, imported.warnings)
            imported_counts.analysis_lenses = imported_counts.analysis_lenses + 1
        end
    end

    return Result.ok({
        schema_version = snapshot.schema_version or 1,
        imported = imported_counts,
        metadata = Validation.copy_table(snapshot.metadata or {}),
    }, warnings)
end

function Persistence.load_project_into_registries(path, options)
    local loaded = Persistence.load_project(path)
    if not loaded.ok then
        return loaded
    end

    return Persistence.import_project_state(loaded.data, options)
end

function Persistence.save_ruleset(path, ruleset)
    local persisted = Persistence.serialize_ruleset_state(ruleset)
    if not persisted.ok then
        return persisted
    end

    local ok, encoded_or_error = pcall(encode_json, persisted.data, {})
    if not ok then
        return Result.fail({
            { code = "persistence.encode_failed", message = tostring(encoded_or_error), severity = "error" },
        })
    end

    if not write_file(path, encoded_or_error) then
        return Result.fail({
            { code = "persistence.write_failed", message = "Failed to write ruleset file.", field = "path", severity = "error" },
        })
    end

    return Result.ok({
        path = path,
        serialization_version = persisted.data.serialization_version,
    })
end

function Persistence.load_ruleset(path)
    return Persistence.load_project(path)
end

function Persistence.save_profile(path, profile)
    local persisted = Persistence.serialize_profile_state(profile)
    if not persisted.ok then
        return persisted
    end

    local ok, encoded_or_error = pcall(encode_json, persisted.data, {})
    if not ok then
        return Result.fail({
            { code = "persistence.encode_failed", message = tostring(encoded_or_error), severity = "error" },
        })
    end

    if not write_file(path, encoded_or_error) then
        return Result.fail({
            { code = "persistence.write_failed", message = "Failed to write profile file.", field = "path", severity = "error" },
        })
    end

    return Result.ok({
        path = path,
        version = persisted.data.version,
    })
end

function Persistence.load_profile(path)
    return Persistence.load_project(path)
end

return Persistence
