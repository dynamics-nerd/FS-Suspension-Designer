function assessment = designAssessConstraint(definition, candidate, kind)
%DESIGNASSESSCONSTRAINT Nominal-coordinate inclusion or explicit scalar binding.
d = definition.definitionSI; violation = NaN; binding = "HARDPOINT_POSITION";
if kind == "PARAMETER", binding = d.binding; end
[value,reason] = designBoundValue(binding,d.scope,candidate);
strength = "HARD"; unit = d.unit;
if kind == "CONSTRAINT", strength = d.strength; end
if ~isempty(value)
    if (kind == "PARAMETER" && d.type == "FIXED") || ...
            (kind == "CONSTRAINT" && d.type == "HARDPOINT_FIXED")
        if kind == "CONSTRAINT", reference = d.position; else, reference = d.value; end
        violation = max(abs(value-reference)-d.comparisonTolerance,0);
    elseif ~isempty(d.bounds)
        if kind == "PARAMETER", lo = d.bounds(1); hi = d.bounds(2);
        else, lo = d.bounds(:,1)'; hi = d.bounds(:,2)'; end
        violation = max(max(lo-value,value-hi),0);
    else
        reason = "MISSING_VARIABLE_BOUNDS";
    end
end
status = "NOT_EVALUATED";
if all(isfinite(violation))
    status = "SAMPLED_PASS"; if any(violation > 0), status = "SAMPLED_FAIL"; end
end
assessment = struct("id",d.id,"kind",kind,"scope",d.scope,"strength",strength, ...
    "unit",unit,"actual",value,"violation",violation,"status",status, ...
    "demonstratedViolation",any(violation > 0),"reasons",string(reason), ...
    "domainCoverage",double(status ~= "NOT_EVALUATED"),"verificationDomain","SUPPLIED_NOMINAL_MODEL_ONLY");
end
