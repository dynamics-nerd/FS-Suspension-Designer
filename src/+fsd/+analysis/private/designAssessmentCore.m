function assessment = designAssessmentCore(specification, candidate, sources)
%DESIGNASSESSMENTCORE Pure comparisons on prevalidated data; no source validation in loops.
d = specification.definitionSI; targets = d.targets.definitionSI.targets;
targetAssessments = cell(size(targets)); constraints = cell(size(d.constraints)); parameters = cell(0,1);
for i = 1:numel(targets)
    data = designMetricData(targets{i},sources,candidate.identity.definitionSI.sources);
    targetAssessments{i} = designAssessTarget(targets{i},data);
end
for i = 1:numel(d.constraints)
    constraints{i} = designAssessConstraint(d.constraints{i},candidate,"CONSTRAINT");
end
unknown = strings(0,1);
for i = 1:numel(d.parameters)
    p = d.parameters{i}.definitionSI;
    if any(p.availability == ["NOT_PROVIDED","PENDING_CALCULATION","INVALID"])
        unknown(end+1,1) = p.id+":"+p.availability; %#ok<AGROW>
    end
    if p.binding ~= "NONE" && any(p.type == ["FIXED","RANGE","FREE"])
        parameters{end+1,1} = designAssessConstraint(d.parameters{i},candidate,"PARAMETER"); %#ok<AGROW>
    end
end
allRows = [targetAssessments;constraints;parameters]; hardFailure = false; hardUnknown = false; hardCount = 0;
missing = cell(size(allRows)); statuses = strings(numel(allRows),1);
for i = 1:numel(allRows)
    row = allRows{i}; statuses(i) = row.status;
    missing{i} = unique(row.reasons(row.reasons ~= "AVAILABLE"));
    if row.strength == "HARD"
        hardCount = hardCount+1;
        hardFailure = hardFailure || row.demonstratedViolation;
        hardUnknown = hardUnknown || any(row.status == ["NOT_EVALUATED","PARTIALLY_EVALUATED"]);
    end
end
feasibility = "SATISFIES_SAMPLED_HARD_REQUIREMENTS";
if hardCount == 0
    feasibility = "NO_HARD_REQUIREMENTS";
elseif hardFailure
    feasibility = "INFEASIBLE_FOR_SPECIFICATION";
elseif hardUnknown
    feasibility = "INDETERMINATE_HARD_REQUIREMENTS";
end
missingVariables = strings(0,1);
for i = 1:numel(d.parameters)
    p = d.parameters{i}.definitionSI;
    if any(p.type == ["FREE","RANGE"]) && (isempty(p.bounds) || p.binding == "NONE")
        missingVariables(end+1,1) = p.id; %#ok<AGROW>
    end
end
spaceStatus = "CLOSED_DECLARED_SPACE";
if ~isempty(missingVariables), spaceStatus = "INCOMPLETE_VARIABLE_SPACE"; end
ready = ~isempty(allRows) && all(statuses ~= "NOT_EVALUATED" & statuses ~= "PARTIALLY_EVALUATED");
score = NaN; scoreStatus = "NOT_REQUESTED";
if d.compositeScore
    scoreStatus = "UNAVAILABLE_COVERAGE"; values = []; weights = []; complete = true;
    for i = 1:numel(targets)
        t = targets{i}.definitionSI; a = targetAssessments{i};
        if t.strength ~= "SOFT", continue; end
        complete = complete && any(a.status == ["SAMPLED_PASS","SAMPLED_FAIL"]) && isfinite(a.rmsNormalizedViolation);
        values(end+1,1) = a.rmsNormalizedViolation; weights(end+1,1) = t.weight; %#ok<AGROW>
    end
    if complete
        score = sqrt(sum(weights.*values.^2)/sum(weights)); scoreStatus = "EXPLICIT_WEIGHTED_NORMALIZED_VIOLATION_RMS";
    end
end
assessment = struct("schemaVersion","0.11.0","kind","DesignAssessment", ...
    "specificationIdentity",specification.identity,"candidateIdentity",candidate.identity, ...
    "candidateId",candidate.definitionSI.id,"targetAssessments",{targetAssessments}, ...
    "constraintAssessments",{constraints},"parameterAssessments",{parameters}, ...
    "hardFeasibility",feasibility,"compositeScore",score,"compositeScoreStatus",scoreStatus, ...
    "readiness",struct("allRequirementsEvaluated",ready,"missingByRequirement",{missing}, ...
        "unknownParameters",unknown,"variableSpaceStatus",spaceStatus, ...
        "missingVariableBoundsOrBindings",missingVariables), ...
    "verificationDomain","SAMPLES_AND_SUPPLIED_NOMINAL_MODELS_ONLY");
catalog = fsd.model.designMetricCatalog; readiness = cell(size(targets));
for i = 1:numel(targets)
    t = targets{i}.definitionSI; m = catalog(string({catalog.id}) == t.metricId);
    readiness{i} = struct("id",t.id,"metricId",t.metricId,"scope",t.scope, ...
        "sourceId",t.sourceId,"sourceType",t.sourceType,"prerequisites",m.prerequisites, ...
        "conditions",t.conditions,"subjectId",t.subjectId,"status",targetAssessments{i}.status, ...
        "missingOrInvalid",unique(targetAssessments{i}.reasons(targetAssessments{i}.reasons ~= "AVAILABLE")));
end
assessment.readiness.targets = readiness;
end
