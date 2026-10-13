classdef TestAxleSynthesisPhysics < matlab.unittest.TestCase
    properties (TestParameter)
        Side={1,2}
        Metric={"CAMBER","TOE","BUMP_STEER","CASTER","KPI"}
        RollMetric={"CAMBER","ROAD_CAMBER","TOE","ROLL_CENTER_HEIGHT", ...
            "ROLL_CENTER_ROAD_HEIGHT","ROLL_CENTER_Y","WHEEL_CENTER_TRACK_CHANGE"}
        Arm={"UCA","LCA"}
        Pickup={"FWD","AFT"}
        Axle={"FRONT","REAR"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
        end
    end
    methods (Test)
        function bumpNativeBothSides(t,Side,Metric)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            td=targets{Side}.definitionSI; td.metricId=Metric; td.type="CURVE_TARGET"; td.x=[-.01;0;.01]; td.value=0; td.tolerance=1;
            targets{Side}=fsd.model.createDesignTarget(td,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildAxleSpace(s,d); e=fsd.synthesis.evaluateAxleCandidate(s,[.75;.25]);
            g=e.axle.leftGeometry; plan=s.plan.leftBump; if Side==2, g=e.axle.rightGeometry; plan=s.plan.rightBump; end
            direct=fsd.kinematics.solveBumpSweep(g,plan.travel_m,'m',plan.solverOptions);
            a=fsd.analysis.analyzeBumpSweep(g,direct); names=["camber_rad","toe_rad","bumpSteer_rad","caster_rad","kingpinInclination_rad"];
            field=names(["CAMBER","TOE","BUMP_STEER","CASTER","KPI"]==Metric);
            t.verifyEqual(e.physical{Side}.analysis.(field),a.(field),'AbsTol',1e-10);
            t.verifyEqual(e.assessment.targetAssessments{Side}.actual,a.(field),'AbsTol',1e-10);
            t.verifyEqual(e.physical{Side}.modelIdentity,fsd.model.geometryIdentity(g));
            t.verifyEqual(e.physical{Side}.quality.reliable,true(3,1));
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisEvaluation(e,s));
        end
        function rollNativeSupportedMetrics(t,RollMetric,Axle)
            s=axleSynthesisFixture(true,Axle); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            td=targets{2}.definitionSI; td.metricId=RollMetric; td.id="ROLL_METRIC";
            if startsWith(RollMetric,"ROLL_CENTER") || RollMetric=="WHEEL_CENTER_TRACK_CHANGE"
                td.scope=fsd.model.designScope('AXLE',Axle); valueUnit='m';
            else
                valueUnit='rad';
            end
            td.type="CURVE_TARGET"; td.x=[-.01;0;.01]; td.value=0; td.tolerance=1;
            targets{2}=fsd.model.createDesignTarget(td,valueUnit,'rad'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildAxleSpace(s,d); e=fsd.synthesis.evaluateAxleCandidate(s,[.75;.25]);
            direct=fsd.kinematics.solveAxleRollSweep(e.axle,s.plan.roll.angles_rad,0,'rad','m',s.plan.roll.solverOptions);
            a=fsd.analysis.analyzeAxleRollSweep(e.axle,direct);
            switch RollMetric
                case "CAMBER", expected=a.chassisCamber_rad(:,1);
                case "ROAD_CAMBER", expected=a.roadCamber_rad(:,1);
                case "TOE", expected=a.toe_rad(:,1);
                case "ROLL_CENTER_HEIGHT", expected=a.rollCenterHeight_m;
                case "ROLL_CENTER_ROAD_HEIGHT", expected=a.rollCenterRoadHeight_m;
                case "ROLL_CENTER_Y", expected=a.rollCenterY_m;
                case "WHEEL_CENTER_TRACK_CHANGE", expected=a.wheelCenterTrackChange_m;
            end
            t.verifyEqual(e.assessment.targetAssessments{2}.actual,expected,'AbsTol',1e-9);
            t.verifyEqual(e.physical{3}.analysis.wheelTravel_m,a.wheelTravel_m,'AbsTol',1e-10);
            t.verifyEqual(e.physical{3}.modelIdentity,e.axleIdentity);
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisEvaluation(e,s));
        end
        function analyticRollClosure(t,Axle)
            a=translationAxleFixture(Axle); control=axleSynthesisFixture(true,Axle); d=control.specification.definitionSI;
            d.parameters={}; d.constraints={}; d.compositeScore=false; targets=d.targets.definitionSI.targets;
            targets=targets(cellfun(@(v) v.definitionSI.sourceType=="ROLL",targets)); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=fsd.synthesis.createAxleDesignSpace(a.leftGeometry,a.rightGeometry,fsd.model.createDesignSpecification(d),control.plan);
            e=fsd.synthesis.evaluateAxleCandidate(s,zeros(0,1)); phi=control.plan.roll.angles_rad;
            % Independent exact circle + flat road formula documented since v0.6.
            r=.30; offset=.35; tangent=tan(phi);
            delta=tangent.*(offset+sqrt(r^2+tangent.^2*(r^2-offset^2)))./(1+tangent.^2);
            actual=e.physical{3}.analysis;
            t.verifyEqual(actual.wheelTravel_m,[delta,-delta],'AbsTol',2e-9);
            t.verifyEqual(actual.chassisCamber_rad,zeros(3,2),'AbsTol',1e-9);
            % Rx(+phi)*[0,-1,0] has a_z=-sin(phi): left camber=+phi.
            t.verifyEqual(actual.roadCamber_rad,[phi,-phi],'AbsTol',1e-9);
            t.verifyEqual(actual.toe_rad,zeros(3,2),'AbsTol',1e-9);
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisEvaluation(e,s));
        end
        function nullLinksRecover(t,Arm,Side,Pickup)
            [s,u]=axleNullLinkFixture(Arm,Side,Pickup); e=fsd.synthesis.evaluateAxleCandidate(s,u);
            id="fsd:model:ZeroLengthUcaLink"; if Arm=="LCA", id="fsd:model:ZeroLengthLcaLink"; end
            t.verifyEqual(e.exceptionId,id); t.verifyEqual(e.failureStage,"BUILDER"); t.verifyFalse(e.geometryValid);
            t.verifyEqual(e.physical,{[];[];[]}); t.verifyEmpty(e.axleIdentity); t.verifyEmpty(e.candidate); t.verifyTrue(isnan(e.score));
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisEvaluation(e,s));
        end
        function builderFailureCacheAndContinuation(t)
            [s,u]=axleNullLinkFixture("UCA",1,"FWD"); initial=fsd.synthesis.normalizeAxleVariables(s,s.initial_m);
            r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',3,'maxIterations',1,'initialStep',1, ...
                'minimumStep',1,'seeds',[u';initial']));
            t.verifyGreaterThan(r.statistics.preSolverFailures,0); t.verifyLessThan(r.statistics.leftBumpSweeps,r.statistics.axleCandidateEvaluations);
            t.verifyEqual(r.statistics.leftBumpSweeps,r.statistics.rightBumpSweeps);
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisResult(r));
        end
        function allInvalidNoPhysics(t)
            [s,u]=axleNullLinkFixture("LCA",1,"AFT",true);
            r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',3,'maxIterations',2,'initialStep',1,'minimumStep',1,'seeds',u'));
            t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex)); t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,0);
            t.verifyGreaterThan(r.statistics.cacheHits,0); t.verifyTrue(fsd.synthesis.validateAxleSynthesisResult(r));
        end
        function unknownErrorEscapes(t)
            t.verifyError(@() axleUnknownBuilderCall(axleSynthesisFixture()),'MATLAB:nonExistentField');
        end
        function analysisFailureOneSideRetained(t,Side)
            s=axleSynthesisFixture(); seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; g=seeds{Side};
            g.hardpoints.xyz_m(3,:)=g.hardpoints.xyz_m(6,:)+[0,.1,0]; seeds{Side}=g;
            d=s.specification.definitionSI; c=d.constraints{Side}.definitionSI; c.position=g.hardpoints.xyz_m(3,:);
            d.constraints{Side}=fsd.model.createDesignConstraint(c,'m'); plan=s.plan; plan.leftBump.travel_m=0; plan.rightBump.travel_m=0;
            s=rebuildAxleSpace(s,d,plan,s.symmetryLinks,seeds); e=fsd.synthesis.evaluateAxleCandidate(s,[.5;.5]);
            t.verifyEqual(e.physical{Side}.exceptionId,"fsd:analysis:DegenerateCasterProjection");
            t.verifyEqual(e.physical{Side}.failureStage,"ANALYSIS"); t.verifyEmpty(e.physical{Side}.analysis);
            t.verifyTrue(e.physical{Side}.sweep.allConverged); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyNotEmpty(e.physical{3-Side}.analysis); t.verifyNumElements(e.candidate.definitionSI.sources,1);
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisEvaluation(e,s));
        end
        function independentBumpPlans(t)
            s=axleSynthesisFixture(); plan=s.plan; plan.rightBump.travel_m=[-.005;.005];
            plan.rightBump.solverOptions=struct('MaxContinuationStep_m',.002);
            s=rebuildAxleSpace(s,s.specification.definitionSI,plan); e=fsd.synthesis.evaluateAxleCandidate(s,[.5;.5]);
            t.verifyEqual(e.physical{1}.sweep.requestedWheelTravel_m,[-.01;0;.01]);
            t.verifyEqual(e.physical{2}.sweep.requestedWheelTravel_m,[-.005;.005]);
            t.verifyEqual(e.physical{2}.execution.plan.rightBump.solverOptions.MaxContinuationStep_m,.002);
        end
        function invalidWheelAxisRejectedBeforePhysics(t,Side)
            s=axleSynthesisFixture(); seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry};
            seeds{Side}.wheel.wheelAxis=-seeds{Side}.wheel.wheelAxis;
            % Existing model contract rejects this seed before a solver can run.
            profile clear; profile on;
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,s.plan,s.symmetryLinks,seeds), ...
                'fsd:model:WheelAxisNotOutward');
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveAxleRoll"])));
        end
        function unavailableJointRollHonest(t)
            s=axleSynthesisFixture(true); plan=s.plan;
            plan.roll.solverOptions.CornerSolverOptions.MaxIterations=1;
            s=rebuildAxleSpace(s,s.specification.definitionSI,plan);
            e=fsd.synthesis.evaluateAxleCandidate(s,[.5;.5]);
            t.verifyFalse(e.physical{3}.sweep.allConverged); t.verifyFalse(e.physical{3}.quality.allReliable);
            t.verifyEqual(e.analysisStatus(1:2),repmat("RELIABLE_SAMPLES",2,1));
            t.verifyEqual(e.classification,"JOINT_ANALYSIS_UNAVAILABLE"); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisEvaluation(e,s));
        end
        function gapsRemainMissing(t,Side)
            s=axleSynthesisFixture(); plan=s.plan; field="leftBump"; if Side==2, field="rightBump"; end
            plan.(field).solverOptions=struct('MaxIterations',1); s=rebuildAxleSpace(s,s.specification.definitionSI,plan);
            e=fsd.synthesis.evaluateAxleCandidate(s,[.5;.5]); p=e.physical{Side};
            t.verifyTrue(any(~p.sweep.converged)); t.verifyTrue(all(isnan(p.analysis.camber_rad(~p.sweep.converged))));
            t.verifyFalse(p.quality.allReliable); t.verifyFalse(e.eligible);
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisEvaluation(e,s));
        end
    end
end
