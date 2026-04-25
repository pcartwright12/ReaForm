local function get_script_directory()
    local source = debug.getinfo(1, "S").source
    if type(source) ~= "string" or source:sub(1, 1) ~= "@" then
        return "."
    end

    local script_path = source:sub(2)
    local normalized = script_path:gsub("\\", "/")
    local directory = normalized:match("^(.*)/[^/]+$")
    return directory or "."
end

local function get_repository_root(script_directory)
    local root = script_directory:gsub("/reaper$", "")
    return root ~= "" and root or "."
end

local function prepend_package_path(base_directory)
    package.path = table.concat({
        base_directory .. "/?.lua",
        base_directory .. "/?/init.lua",
        "./?.lua",
        "./?/init.lua",
        package.path,
    }, ";")
end

prepend_package_path(get_repository_root(get_script_directory()))

local SessionWorkflow = require("reaform.workflows.session_workflow")
local Result = require("reaform.utils.result")
local Validation = require("reaform.utils.validation")

local GuiMain = {}

local function clamp(value, lower, upper)
    if value < lower then
        return lower
    end
    if value > upper then
        return upper
    end
    return value
end

local function format_scalar(value)
    if type(value) == "string" then
        return "\"" .. value .. "\""
    end
    return tostring(value)
end

local function serialize_lines(value, depth, lines, prefix)
    depth = depth or 0
    prefix = prefix or ""

    if depth > 3 then
        lines[#lines + 1] = prefix .. "..."
        return
    end

    if type(value) ~= "table" then
        lines[#lines + 1] = prefix .. format_scalar(value)
        return
    end

    local is_array = Validation.is_array(value)
    local keys = {}
    if is_array then
        for index = 1, math.min(#value, 8) do
            keys[#keys + 1] = index
        end
    else
        for key, _ in pairs(value) do
            keys[#keys + 1] = key
        end
        table.sort(keys, function(a, b)
            return tostring(a) < tostring(b)
        end)
    end

    lines[#lines + 1] = prefix .. (is_array and "[" or "{")
    for _, key in ipairs(keys) do
        local entry_prefix = prefix .. "  " .. (is_array and "- " or tostring(key) .. ": ")
        if type(value[key]) == "table" then
            lines[#lines + 1] = entry_prefix
            serialize_lines(value[key], depth + 1, lines, prefix .. "    ")
        else
            lines[#lines + 1] = entry_prefix .. format_scalar(value[key])
        end
    end
    if is_array and #value > #keys then
        lines[#lines + 1] = prefix .. "  - ..."
    end
    lines[#lines + 1] = prefix .. (is_array and "]" or "}")
end

local function format_result(title, payload, warnings)
    local lines = { title }
    if type(warnings) == "table" and #warnings > 0 then
        lines[#lines + 1] = "Warnings:"
        for _, warning in ipairs(warnings) do
            lines[#lines + 1] = "- " .. tostring(warning.code) .. ": " .. tostring(warning.message)
        end
    end
    serialize_lines(payload, 0, lines, "")
    return lines
end

local function format_error(error_record)
    if type(error_record) ~= "table" then
        return { "No error details available." }
    end

    local lines = {
        "Error",
        tostring(error_record.code) .. ": " .. tostring(error_record.message),
    }
    if error_record.field ~= nil then
        lines[#lines + 1] = "Field: " .. tostring(error_record.field)
    end
    return lines
end

local function new_button(id, label, x, y, w, h, enabled)
    return {
        id = id,
        label = label,
        x = x,
        y = y,
        w = w,
        h = h,
        enabled = enabled ~= false,
    }
end

function GuiMain.create_app(options)
    local settings = Validation.copy_table(options or {})
    local workflow_result = SessionWorkflow.create({
        reset_state = settings.reset_state ~= false,
        bootstrap_builtins = settings.bootstrap_builtins ~= false,
    })
    if not workflow_result.ok then
        return workflow_result
    end

    local workflow = workflow_result.data
    local rulesets_result = workflow.list_rulesets()
    if not rulesets_result.ok then
        return rulesets_result
    end

    local rulesets = rulesets_result.data or {}
    local active_ruleset_id = nil
    if #rulesets > 0 then
        local selected = workflow.select_ruleset(rulesets[1].id)
        if not selected.ok then
            return selected
        end
        active_ruleset_id = selected.data.active_ruleset_id
    end

    local app = {
        title = "ReaForm Interactive Loop",
        width = settings.width or 980,
        height = settings.height or 700,
        workflow = workflow,
        rulesets = rulesets,
        selected_ruleset_index = 1,
        selected_transform_index = 1,
        output_lines = { "ReaForm GUI ready." },
        last_mouse_down = false,
        buttons = {},
    }

    local function sync_ruleset_selection()
        if #app.rulesets == 0 then
            app.selected_ruleset_index = 1
            return
        end

        if Validation.is_non_empty_string(active_ruleset_id) then
            for index, ruleset in ipairs(app.rulesets) do
                if ruleset.id == active_ruleset_id then
                    app.selected_ruleset_index = index
                    break
                end
            end
        end
    end

    local function sync_transform_selection()
        local transforms_result = app.workflow.list_transforms()
        if transforms_result.ok then
            local transforms = transforms_result.data or {}
            if #transforms == 0 then
                app.selected_transform_index = 1
            else
                app.selected_transform_index = clamp(app.selected_transform_index, 1, #transforms)
            end
        end
    end

    function app:get_active_ruleset()
        if #self.rulesets == 0 then
            return nil
        end
        return self.rulesets[self.selected_ruleset_index]
    end

    function app:get_transforms()
        local listed = self.workflow.list_transforms()
        if listed.ok then
            return listed.data or {}
        end
        return {}
    end

    function app:set_output_lines(lines)
        self.output_lines = Validation.ensure_array(lines)
        if #self.output_lines == 0 then
            self.output_lines = { "" }
        end
    end

    function app:handle_result(title, result, payload_key)
        if result.ok then
            local payload = result.data
            if payload_key ~= nil and type(payload) == "table" then
                payload = payload[payload_key] or payload
            end
            self:set_output_lines(format_result(title, payload, result.warnings))
        else
            self:set_output_lines(format_error(result.errors[1]))
        end
    end

    function app:cycle_ruleset(delta)
        if #self.rulesets == 0 then
            return
        end

        self.selected_ruleset_index = ((self.selected_ruleset_index - 1 + delta) % #self.rulesets) + 1
        local ruleset = self.rulesets[self.selected_ruleset_index]
        local selected = self.workflow.select_ruleset(ruleset.id)
        if selected.ok then
            active_ruleset_id = selected.data.active_ruleset_id
            self.selected_transform_index = 1
            self:handle_result("Active RuleSet", selected, nil)
        else
            self:handle_result("Select RuleSet Failed", selected, nil)
        end
    end

    function app:cycle_transform(delta)
        local transforms = self:get_transforms()
        if #transforms == 0 then
            return
        end

        self.selected_transform_index = ((self.selected_transform_index - 1 + delta) % #transforms) + 1
        local transform = transforms[self.selected_transform_index]
        self:set_output_lines({
            "Selected Transform",
            tostring(transform.id),
            "Ruleset: " .. tostring(transform.ruleset_id),
        })
    end

    function app:generate()
        local generated = self.workflow.generate({})
        sync_transform_selection()
        self:handle_result("Generate", generated, "generated_object")
    end

    function app:evaluate()
        local evaluated = self.workflow.evaluate({})
        self:handle_result("Evaluate", evaluated, "evaluation")
    end

    function app:apply_transform()
        local transforms = self:get_transforms()
        if #transforms == 0 then
            self:set_output_lines({ "No transforms are available for the active ruleset." })
            return
        end

        local transform = transforms[self.selected_transform_index]
        local transformed = self.workflow.apply_transform(transform.id)
        self:handle_result("Transform", transformed, "transformed_object")
    end

    function app:refresh_layout()
        self.buttons = {
            new_button("ruleset_prev", "<", 20, 60, 36, 28, #self.rulesets > 1),
            new_button("ruleset_next", ">", 360, 60, 36, 28, #self.rulesets > 1),
            new_button("generate", "Generate", 20, 110, 110, 32, true),
            new_button("evaluate", "Evaluate", 140, 110, 110, 32, true),
            new_button("transform_prev", "<", 20, 160, 36, 28, #self:get_transforms() > 1),
            new_button("transform_next", ">", 360, 160, 36, 28, #self:get_transforms() > 1),
            new_button("apply_transform", "Apply Transform", 20, 210, 160, 32, #self:get_transforms() > 0),
        }
    end

    function app:draw_button(button)
        local gfx_api = rawget(_G, "gfx")
        local background = button.enabled and 0.20 or 0.12
        gfx_api.set(background, background, background, 1)
        gfx_api.rect(button.x, button.y, button.w, button.h, 1)
        gfx_api.set(1, 1, 1, button.enabled and 1 or 0.45)
        gfx_api.rect(button.x, button.y, button.w, button.h, 0)
        gfx_api.x = button.x + 8
        gfx_api.y = button.y + 8
        gfx_api.drawstr(button.label)
    end

    function app:draw_labels()
        local gfx_api = rawget(_G, "gfx")
        local active_ruleset = self:get_active_ruleset()
        local transforms = self:get_transforms()
        local selected_transform = transforms[self.selected_transform_index]

        gfx_api.set(1, 1, 1, 1)
        gfx_api.x = 20
        gfx_api.y = 20
        gfx_api.drawstr(self.title)

        gfx_api.x = 70
        gfx_api.y = 66
        gfx_api.drawstr("RuleSet: " .. tostring(active_ruleset and active_ruleset.name or "None"))

        gfx_api.x = 70
        gfx_api.y = 166
        gfx_api.drawstr("Transform: " .. tostring(selected_transform and selected_transform.id or "None"))
    end

    function app:draw_output_panel()
        local gfx_api = rawget(_G, "gfx")
        local panel_x = 430
        local panel_y = 20
        local panel_w = self.width - panel_x - 20
        local panel_h = self.height - panel_y - 20

        gfx_api.set(0.08, 0.08, 0.08, 1)
        gfx_api.rect(panel_x, panel_y, panel_w, panel_h, 1)
        gfx_api.set(1, 1, 1, 1)
        gfx_api.rect(panel_x, panel_y, panel_w, panel_h, 0)

        gfx_api.x = panel_x + 10
        gfx_api.y = panel_y + 10
        gfx_api.drawstr("Output")

        local line_y = panel_y + 34
        for index = 1, math.min(#self.output_lines, 28) do
            gfx_api.x = panel_x + 10
            gfx_api.y = line_y + ((index - 1) * 18)
            gfx_api.drawstr(tostring(self.output_lines[index]))
        end
    end

    function app:draw()
        local gfx_api = rawget(_G, "gfx")
        self:refresh_layout()
        gfx_api.set(0.05, 0.05, 0.05, 1)
        gfx_api.rect(0, 0, self.width, self.height, 1)
        self:draw_labels()
        for _, button in ipairs(self.buttons) do
            self:draw_button(button)
        end
        self:draw_output_panel()
    end

    function app:handle_click(x, y)
        for _, button in ipairs(self.buttons) do
            local inside = x >= button.x and x <= (button.x + button.w) and y >= button.y and y <= (button.y + button.h)
            if inside and button.enabled then
                if button.id == "ruleset_prev" then
                    self:cycle_ruleset(-1)
                elseif button.id == "ruleset_next" then
                    self:cycle_ruleset(1)
                elseif button.id == "generate" then
                    self:generate()
                elseif button.id == "evaluate" then
                    self:evaluate()
                elseif button.id == "transform_prev" then
                    self:cycle_transform(-1)
                elseif button.id == "transform_next" then
                    self:cycle_transform(1)
                elseif button.id == "apply_transform" then
                    self:apply_transform()
                end
                break
            end
        end
    end

    function app:loop()
        local gfx_api = rawget(_G, "gfx")
        local reaper_api = rawget(_G, "reaper")
        if gfx_api == nil or reaper_api == nil then
            return
        end

        self.width = gfx_api.w
        self.height = gfx_api.h
        self:draw()

        local mouse_down = (gfx_api.mouse_cap & 1) == 1
        if mouse_down and not self.last_mouse_down then
            self:handle_click(gfx_api.mouse_x, gfx_api.mouse_y)
        end
        self.last_mouse_down = mouse_down

        if gfx_api.getchar() >= 0 then
            gfx_api.update()
            reaper_api.defer(function()
                self:loop()
            end)
        end
    end

    sync_ruleset_selection()
    sync_transform_selection()
    return Result.ok(app, workflow_result.warnings)
end

function GuiMain.run(options)
    local gfx_api = rawget(_G, "gfx")
    local reaper_api = rawget(_G, "reaper")
    if gfx_api == nil or reaper_api == nil then
        error("REAPER gfx and reaper APIs are required to run reaper/gui_main.lua", 2)
    end

    local created = GuiMain.create_app(options)
    if not created.ok then
        error(created.errors[1] and created.errors[1].message or "Failed to create ReaForm GUI app.", 2)
    end

    local app = created.data
    gfx_api.init(app.title, app.width, app.height)
    app:loop()
    return app
end

if ... == nil then
    GuiMain.run()
end

return GuiMain
