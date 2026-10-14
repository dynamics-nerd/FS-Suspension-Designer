function prepared = conceptPreparation(concept,input)
%CONCEPTPREPARATION Pure bookkeeping and native input factory, no loads/solves.
fsd.project.validateVehicleConcept(concept);
if nargin<2, input=struct(); end
options=struct('gravity_mps2',[],'gravitySourceKind',"UNSPECIFIED",'gravitySourceNote',"", ...
    'operatingConfiguration',"",'contactPolicy',"UNSPECIFIED",'contactPoints_m',[], ...
    'contactSourceKind',"UNSPECIFIED",'contactSourceNote',"", ...
    'loadCaseDefinition',struct(),'loadCaseUnits',struct('force',"N",'crossweight',"fraction"));
projectRequire(isstruct(input) && isscalar(input) && all(ismember(string(fieldnames(input)),string(fieldnames(options)))), ...
    'Invalid concept physical options.');
for name=string(fieldnames(input))', options.(name)=input.(name); end
for name=["gravitySourceKind","gravitySourceNote","operatingConfiguration","contactPolicy","contactSourceKind","contactSourceNote"]
    options.(name)=projectText(options.(name),true);
end
plainProjectData(options);
projectRequire(isstruct(options.loadCaseDefinition) && isscalar(options.loadCaseDefinition), ...
    'Load case definition must be a scalar struct.');
projectRequire(ismember(options.contactPolicy,["UNSPECIFIED","CONCEPTUAL_HORIZONTAL","EXPLICIT"]),'Unknown contact policy.');
g=options.gravity_mps2;
projectRequire(isnumeric(g) && isreal(g) && (isempty(g) || (isscalar(g) && isfinite(g) && g>0)), ...
    'Gravity must be empty or a finite positive value in m/s^2.');
if ~isempty(g)
    projectRequire(ismember(options.gravitySourceKind,["KNOWN","ASSUMED","DERIVED"]) && ...
        strlength(options.gravitySourceNote)>0,'Explicit gravity requires provenance and a note.');
end
prepared=struct('conceptIdentity',concept.identity,'options',options,'totalMass_kg',[], ...
    'massDependencies',strings(0,1),'model',[],'loadCase',[],'status',"MISSING_DATA", ...
    'missing',strings(0,1),'diagnostics',strings(0,1));
[vehicleMass,vehicleStatus]=conceptScalar(concept,"VEHICLE_MASS");
[driverMass,driverStatus]=conceptScalar(concept,"DRIVER_MASS"); convention=concept.definitionSI.massConvention;
if isempty(vehicleMass), prepared.missing(end+1,1)="VEHICLE_MASS:"+vehicleStatus; end
if convention=="UNSPECIFIED", prepared.missing(end+1,1)="MASS_CONVENTION";
elseif convention=="EXCLUDES_DRIVER"
    prepared.massDependencies=["VEHICLE_MASS";"DRIVER_MASS"];
    if isempty(driverMass), prepared.missing(end+1,1)="DRIVER_MASS:"+driverStatus; end
    if ~isempty(vehicleMass) && ~isempty(driverMass), prepared.totalMass_kg=sum([vehicleMass,driverMass]); end
else
    prepared.massDependencies="VEHICLE_MASS"; prepared.totalMass_kg=vehicleMass;
    if ~isempty(vehicleMass) && ~isempty(driverMass) && driverMass>vehicleMass
        prepared.totalMass_kg=[]; prepared.status="INVALID_INPUT";
        prepared.diagnostics="Driver mass cannot exceed a declared total already including the driver."; return;
    end
end
if ~isempty(prepared.totalMass_kg) && ~isfinite(prepared.totalMass_kg)
    prepared.totalMass_kg=[]; prepared.status="INVALID_INPUT"; prepared.diagnostics="Mass arithmetic overflow."; return;
end
definition=struct('massMode',"TOTAL_MASS",'sourceKind',"DERIVED", ...
    'operatingConfiguration',options.operatingConfiguration,'totalMass',prepared.totalMass_kg, ...
    'includes',["VEHICLE","DRIVER"],'gravity_mps2',g);
