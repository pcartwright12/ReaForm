local ruleset = {
    id = "schenkerian.basic_reduction",
    name = "Schenkerian Basic Reduction",
    domain = "schenkerian",
    module_path = "reaform.rulesets.schenkerian.ruleset",
    object_types = { "ReductionLayer" },
    analysis_lenses = {
        {
            id = "schenkerian.reduction",
            name = "Reduction Analysis",
            target_object_types = { "ReductionLayer" },
        },
    },
    constraints = {
        {
            id = "schenkerian.layer_has_events",
            description = "Reduction layer should contain at least one event.",
            applicable_object_types = { "ReductionLayer" },
            evaluation_function = function(context)
                local events = (context.target and context.target.properties and context.target.properties.events) or {}
                return {
                    passed = #events > 0,
                    metadata = { event_count = #events },
                }
            end,
        },
    },
    transformations = {},
    generator_strategy = function(context)
        local events = (context.seed_events and #context.seed_events > 0) and context.seed_events or { "structural_tone" }
        return {
            id = "schenkerian_layer_1",
            type = "ReductionLayer",
            properties = {
                level = "foreground",
                events = events,
            },
            relationships = {},
        }
    end,
    evaluation_strategy = function(payload)
        local passed = true
        for _, outcome in ipairs(payload.constraints) do
            if not outcome.passed then
                passed = false
                break
            end
        end

        return {
            classification = passed and "pass" or "hard_failure",
            passed = passed,
            score = passed and 1.0 or 0.0,
            metadata = {
                lens = "reduction",
            },
        }
    end,
}

return ruleset
