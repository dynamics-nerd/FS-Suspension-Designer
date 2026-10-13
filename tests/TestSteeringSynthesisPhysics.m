classdef TestSteeringSynthesisPhysics < matlab.unittest.TestCase
    properties (TestParameter)
        Side={1,2}
        BumpMetric={"CAMBER","TOE","BUMP_STEER","CASTER","KPI"}
        RackMetric={"TOE","ROAD_WHEEL_ANGLE","SCRUB_RADIUS","MECHANICAL_TRAIL"}
        Failure={"LEFT_BUMP","RIGHT_BUMP","RACK"}
        Degenerate={"ZERO_TIE","UBJ_PICKUP","COLLINEAR_PICKUP","ZERO_RACK"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old));
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
        end
    end
    methods (Test)
        function newBumpUsesUpdatedSteering(t,Side,BumpMetric)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            i=2*Side-1; td=targets{i}.definitionSI; td.metricId=BumpMetric; td.type="CURVE_TARGET";
            td.x=[-.01;0;.01]; td.value=0;
            targets{i}=fsd.model.createDesignTarget(td,'rad','m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildSteeringSpace(s,d);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            g=e.axle.leftGeometry; if Side==2, g=e.axle.rightGeometry; end
            sw=fsd.kinematics.solveBumpSweep(g,s.plan.leftBump.travel_m,'m',s.plan.leftBump.solverOptions);
            a=fsd.analysis.analyzeBumpSweep(g,sw);
            names=["camber_rad","toe_rad","bumpSteer_rad","caster_rad","kingpinInclination_rad"];
            name=names(["CAMBER","TOE","BUMP_STEER","CASTER","KPI"]==BumpMetric);
            t.verifyEqual(e.assessment.targetAssessments{i}.actual,a.(name),'AbsTol',1e-10);
            t.verifyEqual(e.physical{Side}.modelIdentity,fsd.model.geometryIdentity(g));
            t.verifyTrue(e.physical{Side}.quality.allReliable);
            t.verifyNotEqual(e.axleIdentity,s.seedIdentity);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function nativeRackMetric(t,Side,RackMetric)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            i=2*Side; td=targets{i}.definitionSI; td.metricId=RackMetric; unit='rad';
            if ismember(RackMetric,["SCRUB_RADIUS","MECHANICAL_TRAIL"]), unit='m'; end
            td.normalizationNote="Explicit unit-correct availability control";
            targets{i}=fsd.model.createDesignTarget(td,unit,'m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildSteeringSpace(s,d);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            sw=fsd.kinematics.solveRackSweep(e.steering,s.plan.rack.travel_m,s.plan.rack.wheelTravel_m,'m',s.plan.rack.solverOptions);
            a=fsd.analysis.analyzeRackSweep(e.steering,sw); side="left"; if Side==2, side="right"; end
            names=["toe_rad","roadWheelAngle_rad","scrubRadius_m","mechanicalTrail_m"];
            name=names(["TOE","ROAD_WHEEL_ANGLE","SCRUB_RADIUS","MECHANICAL_TRAIL"]==RackMetric);
            idx=s.plan.rack.travel_m==td.x;
            t.verifyEqual(e.assessment.targetAssessments{i}.actual,a.states(idx).(side).(name),'AbsTol',1e-10);
            t.verifyEqual(e.physical{4}.modelIdentity,e.steeringIdentity);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function rigidRackAndConstantLinks(t,Side)
            s=steeringSynthesisFixture(false,false,"TIE_ROD_INBOARD",1);
            e=fsd.synthesis.evaluateSteeringCandidate(s,[.75;.25]); sw=e.physical{4}.sweep;
            t.assertTrue(sw.allConverged);
            g=e.axle.leftGeometry; side="leftResult"; if Side==2, g=e.axle.rightGeometry; side="rightResult"; end
            inner=fsd.model.getPoint(g,g.cornerId+"_TIE_ROD_INBOARD");
            length=norm(fsd.model.getPoint(g,g.cornerId+"_TIE_ROD_OUTBOARD")-inner);
            for k=1:numel(sw.results)
                r=sw.results(k); p=r.(side);
                t.verifyEqual(p.tieRodInboardCurrent_m,inner+sw.requestedRackTravel_m(k)*e.steering.rackGeometry.axisDirection,'AbsTol',1e-15);
                t.verifyEqual(norm(p.state.tieRodOutboard_m-p.tieRodInboardCurrent_m),length,'AbsTol',2e-9);
                t.verifyEqual(norm(r.rightResult.tieRodInboardCurrent_m-r.leftResult.tieRodInboardCurrent_m), ...
                    e.steering.rackGeometry.jointSeparation_m,'AbsTol',1e-14);
            end
            t.verifyNotEqual(e.steering.rackGeometry.axisDirection,s.seedSteering.rackGeometry.axisDirection);
            t.verifyEqual(e.mechanismDiagnostics.tieRodLength_m(Side),length);
        end
        function ackermannBothTurnsUsesNativeDefinition(t)
            s=steeringSynthesisFixture(); e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            a=e.physical{4}.analysis;
            t.verifyEqual(a.ackermannStatus(3),"NEAR_STRAIGHT"); t.verifyTrue(isnan(a.ackermannAngleError_rad(3)));
            for k=[1,2,4,5]
                state=a.states(k);
                expected=fsd.analysis.ackermannGeometry(state.left.geometricContact.point_m,state.left.roadWheelHeading, ...
                    state.right.geometricContact.point_m,state.right.roadWheelHeading,e.steering.rearAxleX_m, ...
                    state.left.rackInducedSteer_rad,state.right.rackInducedSteer_rad);
                t.verifyEqual(state.ackermann,expected);
                inner="FR"; if mean([state.left.rackInducedSteer_rad,state.right.rackInducedSteer_rad])<0, inner="FL"; end
                t.verifyEqual(state.ackermann.innerCorner,inner);
            end
            t.verifyEqual(a.roadWheelAngleLeft_rad,-flipud(a.roadWheelAngleRight_rad),'AbsTol',2e-8);
            t.verifyEqual(a.ackermannAngleError_rad(1:2),-flipud(a.ackermannAngleError_rad(4:5)),'AbsTol',2e-8);
        end
        function currentInnerClosureQuality(t,Side)
            s=steeringSynthesisFixture(); e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            g=e.axle.leftGeometry; side="leftResult"; q=e.physical{4}.quality.left;
            if Side==2, g=e.axle.rightGeometry; side="rightResult"; q=e.physical{4}.quality.right; end
            [fixed,initial,lengths]=closureInputs(g); scale=max(lengths);
            for k=1:numel(e.physical{4}.sweep.results)
                r=e.physical{4}.sweep.results(k).(side);
                b=[r.state.ubj_m;r.state.ubj_m;r.state.lbj_m;r.state.lbj_m;r.state.tieRodOutboard_m];
                p=fixed; p(5,:)=r.tieRodInboardCurrent_m;
                u=(b-p)./vecnorm(b-p,2,2);
                J=[u(:,1:2)*scale,cross(b-r.state.wheelCenter_m,u,2)]./lengths;
                t.verifyEqual(q.rcond(k),rcond(J),'AbsTol',1e-12);
                t.verifyEqual(q.orientation(k),sign(det(J)));
            end
            t.verifyEqual(lengths,vecnorm(initial-fixed,2,2));
            t.verifyEqual(q.threshold,sqrt(eps('double')));
        end
        function independentSourcesSurviveFailure(t,Failure)
            s=steeringSynthesisFixture(); p=s.plan; index=4;
            if Failure=="LEFT_BUMP"
                p.leftBump.solverOptions.MaxIterations=1; index=1;
            elseif Failure=="RIGHT_BUMP"
                p.rightBump.solverOptions.MaxIterations=1; index=2;
            else
                p.rack.solverOptions.MaxIterations=1;
            end
            s=rebuildSteeringSpace(s,s.specification.definitionSI,p);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            t.verifyFalse(e.physical{index}.sweep.allConverged); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            others=setdiff([1,2,4],index);
            for k=others, t.verifyTrue(e.physical{k}.sweep.allConverged); end
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function recoverableGeometricFailures(t,Degenerate)
            s=steeringSynthesisFixture(false,false); d=s.specification.definitionSI; g=s.seedAxle.leftGeometry;
            role="TIE_ROD_OUTBOARD"; expected="fsd:model:CoincidentTieRod";
            bad=fsd.model.getPoint(g,"FL_TIE_ROD_INBOARD");
            switch Degenerate
                case "UBJ_PICKUP", bad=fsd.model.getPoint(g,"FL_UBJ"); expected="fsd:model:CoincidentUprightPoints";
                case "COLLINEAR_PICKUP"
                    bad=(fsd.model.getPoint(g,"FL_UBJ")+fsd.model.getPoint(g,"FL_LBJ"))/2;
                    expected="fsd:model:DegenerateUpright";
                case "ZERO_RACK"
                    role="TIE_ROD_INBOARD"; bad=fsd.model.getPoint(s.seedAxle.rightGeometry,"FR_TIE_ROD_INBOARD");
                    expected="fsd:model:DegenerateRackAxis";
            end
            point=fsd.model.getPoint(g,"FL_"+role); bindings=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
            parameters=cell(3,1); p=d.parameters{1}.definitionSI;
            for k=1:3
                p.id="BAD_COORD_"+k; p.scope=fsd.model.designScope('HARDPOINT',"FL_"+role,"FL");
                p.binding=bindings(k); p.value=point(k); p.bounds=sort([point(k),bad(k)]);
                parameters{k}=fsd.model.createDesignParameter(p,'m');
            end
            d.parameters=parameters; s=rebuildSteeringSpace(s,d,s.plan,strings(0,2));
            u=fsd.synthesis.normalizeSteeringVariables(s,bad');
            e=fsd.synthesis.evaluateSteeringCandidate(s,u);
            t.verifyEqual(e.failureStage,"BUILDER"); t.verifyEqual(e.exceptionId,expected);
            t.verifyFalse(e.geometryValid); t.verifyEmpty(e.steering); t.verifyEmpty(e.axle);
            t.verifyEmpty(e.steeringIdentity); t.verifyEqual(e.physical,{[];[];[];[]}); t.verifyTrue(isnan(e.score));
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function rollUsesReconstructedCorners(t)
            s=steeringSynthesisFixture(true); e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            sw=fsd.kinematics.solveAxleRollSweep(e.axle,s.plan.roll.angles_rad,0,'rad','m',s.plan.roll.solverOptions);
            a=fsd.analysis.analyzeAxleRollSweep(e.axle,sw);
            t.verifyEqual(e.physical{3}.analysis.roadCamber_rad,a.roadCamber_rad,'AbsTol',1e-10);
            t.verifyEqual(e.physical{3}.modelIdentity,e.axleIdentity);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function analyticTranslationWithChangedTieEndpoints(t)
            control=steeringSynthesisFixture(); d=control.specification.definitionSI;
            a=translationAxleFixture(); seeds={a.leftGeometry;a.rightGeometry}; parameters=cell(0,1);
            for j=1:2
                g=seeds{j};
                for role=["TIE_ROD_INBOARD","TIE_ROD_OUTBOARD"]
                    p=d.parameters{j}.definitionSI; p.id=g.cornerId+"_"+role+"_X";
                    p.scope=fsd.model.designScope('HARDPOINT',g.cornerId+"_"+role,g.cornerId);
                    p.binding="HARDPOINT_X"; point=fsd.model.getPoint(g,p.scope.id); p.value=point(1);
                    p.bounds=p.value+[-.01,.01]; parameters{end+1,1}=fsd.model.createDesignParameter(p,'m'); %#ok<AGROW>
                end
            end
            d.parameters=parameters; d.constraints={}; targets=d.targets.definitionSI.targets;
            d.targets=fsd.model.createSuspensionDesignTargets(targets(cellfun(@(q) q.definitionSI.sourceType=="BUMP",targets)));
            plan=control.plan; plan.rack.travel_m=0; plan.rack.wheelTravel_m=[.01,.01];
            links=["FL_TIE_ROD_INBOARD_X","FR_TIE_ROD_INBOARD_X";"FL_TIE_ROD_OUTBOARD_X","FR_TIE_ROD_OUTBOARD_X"];
            s=rebuildSteeringSpace(control,d,plan,links,seeds);
            e=fsd.synthesis.evaluateSteeringCandidate(s,fsd.synthesis.normalizeSteeringVariables(s,s.initial_m+.005));
            t.assertTrue(e.geometryValid); t.verifyNumElements(e.changes,4);
            % Independent historical circle equation, not synthesis/native solve output.
            z=s.plan.leftBump.travel_m; dy=.3-sqrt(.3^2-z.^2);
            for j=1:2
                sw=e.physical{j}.sweep; wc=fsd.model.getPoint(seeds{j},seeds{j}.cornerId+"_WHEEL_CENTER");
                signValue=1; if j==2, signValue=-1; end
                centers=vertcat(sw.results.state); centers=vertcat(centers.wheelCenter_m);
                t.verifyEqual(centers-wc,[zeros(3,1),signValue*dy,z],'AbsTol',2e-9);
                t.verifyEqual(e.physical{j}.analysis.bumpSteer_rad,zeros(3,1),'AbsTol',1e-9);
            end
            t.verifyEqual([e.physical{4}.analysis.roadWheelAngleLeft_rad,e.physical{4}.analysis.roadWheelAngleRight_rad],[0,0],'AbsTol',1e-9);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function closureQualityIndependentFiniteDifference(t)
            s=steeringSynthesisFixture(); e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            g=e.axle.leftGeometry; r=e.physical{4}.sweep.results(4).leftResult;
            [p,~,lengths]=closureInputs(g); p(5,:)=r.tieRodInboardCurrent_m; scale=max(lengths);
            b=[r.state.ubj_m;r.state.ubj_m;r.state.lbj_m;r.state.lbj_m;r.state.tieRodOutboard_m];
            h=1e-6; J=zeros(5); % dimensionless finite-difference verification step, not a solver tolerance
            for k=1:5
                delta=zeros(5,1); delta(k)=h;
                J(:,k)=(poseLengthResidual(b,r.state.wheelCenter_m,p,lengths,delta,scale)- ...
                    poseLengthResidual(b,r.state.wheelCenter_m,p,lengths,-delta,scale))/(2*h);
            end
            q=e.physical{4}.quality.left;
            t.verifyEqual(q.rcond(4),rcond(J),'AbsTol',1e-8);
            t.verifyEqual(q.orientation(4),sign(det(J)));
        end
        function singularStaticClosureIsNotEligible(t)
            s=steeringSynthesisFixture(); a=translationAxleFixture(); g=a.leftGeometry;
            g.hardpoints.xyz_m(8,:)=(fsd.model.getPoint(g,"FL_UBJ")+fsd.model.getPoint(g,"FL_LBJ"))/2+[1e-8,0,0];
            % Deliberately tiny steering arm: software conditioning stress, not a vehicle design.
            seeds={g;fsd.geometry.reflectDoubleWishboneGeometry(g)};
            d=s.specification.definitionSI; d.parameters={}; d.constraints={}; d.targets=fsd.model.createSuspensionDesignTargets({});
            d.compositeScore=false; p=s.plan; p.leftBump.travel_m=0; p.rightBump.travel_m=0; p.rack.travel_m=0;
            s=rebuildSteeringSpace(s,d,p,strings(0,2),seeds);
            e=fsd.synthesis.evaluateSteeringCandidate(s,zeros(0,1));
            t.verifyTrue(e.geometryValid); t.verifyTrue(e.physical{4}.sweep.allConverged);
            t.verifyLessThan(e.physical{4}.quality.left.referenceRcond,sqrt(eps('double')));
            t.verifyFalse(e.physical{4}.quality.allReliable); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function invalidBuilderCacheHasNoPhysicalCalls(t)
            [old,~]=axleNullLinkFixture("UCA",1,"FWD",true); a=old.seedAxle;
            p=old.plan; p.referenceRackTravel_m=0;
            p.rack=struct('travel_m',0,'wheelTravel_m',[0,0],'travelLimits_m',[-.01,.01]);
            st=fsd.model.createSteeringSystem(a,1.6,'m');
            s=fsd.synthesis.createSteeringDesignSpace(a.leftGeometry,a.rightGeometry,st,old.specification,p);
            u=fsd.synthesis.normalizeSteeringVariables(s,s.initial_m);
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',3,'maxIterations',2, ...
                'initialStep',1,'minimumStep',1,'seeds',u'));
            t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,0);
            t.verifyEqual(r.statistics.preSolverFailures,r.search.evaluationCount); t.verifyGreaterThan(r.statistics.cacheHits,0);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
        end
        function unknownProgrammingErrorEscapes(t)
            t.verifyError(@() steeringUnknownBuilderCall(steeringSynthesisFixture()),'MATLAB:nonExistentField');
        end
    end
end

function [p,b,lengths] = closureInputs(g)
in=["UCA_FWD_CHASSIS","UCA_AFT_CHASSIS","LCA_FWD_CHASSIS","LCA_AFT_CHASSIS","TIE_ROD_INBOARD"];
out=["UBJ","UBJ","LBJ","LBJ","TIE_ROD_OUTBOARD"]; p=zeros(5,3); b=p;
for k=1:5
    p(k,:)=fsd.model.getPoint(g,g.cornerId+"_"+in(k)); b(k,:)=fsd.model.getPoint(g,g.cornerId+"_"+out(k));
end
lengths=vecnorm(b-p,2,2);
end

function residual = poseLengthResidual(b,wc,p,lengths,delta,scale)
R=fsd.geometry.rotationVectorToMatrix(delta(3:5)');
shifted=(R*(b-wc)')'+wc+[scale*delta(1),scale*delta(2),0];
residual=(vecnorm(shifted-p,2,2)-lengths)./lengths;
end