for pair=["WHEELBASE","wheelbase";"FRONT_TRACK","frontTrack";"REAR_TRACK","rearTrack"]'
    [value,status]=conceptScalar(concept,pair(1)); definition.(pair(2))=value;
    if isempty(value), prepared.missing(end+1,1)=pair(1)+":"+status; end
end
if isempty(g), prepared.missing(end+1,1)="GRAVITY_MPS2"; end
if strlength(options.operatingConfiguration)==0, prepared.missing(end+1,1)="OPERATING_CONFIGURATION"; end
if options.contactPolicy=="UNSPECIFIED", prepared.missing(end+1,1)="CONTACT_POLICY"; end
if options.contactPolicy=="CONCEPTUAL_HORIZONTAL"
    projectRequire(ismember(options.contactSourceKind,["UNSPECIFIED","ASSUMED"]) && strlength(options.contactSourceNote)>0 && ...
        isempty(options.contactPoints_m),'Conceptual contacts need an explicit assumption, not measured-contact provenance.');
elseif options.contactPolicy=="EXPLICIT"
    projectRequire(isnumeric(options.contactPoints_m) && isreal(options.contactPoints_m) && ...
        isequal(size(options.contactPoints_m),[4,3]) && all(isfinite(options.contactPoints_m),'all') && ...
        ismember(options.contactSourceKind,["KNOWN","ASSUMED","DERIVED"]) && strlength(options.contactSourceNote)>0, ...
        'Explicit contacts require finite 4-by-3 SI points and provenance.');
    definition.contactPoints=options.contactPoints_m; definition.contactSourceKind=options.contactSourceKind;
end
if ~isempty(prepared.missing), return; end
cg=nan(1,3); ids=["CG_X","CG_Y","CG_Z"];
for j=1:3
    [value,status]=conceptScalar(concept,ids(j)); if ~isempty(value), cg(j)=value; end
    if startsWith(status,["RULE_","TARGET_"]), prepared.diagnostics(end+1,1)=ids(j)+":"+status; end
end
definition.cg=cg;
for pair=["FRONT_WEIGHT_FRACTION","frontWeightFraction";"REAR_WEIGHT_FRACTION","rearWeightFraction"]'
    [value,status]=conceptScalar(concept,pair(1)); if ~isempty(value), definition.(pair(2))=value; end
    if startsWith(status,["RULE_","TARGET_"]), prepared.diagnostics(end+1,1)=pair(1)+":"+status; end
end
unsprung=nan(1,4); ids="UNSPRUNG_MASS_"+["FL","FR","RL","RR"];
for j=1:4
    [value,status]=conceptScalar(concept,ids(j)); if ~isempty(value), unsprung(j)=value; end
    if startsWith(status,["RULE_","TARGET_"]), prepared.diagnostics(end+1,1)=ids(j)+":"+status; end
end
definition.unsprungMass=unsprung;
definition.metadata=struct('sourceKind',"DERIVED",'sourceNote',"Explicit concept inputs adapted to native v0.9", ...
    'conceptIdentity',concept.identity,'physicalOptions',options);
try
    prepared.model=fsd.model.createVehicleParameters(definition,struct('length',"m",'mass',"kg",'gravity',"m/s^2"));
    loadDefinition=options.loadCaseDefinition;
    if isempty(fieldnames(loadDefinition)), loadDefinition=struct('mode',"UNDERDETERMINED",'sourceKind',"DERIVED"); end
    prepared.loadCase=fsd.model.createVehicleLoadCase(prepared.model,loadDefinition,options.loadCaseUnits);
catch cause
    if string(cause.identifier)~="fsd:model:InvalidVehicleParameters", rethrow(cause); end
    prepared.model=[]; prepared.loadCase=[]; prepared.status="INVALID_INPUT";
    prepared.diagnostics=string(cause.identifier)+": "+string(cause.message); return;
end
prepared.status="READY";
prepared.diagnostics=[prepared.diagnostics;"Native v0.9 static approximation; no performance targets inferred."; ...
    "Mass/CG/dimensions do not specify an optimal suspension."];
end
