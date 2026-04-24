local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local Transformation = require("reaform.core.transformation")

local TransformRegistry = {
    _transforms = {},
}

function TransformRegistry.reset()
    TransformRegistry._transforms = {}
end

function TransformRegistry.register_transform(ruleset_id, transform)
    if not Validation.is_non_empty_string(ruleset_id) then
        return Result.fail({
            Validation.error("transform.invalid_ruleset_id", "Transform ruleset_id is required.", "ruleset_id", nil),
        })
    end

    local checked = Transformation.validate(transform)
    if not checked.ok then
        return checked
    end

    local stored = Validation.copy_table(transform)
    stored.ruleset_id = ruleset_id
    TransformRegistry._transforms[stored.id] = stored
    return Result.ok(Validation.copy_table(stored), checked.warnings)
end

function TransformRegistry.register_ruleset_transforms(ruleset)
    if not Validation.is_table(ruleset) or not Validation.is_non_empty_string(ruleset.id) then
        return Result.fail({
            Validation.error("transform.invalid_ruleset", "Ruleset with id is required to register transforms.", nil, nil),
        })
    end

    local stored = {}
    local warnings = {}
    for _, transform in ipairs(Validation.ensure_array(ruleset.transformations or ruleset.transforms)) do
        local registered = TransformRegistry.register_transform(ruleset.id, transform)
        if not registered.ok then
            return registered
        end
        stored[#stored + 1] = registered.data
        warnings = Result.merge_warnings(warnings, registered.warnings)
    end

    return Result.ok(stored, warnings)
end

function TransformRegistry.get_transform(id)
    local transform = TransformRegistry._transforms[id]
    if transform == nil then
        return Result.fail({})
    end

    return Result.ok(Validation.copy_table(transform))
end

function TransformRegistry.list_transforms(filter)
    local matches = {}
    for _, transform in pairs(TransformRegistry._transforms) do
        local include = true
        if filter and filter.ruleset_id ~= nil and transform.ruleset_id ~= filter.ruleset_id then
            include = false
        end
        if include and filter and filter.input_type ~= nil then
            include = false
            for _, input_type in ipairs(Validation.ensure_array(transform.input_types)) do
                if input_type == filter.input_type then
                    include = true
                    break
                end
            end
        end
        if include and filter and filter.output_type ~= nil then
            include = false
            for _, output_type in ipairs(Validation.ensure_array(transform.output_types)) do
                if output_type == filter.output_type then
                    include = true
                    break
                end
            end
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(transform)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

return TransformRegistry
