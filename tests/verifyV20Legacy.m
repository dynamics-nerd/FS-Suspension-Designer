function report=verifyV20Legacy(file,expectedFile,destination)
%VERIFYV20LEGACY Explicit authentic prior-release fixture; no missing-fixture PASS.
% Produce input with unmodified v0.19.0 in a separate MATLAB process. All paths
% must be supplied; the unit suite never depends on ignored development artifacts.
expected=load(expectedFile,'project'); project=fsd.project.loadEngineeringProject(file);
assert(isequaln(project,expected.project));
assert(~isempty(project.definition.results) && all(cellfun(@(r)r.fsdVersion=="0.19.0",project.definition.results)));
fsd.project.saveEngineeringProject(project,destination,false);
assert(isequaln(fsd.project.loadEngineeringProject(destination),project));
report=struct('sourceSoftware',"0.19.0",'readerSoftware',fsd.version(),'records',numel(project.definition.results),'exact',true);
fprintf('V20_LEGACY_PASS RECORDS=%d\n',report.records);
end
