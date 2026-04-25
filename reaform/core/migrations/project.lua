local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")

local ProjectMigration = {
    CURRENT_SCHEMA_VERSION = 2,
}

local function migrate_v1_to_v2(snapshot)
    local migrated = Validation.copy_table(snapshot)
    migrated.metadata = Validation.copy_table(migrated.metadata or {})
    migrated.objects = Validation.ensure_array(migrated.objects)
    migrated.relationships = Validation.ensure_array(migrated.relationships)
    migrated.analyses = Validation.ensure_array(migrated.analyses)
    migrated.rulesets = Validation.ensure_array(migrated.rulesets)
    migrated.profiles = Validation.ensure_array(migrated.profiles)
    migrated.transforms = Validation.ensure_array(migrated.transforms)
    migrated.analysis_lenses = Validation.ensure_array(migrated.analysis_lenses)
    migrated.migration_history = Validation.ensure_array(migrated.migration_history)
    migrated.migration_history[#migrated.migration_history + 1] = {
        from_version = 1,
        to_version = 2,
        reason = "canonicalize_project_snapshot_collections",
    }
    migrated.schema_version = 2

    return Result.ok(migrated, {
        Validation.warning(
            "persistence.project.migrated_v1_to_v2",
            "Project snapshot was migrated from schema_version 1 to 2.",
            "schema_version",
            nil
        ),
    })
end

local PROJECT_MIGRATORS = {
    [1] = migrate_v1_to_v2,
}

function ProjectMigration.migrate(snapshot)
    if not Validation.is_table(snapshot) then
        return Result.fail({
            Validation.error("persistence.invalid_snapshot", "Project snapshot must be a table.", nil, nil),
        })
    end

    local migrated = Validation.copy_table(snapshot)
    local warnings = {}
    local schema_version = migrated.schema_version

    if schema_version == nil then
        schema_version = 1
        warnings[#warnings + 1] = Validation.warning(
            "persistence.project.assumed_schema_version",
            "Project snapshot did not declare schema_version; assuming version 1.",
            "schema_version",
            nil
        )
    end

    if not Validation.is_number(schema_version) or schema_version < 1 then
        return Result.fail({
            Validation.error(
                "persistence.invalid_project_schema_version",
                "Project schema_version must be a positive number.",
                "schema_version",
                { received_value = schema_version }
            ),
        })
    end

    if schema_version > ProjectMigration.CURRENT_SCHEMA_VERSION then
        return Result.fail({
            Validation.error(
                "persistence.unsupported_project_schema_version",
                "Project snapshot schema_version is newer than this repository supports.",
                "schema_version",
                { received_version = schema_version, supported_version = ProjectMigration.CURRENT_SCHEMA_VERSION }
            ),
        })
    end

    migrated.schema_version = schema_version

    while migrated.schema_version < ProjectMigration.CURRENT_SCHEMA_VERSION do
        local migrator = PROJECT_MIGRATORS[migrated.schema_version]
        if type(migrator) ~= "function" then
            return Result.fail({
                Validation.error(
                    "persistence.missing_project_migrator",
                    "No project snapshot migrator is available for this schema_version.",
                    "schema_version",
                    { version = migrated.schema_version, supported_version = ProjectMigration.CURRENT_SCHEMA_VERSION }
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

return ProjectMigration
