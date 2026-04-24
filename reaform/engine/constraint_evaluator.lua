local Constraint = require("reaform.core.constraint")

local ConstraintEvaluator = {}

function ConstraintEvaluator.evaluate(constraint, context)
    return Constraint.evaluate(constraint, context)
end

return ConstraintEvaluator
