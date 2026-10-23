function [payload,assessment] = executeScenarioCore(p)
%EXECUTESCENARIOCORE Only entry point permitted to call native forward/search APIs.
engine=p.scenario.definition.engine; plan=p.plan; resources=p.resources;
assessment=[];
if engine=="GLOBAL_STATIC"
    sources=cell(4,1);
    for k=1:4
        cp=p.corners{k}; native=executeScenarioCore(cp);
        sources{k}=struct('geometry',cp.resources.geometries{1},'actuation',cp.resources.actuations{1}, ...
            'springDamper',cp.resources.mechanicals{1},'mechanical',native.analysis, ...
            'bump',native.bump,'pathKind',"ACTUATION_BUMP_3D");
    end
    system=globalScenarioSystem(p,sources);
    equilibrium=fsd.analysis.solveGlobalStaticEquilibrium(system,plan.initialGuesses,p.options);
    payload=struct('system',system,'equilibrium',equilibrium); return;
end
if engine=="PACKAGING"
    payload=fsd.packaging.evaluate(p.packagingDefinition,p.packagingGeometry,p.plan,p.packagingSource); return;
end
if ismember(engine,["PARAMETRIC_SEED","PARAMETRIC_BUMP"])
    seed=fsd.construction.buildParametricSeed(p.seedDefinition,p.seedReferences);
    payload=struct('seed',seed,'bumpCheck',[]);
    if engine=="PARAMETRIC_BUMP" && seed.nominalStatus=="VALID"
        payload.bumpCheck=fsd.project.checkParametricSeedBump(seed,p.plan);
    end
    return;
end
if endsWith(engine,'SYNTHESIS')
    switch engine
        case "CORNER_SYNTHESIS", payload=fsd.synthesis.runInverseSearch(p.space,p.options);
        case "AXLE_SYNTHESIS", payload=fsd.synthesis.runAxleInverseSearch(p.space,p.options);
        case "STEERING_SYNTHESIS", payload=fsd.synthesis.runSteeringInverseSearch(p.space,p.options);
        case "ACTUATION_SYNTHESIS", payload=fsd.synthesis.runActuationInverseSearch(p.space,p.options);
    end
    if isfinite(payload.selectedIndex), assessment=payload.search.records{payload.selectedIndex}.assessment; end
    return;
end
payload=struct('bump',[],'sweep',[],'analysis',[],'actuationAnalysis',[],'candidate',[]);
switch engine
    case "STATIC_GEOMETRY"
        payload.analysis=fsd.geometry.staticMetrics(resources.geometries{1});
    case "STATIC_LOADS"
        payload.analysis=fsd.analysis.analyzeStaticVehicleLoads(p.vehicle,p.loadCase);
    case "BUMP"
        g=resources.geometries{1}; payload.sweep=fsd.kinematics.solveBumpSweep(g,plan.travel_m,'m',plan.solverOptions);
        payload.analysis=fsd.analysis.analyzeBumpSweep(g,payload.sweep);
    case "ROLL"
        axle=fsd.model.createAxleGeometry(resources.geometries{1},resources.geometries{2});
        payload.sweep=fsd.kinematics.solveAxleRollSweep(axle,plan.angles_rad,plan.axleHeave_m,'rad','m',plan.solverOptions);
        payload.analysis=fsd.analysis.analyzeAxleRollSweep(axle,payload.sweep);
    case "RACK"
        s=resources.steerings{1}; payload.sweep=fsd.kinematics.solveRackSweep(s,plan.travel_m,plan.wheelTravel_m,'m',plan.solverOptions);
        payload.analysis=fsd.analysis.analyzeRackSweep(s,payload.sweep);
    case {"ACTUATION","MECHANICAL"}
        g=resources.geometries{1}; a=resources.actuations{1};
        payload.bump=fsd.kinematics.solveBumpSweep(g,plan.travel_m,'m',plan.solverOptions);
        payload.sweep=fsd.kinematics.solveActuationSweep(a,payload.bump);
        payload.actuationAnalysis=fsd.analysis.analyzeActuationSweep(a,payload.sweep);
        payload.analysis=payload.actuationAnalysis;
        if engine=="MECHANICAL"
            payload.analysis=fsd.analysis.analyzeSpringDamperSweep(resources.mechanicals{1},a,payload.sweep, ...
                payload.actuationAnalysis,plan.wheelVelocity_m_per_s,'m/s');
        end
    case "TARGET_EVALUATION"
        payload.candidate=p.scenario.definition.inputs.candidate;
end
if ~isempty(p.scenario.definition.specification)
    if engine~="TARGET_EVALUATION", payload.candidate=scenarioCandidate(p,payload); end
    assessment=fsd.analysis.evaluateDesignCandidate(p.scenario.definition.specification,payload.candidate);
end
end
