package.path = table.concat({
    "./?.lua",
    "./?/init.lua",
    package.path,
}, ";")

local suites = {
    require("reaform.tests.test_contracts"),
    require("reaform.tests.test_behavior"),
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
