function sources = designPrepareCandidate(candidate)
%DESIGNPREPARECANDIDATE Validate complete native sources once, never solve.
try
    fsd.model.validateDesignCandidate(candidate);
catch cause
    exception = MException("fsd:analysis:InvalidDesignCandidate", ...
        "INVALID_CANONICAL_EVIDENCE: candidate structure/model provenance cannot be verified.");
    throwAsCaller(addCause(exception,cause));
end
sources = candidate.definitionSI.sources;
for i = 1:numel(sources)
    s = sources{i}; expected = [];
    switch s.type
        case "BUMP"
            expected = fsd.analysis.analyzeBumpSweep(s.model,s.sweep);
        case "RACK"
            expected = fsd.analysis.analyzeRackSweep(s.model,s.sweep);
        case "ROLL"
            expected = fsd.analysis.analyzeAxleRollSweep(s.model,s.sweep);
        case "ACTUATION"
            fsd.analysis.validateActuationSweepAnalysis(s.result,s.model,s.sweep);
        case "MECHANICAL"
            fsd.analysis.validateSpringDamperSweepAnalysis(s.result,s.model,s.auxiliary);
        case "GLOBAL_STATIC"
            fsd.analysis.validateGlobalStaticEquilibrium(s.result,s.model);
        case "STATIC_LOADS"
            fsd.analysis.validateStaticVehicleLoads(s.result,s.model);
    end
    if ~isempty(expected) && ~isequaln(designComparable(s.result),designComparable(expected))
        error("fsd:analysis:InvalidDesignCandidate","Analysis does not match its original source.");
    end
end
% Cross-source and optional-reference checks share one typed association map.
% Native payloads above are verified first; source names are not evidence.
designCandidateAssociations(candidate,sources);
end
