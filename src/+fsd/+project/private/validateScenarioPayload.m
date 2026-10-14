function assessment = validateScenarioPayload(p,payload)
%VALIDATESCENARIOPAYLOAD Native algebraic evidence validators, never forward solves.
engine=p.scenario.definition.engine; assessment=[];
if endsWith(engine,'SYNTHESIS')
    switch engine
        case "CORNER_SYNTHESIS", fsd.synthesis.validateSynthesisResult(payload);
        case "AXLE_SYNTHESIS", fsd.synthesis.validateAxleSynthesisResult(payload);
        case "STEERING_SYNTHESIS", fsd.synthesis.validateSteeringSynthesisResult(payload);
        case "ACTUATION_SYNTHESIS", fsd.synthesis.validateActuationSynthesisResult(payload);
    end
    projectRequire(isequaln(payload.problem,p.space) && isequaln(payload.search.options,p.options),'Native synthesis problem/options differ.');
    if isfinite(payload.selectedIndex), assessment=payload.search.records{payload.selectedIndex}.assessment; end
    return;
end
projectRequire(isstruct(payload) && isscalar(payload) && isequal(sort(string(fieldnames(payload))), ...
    sort(["bump";"sweep";"analysis";"actuationAnalysis";"candidate"])),'Invalid analysis payload fields.');
expected=payload;
switch engine
    case "STATIC_GEOMETRY", expected.analysis=fsd.geometry.staticMetrics(p.resources.geometries{1});
    case "STATIC_LOADS", fsd.analysis.validateStaticVehicleLoads(payload.analysis,p.vehicle,p.loadCase);
    case "BUMP"
        checkBump(payload.sweep,p); expected.analysis=fsd.analysis.analyzeBumpSweep(p.resources.geometries{1},payload.sweep);
    case "ROLL"
        axle=fsd.model.createAxleGeometry(p.resources.geometries{1},p.resources.geometries{2});
        projectRequire(isequaln(payload.sweep.requestedBodyRollAngle_rad,p.plan.angles_rad) && ...
            isequaln(payload.sweep.requestedAxleHeave_m,p.plan.axleHeave_m),'ROLL path differs.');
        expected.analysis=fsd.analysis.analyzeAxleRollSweep(axle,payload.sweep);
    case "RACK"
        projectRequire(isequaln(payload.sweep.requestedRackTravel_m,p.plan.travel_m) && ...
            isequaln(payload.sweep.requestedWheelTravel_m,p.plan.wheelTravel_m),'RACK path differs.');
        expected.analysis=fsd.analysis.analyzeRackSweep(p.resources.steerings{1},payload.sweep);
    case {"ACTUATION","MECHANICAL"}
        checkBump(payload.bump,p); a=p.resources.actuations{1};
        fsd.kinematics.validateActuationSweepResult(payload.sweep,a);
        projectRequire(numel(payload.sweep.results)==numel(payload.bump.results),'Actuation/BUMP sample counts differ.');
        for j=1:numel(payload.bump.results)
            projectRequire(isequaln(payload.sweep.results(j).sourceResult,payload.bump.results(j)), ...
                'Actuation samples do not retain the declared BUMP source.');
        end
        projectRequire(isequaln(payload.sweep.requestedWheelTravel_m,p.plan.travel_m) && ...
            isequaln(payload.sweep.sourceGeometryIdentity,fsd.model.geometryIdentity(p.resources.geometries{1})), 'Actuation source path differs.');
        expected.actuationAnalysis=fsd.analysis.analyzeActuationSweep(a,payload.sweep);
        expected.analysis=expected.actuationAnalysis;
        if engine=="MECHANICAL"
            expected.analysis=fsd.analysis.analyzeSpringDamperSweep(p.resources.mechanicals{1},a,payload.sweep, ...
                expected.actuationAnalysis,p.plan.wheelVelocity_m_per_s,'m/s');
        end
    case "TARGET_EVALUATION"
        projectRequire(isequaln(payload.candidate,p.scenario.definition.inputs.candidate),'Evaluation source candidate differs.');
end
if ~isempty(p.scenario.definition.specification)
    if engine~="TARGET_EVALUATION", expected.candidate=scenarioCandidate(p,expected); end
    assessment=fsd.analysis.evaluateDesignCandidate(p.scenario.definition.specification,expected.candidate);
else
    projectRequire(isempty(payload.candidate),'Unrequested candidate payload.');
end
% Reject extraneous evidence as well as altered calculations.
if ~ismember(engine,["ACTUATION","MECHANICAL"])
    projectRequire(isempty(payload.bump) && isempty(payload.actuationAnalysis),'Unexpected actuation/bump payload.');
end
if ismember(engine,["STATIC_GEOMETRY","STATIC_LOADS","TARGET_EVALUATION"])
    projectRequire(isempty(payload.sweep),'Unexpected physical sweep.');
end
if engine=="TARGET_EVALUATION", projectRequire(isempty(payload.analysis),'Unrequested analysis.'); end
projectRequire(isequaln(workflowComparable(payload),workflowComparable(expected)),'Native analysis/candidate payload mismatch.');
end

function checkBump(sweep,p)
fsd.kinematics.validateBumpSweepResult(sweep);
projectRequire(isequaln(sweep.geometryIdentity,fsd.model.geometryIdentity(p.resources.geometries{1})) && ...
    isequaln(sweep.requestedWheelTravel_m,p.plan.travel_m),'BUMP seed or prescribed path differs.');
end
