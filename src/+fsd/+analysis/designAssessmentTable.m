function dashboard = designAssessmentTable(assessment, specification, candidate)
%DESIGNASSESSMENTTABLE Validated requirement dashboard, not a UI/solver callback.
fsd.analysis.validateDesignAssessment(assessment,specification,candidate);
rows = [assessment.targetAssessments;assessment.constraintAssessments;assessment.parameterAssessments];
n = numel(rows); id = strings(n,1); metric = id; scope = id; strength = id; status = id;
errorValue = nan(n,1); coverage = zeros(n,1); missing = cell(n,1); unit = strings(n,1);
for i = 1:n
    r = rows{i}; id(i) = r.id; scope(i) = r.scope.kind+":"+r.scope.id;
    strength(i) = r.strength; status(i) = r.status; coverage(i) = r.domainCoverage; unit(i) = r.unit;
    if r.kind == "TARGET", metric(i) = r.metricId; errorValue(i) = r.maximumAbsoluteError;
    else, metric(i) = r.kind; if all(isfinite(r.violation)), errorValue(i) = max(r.violation); end; end
    missing{i} = unique(r.reasons(r.reasons ~= "AVAILABLE"));
end
dashboard = table(id,metric,scope,strength,status,errorValue,unit,coverage,missing, ...
    'VariableNames',["RequirementId","Metric","Scope","Strength","Status","Error","Unit","Coverage","MissingPrerequisites"]);
end
