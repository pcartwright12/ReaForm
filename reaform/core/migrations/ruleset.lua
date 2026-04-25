local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")

local RulesetMigration = {
    CURRENT_SERIALIZATION_VERSION = 2,
}

local function migrate_v1_to_v2(ruleset_state)
    local migrated = Validation.copy_table(ruleset_state)
    local transforms = Validation.ensure_array(migrated.transforms)
    if #transforms == 0 then
        transforms = Validation.ensure_array(migrated.transformations)
    end

    migrated.transforms = transforms
    migrated.transformations = Validation.copy_table(transforms)
    migrated.analysis_lenses = Validation.ensure_array(migrated.analysis_lenses)
    migrated.constraints = Validation.ensure_array(migrated.constraints)
    if migrated.has_generator_strategy == nil then
        migrated.has_generator_strategy = type(migrated.generator_strategy) == "function"
    end
    if migrated.has_evaluation_strategy == nil then
        migrated.has_evaluation_strategy = type(migrated.evaluation_strategy) == "function"
    end
    migrated.serialization_version = 2

    return Result.ok(migrated, {
        Validation.warning(
            "persistence.ruleset.migrated_v1_to_v2",
            "Persisted RuleSet state was migrated from serialization_version 1 to 2.",
            "serialization_version",
            { ruleset_id = migrated.id }
        ),
    })
end

local RULESET_MIGRATORS = {
    [1] = migrate_v1_to_v2,
}

function RulesetMigration.migrate(ruleset_state)
    if not Validation.is_table(ruleset_state) then
        return Result.fail({
            Validation.error("ruleset.invalid_state", "Persisted RuleSet state must be a table.", nil, nil),
        })
    end

    local migrated = Validation.copy_table(ruleset_state)
    local warnings = {}
    local serialization_version = migrated.serialization_version

    if serialization_version == nil then
        serialization_version = 1
        warnings[#warnings + 1] = Validation.warning(
            "persistence.ruleset.assumed_serialization_version",
            "Persisted RuleSet state did not declare serialization_version; assuming version 1.",
            "serialization_version",
            { ruleset_id = migrated.id }
        )
    end

    if not Validation.is_number(serialization_version) or serialization_version < 1 then
        return Result.fail({
            Validation.error(
                "persistence.invalid_ruleset_serialization_version",
                "Persisted RuleSet serialization_version must be a positive number.",
                "serialization_version",
                { ruleset_id = migrated.id, received_value = serialization_version }
            ),
        })
    end

    if serialization_version > RulesetMigration.CURRENT_SERIALIZATION_VERSION then
        return Result.fail({
            Validation.error(
                "persistence.unsupported_ruleset_serialization_version",
                "Persisted RuleSet serialization_version is newer than this repository supports.",
                "serialization_version",
                {
                    ruleset_id = migrated.id,
                    received_version = serialization_version,
                    supported_version = RulesetMigration.CURRENT_SERIALIZATION_VERSION,
                }
            ),
        })
    end

    migrated.serialization_version = serialization_version

    while migrated.serialization_version < RulesetMigration.CURRENT_SERIALIZATION_VERSION do
        local migrator = RULESET_MIGRATORS[migrated.serialization_version]
        if type(migrator) ~= "function" then
            return Result.fail({
                Validation.error(
                    "persistence.missing_ruleset_migrator",
                    "No persisted RuleSet migrator is available for this serialization_version.",
                    "serialization_version",
                    { ruleset_id = migrated.id, version = migrated.serialization_version, supported_version = RulesetMigration.CURRENT_SERIALIZATION_VERSION }
                ),
            }, warnings)
        end

        local stepped = migrator(migrated)
        if not stepped.ok then
            return stepped
        end

        migrated = stepped.data
        warnings = Result.merge_warnings(warnings, stepped.warnings)
    end

    return Result.ok(migrated, warnings)
end

return RulesetMigration
