local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")
local Schemas = require("reaform.core.schemas")

local ProfileRegistry = {
    _profiles = {},
}

function ProfileRegistry.reset()
    ProfileRegistry._profiles = {}
end

function ProfileRegistry.save_profile(profile)
    local normalized = Schemas.normalize_profile(profile)
    if not normalized.ok then
        return normalized
    end

    ProfileRegistry._profiles[normalized.data.id] = Validation.copy_table(normalized.data)
    return Result.ok(Validation.copy_table(normalized.data), normalized.warnings)
end

function ProfileRegistry.get_profile(id)
    local profile = ProfileRegistry._profiles[id]
    if profile == nil then
        return Result.fail({})
    end

    return Result.ok(Validation.copy_table(profile))
end

function ProfileRegistry.list_profiles(filter)
    local matches = {}
    for _, profile in pairs(ProfileRegistry._profiles) do
        local include = true
        if filter and filter.active_ruleset_id ~= nil and profile.active_ruleset_id ~= filter.active_ruleset_id then
            include = false
        end
        if include then
            matches[#matches + 1] = Validation.copy_table(profile)
        end
    end

    table.sort(matches, function(a, b)
        return a.id < b.id
    end)

    return Result.ok(matches)
end

return ProfileRegistry
