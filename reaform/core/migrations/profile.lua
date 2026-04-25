local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")

local ProfileMigration = {}

function ProfileMigration.migrate(profile_state)
    if not Validation.is_table(profile_state) then
        return Result.fail({
            Validation.error("profile.invalid_state", "Persisted Profile state must be a table.", nil, nil),
        })
    end

    local migrated = Validation.copy_table(profile_state)
    local warnings = {}
    local version = migrated.version

    if version == nil then
        version = 1
        warnings[#warnings + 1] = Validation.warning(
            "persistence.profile.assumed_version",
            "Persisted Profile state did not declare version; assuming version 1.",
            "version",
            { profile_id = migrated.id }
        )
    end

    if not Validation.is_number(version) or version < 1 then
        return Result.fail({
            Validation.error(
                "persistence.invalid_profile_version",
                "Persisted Profile version must be a positive number.",
                "version",
                { profile_id = migrated.id, received_value = version }
            ),
        })
    end

    migrated.version = version

    if version > 1 then
        warnings[#warnings + 1] = Validation.warning(
            "persistence.profile.version_passthrough",
            "Persisted Profile version is preserved, but profile-specific migration dispatch is not yet implemented.",
            "version",
            { profile_id = migrated.id, version = version }
        )
    end

    return Result.ok(migrated, warnings)
end

return ProfileMigration
