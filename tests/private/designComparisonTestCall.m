function assessment = designComparisonTestCall(target, x, y, valid, connected)
%DESIGNCOMPARISONTESTCALL Isolated mathematical tests, not fabricated native results.
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
original = pwd; cleanup = onCleanup(@() cd(original));
cd(fullfile(root,"src","+fsd","+analysis","private"));
reasons = repmat("AVAILABLE",size(x)); reasons(~valid) = "ISOLATED_TEST_GAP";
data = struct("x",x,"y",y,"valid",valid,"connected",connected, ...
    "reasons",reasons,"sourceIdentity",[],"missingReason","");
assessment = designAssessTarget(target,data);
end
