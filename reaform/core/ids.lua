local Ids = {}

local counter = 0

function Ids.timestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

function Ids.generate(prefix)
    counter = counter + 1
    local safe_prefix = type(prefix) == "string" and prefix ~= "" and prefix or "reaform"
    return string.format("%s_%d_%d", safe_prefix, os.time(), counter)
end

return Ids
