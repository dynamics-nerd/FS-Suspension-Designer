function candidate = designCandidateCore(input)
%DESIGNCANDIDATECORE Structural/model validation only; result physics is downstream.
d = designDefinition(input,struct("id",[],"geometries",{{}},"sources",{{}}, ...
    "vehicle",[],"metadata",struct()),"id");
d.id = designText(d.id);
designRequire(iscell(d.geometries) && iscell(d.sources),"Geometry/source cell vectors required.");
d.geometries = d.geometries(:); d.sources = d.sources(:);
corners = strings(numel(d.geometries),1); geometryIds = cell(size(d.geometries));
for i = 1:numel(d.geometries)
    fsd.model.validateDoubleWishboneGeometry(d.geometries{i});
    corners(i) = d.geometries{i}.cornerId; geometryIds{i} = fsd.model.geometryIdentity(d.geometries{i});
end
designRequire(numel(unique(corners)) == numel(corners),"Duplicate candidate corners.");
vehicleIdentity = [];
if ~isempty(d.vehicle), fsd.model.validateVehicleParameters(d.vehicle); vehicleIdentity = d.vehicle.identity; end
sourceIds = strings(numel(d.sources),1); references = cell(size(d.sources));
for i = 1:numel(d.sources)
    s = designDefinition(d.sources{i},struct("id",[],"type",[],"model",[], ...
        "auxiliary",[],"sweep",[],"result",[]),["id","type","model","result"]);
    s.id = designText(s.id); s.type = designText(s.type); auxiliaryIdentity = [];
    switch s.type
        case "BUMP"
            fsd.model.validateDoubleWishboneGeometry(s.model); modelIdentity = fsd.model.geometryIdentity(s.model);
            controls = struct("x",s.sweep.requestedWheelTravel_m, ...
                "poses",{arrayfun(@(r) r.uprightPose,s.sweep.results,"UniformOutput",false)});
        case "RACK"
            fsd.model.validateSteeringSystemGeometry(s.model); modelIdentity = s.model.identity;
            controls = struct("x",s.sweep.requestedRackTravel_m,"wheelTravel",s.sweep.requestedWheelTravel_m, ...
                "leftPoses",{arrayfun(@(r) r.leftResult.uprightPose,s.sweep.results,"UniformOutput",false)}, ...
                "rightPoses",{arrayfun(@(r) r.rightResult.uprightPose,s.sweep.results,"UniformOutput",false)});
        case "ROLL"
            fsd.model.validateAxleGeometry(s.model); modelIdentity = fsd.model.axleIdentity(s.model);
            controls = struct("x",s.sweep.requestedBodyRollAngle_rad,"heave",s.sweep.requestedAxleHeave_m, ...
                "wheelTravel",s.result.wheelTravel_m);
        case "ACTUATION"
            fsd.model.validateActuationGeometry(s.model); modelIdentity = s.model.identity;
            controls = struct("x",s.sweep.requestedWheelTravel_m,"rockerAngles",s.sweep.rockerAngle_rad);
        case "MECHANICAL"
            fsd.model.validateSpringDamperModel(s.model); modelIdentity = s.model.identity;
            if ~isempty(s.auxiliary)
                fsd.model.validateActuationGeometry(s.auxiliary); auxiliaryIdentity = s.auxiliary.identity;
            end
            controls = struct("path",s.result.path,"velocity",s.result.inputWheelVelocity_m_per_s);
        case "GLOBAL_STATIC"
            fsd.model.validateGlobalStaticSystem(s.model); modelIdentity = s.model.identity;
            controls = struct("options",s.result.solverOptions,"seeds",s.result.initialGuesses, ...
                "q",{cellfun(@(a) a.solution.state.q,s.result.attempts,"UniformOutput",false)}, ...
                "selectedIndex",s.result.selectedIndex);
        case "STATIC_LOADS"
            fsd.model.validateVehicleParameters(s.model); modelIdentity = s.model.identity;
            controls = s.result.loadCase.identity;
        otherwise, designRequire(false,"Unknown source type.");
    end
    if any(s.type == ["BUMP","RACK","ROLL","ACTUATION"])
        designRequire(~isempty(s.sweep) && isempty(s.auxiliary),"Source requires sweep, no auxiliary.");
    else
        designRequire(isempty(s.sweep),"Source contains unexpected duplicate sweep.");
    end
    sourceIds(i) = s.id; d.sources{i} = s;
    references{i} = struct("id",s.id,"type",s.type,"modelIdentity",modelIdentity, ...
        "auxiliaryIdentity",auxiliaryIdentity,"controls",controls);
end
designRequire(numel(unique(sourceIds)) == numel(sourceIds),"Duplicate source IDs.");
candidate = designRecord("DesignCandidate",d);
candidate.identity.definitionSI.geometries = geometryIds;
candidate.identity.definitionSI.sources = references;
candidate.identity.definitionSI.vehicle = vehicleIdentity;
end
