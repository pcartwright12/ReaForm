local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")
local Schemas = require("reaform.core.schemas")

local MusicalObject = {}

local REQUIRED_FIELDS = {
    id = "string",
    type = "string",
    properties = "table",
    relationships = "table",
}

function MusicalObject.validate(candidate)
    local normalized = Schemas.normalize_object(candidate)
    if not normalized.ok then
        return Result.fail(normalized.errors, normalized.warnings)
    end

    local legacy = Schemas.to_legacy_object(normalized.data)
    if not legacy.ok then
        return legacy
    end

    return Result.ok(legacy.data, normalized.warnings)
end

function MusicalObject.create(payload)
    local candidate = payload or {}

    local normalized = {
        id = candidate.id,
        type = candidate.type,
        properties = type(candidate.properties) == "table" and Validation.copy_table(candidate.properties) or {},
        relationships = type(candidate.relationships) == "table" and Validation.copy_table(candidate.relationships) or {},
    }

    return MusicalObject.validate(normalized)
end

function MusicalObject.normalize(payload)
    return Schemas.normalize_object(payload)
end

return MusicalObject
