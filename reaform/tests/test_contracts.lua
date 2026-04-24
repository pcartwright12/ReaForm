local MusicalObject = require("reaform.core.musical_object")
local RuleSet = require("reaform.core.ruleset")
local Constraint = require("reaform.core.constraint")
local Transformation = require("reaform.core.transformation")

local Tests = {}

local function assert_true(value, message)
    if not value then
        error(message or "expected true", 2)
    end
end

function Tests.run()
    local test_count = 0

    local musical_object = MusicalObject.create({
        id = "obj_1",
        type = "Material",
        properties = { anything = "allowed" },
        relationships = {},
    })
    assert_true(musical_object.ok, "musical object should validate")
    test_count = test_count + 1

    local missing_field = MusicalObject.validate({
        id = "obj_2",
        properties = {},
        relationships = {},
    })
    assert_true(not missing_field.ok, "missing type should fail")
    test_count = test_count + 1

    local invalid_ruleset = RuleSet.validate({ id = "x" })
    assert_true(not invalid_ruleset.ok, "incomplete ruleset should fail")
    test_count = test_count + 1

    local unknown_field_ruleset = RuleSet.validate({
        id = "r1",
        name = "R1",
        domain = "custom",
        object_types = { "A" },
        constraints = {},
        transformations = {},
        generator_strategy = function() return {} end,
        evaluation_strategy = function() return { passed = true } end,
        future_extension = { enabled = true },
    })
    assert_true(unknown_field_ruleset.ok, "ruleset with unknown field should pass")
    assert_true(#unknown_field_ruleset.warnings >= 1, "ruleset should emit unknown field warning")
    test_count = test_count + 1

    local constraint = {
        id = "c1",
        description = "simple",
        applicable_object_types = { "A" },
        evaluation_function = function(ctx)
            return { passed = ctx.flag == true, metadata = { checked = true } }
        end,
    }

    local constraint_result = Constraint.evaluate(constraint, { flag = true })
    assert_true(constraint_result.ok, "constraint should execute")
    assert_true(constraint_result.data.passed == true, "constraint should pass")
    test_count = test_count + 1

    local transformation = {
        id = "t1",
        input_types = { "A" },
        output_types = { "A" },
        transform_function = function(input)
            return { id = input.id .. "_t", type = input.type, properties = {}, relationships = {} }, { op = "t" }
        end,
    }

    local transform_result = Transformation.apply(transformation, { id = "a", type = "A" }, {})
    assert_true(transform_result.ok, "transformation should execute")
    assert_true(transform_result.data.output.id == "a_t", "transformation should return updated object")
    test_count = test_count + 1

    return {
        name = "test_contracts",
        count = test_count,
    }
end

return Tests
