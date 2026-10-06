function results = runProjectTests()
%RUNPROJECTTESTS Run all MATLAB tests without permanently changing the path.

projectRoot = fileparts(mfilename("fullpath"));
originalPath = path;
pathCleanup = onCleanup(@() path(originalPath));
addpath(fullfile(projectRoot, "src"));

suite = matlab.unittest.TestSuite.fromFolder( ...
    fullfile(projectRoot, "tests"), "IncludingSubfolders", true);
runner = matlab.unittest.TestRunner.withTextOutput;
results = runner.run(suite);

if ~isempty(results) && any(~[results.Passed])
    error("fsd:tests:Failed", "One or more project tests did not pass.");
end
end
