local function rotate_quality(quality, map)
    return map[quality] or quality
end

local ruleset = {
    id = "neo_riemannian.basic_triads",
    name = "Neo-Riemannian Basic Triads",
    domain = "transformational",
    module_path = "reaform.rulesets.neo_riemannian.ruleset",
    object_types = { "Triad" },
    analysis_lenses = {
        {
            id = "nr.triad_quality",
            name = "Triad Quality Analysis",
            target_object_types = { "Triad" },
        },
    },
    constraints = {
        {
            id = "nr.valid_quality",
            description = "Triad quality must be major or minor.",
            applicable_object_types = { "Triad" },
            evaluation_function = function(context)
                local quality = context.target and context.target.properties and context.target.properties.quality
                local passed = quality == "major" or quality == "minor"
                return {
                    passed = passed,
                    metadata = { quality = quality },
                }
            end,
        },
    },
    transformations = {
        {
            id = "nr.P",
            input_types = { "Triad" },
            output_types = { "Triad" },
            transform_function = function(input)
                local quality = input.properties and input.properties.quality or "major"
                return {
                    id = input.id .. "_P",
                    type = "Triad",
                    properties = {
                        root = input.properties and input.properties.root,
                        quality = rotate_quality(quality, { major = "minor", minor = "major" }),
                    },
                    relationships = { { type = "transforms_from", from = input.id } },
                },
                { operation = "P" }
            end,
        },
        {
            id = "nr.L",
            input_types = { "Triad" },
            output_types = { "Triad" },
            transform_function = function(input)
                local quality = input.properties and input.properties.quality or "major"
                return {
                    id = input.id .. "_L",
                    type = "Triad",
                    properties = {
                        root = input.properties and input.properties.root,
                        quality = rotate_quality(quality, { major = "minor", minor = "major" }),
                    },
                    relationships = { { type = "transforms_from", from = input.id } },
                },
                { operation = "L" }
            end,
        },
        {
            id = "nr.R",
            input_types = { "Triad" },
            output_types = { "Triad" },
            transform_function = function(input)
                local quality = input.properties and input.properties.quality or "major"
                return {
                    id = input.id .. "_R",
                    type = "Triad",
                    properties = {
                        root = input.properties and input.properties.root,
                        quality = rotate_quality(quality, { major = "minor", minor = "major" }),
                    },
                    relationships = { { type = "transforms_from", from = input.id } },
                },
                { operation = "R" }
            end,
        },
    },
    generator_strategy = function()
        return {
            id = "triad_c_major",
            type = "Triad",
            properties = { root = "C", quality = "major" },
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
        }
    end,
}

return ruleset
