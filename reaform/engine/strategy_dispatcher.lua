local Validation = require("reaform.utils.validation")
local Result = require("reaform.utils.result")

local StrategyDispatcher = {}

function StrategyDispatcher.call(owner, field_name, input, error_code, error_message)
    local strategy = owner and owner[field_name]
    if type(strategy) ~= "function" then
        return Result.fail({
            Validation.error(
                error_code or "strategy_dispatcher.missing_strategy",
                error_message or "Strategy function is missing.",
                field_name,
                nil
            ),
        })
    end

    local ok, value = pcall(strategy, input)
    if not ok then
        return Result.fail({
            Validation.error(
                error_code or "strategy_dispatcher.execution_error",
                error_message or "Strategy function raised an error.",
                field_name,
                { reason = value }
            ),
        })
    end

    return Result.ok(value)
end

return StrategyDispatcher
