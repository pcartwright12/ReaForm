local Generator = require("reaform.engine.generator")
local Evaluator = require("reaform.engine.evaluator")
local Transformation = require("reaform.core.transformation")

local serialism = require("reaform.rulesets.serialism.basic_row")
local neo_riemannian = require("reaform.rulesets.neo_riemannian.basic_triads")
local counterpoint = require("reaform.rulesets.counterpoint.species_1")
local dummy = require("reaform.rulesets.custom.dummy")

local Tests = {}

local function assert_true(value, message)
    if not value then
        error(message or "expected true", 2)
    end
end

local function find_transformation(ruleset, id)
    for _, transformation in ipairs(ruleset.transformations) do
        if transformation.id == id then
            return transformation
        end
    end
    return nil
end

function Tests.run()
    local test_count = 0

    local serial_generated = Generator.generate(serialism, {})
    assert_true(serial_generated.ok, "serialism generation should pass")
    assert_true(serial_generated.data.generated.type == "ToneRow", "serialism should generate ToneRow")

    local serial_evaluated = Evaluator.evaluate(serialism, {
        target = serial_generated.data.generated,
    })
    assert_true(serial_evaluated.ok, "serialism evaluation should pass")
    assert_true(serial_evaluated.data.evaluation.passed == true, "serialism evaluation should pass without voice objects")
    test_count = test_count + 1

    local triad = Generator.generate(neo_riemannian, {}).data.generated
    local p_transform = find_transformation(neo_riemannian, "nr.P")
    assert_true(p_transform ~= nil, "neo-riemannian P transformation should exist")

    local transformed = Transformation.apply(p_transform, triad, {})
    assert_true(transformed.ok, "neo-riemannian transformation should run")
    assert_true(transformed.data.output.type == "Triad", "neo-riemannian transformation should not require line/species/cantus")
    test_count = test_count + 1

    local cp_generated = Generator.generate(counterpoint, {
        reference = { segments = { "x", "y", "z" } },
    })
    assert_true(cp_generated.ok, "counterpoint generation should use generic generator API")

    local cp_eval = Evaluator.evaluate(counterpoint, {
        candidate = cp_generated.data.generated.properties,
        reference = { segments = { "x", "y", "z" } },
    })
    assert_true(cp_eval.ok, "counterpoint evaluation should use generic evaluator API")
    assert_true(cp_eval.data.evaluation.passed == true, "counterpoint should pass through shared APIs")
    test_count = test_count + 1

    local dummy_generated = Generator.generate(dummy, {})
    assert_true(dummy_generated.ok, "dummy ruleset should generate without engine changes")

    local dummy_eval = Evaluator.evaluate(dummy, {
        target = dummy_generated.data.generated,
    })
    assert_true(dummy_eval.ok, "dummy ruleset should evaluate without core/engine modification")
    assert_true(dummy_eval.data.evaluation.classification == "pass", "dummy ruleset classification should pass")
    test_count = test_count + 1

    return {
        name = "test_behavior",
        count = test_count,
    }
end

return Tests
