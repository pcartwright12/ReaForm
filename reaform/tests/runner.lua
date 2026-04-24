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
    local root = script_directory:gsub("/reaform/tests$", "")
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

local suites = {
    (require("reaform.tests.test_contracts")),
    (require("reaform.tests.test_behavior")),
    (require("reaform.tests.test_foundation")),
}

local total_tests = 0
local failed = false

for _, suite in ipairs(suites) do
    local ok, result_or_error = pcall(suite.run)
    if not ok then
        failed = true
        io.write("[FAIL] suite crashed: " .. tostring(result_or_error) .. "\n")
    else
        total_tests = total_tests + (result_or_error.count or 0)
        io.write("[PASS] " .. tostring(result_or_error.name) .. " (" .. tostring(result_or_error.count) .. " tests)\n")
    end
end

if failed then
    io.write("\nTest run failed.\n")
    os.exit(1)
end

io.write("\nAll suites passed. Total tests: " .. tostring(total_tests) .. "\n")
os.exit(0)
