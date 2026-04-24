local ruleset = {
    id = "custom.dummy",
    name = "Dummy Custom RuleSet",
    domain = "custom",
    object_types = { "DummyObject" },
    constraints = {
        {
            id = "dummy.always_pass",
            description = "Always passes for pluggability tests.",
            applicable_object_types = { "DummyObject" },
            evaluation_function = function()
                return { passed = true, metadata = { reason = "always_pass" } }
            end,
        },
    },
    transformations = {},
    generator_strategy = function()
        return {
            id = "dummy_1",
            type = "DummyObject",
            properties = { marker = "dummy" },
            relationships = {},
        }
    end,
    evaluation_strategy = function(payload)
        return {
            classification = "pass",
            passed = true,
            score = #payload.constraints,
        }
    end,
}

return ruleset
