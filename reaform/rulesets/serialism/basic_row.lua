local function mod12(n)
    local value = n % 12
    if value < 0 then
        value = value + 12
    end
    return value
end

local function invert_row(row)
    if #row == 0 then
        return {}
    end

    local anchor = row[1]
    local output = { anchor }
    for i = 2, #row do
        local interval = row[i] - anchor
        output[i] = mod12(anchor - interval)
    end
    return output
end

local ruleset = {
    id = "serialism.basic_row",
    name = "Serialism Basic Row",
    domain = "serialism",
    object_types = { "ToneRow" },
    constraints = {
        {
            id = "serial.row_length",
            description = "Tone row must contain 12 elements.",
            applicable_object_types = { "ToneRow" },
            evaluation_function = function(context)
                local row = (context.target and context.target.properties and context.target.properties.row) or {}
                return {
                    passed = #row == 12,
                    metadata = { row_length = #row },
                }
            end,
        },
    },
    transformations = {
        {
            id = "serial.retrograde",
            input_types = { "ToneRow" },
            output_types = { "ToneRow" },
            transform_function = function(input)
                local row = (input.properties and input.properties.row) or {}
                local out = {}
                for i = #row, 1, -1 do
                    out[#out + 1] = row[i]
                end

                return {
                    id = input.id .. "_retrograde",
                    type = "ToneRow",
                    properties = { row = out },
                    relationships = { { type = "transforms_from", from = input.id } },
                },
                { operation = "retrograde" }
            end,
        },
        {
            id = "serial.inversion",
            input_types = { "ToneRow" },
            output_types = { "ToneRow" },
            transform_function = function(input)
                local row = (input.properties and input.properties.row) or {}
                local out = invert_row(row)
                return {
                    id = input.id .. "_inversion",
                    type = "ToneRow",
                    properties = { row = out },
                    relationships = { { type = "transforms_from", from = input.id } },
                },
                { operation = "inversion" }
            end,
        },
    },
    generator_strategy = function()
        local row = {}
        for i = 0, 11 do
            row[#row + 1] = i
        end

        return {
            id = "serial_row_0",
            type = "ToneRow",
            properties = { row = row },
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
