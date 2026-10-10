function output = designAuditTestCall(action,specification,candidate)
%DESIGNAUDITTESTCALL Test-only legacy replay / isolated association benchmark.
% Legacy replay deliberately bypasses preparation, emulating pre-F01 records.
% It is NOT a validator or a supported engineering API. Always restore pwd.
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
original = pwd; cleanup = onCleanup(@() cd(original));
cd(fullfile(root,"src","+fsd","+analysis","private"));
if action == "LEGACY_ASSESSMENT"
    output = designAssessmentCore(specification,candidate,candidate.definitionSI.sources);
elseif action == "ASSOCIATIONS"
    output = designCandidateAssociations(candidate,candidate.definitionSI.sources);
elseif action == "BENCHMARK_ASSOCIATIONS"
    designCandidateAssociations(candidate,candidate.definitionSI.sources); % warm-up
    times = zeros(5,1);
    for i = 1:numel(times)
        timer = tic; designCandidateAssociations(candidate,candidate.definitionSI.sources); times(i) = toc(timer);
    end
    output = median(times);
else
    error("fsd:test:InvalidAuditAction","Unknown test-only action.");
end
end
