local ReaForm = require("main")
local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")

local SessionWorkflow = {}

local function make_error(code, message, field, details)
    return Result.fail({
        {
            code = code,
            message = message,
            field = field,
            details = details,
            severity = "error",
        },
    })
end

local function build_ruleset_summary(ruleset)
    local description = ReaForm.describe_ruleset(ruleset.id) or {}
    return {
        id = ruleset.id,
        name = ruleset.name,
        domain = ruleset.domain,
        module_path = ruleset.module_path,
        execution_state = description.execution_state or "unknown",
        executable = description.executable == true,
    }
end

local function build_state_snapshot(state)
    return {
        active_ruleset_id = state.active_ruleset_id,
        last_generated_object = Validation.copy_table(state.last_generated_object),
        last_evaluation = Validation.copy_table(state.last_evaluation),
        last_error = Validation.copy_table(state.last_error),
        available_transforms = Validation.copy_table(state.available_transforms),
    }
end

local function load_active_ruleset(state)
    if not Validation.is_non_empty_string(state.active_ruleset_id) then
        return make_error(
            "workflow.missing_active_ruleset",
            "No active ruleset is selected.",
            "active_ruleset_id",
            nil
        )
    end

    local resolved = ReaForm.resolve_ruleset(state.active_ruleset_id)
    if not resolved.ok then
        return resolved
    end

    return resolved
end

local function refresh_available_transforms(state)
    if not Validation.is_non_empty_string(state.active_ruleset_id) then
        state.available_transforms = {}
        return Result.ok({})
    end

    local listed = ReaForm.registries.transforms.list_transforms({
        ruleset_id = state.active_ruleset_id,
    })
    if not listed.ok then
        state.available_transforms = {}
        return listed
    end

    state.available_transforms = listed.data or {}
    return Result.ok(Validation.copy_table(state.available_transforms))
end

local function store_object_in_registry(object, ruleset_id)
    if not Validation.is_table(object) then
        return Result.ok(nil)
    end

    local created = ReaForm.registries.objects.create_object(object.object_type or object.type, object)
    if not created.ok then
        return created
    end

    if ruleset_id ~= nil then
        local scoped = ReaForm.registries.objects.update_object(created.data.id, {
            ruleset_scope = ruleset_id,
        })
        if not scoped.ok then
            return scoped
        end
        return scoped
    end

    return created
end

