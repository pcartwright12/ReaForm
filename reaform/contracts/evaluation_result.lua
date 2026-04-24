local Schemas = require("reaform.core.schemas")

local EvaluationResult = {}

function EvaluationResult.create(payload)
    return Schemas.normalize_evaluation_result(payload or {})
end

return EvaluationResult
