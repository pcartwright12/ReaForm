local ruleset = {
    id = "counterpoint.species_1",
    name = "Counterpoint Species 1 (Minimal)",
    domain = "counterpoint",
    object_types = { "SpeciesLine", "ReferenceLine" },
    constraints = {
        {
            id = "cp.same_length",
            description = "Candidate and reference line should have same segment count.",
            applicable_object_types = { "SpeciesLine", "ReferenceLine" },
            evaluation_function = function(context)
                local candidate = context.candidate or {}
                local reference = context.reference or {}
                local c = candidate.segments or {}
                local r = reference.segments or {}
                return {
                    passed = #c == #r,
                    metadata = { candidate_count = #c, reference_count = #r },
                }
            end,
        },
    },
    transformations = {},
    generator_strategy = function(context)
        local source = (context.reference and context.reference.segments) or { "a", "b", "c" }
        local segments = {}
        for index, token in ipairs(source) do
            segments[index] = token .. "_variant"
        end

        return {
            id = "cp_generated_1",
            type = "SpeciesLine",
            properties = { segments = segments },
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