function SessionWorkflow.create(options)
    local settings = Validation.copy_table(options or {})
    local state = {
        active_ruleset_id = settings.active_ruleset_id,
        last_generated_object = nil,
        last_evaluation = nil,
        last_error = nil,
        available_transforms = {},
    }

    if settings.reset_state ~= false then
        ReaForm.reset_state()
    end

    local warnings = {}
    if settings.bootstrap_builtins ~= false then
        local bootstrapped = ReaForm.register_builtin_rulesets()
        if not bootstrapped.ok then
            return bootstrapped
        end
        warnings = Result.merge_warnings(warnings, bootstrapped.warnings)
    end

    if Validation.is_non_empty_string(state.active_ruleset_id) then
        local selected = ReaForm.resolve_ruleset(state.active_ruleset_id)
        if not selected.ok then
            return selected
        end
        state.active_ruleset_id = selected.data.id
    end

    local refreshed = refresh_available_transforms(state)
    if not refreshed.ok then
        return refreshed
    end
    warnings = Result.merge_warnings(warnings, refreshed.warnings)

    local workflow = {}

    function workflow.list_rulesets(filter)
        local listed = ReaForm.registries.rulesets.list_rulesets(filter)
        if not listed.ok then
            state.last_error = listed.errors[1]
            return listed
        end

        local rulesets = {}
        for _, ruleset in ipairs(listed.data or {}) do
            rulesets[#rulesets + 1] = build_ruleset_summary(ruleset)
        end

        state.last_error = nil
        return Result.ok(rulesets)
    end

    function workflow.select_ruleset(ruleset_reference)
        local resolved = ReaForm.resolve_ruleset(ruleset_reference)
        if not resolved.ok then
            state.last_error = resolved.errors[1]
            return resolved
        end

        state.active_ruleset_id = resolved.data.id
        local refreshed_transforms = refresh_available_transforms(state)
        if not refreshed_transforms.ok then
            state.last_error = refreshed_transforms.errors[1]
            return refreshed_transforms
        end

        state.last_error = nil
        return Result.ok({
            active_ruleset_id = state.active_ruleset_id,
            available_transforms = Validation.copy_table(state.available_transforms),
        }, refreshed_transforms.warnings)
    end

    function workflow.get_active_ruleset()
        local active = load_active_ruleset(state)
        if not active.ok then
            state.last_error = active.errors[1]
            return active
        end

        state.last_error = nil
        return Result.ok(build_ruleset_summary(active.data))
    end

    function workflow.generate(context)
        local active = load_active_ruleset(state)
        if not active.ok then
            state.last_error = active.errors[1]
            return active
        end

        local generated = ReaForm.generate(active.data, context or {})
        if not generated.ok then
            state.last_error = generated.errors[1]
            return generated
        end

        local stored_object = store_object_in_registry(generated.data.generated, active.data.id)
        if not stored_object.ok then
            state.last_error = stored_object.errors[1]
            return stored_object
        end

        state.last_generated_object = stored_object.data
        state.last_error = nil
        return Result.ok({
            active_ruleset_id = active.data.id,
            generated_object = Validation.copy_table(state.last_generated_object),
            session = build_state_snapshot(state),
        }, generated.warnings)
    end

    function workflow.evaluate(context)
        local active = load_active_ruleset(state)
        if not active.ok then
            state.last_error = active.errors[1]
            return active
        end

        local evaluation_context = Validation.copy_table(context or {})
        if evaluation_context.target == nil and Validation.is_table(state.last_generated_object) then
            evaluation_context.target = Validation.copy_table(state.last_generated_object)
        end

        local evaluated = ReaForm.evaluate(active.data, evaluation_context)
        if not evaluated.ok then
            state.last_error = evaluated.errors[1]
            return evaluated
        end

        state.last_evaluation = Validation.copy_table(evaluated.data)
        state.last_error = nil
        return Result.ok({
            active_ruleset_id = active.data.id,
            evaluation = Validation.copy_table(state.last_evaluation),
            session = build_state_snapshot(state),
        }, evaluated.warnings)
    end

    function workflow.list_transforms()
        local refreshed_transforms = refresh_available_transforms(state)
        if not refreshed_transforms.ok then
            state.last_error = refreshed_transforms.errors[1]
            return refreshed_transforms
        end

        state.last_error = nil
        return Result.ok(Validation.copy_table(state.available_transforms), refreshed_transforms.warnings)
    end

    function workflow.apply_transform(transform_reference, input, context)
        local active = load_active_ruleset(state)
        if not active.ok then
            state.last_error = active.errors[1]
            return active
        end

        local source_object = input
        if source_object == nil then
            source_object = state.last_generated_object
        end

        if not Validation.is_table(source_object) then
            local missing_input = make_error(
                "workflow.missing_transform_input",
                "Transform input is required when no generated object is available in the session.",
                "input",
                { transform_reference = transform_reference }
            )
            state.last_error = missing_input.errors[1]
            return missing_input
        end

        local transform = ReaForm.resolve_transform(transform_reference)
        if not transform.ok then
            state.last_error = transform.errors[1]
            return transform
        end

        if transform.data.ruleset_id ~= active.data.id then
            local mismatch = make_error(
                "workflow.transform_ruleset_mismatch",
                "Transform does not belong to the active ruleset.",
                "transform",
                { transform_id = transform.data.id, active_ruleset_id = active.data.id, transform_ruleset_id = transform.data.ruleset_id }
            )
            state.last_error = mismatch.errors[1]
            return mismatch
        end

        local transformed = ReaForm.apply_transform(transform.data, source_object, context or {})
        if not transformed.ok then
            state.last_error = transformed.errors[1]
            return transformed
        end

        local stored_object = store_object_in_registry(transformed.data.output, active.data.id)
        if not stored_object.ok then
            state.last_error = stored_object.errors[1]
            return stored_object
        end

        state.last_generated_object = stored_object.data
        state.last_error = nil
        return Result.ok({
            active_ruleset_id = active.data.id,
            transform_id = transform.data.id,
            transformed_object = Validation.copy_table(state.last_generated_object),
            session = build_state_snapshot(state),
        }, transformed.warnings)
    end

    function workflow.list_objects(filter)
        return ReaForm.registries.objects.list_objects(filter)
    end

    function workflow.list_results()
        return Result.ok({
            last_generated_object = Validation.copy_table(state.last_generated_object),
            last_evaluation = Validation.copy_table(state.last_evaluation),
            last_error = Validation.copy_table(state.last_error),
        })
    end

    function workflow.get_state_snapshot()
        return Result.ok(build_state_snapshot(state))
    end

    function workflow.get_last_generated_object()
        return Result.ok(Validation.copy_table(state.last_generated_object))
    end

    function workflow.get_last_evaluation()
        return Result.ok(Validation.copy_table(state.last_evaluation))
    end

    function workflow.get_last_error()
        return Result.ok(Validation.copy_table(state.last_error))
    end

    return Result.ok(workflow, warnings)
end

return SessionWorkflow
