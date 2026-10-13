classdef TestSteeringSynthesisIntegration < matlab.unittest.TestCase
    properties
        Benchmark
    end
    properties (TestParameter)
        Attack={"GEOMETRY","RACK_IDENTITY","LEFT_IDENTITY","OLD_BUMP","OLD_RACK","SOURCE_ALIAS", ...
            "RACK_OPTIONS","BUMP_OPTIONS","RACK_GRID","BUMP_GRID","REAR_REFERENCE","LIMITS","WHEEL_TRAVEL", ...
            "SNAPSHOT","EVIDENCE_SNAPSHOT","EVIDENCE_ID","SCORE","ELIGIBLE","CLASSIFICATION","QUALITY", ...
            "ASSESSMENT","SPECIFICATION","HISTORY","SELECTION","STOP","CACHE","COUNTERS","TIMING","ORDER"}
        HardMetric={"BUMP_STEER","ACKERMANN_ANGLE_ERROR"}
        MissingStrength={"HARD","SOFT"}
        Domain={"ONE_DIRECTION","PARTIAL_CURVE"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples')); t.Benchmark=steeringSynthesisExample(false);
        end
    end
    methods (Test)
        function independentReachableBenchmark(t)
            b=t.Benchmark; r=b.result; first=r.search.records{1}; best=r.search.records{r.selectedIndex};
            t.verifyLessThan(best.score,first.score); t.verifyLessThan(best.score,1e-8);
            t.verifyEqual(r.search.evaluationCount,3);
            t.verifyEqual([r.statistics.leftBumpSweeps,r.statistics.rightBumpSweeps,r.statistics.rackSweeps,r.statistics.rollSweeps],[3,3,3,0]);
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,9);
            t.verifyEqual(best.axle.leftGeometry.hardpoints.xyz_m(8,1),.055,'AbsTol',1e-12);
            t.verifyEqual(best.axle.rightGeometry.hardpoints.xyz_m(8,1),.055,'AbsTol',1e-12);
            t.verifyEqual(best.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
            left=fsd.analysis.analyzeBumpSweep(best.axle.leftGeometry,b.directLeft);
            right=fsd.analysis.analyzeBumpSweep(best.axle.rightGeometry,b.directRight);
            rack=fsd.analysis.analyzeRackSweep(best.steering,b.directRack);
            t.verifyEqual(best.physical{1}.analysis.bumpSteer_rad,left.bumpSteer_rad,'AbsTol',1e-10);
            t.verifyEqual(best.physical{2}.analysis.toe_rad,right.toe_rad,'AbsTol',1e-10);
            t.verifyEqual(best.physical{4}.analysis.roadWheelAngleLeft_rad,rack.roadWheelAngleLeft_rad,'AbsTol',1e-10);
            t.verifyEqual(best.physical{4}.analysis.roadWheelAngleRight_rad,rack.roadWheelAngleRight_rad,'AbsTol',1e-10);
            t.verifyEqual(best.physical{4}.analysis.ackermannAngleError_rad,rack.ackermannAngleError_rad,'AbsTol',1e-10);
            t.verifyEqual(b.additionalPhysicalSweeps,6);
        end
        function genuinePhysicalTradeoff(t)
            b=t.Benchmark; values=b.tradeoffValues;
            t.verifyGreaterThan(values(2,1:2),values(1,1:2)); % negative X: more bump steer
            t.verifyLessThan(values(2,3:4),values(1,3:4));    % but less ideal-Ackermann error
            t.verifyLessThan(values(3,1:2),values(1,1:2));
            t.verifyGreaterThan(values(3,3:4),values(1,3:4));
            t.verifyEqual(b.tradeoffComparison.selectionPolicy,"NO_AUTOMATIC_WINNER");
            t.verifyNotEqual(b.tradeoffSpecification.identity,b.space.specification.identity);
        end
        function adversarialResult(t,Attack)
            r=t.Benchmark.result; i=r.selectedIndex; e=r.search.records{i};
            switch Attack
                case "GEOMETRY", e.steering.frontAxleGeometry.leftGeometry.hardpoints.xyz_m(8,1)=.05;
                case "RACK_IDENTITY", e.steeringIdentity=r.problem.seedSteering.identity;
                case "LEFT_IDENTITY", e.axleIdentity.leftGeometryIdentity=e.axleIdentity.rightGeometryIdentity;
                case "OLD_BUMP", e.physical{1}.sweep=r.search.records{1}.physical{1}.sweep;
                case "OLD_RACK", e.physical{4}.sweep=r.search.records{1}.physical{4}.sweep;
                case "SOURCE_ALIAS", e.candidate.definitionSI.sources{1}.sweep=e.physical{2}.sweep;
                case "RACK_OPTIONS", r.problem.plan.rack.solverOptions.MaxIterations=1;
                case "BUMP_OPTIONS", r.problem.plan.leftBump.solverOptions.MaxIterations=1;
                case "RACK_GRID", r.problem.plan.rack.travel_m=[-.004;0;.004];
                case "BUMP_GRID", r.problem.plan.rightBump.travel_m=[-.02;0;.02];
                case "REAR_REFERENCE"
                    r.problem.seedSteering=fsd.model.createSteeringSystem(r.problem.seedAxle,1.7,'m');
                case "LIMITS", r.problem.plan.rack.travelLimits_m=[-.02,.02];
                case "WHEEL_TRAVEL", r.problem.plan.rack.wheelTravel_m=[.001,0];
                case "SNAPSHOT", r.execution.plan.referenceRackTravel_m=.001;
                case "EVIDENCE_SNAPSHOT", e.physical{4}.execution.plan.rack.solverOptions.MaxIterations=1;
                case "EVIDENCE_ID", e.physical{4}.evaluationId=1;
                case "SCORE", e.score=100;
                case "ELIGIBLE", e.eligible=false;
                case "CLASSIFICATION", e.classification="INVALID_GEOMETRY";
                case "QUALITY", e.physical{4}.quality.left.rcond(:)=1;
                case "ASSESSMENT", e.assessment.hardFeasibility="NO_HARD_REQUIREMENTS";
                case "SPECIFICATION"
                    d=r.problem.specification.definitionSI; targets=d.targets.definitionSI.targets;
                    q=targets{1}.definitionSI; q.value(:)=1; targets{1}=fsd.model.createDesignTarget(q,'rad','m');
                    d.targets=fsd.model.createSuspensionDesignTargets(targets); r.problem=rebuildSteeringSpace(r.problem,d);
                case "HISTORY", r.search.history{1}.accepted=false;
                case "SELECTION", r.selectedIndex=1;
                case "STOP", r.search.stopReason="GLOBAL_OPTIMUM";
                case "CACHE", r.search.keys{i}(:)=0;
                case "COUNTERS", r.statistics.rackSweeps=0;
                case "TIMING", e.timing_s.total=-1;
                case "ORDER", e.evaluationId=1;
            end
            r.search.records{i}=e;
            t.verifyError(@() fsd.synthesis.validateSteeringSynthesisResult(r),'fsd:synthesis:InvalidSteeringResult');
        end
        function alteredCanonicalContextCannotReuseSources(t)
            r=t.Benchmark.result; p=r.problem.plan; p.rack.solverOptions.MaxContinuationStep_m=.002;
            r.problem=rebuildSteeringSpace(r.problem,r.problem.specification.definitionSI,p);
            r.execution.plan=r.problem.plan;
            for j=1:numel(r.search.records), r.search.records{j}.execution.plan=r.problem.plan; end
            t.verifyError(@() fsd.synthesis.validateSteeringSynthesisResult(r),'fsd:synthesis:InvalidSteeringResult');
        end
        function hardViolationRejectsEvenWithOtherFailure(t,HardMetric)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            index=1; if HardMetric=="ACKERMANN_ANGLE_ERROR", index=6; end
            q=targets{index}.definitionSI; q.id="DEMONSTRATED_HARD"; q.strength="HARD"; q.value=1; q.tolerance=0;
            targets{end+1,1}=fsd.model.createDesignTarget(q,'rad','m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets);
            p=s.plan; p.rightBump.solverOptions.MaxIterations=1;
            s=rebuildSteeringSpace(s,d,p); e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            t.verifyEqual(e.classification,"HARD_CONSTRAINT_FAILED");
            t.verifyEqual(e.hardFeasibility,"INFEASIBLE_FOR_SPECIFICATION"); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
        end
        function straightAckermannNotHardPass(t,MissingStrength)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{6}.definitionSI; q.x=0; q.strength=MissingStrength;
            targets{6}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildSteeringSpace(s,d); e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyEqual(e.assessment.targetAssessments{6}.status,"NOT_EVALUATED");
            if MissingStrength=="HARD", t.verifyEqual(e.hardFeasibility,"INDETERMINATE_HARD_REQUIREMENTS"); end
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function unavailableDomainsRemainUnavailable(t,Domain)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; p=s.plan;
            if Domain=="ONE_DIRECTION"
                p.rack.travel_m=[0;.003;.006];
            else
                targets=d.targets.definitionSI.targets; q=targets{6}.definitionSI;
                q.type="CURVE_TARGET"; q.x=[.003;.01]; q.value=0;
                targets{6}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            end
            s=rebuildSteeringSpace(s,d,p); e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            if Domain=="PARTIAL_CURVE", t.verifyEqual(e.assessment.targetAssessments{6}.status,"PARTIALLY_EVALUATED"); end
        end
        function budgetsCacheAndSingleCandidate(t)
            s=steeringSynthesisFixture(); u=fsd.synthesis.normalizeSteeringVariables(s,s.initial_m);
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',1));
            t.verifyEqual(r.search.evaluationCount,1); t.verifyEqual(r.selectedIndex,1);
            t.verifyEqual(r.search.stopReason,"MAX_EVALUATIONS");
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',5,'maxIterations',2, ...
                'initialStep',1,'minimumStep',1,'seeds',u'));
            t.verifyGreaterThan(r.statistics.cacheHits,0);
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,3*r.search.evaluationCount);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
        end
        function noCompleteScalarNoAutomaticWinner(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; d.compositeScore=false;
            s=rebuildSteeringSpace(s,d); r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',1));
            t.verifyEqual(r.feasibleIndices,1); t.verifyTrue(isnan(r.selectedIndex)); t.verifyTrue(isnan(r.search.records{1}.score));
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
        end
        function matRoundTripAndPureConsumers(t)
            r=t.Benchmark.result; filename=[tempname,'.mat']; t.addTeardown(@() delete(filename));
            save(filename,'r'); loaded=load(filename,'r'); t.verifyEqual(loaded.r,r);
            profile clear; profile on;
            fsd.synthesis.validateSteeringSynthesisResult(loaded.r);
            best=r.search.records{r.selectedIndex}; fsd.analysis.evaluateDesignCandidate(r.problem.specification,best.candidate);
            fsd.synthesis.compareSteeringSynthesisCandidates(r,[1;r.selectedIndex]);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveRack","solveAxleRoll","solveCornerPath"])));
        end
    end
end
