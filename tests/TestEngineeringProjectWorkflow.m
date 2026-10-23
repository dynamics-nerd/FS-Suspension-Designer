classdef TestEngineeringProjectWorkflow < matlab.unittest.TestCase
    properties (TestParameter)
        Engine={"STATIC_GEOMETRY","BUMP","ROLL","RACK","ACTUATION","MECHANICAL","STATIC_LOADS", ...
            "CORNER_SYNTHESIS","AXLE_SYNTHESIS","STEERING_SYNTHESIS","ACTUATION_SYNTHESIS"}
        Missing={"GEOMETRY","OPPOSITE","STEERING","ACTUATION","MECHANICAL","SPEC","PLAN"}
        Bad={"GRID","OPTIONS","SCOPE","VELOCITY","ARCHITECTURE","GLOBAL_STATIC"}
        Revision={"MASS","CG","PLAN","OPTIONS","TARGET","SEED","ARCHITECTURE"}
        Synthesis={"CORNER_SYNTHESIS","AXLE_SYNTHESIS","STEERING_SYNTHESIS","ACTUATION_SYNTHESIS"}
        Analysis={"STATIC_GEOMETRY","ROLL","RACK","ACTUATION","MECHANICAL"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function readyNativeAdaptersNoHiddenSolves(t,Engine)
            p=projectWorkflowFixture(Engine); profile clear; profile on;
            prepared=fsd.project.prepareEngineeringScenario(p,'SCENARIO'); fsd.project.validateEngineeringProject(p);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyEqual(prepared.readiness.status,"READY");
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveRack","solveAxleRoll", ...
                "solveActuation","boundedDirectSearch","analyzeStaticVehicleLoads"])));
            t.verifyEmpty(p.definition.results);
        end
        function exactMissingDependencies(t,Missing)
            engine="MECHANICAL"; if ismember(Missing,["OPPOSITE","STEERING"]), engine="RACK"; end
            if Missing=="SPEC", engine="ACTUATION_SYNTHESIS"; end
            p=projectWorkflowFixture(engine); d=p.definition; scenario=d.scenarios{1}.definition;
            switch Missing
                case "GEOMETRY", d.resources.geometries={}; expected="GEOMETRY:FL";
                case "OPPOSITE", d.resources.geometries=d.resources.geometries(1); expected="GEOMETRY:FR";
                case "STEERING", d.resources.steerings={}; expected="STEERING:FRONT";
                case "ACTUATION", d.resources.actuations={}; expected="ACTUATION:FL";
                case "MECHANICAL", d.resources.mechanicals={}; expected="MECHANICAL:FL";
                case "SPEC", scenario.specification=[]; expected="DESIGN_SPECIFICATION";
                case "PLAN", scenario.plan=struct(); expected="PLAN:travel_m";
            end
            d.scenarios={fsd.project.createEngineeringScenario(scenario)}; p=fsd.project.createEngineeringProject(d);
            r=fsd.project.designReadiness(p,'SCENARIO'); t.verifyEqual(r.status,"MISSING_DATA"); t.verifyTrue(any(r.missing==expected));
        end
        function invalidAndUnsupportedAreNotReady(t,Bad)
            p=projectWorkflowFixture('MECHANICAL'); d=p.definition; s=d.scenarios{1}.definition; expected="INVALID_INPUT";
            switch Bad
                case "GRID", s.plan.travel_m=[0;0];
                case "OPTIONS", s.plan.solverOptions=struct('NotASolverOption',1);
                case "SCOPE", s.scope=fsd.model.designScope('AXLE','FRONT');
                case "VELOCITY", s.plan.wheelVelocity_m_per_s=NaN;
                case "ARCHITECTURE"
                    c=d.concept.definitionSI; c.architectures.frontSuspension="MACPHERSON";
                    d.concept=fsd.project.createVehicleConcept(c); expected="UNSUPPORTED";
                case "GLOBAL_STATIC", s.engine="GLOBAL_STATIC"; expected="INVALID_INPUT"; % existing CORNER scope is invalid for global
            end
            d.scenarios={fsd.project.createEngineeringScenario(s)}; r=fsd.project.designReadiness(fsd.project.createEngineeringProject(d),'SCENARIO');
            t.verifyEqual(r.status,expected); t.verifyNotEmpty(r.diagnostics);
        end
        function actualNativeAnalysis(t)
            p=projectWorkflowFixture('BUMP'); original=p; r=fsd.project.runEngineeringScenario(p,'SCENARIO','BUMP_RESULT');
            g=p.definition.resources.geometries{1}; native=fsd.kinematics.solveBumpSweep(g,[-.01;0;.01],'m');
            a=fsd.analysis.analyzeBumpSweep(g,native);
            t.verifyEqual(r.nativePayload.analysis.camber_rad,a.camber_rad,'AbsTol',1e-10);
            t.verifyEqual(p,original); t.verifyTrue(fsd.project.validateEngineeringResult(r));
            p=fsd.project.attachEngineeringResult(p,r); t.verifyEqual(fsd.project.resultCompatibility(r,p).status,"CURRENT_EXECUTION");
        end
        function operationalAnalysisAdapters(t,Analysis)
            p=projectWorkflowFixture(Analysis); r=fsd.project.runEngineeringScenario(p,'SCENARIO','ANALYSIS');
            t.verifyEqual(r.engine,Analysis); t.verifyTrue(fsd.project.validateEngineeringResult(r));
            payload=r.nativePayload; resources=p.definition.resources;
            switch Analysis
                case "STATIC_GEOMETRY"
                    t.verifyEqual(payload.analysis,fsd.geometry.staticMetrics(resources.geometries{1}));
                case "ROLL"
                    native=fsd.kinematics.solveAxleRollSweep(fsd.model.createAxleGeometry(resources.geometries{1},resources.geometries{2}), ...
                        [-.01;0;.01],0,'rad','m');
                    t.verifyEqual(payload.sweep.results(2).wheelTravel_m,native.results(2).wheelTravel_m,'AbsTol',1e-10);
                case "RACK"
                    native=fsd.kinematics.solveRackSweep(resources.steerings{1},[-.005;0;.005],[0,0],'m');
                    t.verifyEqual(payload.sweep.requestedRackTravel_m,native.requestedRackTravel_m);
                case {"ACTUATION","MECHANICAL"}
                    native=fsd.kinematics.solveActuationSweep(resources.actuations{1},payload.bump);
                    t.verifyEqual(payload.sweep.damperCompression_m,native.damperCompression_m,'AbsTol',1e-12);
                    if Analysis=="MECHANICAL"
                        expected=fsd.analysis.analyzeSpringDamperSweep(resources.mechanicals{1},resources.actuations{1}, ...
                            native,fsd.analysis.analyzeActuationSweep(resources.actuations{1},native),0,'m/s');
                        t.verifyEqual(payload.analysis.springAxialForce_N,expected.springAxialForce_N,'AbsTol',1e-10);
                    end
            end
        end
        function delegatedNativeSynthesis(t,Synthesis)
            family=Synthesis;
            p=projectWorkflowFixture(family); d=p.definition.scenarios{1}.definition; d.options=struct('maxEvaluations',1);
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{fsd.project.createEngineeringScenario(d)}}));
            r=fsd.project.runEngineeringScenario(p,'SCENARIO','SYNTH'); prepared=fsd.project.prepareEngineeringScenario(p,'SCENARIO');
            switch family
                case "CORNER_SYNTHESIS", native=fsd.synthesis.runInverseSearch(prepared.space,prepared.options);
                case "AXLE_SYNTHESIS", native=fsd.synthesis.runAxleInverseSearch(prepared.space,prepared.options);
                case "STEERING_SYNTHESIS", native=fsd.synthesis.runSteeringInverseSearch(prepared.space,prepared.options);
                case "ACTUATION_SYNTHESIS", native=fsd.synthesis.runActuationInverseSearch(prepared.space,prepared.options);
            end
            t.verifyEqual(r.nativePayload.search.records{1}.score,native.search.records{1}.score,'AbsTol',1e-12);
            t.verifyEqual(r.nativePayload.problem.specification,prepared.space.specification);
            t.verifyEqual(r.nativePayload.search.evaluationCount,1); t.verifyTrue(fsd.project.validateEngineeringResult(r));
        end
        function selectiveRevisionCompatibility(t,Revision)
            p=projectWorkflowFixture('BUMP'); result=fsd.project.runEngineeringScenario(p,'SCENARIO','BASE');
            c=p.definition.concept.definitionSI; s=p.definition.scenarios{1}.definition; resources=p.definition.resources; expected="STALE";
            switch Revision
                case {"MASS","CG"}
                    id="VEHICLE_MASS"; if Revision=="CG", id="CG_Z"; end
                    index=find(cellfun(@(q)q.id==id,c.parameters)); q=c.parameters{index}.parameter.definitionSI;
                    value=q.value+1; unit=q.unit;
                    c.parameters{index}=fsd.project.createConceptParameter(id,struct('type',"ASSUMED",'value',value, ...
                        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit alternative test input"),unit);
                    expected="REUSABLE_DEPENDENCIES";
                case "PLAN", s.plan.travel_m=[-.005;0;.005];
                case "OPTIONS", s.plan.solverOptions=struct('MaxIterations',100);
                case "TARGET"
                    spec=actuationSynthesisFixture(); d=spec.specification.definitionSI; d.parameters={}; d.constraints={};
                    d.targets=fsd.model.createSuspensionDesignTargets({}); d.compositeScore=false;
                    s.specification=fsd.model.createDesignSpecification(d);
                case "SEED"
                    g=resources.geometries{1}; xyz=g.hardpoints.xyz_m; xyz(1,3)=xyz(1,3)+.001;
                    resources=struct('geometries',{{fsd.model.createDoubleWishboneGeometry('FL',g.hardpoints.ids,xyz,'m',g.wheel.wheelAxis)}});
                case "ARCHITECTURE", c.architectures.frontSuspension="DOUBLE_WISHBONE";
            end
            revised=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(c), ...
                'resources',resources,'scenarios',{{fsd.project.createEngineeringScenario(s)}}));
            t.verifyEqual(revised.definition.revision,p.definition.revision+1);
            t.verifyEqual(fsd.project.resultCompatibility(result,revised).status,expected);
            t.verifyEqual(result.projectRevision,1);
        end
        function projectAndScenarioIntegrity(t)
            p=projectWorkflowFixture(); t.verifyEqual(fsd.project.reviseEngineeringProject(p,struct()),p);
            d=p.definition; d.scenarios{end+1}=d.scenarios{1}; t.verifyError(@()fsd.project.createEngineeringProject(d),'fsd:project:InvalidInput');
            d=p.definition; d.resources.geometries{end+1}=d.resources.geometries{1};
            t.verifyError(@()fsd.project.createEngineeringProject(d),'fsd:project:InvalidInput');
            copy=p; copy.identity.revision=3; t.verifyError(@()fsd.project.validateEngineeringProject(copy),'fsd:project:InvalidInput');
            s=p.definition.scenarios{1}; s.definition.plan.travel_m=0;
            t.verifyError(@()fsd.project.validateEngineeringScenario(s),'fsd:project:InvalidInput');
        end
        function incompleteVariablesKeepProjectButBlockSynthesis(t)
            p=projectWorkflowFixture('ACTUATION_SYNTHESIS'); s=p.definition.scenarios{1}.definition;
            d=s.specification.definitionSI; q=d.parameters{1}.definitionSI; q.bounds=[];
            d.parameters{1}=fsd.model.createDesignParameter(q,'m'); s.specification=fsd.model.createDesignSpecification(d);
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{fsd.project.createEngineeringScenario(s)}}));
            t.verifyTrue(fsd.project.validateEngineeringProject(p)); readiness=fsd.project.designReadiness(p,'SCENARIO');
            t.verifyEqual(readiness.status,"MISSING_DATA");
            t.verifyTrue(any(readiness.missing=="DESIGN_VARIABLE:"+q.id+":BOUNDS_OR_BINDING"));
        end
        function fixedRackTargetConditionNeedsMatchingPlan(t)
            p=projectWorkflowFixture('RACK'); nativeSpace=steeringSynthesisFixture();
            d=nativeSpace.specification.definitionSI; ts=d.targets.definitionSI.targets;
            ts=ts(cellfun(@(q)q.definitionSI.sourceType=="RACK",ts)); q=ts{1}.definitionSI;
            q.conditions.wheelTravel_m=[.001,.001]; ts={fsd.model.createDesignTarget(q,'rad','m')};
            d.parameters={}; d.constraints={}; d.targets=fsd.model.createSuspensionDesignTargets(ts);
            s=p.definition.scenarios{1}.definition; s.specification=fsd.model.createDesignSpecification(d);
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{fsd.project.createEngineeringScenario(s)}}));
            r=fsd.project.designReadiness(p,'SCENARIO'); t.verifyEqual(r.status,"BLOCKED_BY_DEPENDENCY");
            t.verifyTrue(any(r.missing=="PLAN_CONDITION:"+q.id));
        end
        function staticLoadRevisionDependsOnConcept(t)
            p=projectWorkflowFixture('STATIC_LOADS'); r=fsd.project.runEngineeringScenario(p,'SCENARIO','LOADS');
            t.verifyEqual(r.nativePayload.analysis.cornerLoads_N,675*ones(4,1),'AbsTol',1e-10);
            c=p.definition.concept.definitionSI; c.massConvention="INCLUDES_DRIVER";
            revised=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(c)));
            t.verifyEqual(fsd.project.resultCompatibility(r,revised).status,"STALE");
        end
        function explicitConceptDependency(t)
            p=projectWorkflowFixture(); s=p.definition.scenarios{1}.definition; s.conceptDependencies="CG_Z";
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{fsd.project.createEngineeringScenario(s)}}));
            r=fsd.project.runEngineeringScenario(p,'SCENARIO','JUSTIFIED');
            c=p.definition.concept.definitionSI; c.parameters=c.parameters(~cellfun(@(q)q.id=="CG_Z",c.parameters));
            revised=fsd.project.reviseEngineeringProject(p,struct('concept',fsd.project.createVehicleConcept(c)));
            t.verifyEqual(fsd.project.resultCompatibility(r,revised).status,"STALE");
        end
    end
end
