local Schemas = require("reaform.core.schemas")
local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local Ids = require("reaform.core.ids")

local ObjectRegistry = {
    _objects = {},
}

function ObjectRegistry.reset()
    ObjectRegistry._objects = {}
end

function ObjectRegistry.create_object(object_type, payload)
    local candidate = Validation.copy_table(payload or {})
    candidate.object_type = object_type or candidate.object_type or candidate.type
    local normalized = Schemas.normalize_object(candidate)
    if not normalized.ok then
        return normalized
    end

    local object = normalized.data
    if not Validation.is_non_empty_string(object.id) then
        object.id = Ids.generate("object")
    end

    ObjectRegistry._objects[object.id] = Validation.copy_table(object)
    return Result.ok(Validation.copy_table(object), normalized.warnings)
end

function ObjectRegistry.get_object(id)
    local object = ObjectRegistry._objects[id]
    if object == nil then
        return Result.fail({})
    end

    return Result.ok(Validation.copy_table(object))
end

function ObjectRegistry.update_object(id, patch)
    local existing = ObjectRegistry._objects[id]
    if existing == nil then
        return Result.fail({})
    end

    local merged = Validation.copy_table(existing)
    for key, value in pairs(patch or {}) do
        merged[key] = Validation.copy_table(value)
    end
    merged.id = id
    merged.updated_at = Ids.timestamp()

    local normalized = Schemas.normalize_object(merged)
    if not normalized.ok then
        return normalized
    end

    ObjectRegistry._objects[id] = Validation.copy_table(normalized.data)
    return Result.ok(Validation.copy_table(normalized.data), normalized.warnings)
end

function ObjectRegistry.list_objects(filter)
    local matches = {}
    local wanted_type = filter and (filter.object_type or filter.type) or nil
    local wanted_ruleset_scope = filter and filter.ruleset_scope or nil

    for _, object in pairs(ObjectRegistry._objects) do
        local include = true
        if wanted_type ~= nil and object.object_type ~= wanted_type then
            include = false
        end
        if wanted_ruleset_scope ~= nil and object.ruleset_scope ~= wanted_ruleset_scope then
            include = false
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(object)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

return ObjectRegistry
