local Schemas = require("reaform.core.schemas")

local EvaluationContext = {}

function EvaluationContext.create(payload)
    return Schemas.normalize_evaluation_context(payload or {})
end

return EvaluationContext
