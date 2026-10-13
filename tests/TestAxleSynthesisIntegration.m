classdef TestAxleSynthesisIntegration < matlab.unittest.TestCase
    properties (TestParameter)
        Attack={"VECTOR","LEFT_GEOMETRY","RIGHT_GEOMETRY","JOINT_IDENTITY","LEFT_IDENTITY","CROSS_BUMP", ...
            "OLD_ROLL","OLD_BUMP","SOURCE_ALIAS","SCORE","ELIGIBLE","CLASSIFICATION","QUALITY","ASSESSMENT", ...
            "SPECIFICATION","LEFT_OPTIONS","RIGHT_OPTIONS","ROLL_OPTIONS","GRID","HEAVE","SNAPSHOT", ...
            "EVIDENCE_SNAPSHOT","EVIDENCE_ID","HISTORY","SELECTION","STOP","CACHE","COUNTERS","TIMING","ORDER"}
        Side={1,2}
        Unsupported={"RACK","ACTUATION","GLOBAL_STATIC"}
    end
    properties
        Benchmark
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples')); t.Benchmark=axleSuspensionSynthesisExample(false);
        end
    end
    methods (Test)
        function benchmarkChangesBoth(t)
            r=t.Benchmark.result; first=r.search.records{1}; best=r.search.records{r.selectedIndex};
            t.verifyLessThan(best.score,first.score); t.verifyLessThan(best.score,1e-8);
            t.verifyEqual(best.axle.leftGeometry.hardpoints.xyz_m(1:2,3),[.365;.345],'AbsTol',1e-12);
            t.verifyEqual(best.axle.rightGeometry.hardpoints.xyz_m(1:2,3),[.365;.345],'AbsTol',1e-12);
            t.verifyNotEqual(best.axleIdentity.leftGeometryIdentity,r.problem.seedIdentity.leftGeometryIdentity);
            t.verifyNotEqual(best.axleIdentity.rightGeometryIdentity,r.problem.seedIdentity.rightGeometryIdentity);
            t.verifyEqual(best.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
            t.verifyEqual(r.statistics.axleCandidateEvaluations,7);
            t.verifyEqual([r.statistics.leftBumpSweeps,r.statistics.rightBumpSweeps,r.statistics.rollSweeps],[7,7,7]);
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,21);
            left=fsd.analysis.analyzeBumpSweep(best.axle.leftGeometry,t.Benchmark.directLeft);
            right=fsd.analysis.analyzeBumpSweep(best.axle.rightGeometry,t.Benchmark.directRight);
            t.verifyEqual(best.physical{1}.analysis.camber_rad,left.camber_rad,'AbsTol',1e-10);
            t.verifyEqual(best.physical{2}.analysis.toe_rad,right.toe_rad,'AbsTol',1e-10);
            a=fsd.analysis.analyzeAxleRollSweep(best.axle,t.Benchmark.directRoll);
            t.verifyEqual(best.physical{3}.analysis.roadCamber_rad,a.roadCamber_rad,'AbsTol',1e-10);
            t.verifyEqual(best.physical{3}.analysis.rollCenterRoadHeight_m,a.rollCenterRoadHeight_m,'AbsTol',1e-9);
        end
        function adversarialResult(t,Attack)
            r=t.Benchmark.result; i=r.selectedIndex; e=r.search.records{i};
            switch Attack
                case "VECTOR", e.x_m(1)=e.x_m(1)+.001;
                case "LEFT_GEOMETRY", e.axle.leftGeometry.hardpoints.xyz_m(3,3)=.5;
                case "RIGHT_GEOMETRY", e.axle.rightGeometry.hardpoints.xyz_m(3,3)=.5;
                case "JOINT_IDENTITY", e.axleIdentity=r.problem.seedIdentity;
                case "LEFT_IDENTITY", e.axleIdentity.leftGeometryIdentity=e.axleIdentity.rightGeometryIdentity;
                case "CROSS_BUMP", e.physical{2}=e.physical{1};
                case "OLD_ROLL", e.physical{3}.sweep=r.search.records{1}.physical{3}.sweep;
                case "OLD_BUMP", e.physical{1}.sweep=r.search.records{1}.physical{1}.sweep;
                case "SOURCE_ALIAS", e.candidate.definitionSI.sources{1}.sweep=e.physical{2}.sweep;
                case "SCORE", e.score=100;
                case "ELIGIBLE", e.eligible=false;
                case "CLASSIFICATION", e.classification="INVALID_GEOMETRY";
                case "QUALITY", e.physical{3}.quality.reliable(:)=false;
                case "ASSESSMENT", e.assessment.hardFeasibility="NO_HARD_REQUIREMENTS";
                case "SPECIFICATION"
                    d=r.problem.specification.definitionSI; q=d.targets.definitionSI.targets{1}.definitionSI; q.value(:)=1;
                    d.targets.definitionSI.targets{1}=fsd.model.createDesignTarget(q,'rad','m');
                    d.targets=fsd.model.createSuspensionDesignTargets(d.targets.definitionSI.targets);
                    r.problem=rebuildAxleSpace(r.problem,d);
                case "LEFT_OPTIONS", r.problem.plan.leftBump.solverOptions.MaxIterations=1;
                case "RIGHT_OPTIONS", r.problem.plan.rightBump.solverOptions.StepTolerance=1e-8;
                case "ROLL_OPTIONS", r.problem.plan.roll.solverOptions.MaxRollStep_rad=.01;
                case "GRID", r.problem.plan.rightBump.travel_m=[-.02;0;.02];
                case "HEAVE", r.problem.plan.roll.axleHeave_m=.01;
                case "SNAPSHOT", r.execution.plan.leftBump.solverOptions.MaxIterations=1;
                case "EVIDENCE_SNAPSHOT", e.physical{2}.execution.plan.rightBump.solverOptions.MaxIterations=1;
                case "EVIDENCE_ID", e.physical{3}.evaluationId=1;
                case "HISTORY", r.search.history{1}.accepted=false;
                case "SELECTION", r.selectedIndex=1;
                case "STOP", r.search.stopReason="GLOBAL_OPTIMUM";
                case "CACHE", r.search.keys{i}(:)=0;
                case "COUNTERS", r.statistics.rollSweeps=0;
                case "TIMING", e.timing_s.total=-1;
                case "ORDER", e.evaluationId=1;
            end
            r.search.records{i}=e;
            t.verifyError(@() fsd.synthesis.validateAxleSynthesisResult(r),'fsd:synthesis:InvalidAxleResult');
        end
        function alteredCanonicalPlanStillRejected(t)
            r=t.Benchmark.result; d=r.problem.specification.definitionSI; plan=r.problem.plan;
            plan.leftBump.solverOptions.MaxIterations=1; r.problem=rebuildAxleSpace(r.problem,d,plan);
            % Alter superficial snapshots coherently, retain original native wrappers.
            r.execution.plan=r.problem.plan;
            for i=1:numel(r.search.records), r.search.records{i}.execution.plan=r.problem.plan; end
            t.verifyError(@() fsd.synthesis.validateAxleSynthesisResult(r),'fsd:synthesis:InvalidAxleResult');
        end
        function validatorsAndEvaluatorPure(t)
            r=t.Benchmark.result; e=r.search.records{r.selectedIndex};
            profile clear; profile on;
            fsd.synthesis.validateAxleSynthesisResult(r);
            fsd.analysis.evaluateDesignCandidate(r.problem.specification,e.candidate);
            fsd.synthesis.compareAxleSynthesisCandidates(r,[1;r.selectedIndex]);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveAxleRoll","solveCornerPath"])));
        end
        function physicalCountsProfile(t)
            s=t.Benchmark.space;
            profile clear; profile on; r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',1)); profile off;
            info=profile('info'); names=string({info.FunctionTable.FunctionName});
            bump=info.FunctionTable(endsWith(names,'solveBumpSweep')); roll=info.FunctionTable(endsWith(names,'solveAxleRollSweep'));
            t.verifyEqual(sum([bump.NumCalls]),2); t.verifyEqual(sum([roll.NumCalls]),1);
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,3);
            t.verifyGreaterThan(r.statistics.nativeRollCornerSolves,0);
        end
        function deterministicSearch(t)
            r=t.Benchmark.result; repeated=fsd.synthesis.runAxleInverseSearch(r.problem,r.search.options);
            t.verifyEqual(repeated.search.history,r.search.history); t.verifyEqual(repeated.selectedIndex,r.selectedIndex);
            for i=1:numel(r.search.records)
                t.verifyEqual(repeated.search.records{i}.axleIdentity,r.search.records{i}.axleIdentity);
                t.verifyEqual(repeated.search.records{i}.assessment,r.search.records{i}.assessment);
            end
        end
        function hardFailEitherSide(t,Side)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{Side}.definitionSI; q.strength="HARD"; q.value=1; q.tolerance=0;
            targets{Side}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildAxleSpace(s,d); r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',2));
            t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyTrue(all(cellfun(@(e) e.classification=="HARD_CONSTRAINT_FAILED",r.search.records)));
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisResult(r));
        end
        function hardIncompleteEitherSide(t,Side)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{Side}.definitionSI; q.id=q.id+"_HARD"; q.strength="HARD"; q.x=.02;
            targets{end+1,1}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildAxleSpace(s,d); e=fsd.synthesis.evaluateAxleCandidate(s,[.5;.5]);
            t.verifyEqual(e.hardFeasibility,"INDETERMINATE_HARD_REQUIREMENTS"); t.verifyFalse(e.eligible);
        end
        function partialSoftNoWinner(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{2}.definitionSI; q.type="CURVE_TARGET"; q.x=[-.02;0;.02]; q.value=0; q.tolerance=1;
            targets{2}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildAxleSpace(s,d); r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',1)); e=r.search.records{1};
            t.verifyEqual(e.assessment.targetAssessments{2}.domainCoverage,.5); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisResult(r));
        end
        function noScalarObjective(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; d.compositeScore=false; s=rebuildAxleSpace(s,d);
            r=fsd.synthesis.runAxleInverseSearch(s,struct('maxEvaluations',3));
            t.verifyNotEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyTrue(all(cellfun(@(e) isnan(e.score),r.search.records)));
            c=fsd.synthesis.compareAxleSynthesisCandidates(r,[1;2]); t.verifyNumElements(c.hardpointChanges,2);
        end
        function rollPlanMissingOrHeaveMismatch(t)
            s=axleSynthesisFixture(true); p=s.plan; p.roll=[];
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,p),'fsd:synthesis:MissingAnalysisPlan');
            p=s.plan; p.roll.axleHeave_m=.01;
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,p),'fsd:synthesis:InvalidInput');
        end
        function unsupportedReconstruction(t,Unsupported)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; q=d.targets.definitionSI.targets{1}.definitionSI;
            q.sourceType=Unsupported; q.sourceId="UNSUPPORTED";
            switch Unsupported
                case "RACK", q.metricId="TOE"; q.independentVariable="RACK_TRAVEL"; q.conditions=struct('wheelTravel_m',[0,0]); unit='rad'; xUnit='m';
                case "ACTUATION", q.metricId="MOTION_RATIO"; unit='1'; xUnit='m';
                case "GLOBAL_STATIC", q.metricId="CORNER_LOAD"; q.independentVariable="NONE"; q.x=[]; unit='N'; xUnit='1';
            end
            d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(q,unit,xUnit)});
            t.verifyError(@() rebuildAxleSpace(s,d),'fsd:synthesis:UnsupportedTarget');
        end
        function matRoundTripAndTamper(t)
            r=t.Benchmark.result; file=string(tempname)+".mat"; t.addTeardown(@() delete(file)); save(file,'r'); loaded=load(file);
            t.verifyEqual(loaded.r,r); t.verifyTrue(fsd.synthesis.validateAxleSynthesisResult(loaded.r));
            loaded.r.search.records{r.selectedIndex}.physical{2}=[];
            t.verifyError(@() fsd.synthesis.validateAxleSynthesisResult(loaded.r),'fsd:synthesis:InvalidAxleResult');
        end
        function frozenCacheBudget(t)
            [s,o]=axleSynthesisFixture(); d=s.specification.definitionSI;
            for j=1:2, p=d.parameters{j}.definitionSI; p.bounds=[p.value,p.value]; d.parameters{j}=fsd.model.createDesignParameter(p,'m'); end
            s=rebuildAxleSpace(s,d); r=fsd.synthesis.runAxleInverseSearch(s,o);
            t.verifyEqual(r.search.stopReason,"NO_FREE_VARIABLES"); t.verifyEqual(r.statistics.axleCandidateEvaluations,1);
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,2);
            t.verifyTrue(fsd.synthesis.validateAxleSynthesisResult(r));
        end
    end
end
