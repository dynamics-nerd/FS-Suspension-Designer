function report = checkConceptGeometryConsistency(concept,geometries,definition)
%CHECKCONCEPTGEOMETRYCONSISTENCY Native geometry versus eligible conceptual dimensions.
fsd.project.validateVehicleConcept(concept); references=cell(3,1); diagnostics=strings(3,1); used=false(3,1);
ids=["WHEELBASE","FRONT_TRACK","REAR_TRACK"];
for j=1:3
    id=ids(j);
    [value,status,p]=conceptScalar(concept,id);
    if isempty(value), diagnostics(j)=id+":"+status;
    else, references{j}=p.parameter; used(j)=true; end
end
references=references(used); diagnostics=diagnostics(~used);
if nargin<3, report=fsd.construction.checkConceptGeometryConsistency(geometries,references);
else, report=fsd.construction.checkConceptGeometryConsistency(geometries,references,definition); end
report.inputDiagnostics=diagnostics;
end
