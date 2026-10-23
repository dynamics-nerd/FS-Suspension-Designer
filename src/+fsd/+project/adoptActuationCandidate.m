function project = adoptActuationCandidate(project,result,index)
%ADOPTACTUATIONCANDIDATE Adopt exact compatible resources, preserving geometry.
fsd.project.validateEngineeringProject(project);
fsd.project.validateEngineeringResult(result);
ids=cellfun(@(r)string(r.id)==string(result.id),project.definition.results);
assert(nnz(ids)==1 && isequaln(project.definition.results{ids},result), ...
    'fsd:project:InvalidAdoption','Adoption requires the exact stored result.');
report=fsd.project.resultCompatibility(result,project);
assert(ismember(report.status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"]) && ...
    result.engine=="ACTUATION_SYNTHESIS",'fsd:project:InvalidAdoption','Select compatible actuation synthesis evidence.');
records=result.nativePayload.search.records;
assert(isnumeric(index) && isreal(index) && isscalar(index) && isfinite(index) && ...
    index==fix(index) && index>=1 && index<=numel(records), ...
    'fsd:project:InvalidAdoption','Candidate index must identify an existing record.');
e=records{index};
assert(e.eligible && ~isempty(e.actuation),'fsd:project:InvalidAdoption','Candidate is not eligible.');
resources=project.definition.resources; corner=e.geometry.cornerId;
found=cellfun(@(g)g.cornerId==corner,resources.geometries);
assert(nnz(found)==1 && isequaln(resources.geometries{found},e.geometry), ...
    'fsd:project:InvalidAdoption','The complete fixed suspension must remain unchanged.');
resources.actuations=resources.actuations(~cellfun(@(a)a.cornerId==corner,resources.actuations));
resources.actuations{end+1,1}=e.actuation;
resources.mechanicals=resources.mechanicals(~cellfun(@(m)m.cornerId==corner,resources.mechanicals));
if ~isempty(e.mechanical), resources.mechanicals{end+1,1}=e.mechanical; end
project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
end
