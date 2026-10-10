classdef TestDesignIntegration < matlab.unittest.TestCase
    properties (TestParameter)
        GlobalMetric = {"CORNER_LOAD","CROSSWEIGHT","REFERENCE_HEIGHT"}
        Nonselected = {"NON_RESTORING_STATIONARY_POINT","MARGINAL_OR_DEGENERATE","STABILITY_NOT_EVALUABLE"}
        RackMetric = {"TOE","ROAD_WHEEL_ANGLE","SCRUB_RADIUS","MECHANICAL_TRAIL","ACKERMANN_ANGLE_ERROR"}
        RollMetric = {"CAMBER","ROAD_CAMBER","TOE","ROLL_CENTER_HEIGHT","ROLL_CENTER_ROAD_HEIGHT","ROLL_CENTER_Y","WHEEL_CENTER_TRACK_CHANGE"}
        ActuationMetric = {"DAMPER_COMPRESSION","MOTION_RATIO","INSTALLATION_RATIO"}
        BumpMetric = {"CAMBER","TOE","BUMP_STEER","CASTER","KPI"}
    end
    methods (TestMethodSetup)
        function examplePath(t)
            oldPath = path; t.addTeardown(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"examples"));
        end
    end
    methods (Test)
        function allBumpMetricsHaveKnownTranslationReference(t,BumpMetric)
            axle = translationAxleFixture(); g = axle.leftGeometry;
            sweep = fsd.kinematics.solveBumpSweep(g,[-.01;0;.01],"m");
            c = fsd.model.createDesignCandidate(struct("id","TRANSLATION","sources",{{ ...
                struct("id","BUMP_FL","type","BUMP","model",g,"sweep",sweep,"result",fsd.analysis.analyzeBumpSweep(g,sweep))}}));
            target = designTargetFixture("CURVE_TARGET",BumpMetric,struct("sourceId","BUMP_FL","sourceType","BUMP", ...
                "x",[-.01;.01],"value",0,"tolerance",1e-9));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.actual,zeros(3,1),"AbsTol",1e-9);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
        end
        function nativeActuationSource(t,ActuationMetric)
            [g,model] = actuationFixture(); bump = fsd.kinematics.solveBumpSweep(g,[-.01;0;.01],"m");
            sweep = fsd.kinematics.solveActuationSweep(model,bump); analysis = fsd.analysis.analyzeActuationSweep(model,sweep);
            c = fsd.model.createDesignCandidate(struct("id","ACTUATION","geometries",{{g}},"sources",{{ ...
                struct("id","ACT_FL","type","ACTUATION","model",model,"sweep",sweep,"result",analysis)}}));
            target = designTargetFixture("POINT_TARGET",ActuationMetric,struct("sourceId","ACT_FL","sourceType","ACTUATION", ...
                "x",0,"value",0,"tolerance",10));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
        end
        function staticLoadSourceAndUnknownClosure(t)
            vehicle = vehicleFixture(); modes = ["CROSSWEIGHT_SPECIFIED","UNDERDETERMINED"];
            for i = 1:2
                definition = struct("mode",modes(i),"sourceKind","KNOWN");
                if i == 1, definition.crossweight = .5; end
                loadCase = fsd.model.createVehicleLoadCase(vehicle,definition);
                result = fsd.analysis.analyzeStaticVehicleLoads(vehicle,loadCase);
                c = fsd.model.createDesignCandidate(struct("id","STATIC_LOAD","vehicle",vehicle,"sources",{{ ...
                    struct("id","LOADS","type","STATIC_LOADS","model",vehicle,"result",result)}}));
                target = designTargetFixture("POINT_TARGET","CORNER_LOAD",struct("sourceId","LOADS","sourceType","STATIC_LOADS", ...
                    "independentVariable","NONE","x",[],"value",250,"tolerance",1e-9));
                a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
                expected = "NOT_EVALUATED"; if i == 1, expected = "SAMPLED_PASS"; end
                t.verifyEqual(a.targetAssessments{1}.status,expected);
                target = designTargetFixture("POINT_TARGET","CROSSWEIGHT",struct("sourceId","LOADS","sourceType","STATIC_LOADS", ...
                    "scope",fsd.model.designScope("VEHICLE","VEHICLE"),"independentVariable","NONE", ...
                    "x",[],"value",50,"tolerance",1e-7));
                d = target.definitionSI; d.metadata = target.metadata;
                target = fsd.model.createDesignTarget(d,"%","1");
                a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
                t.verifyEqual(a.targetAssessments{1}.status,expected);
            end
        end
        function boundMechanicalAndVehicleValues(t)
            c = designEvaluationFixture(); v = vehicleFixture(); d = c.definitionSI; d.metadata = c.metadata; d.vehicle = v;
            c = fsd.model.createDesignCandidate(d);
            p = fsd.model.createDesignParameter(struct("id","SPRING_RATE","quantity","STIFFNESS", ...
                "scope",fsd.model.designScope("COMPONENT","MECH_FL","FL"),"type","FREE", ...
                "binding","SPRING_RATE","bounds",[20,40]),"N/mm");
            fixed = fsd.model.createDesignParameter(struct("id","WB_FIXED","quantity","LENGTH", ...
                "scope",fsd.model.designScope("VEHICLE","VEHICLE"),"type","FIXED","binding","VEHICLE_WHEELBASE", ...
                "value",2000,"comparisonTolerance",0,"availability","KNOWN","sourceKind","KNOWN","sourceNote","Test"),"mm");
            spec = fsd.model.createDesignSpecification(struct("id","MODEL_BINDINGS","parameters",{{p;fixed}}));
            a = fsd.analysis.evaluateDesignCandidate(spec,c);
            t.verifyEqual(a.parameterAssessments{1}.actual,30000); t.verifyEqual(a.parameterAssessments{2}.actual,2);
            t.verifyEqual(a.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
        end
        function realGeometriesTradeoffsAndNoWinner(t)
            e = designTargetEvaluationExample(false); a = e.comparison.assessments{1}; b = e.comparison.assessments{2};
            t.verifyEqual(a.targetAssessments{1}.actual,zeros(9,1),"AbsTol",1e-9);
            t.verifyEqual(b.targetAssessments{1}.actual,repmat(-.02,9,1),"AbsTol",1e-9);
            t.verifyEqual(a.targetAssessments{2}.actual,zeros(9,1),"AbsTol",1e-9);
            t.verifyEqual(b.targetAssessments{2}.actual,repmat(.01,9,1),"AbsTol",1e-9);
            t.verifyLessThan(b.targetAssessments{1}.maximumAbsoluteError,a.targetAssessments{1}.maximumAbsoluteError);
            t.verifyLessThan(a.targetAssessments{2}.maximumAbsoluteError,b.targetAssessments{2}.maximumAbsoluteError);
            t.verifyEqual(a.constraintAssessments{1}.status,"SAMPLED_PASS");
            t.verifyEqual(b.constraintAssessments{1}.status,"SAMPLED_FAIL");
            t.verifyEqual(a.targetAssessments{4}.status,"NOT_EVALUATED");
            t.verifyEqual(b.hardFeasibility,"INFEASIBLE_FOR_SPECIFICATION");
            t.verifyEqual(e.comparison.selectionPolicy,"NO_AUTOMATIC_WINNER");
            again = fsd.analysis.evaluateDesignCandidate(e.specification,e.candidates{1}); t.verifyEqual(again,a);
            d = e.candidates{1}.definitionSI; d.metadata = e.candidates{1}.metadata;
            d.geometries = e.candidates{2}.definitionSI.geometries;
            forged = fsd.model.createDesignCandidate(d);
            t.verifyError(@() fsd.analysis.validateDesignCandidate(forged),"fsd:analysis:InvalidDesignCandidate");
        end
        function explicitBumpReflectionRule(t)
            axle = translationAxleFixture(); ids = ["LEFT_BUMP","RIGHT_BUMP"]; geos = {axle.leftGeometry;axle.rightGeometry};
            sources = cell(2,1);
            for i = 1:2
                sweep = fsd.kinematics.solveBumpSweep(geos{i},[-.01;0;.01],"m");
                sources{i} = struct("id",ids(i),"type","BUMP","model",geos{i},"sweep",sweep, ...
                    "result",fsd.analysis.analyzeBumpSweep(geos{i},sweep));
            end
            c = fsd.model.createDesignCandidate(struct("id","SYMMETRIC","geometries",{geos},"sources",{sources}));
            left = designTargetFixture("CURVE_TARGET","CAMBER",struct("sourceId",ids(1),"sourceType","BUMP", ...
                "x",[-.01;.01],"value",0,"tolerance",1e-9));
            right = fsd.model.mirrorBumpDesignTarget(left,"RIGHT_CAMBER",ids(2));
            s = fsd.model.createDesignSpecification(struct("id","SYMMETRY_SPEC", ...
                "targets",fsd.model.createSuspensionDesignTargets({left;right})));
            a = fsd.analysis.evaluateDesignCandidate(s,c);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS"); t.verifyEqual(a.targetAssessments{2}.status,"SAMPLED_PASS");
        end
        function nativeFailureAndNotAttempted(t)
            axle = translationAxleFixture(); g = axle.leftGeometry; z = [-.01;0;1;2];
            sweep = fsd.kinematics.solveBumpSweep(g,z,"m");
            source = struct("id","BUMP_FL","type","BUMP","model",g,"sweep",sweep, ...
                "result",fsd.analysis.analyzeBumpSweep(g,sweep));
            c = fsd.model.createDesignCandidate(struct("id","PARTIAL_BUMP","sources",{{source}}));
            target = designTargetFixture("CURVE_TARGET","CAMBER",struct("sourceId","BUMP_FL","sourceType","BUMP", ...
                "x",[-.01;2],"value",0,"tolerance",1e-9));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c); r = a.targetAssessments{1};
            t.verifyEqual(r.status,"PARTIALLY_EVALUATED"); t.verifyEqual(r.evaluatedSampleCount,2);
            t.verifyEqual(r.reasons(end),"NOT_ATTEMPTED"); t.verifyEqual(r.domainCoverage,.01/2.01,"AbsTol",1e-14);
        end
        function nativeRackMetricsAndConditions(t,RackMetric)
            e = steeringKinematicsExample(false); model = e.steeringSystem;
            sweep = fsd.kinematics.solveRackSweep(model,[0;.005],0,"m");
            analysis = fsd.analysis.analyzeRackSweep(model,sweep);
            c = fsd.model.createDesignCandidate(struct("id","STEERING", "sources",{{ ...
                struct("id","RACK_FRONT","type","RACK","model",model,"sweep",sweep,"result",analysis)}}));
            scope = fsd.model.designScope("CORNER","FL");
            if RackMetric == "ACKERMANN_ANGLE_ERROR", scope = fsd.model.designScope("AXLE","FRONT"); end
            target = designTargetFixture("POINT_TARGET",RackMetric,struct("sourceId","RACK_FRONT","sourceType","RACK", ...
                "scope",scope,"independentVariable","RACK_TRAVEL","conditions",struct("wheelTravel_m",[0,0]), ...
                "x",.005,"value",0,"tolerance",10));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            d = target.definitionSI; d.metadata = target.metadata; d.conditions.wheelTravel_m = [.001,0];
            target = fsd.model.createDesignTarget(d,target.definitionSI.unit,"m");
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.reasons,"FIXED_WHEEL_TRAVEL_MISMATCH");
        end
        function nativeRollMetricsAndReference(t,RollMetric)
            axle = analyticAxleFixture(false); sweep = fsd.kinematics.solveAxleRollSweep(axle,[-.01;0;.01],0,"rad","m");
            analysis = fsd.analysis.analyzeAxleRollSweep(axle,sweep);
            c = fsd.model.createDesignCandidate(struct("id","ROLL", "sources",{{ ...
                struct("id","ROLL_FRONT","type","ROLL","model",axle,"sweep",sweep,"result",analysis)}}));
            scope = fsd.model.designScope("AXLE","FRONT");
            if any(RollMetric == ["CAMBER","ROAD_CAMBER","TOE"]), scope = fsd.model.designScope("CORNER","FL"); end
            target = designTargetFixture("POINT_TARGET",RollMetric,struct("sourceId","ROLL_FRONT","sourceType","ROLL", ...
                "scope",scope,"independentVariable","ROLL_ANGLE","conditions",struct("axleHeave_m",0), ...
                "x",0,"value",0,"tolerance",10));
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            d = target.definitionSI; d.metadata = target.metadata; d.conditions.axleHeave_m = .001;
            target = fsd.model.createDesignTarget(d,target.definitionSI.unit,"rad");
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.reasons,"FIXED_AXLE_HEAVE_MISMATCH");
        end
        function selectedGlobalReferences(t,GlobalMetric)
            [s,o] = globalStaticFixture; r = fsd.analysis.solveGlobalStaticEquilibrium(s,zeros(7,1),o);
            c = globalCandidate(s,r); target = globalTarget(GlobalMetric);
            a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            t.verifyTrue(fsd.analysis.validateDesignAssessment(a,designSpecificationFixture(target),c));
        end
        function globalWithoutStableSelectionNeverUsesFirst(t,Nonselected)
            [s,o,q] = globalSelectionFixture(Nonselected); r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            t.assertTrue(isnan(r.selectedIndex)); t.assertNotEmpty(r.alternatives);
            c = globalCandidate(s,r); targets = {globalTarget("CORNER_LOAD");globalTarget("CROSSWEIGHT");globalTarget("REFERENCE_HEIGHT")};
            for i = 1:3
                a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(targets{i}),c);
                t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
                t.verifyTrue(isnan(a.targetAssessments{1}.actual));
                t.verifyTrue(startsWith(a.targetAssessments{1}.reasons,"NO_SELECTED_GLOBAL_EQUILIBRIUM:"));
            end
        end
        function plotsDashboardAndGapLines(t)
            c = designEvaluationFixture(); d = c.definitionSI; d.metadata = c.metadata; d.id = "ANALYTICAL_B";
            other = fsd.model.createDesignCandidate(d);
            target = designTargetFixture("CURVE_BAND","DAMPER_COMPRESSION",struct("x",[-.02;.02],"lower",-.01,"upper",.01));
            s = designSpecificationFixture(target); a = fsd.analysis.evaluateDesignCandidate(s,c);
            dashboard = fsd.analysis.designAssessmentTable(a,s,c);
            t.verifyEqual(dashboard.Status,"PARTIALLY_EVALUATED"); t.verifyEqual(dashboard.Unit,"m");
            old = get(groot,"DefaultFigureVisible"); t.addTeardown(@() set(groot,"DefaultFigureVisible",old));
            set(groot,"DefaultFigureVisible","off"); figures = fsd.analysis.plotDesignTargetEvaluation(s,{c;other});
            t.addTeardown(@() close(figures)); lines = findall(figures,"Type","line"); names = string({lines.DisplayName});
            t.verifyTrue(any(contains(names,"ANALYTICAL_A")) && any(contains(names,"ANALYTICAL_B")));
            line = lines(find(startsWith(names,"ANALYTICAL_A —"),1)); t.verifyTrue(any(isnan(line.YData)));
        end
        function fixedBoxBoundariesAndUnits(t)
            axle = translationAxleFixture(); g = axle.leftGeometry;
            c = fsd.model.createDesignCandidate(struct("id","NOMINAL","geometries",{{g}}));
            scope = fsd.model.designScope("HARDPOINT","FL_UBJ","FL");
            d = struct("id","BOX","scope",scope,"type","AXIS_ALIGNED_BOX","strength","HARD", ...
                "bounds",[0,0;-600,-590;400,410],"sourceNote","Closed-box boundary benchmark");
            box = fsd.model.createDesignConstraint(d,"mm");
            d = struct("id","FIXED_POINT","scope",scope,"type","HARDPOINT_FIXED","strength","HARD", ...
                "position",[0,-.6,.4],"comparisonTolerance",0,"sourceNote","Exact test point");
            fixed = fsd.model.createDesignConstraint(d,"m");
            spec = fsd.model.createDesignSpecification(struct("id","GEOMETRIC","constraints",{{box;fixed}}));
            a = fsd.analysis.evaluateDesignCandidate(spec,c);
            t.verifyEqual(a.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
            forged = box; forged.definitionSI.bounds(1,1) = 1;
            t.verifyError(@() fsd.model.validateDesignConstraint(forged),"fsd:model:InvalidDesignDefinition");
            d.comparisonTolerance = -.01;
            t.verifyError(@() fsd.model.createDesignConstraint(d,"m"),"fsd:model:InvalidDesignDefinition");
            t.verifyError(@() fsd.analysis.compareDesignCandidates(spec,{c;c}),"fsd:analysis:InvalidDesignCandidate");
        end
    end
end

function c = globalCandidate(s,r)
c = fsd.model.createDesignCandidate(struct("id","GLOBAL_CANDIDATE","vehicle",s.vehicle,"sources",{{ ...
    struct("id","GLOBAL_RESULT","type","GLOBAL_STATIC","model",s,"result",r)}}));
end

function target = globalTarget(metric)
scope = fsd.model.designScope("VEHICLE","VEHICLE"); expected = .5; subject = "";
if metric == "CORNER_LOAD", scope = fsd.model.designScope("CORNER","FL"); expected = 500;
elseif metric == "REFERENCE_HEIGHT", expected = .095; subject = "TEST_REFERENCE"; end
target = designTargetFixture("POINT_TARGET",metric,struct("sourceId","GLOBAL_RESULT","sourceType","GLOBAL_STATIC", ...
    "scope",scope,"independentVariable","NONE","x",[],"value",expected,"tolerance",1e-5,"subjectId",subject));
end
