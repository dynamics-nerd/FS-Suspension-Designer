function [elapsed, profileNames] = designCoreBenchmark(specification, candidate)
%DESIGNCOREBENCHMARK Test-only access to prevalidated core, never a public bypass.
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
oldFolder = pwd; cleanup = onCleanup(@() cd(oldFolder));
cd(fullfile(root,"src","+fsd","+analysis","private"));
fsd.model.validateDesignSpecification(specification); sources = designPrepareCandidate(candidate);
times = zeros(3,1);
for i = 1:4
    timer = tic; designAssessmentCore(specification,candidate,sources); value = toc(timer);
    if i > 1, times(i-1) = value; end
end
elapsed = median(times);
profile clear; profile on; designAssessmentCore(specification,candidate,sources); profile off;
info = profile("info"); profileNames = string({info.FunctionTable.FunctionName});
assert(~any(contains(profileNames,["validate","solveBump","solveActuation","fsolve","fzero"])), ...
    "Pure comparison core must not validate native sources or call solvers.");
end
