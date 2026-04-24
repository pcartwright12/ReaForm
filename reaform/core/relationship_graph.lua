local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local Ids = require("reaform.core.ids")

local RelationshipGraph = {
    _relationships = {},
}

function RelationshipGraph.reset()
    RelationshipGraph._relationships = {}
end

function RelationshipGraph.create_relationship(relationship_type, from_id, to_id, metadata)
    if not Validation.is_non_empty_string(relationship_type) then
        return Result.fail({
            Validation.error("relationship.invalid_type", "Relationship type is required.", "type", nil),
        })
    end

    if not Validation.is_non_empty_string(from_id) or not Validation.is_non_empty_string(to_id) then
        return Result.fail({
            Validation.error("relationship.invalid_endpoints", "Relationship from_id and to_id are required.", nil, nil),
        })
    end

    local relationship = {
        id = Ids.generate("relationship"),
        type = relationship_type,
        from_id = from_id,
        to_id = to_id,
        metadata = Validation.copy_table(metadata or {}),
    }

    RelationshipGraph._relationships[relationship.id] = relationship
    return Result.ok(Validation.copy_table(relationship))
end

function RelationshipGraph.get_relationships(filter)
    local matches = {}
    for _, relationship in pairs(RelationshipGraph._relationships) do
        local include = true
        if filter and filter.type ~= nil and relationship.type ~= filter.type then
            include = false
        end
        if filter and filter.from_id ~= nil and relationship.from_id ~= filter.from_id then
            include = false
        end
        if filter and filter.to_id ~= nil and relationship.to_id ~= filter.to_id then
            include = false
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(relationship)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

return RelationshipGraph
