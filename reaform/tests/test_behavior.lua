local Generator = require("reaform.engine.generator")
local ReaForm = require("main")

local serialism = ReaForm.load_ruleset("serialism")
local neo_riemannian = ReaForm.load_ruleset("neo_riemannian")
local counterpoint = ReaForm.load_ruleset("counterpoint")
local dummy = ReaForm.load_ruleset("custom")

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

    ReaForm.reset_state()
    local registered_builtins = ReaForm.register_builtin_rulesets()
    assert_true(registered_builtins.ok and registered_builtins.data.count == 5, "main should register built-in rulesets through one orchestration helper")
    local resolved_serialism = ReaForm.resolve_ruleset("serialism.basic_row")
    assert_true(resolved_serialism.ok and resolved_serialism.data.id == serialism.id, "main should resolve registered rulesets by persisted id")
    local resolved_transform = ReaForm.resolve_transform("nr.P")
    assert_true(resolved_transform.ok and resolved_transform.data.ruleset_id == neo_riemannian.id, "main should resolve registered transforms by id")
    test_count = test_count + 1

    local ruleset_modules = ReaForm.get_ruleset_module_map()
    assert_true(ruleset_modules.serialism == "reaform.rulesets.serialism.ruleset", "main should expose directory-level ruleset module paths")
    local described_serialism = ReaForm.describe_ruleset("serialism")
    assert_true(described_serialism ~= nil and described_serialism.executable == true, "main should describe live rulesets as executable")
    test_count = test_count + 1

    local serial_generated = ReaForm.generate("serialism", {})
    assert_true(serial_generated.ok, "serialism generation should pass")
    assert_true(serial_generated.data.generated.type == "ToneRow", "serialism should generate ToneRow")

    local serial_evaluated = ReaForm.evaluate("serialism.basic_row", {
        target = serial_generated.data.generated,
    })
    assert_true(serial_evaluated.ok, "serialism evaluation should pass")
    assert_true(serial_evaluated.data.evaluation.passed == true, "serialism evaluation should pass without voice objects")
    test_count = test_count + 1

    local triad = Generator.generate(neo_riemannian, {}).data.generated
    local p_transform = find_transformation(neo_riemannian, "nr.P")
    assert_true(p_transform ~= nil, "neo-riemannian P transformation should exist")

    local transformed = ReaForm.apply_transform("nr.P", triad, {})
    assert_true(transformed.ok, "neo-riemannian transformation should run")
    assert_true(transformed.data.output.type == "Triad", "neo-riemannian transformation should not require line/species/cantus")
    test_count = test_count + 1

    local cp_generated = ReaForm.generate("counterpoint", {
        reference = { segments = { "x", "y", "z" } },
    })
    assert_true(cp_generated.ok, "counterpoint generation should use generic generator API")

    local cp_eval = ReaForm.evaluate(counterpoint, {
        candidate = cp_generated.data.generated.properties,
        reference = { segments = { "x", "y", "z" } },
    })
    assert_true(cp_eval.ok, "counterpoint evaluation should use generic evaluator API")
    assert_true(cp_eval.data.evaluation.passed == true, "counterpoint should pass through shared APIs")
    test_count = test_count + 1

    local dummy_generated = ReaForm.generate(dummy, {})
    assert_true(dummy_generated.ok, "dummy ruleset should generate without engine changes")

    local dummy_eval = ReaForm.evaluate(dummy, {
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
