local Validation = require("reaform.utils.validation")

local EvaluationClassifier = {}

local VALID_CLASSIFICATIONS = {
    hard_failure = true,
    soft_warning = true,
    advisory_notice = true,
    pass = true,
}

function EvaluationClassifier.classify(payload)
    if type(payload) ~= "table" then
        return "hard_failure"
    end

    if Validation.is_non_empty_string(payload.classification) and VALID_CLASSIFICATIONS[payload.classification] then
        return payload.classification
    end

    if payload.passed == false then
        return "hard_failure"
    end

    if type(payload.warnings) == "table" and #payload.warnings > 0 then
        return "soft_warning"
    end

    if type(payload.advisory_notices) == "table" and #payload.advisory_notices > 0 then
        return "advisory_notice"
    end

    return "pass"
end

return EvaluationClassifier
