classdef TestActuationSynthesisIntegration < matlab.unittest.TestCase
    properties
        Benchmark
    end
    properties (TestParameter)
        Family={"ACT_ONLY","MECH_ONLY","HARD_ACT_SOFT_MECH","HARD_MECH_SOFT_ACT","HARD_ONLY","DISABLED"}
        HardCase={"MR_FAIL","MR_UNKNOWN","RATE_FAIL","TRAVEL_FAIL","BOX_FAIL"}
        Attack={"GEOMETRY","ACTUATION","ACT_IDENTITY","ROCKER_AXIS","RATE","PRELOAD", ...
            "OLD_ACTUATION","OLD_MECHANICAL","SOURCE","QUALITY","SCORE","HARD","ELIGIBLE", ...
            "ASSESSMENT","SNAPSHOT","EVIDENCE","OPTIONS","VELOCITY","GRID","SPEC", ...
            "HISTORY","SELECTION","CACHE","COUNTERS","STOP","TIMING"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples')); t.Benchmark=actuationSynthesisExample(false);
        end
    end
    methods (Test)
        function reachablePhysicalBenchmark(t)
            b=t.Benchmark; r=b.result; seed=r.search.records{1}; best=r.search.records{r.selectedIndex};
            t.verifyLessThan(best.score,seed.score); t.verifyEqual(best.score,0);
            t.verifyEqual(best.geometry,b.space.seed); t.verifyNotEqual(best.actuationIdentity,seed.actuationIdentity);
            t.verifyEqual(best.actuation.damper.chassisPoint.point_m(2:3),[-.375,.345],'AbsTol',1e-12);
            t.verifyEqual(best.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
            t.verifyEqual(best.actuationEvidence.analysis.damperMotionRatio,b.directAnalysis.damperMotionRatio,'AbsTol',1e-10);
            t.verifyEqual(best.actuationEvidence.sweep.damperCompression_m,b.directSweep.damperCompression_m,'AbsTol',1e-10);
            t.verifyEqual(best.mechanicalEvidence.analysis.wheelRateTotal_N_per_m,b.directResponse.wheelRateTotal_N_per_m,'AbsTol',1e-7);
            t.verifyEqual(r.statistics.bumpSweeps,r.search.evaluationCount);
            t.verifyEqual(r.statistics.actuationSweeps,r.search.evaluationCount);
            t.verifyEqual(r.statistics.mechanicalAnalyses,r.search.evaluationCount);
            t.verifyEqual(r.statistics.nativeRockerClosures,9*r.search.evaluationCount);
            t.verifyEqual(b.additionalPhysicalSweepInvocations,6);
        end
        function oneFamilyAndMixedSpecifications(t,Family)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            act=targets(cellfun(@(q)q.definitionSI.sourceType=="ACTUATION",targets));
            mech=targets(cellfun(@(q)q.definitionSI.sourceType=="MECHANICAL",targets));
            if Family=="ACT_ONLY", targets=act; end
            if Family=="MECH_ONLY", targets=mech; end
            if Family=="HARD_ACT_SOFT_MECH"
                q=act{1}.definitionSI; q.strength="HARD"; targets=[{fsd.model.createDesignTarget(q,'1','m')};mech];
            end
            if Family=="HARD_MECH_SOFT_ACT"
                q=mech{1}.definitionSI; q.strength="HARD"; targets=[act;{fsd.model.createDesignTarget(q,'N/m','m')}];
            end
            if Family=="HARD_ONLY"
                for j=1:numel(targets)
                    q=targets{j}.definitionSI; q.strength="HARD"; targets{j}=fsd.model.createDesignTarget(q,q.unit,'m');
                end
            end
            if ismember(Family,["HARD_ONLY","DISABLED"]), d.compositeScore=false; end
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildActuationSpace(s,d); original=s;
            r=fsd.synthesis.runActuationInverseSearch(s,struct('maxEvaluations',1)); e=r.search.records{1};
            t.verifyTrue(e.eligible); t.verifyEqual(s,original); t.verifyEqual(s.specification.definitionSI,d);
            t.verifyNumElements(e.assessment.targetAssessments,numel(targets));
            t.verifyEqual(e.assessment.specificationIdentity,s.specification.identity);
            if d.compositeScore, t.verifyTrue(isfinite(e.score));
            else, t.verifyTrue(isnan(e.score)); t.verifyTrue(isnan(r.selectedIndex)); end
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisResult(r));
        end
        function hardEvidenceAndCoverage(t,HardCase)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            if HardCase=="BOX_FAIL"
                c=fsd.model.createDesignConstraint(struct('id',"OUTSIDE_BOX",'type',"AXIS_ALIGNED_BOX",'strength',"HARD", ...
                    'scope',fsd.model.designScope('HARDPOINT','FL_DAMPER_CHASSIS','FL'),'bounds',[.1,.2;.1,.2;.3,.4], ...
                    'sourceNote',"Explicit impossible nominal mounting box control"),'m');
                d.constraints{end+1,1}=c;
            else
                index=1; if HardCase=="RATE_FAIL", index=4; end
                if HardCase=="TRAVEL_FAIL", index=2; end
                q=targets{index}.definitionSI; q.id="HARD_CONTROL"; q.strength="HARD"; q.tolerance=0; q.value=1;
                if HardCase=="MR_UNKNOWN", q.x=.03; end
                targets{end+1,1}=fsd.model.createDesignTarget(q,q.unit,'m');
                d.targets=fsd.model.createSuspensionDesignTargets(targets);
            end
            s=rebuildActuationSpace(s,d); e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]);
            t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            if HardCase=="MR_UNKNOWN"
                t.verifyEqual(e.hardFeasibility,"INDETERMINATE_HARD_REQUIREMENTS");
                t.verifyTrue(isfinite(e.assessment.compositeScore));
            else
                t.verifyEqual(e.hardFeasibility,"INFEASIBLE_FOR_SPECIFICATION");
                t.verifyEqual(e.classification,"HARD_CONSTRAINT_FAILED");
            end
            if HardCase=="BOX_FAIL"
                t.verifyEmpty(e.bumpEvidence); t.verifyEmpty(e.actuationEvidence); t.verifyEmpty(e.mechanicalEvidence);
                t.verifyEqual(e.evidenceStatus,"NOMINAL_HARD_REJECTED");
            end
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisEvaluation(e,s));
        end
        function incompleteSoftIsNotZeroScore(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{1}.definitionSI; q.type="CURVE_TARGET"; q.x=[-.02;.03]; q.value=0;
            targets{1}=fsd.model.createDesignTarget(q,'1','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            s=rebuildActuationSpace(s,d); e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]);
            t.verifyEqual(e.assessment.targetAssessments{1}.status,"PARTIALLY_EVALUATED");
            t.verifyEqual(e.softScoreStatus,"UNAVAILABLE_COVERAGE"); t.verifyTrue(isnan(e.score)); t.verifyFalse(e.eligible);
        end
        function unsupportedHardIsNeverDropped(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=struct('id',"UNSUPPORTED_HARD",'metricId',"ROAD_WHEEL_ANGLE",'sourceType',"RACK",'sourceId',"RACK", ...
                'scope',fsd.model.designScope('CORNER','FL'),'type',"POINT_TARGET",'strength',"HARD", ...
                'independentVariable',"RACK_TRAVEL",'x',.003,'value',0,'tolerance',1, ...
                'conditions',struct('wheelTravel_m',[0,0]),'sourceNote',"Unsupported reconstruction control");
            targets{end+1,1}=fsd.model.createDesignTarget(q,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            t.verifyError(@()rebuildActuationSpace(s,d),'fsd:synthesis:UnsupportedTarget');
        end
        function corruptedResult(t,Attack)
            r=t.Benchmark.result; index=r.selectedIndex; e=r.search.records{index};
            switch Attack
                case "GEOMETRY", e.geometry.hardpoints.xyz_m(1,1)=0;
                case "ACTUATION", e.actuation.damper.chassisPoint.point_m(2)=0;
                case "ACT_IDENTITY", e.actuationIdentity=r.problem.seedActuation.identity;
                case "ROCKER_AXIS", e.actuation.rocker.axis.point_m(3)=0;
                case "RATE", e.mechanical.spring.rate_N_per_m=60000;
                case "PRELOAD", e.mechanical.spring.preloadCompression_m=.01;
                case "OLD_ACTUATION", e.actuationEvidence.sweep=r.search.records{1}.actuationEvidence.sweep;
                case "OLD_MECHANICAL", e.mechanicalEvidence.analysis=r.search.records{1}.mechanicalEvidence.analysis;
                case "SOURCE", e.candidate.definitionSI.sources{2}.model=r.problem.seedActuation;
                case "QUALITY", e.bumpEvidence.quality.rcond(:)=1;
                case "SCORE", e.score=1;
                case "HARD", e.assessment.hardFeasibility="NO_HARD_REQUIREMENTS";
                case "ELIGIBLE", e.eligible=false;
                case "ASSESSMENT", e.assessment.compositeScore=1;
                case "SNAPSHOT", e.execution.plan.wheelVelocity_m_per_s(:)=1;
                case "EVIDENCE", e.actuationEvidence.evaluationId=1;
                case "OPTIONS", r.problem.plan.solverOptions.MaxIterations=1;
                case "VELOCITY", r.problem.plan.wheelVelocity_m_per_s(:)=1;
                case "GRID", r.problem.plan.travel_m=flipud(r.problem.plan.travel_m);
                case "SPEC", r.problem.specification.definitionSI.compositeScore=false;
                case "HISTORY", r.search.history{1}.accepted=false;
                case "SELECTION", r.selectedIndex=1;
                case "CACHE", r.search.keys{index}(:)=0;
                case "COUNTERS", r.statistics.nativeRockerClosures=0;
                case "STOP", r.search.stopReason="GLOBAL_OPTIMUM";
                case "TIMING", e.timing_s.total=-1;
            end
            r.search.records{index}=e;
            t.verifyError(@()fsd.synthesis.validateActuationSynthesisResult(r),'fsd:synthesis:InvalidActuationResult');
        end
        function changedCanonicalPlanCannotReuseEvidence(t)
            r=t.Benchmark.result; p=r.problem.plan; p.solverOptions.MaxContinuationStep_m=.003;
            r.problem=rebuildActuationSpace(r.problem,r.problem.specification.definitionSI,p); r.execution.plan=r.problem.plan;
            for j=1:numel(r.search.records), r.search.records{j}.execution.plan=r.problem.plan; end
            t.verifyError(@()fsd.synthesis.validateActuationSynthesisResult(r),'fsd:synthesis:InvalidActuationResult');
        end
        function budgetsDeterminismAndCache(t)
            s=actuationSynthesisFixture(); u=fsd.synthesis.normalizeActuationVariables(s,s.initial_m);
            options=struct('maxEvaluations',8,'maxIterations',2,'initialStep',1,'minimumStep',1,'seeds',u');
            first=fsd.synthesis.runActuationInverseSearch(s,options); second=fsd.synthesis.runActuationInverseSearch(s,options);
            t.verifyGreaterThan(first.statistics.cacheHits,0); t.verifyLessThanOrEqual(first.search.evaluationCount,8);
            t.verifyEqual(first.search.keys,second.search.keys); t.verifyEqual(first.selectedIndex,second.selectedIndex);
            t.verifyEqual(first.search.stopReason,second.search.stopReason);
            t.verifyEqual(first.statistics.bumpSweeps,first.search.evaluationCount);
            t.verifyEqual(first.statistics.actuationSweeps,first.search.evaluationCount);
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisResult(first));
        end
        function matAndPureConsumers(t)
            r=t.Benchmark.result; file=[tempname,'.mat']; t.addTeardown(@()delete(file)); save(file,'r');
            loaded=load(file,'r'); t.verifyEqual(loaded.r,r);
            profile clear; profile on;
            fsd.synthesis.validateActuationSynthesisResult(loaded.r);
            fsd.synthesis.compareActuationSynthesisCandidates(r,[1;r.selectedIndex]);
            best=r.search.records{r.selectedIndex}; fsd.analysis.evaluateDesignCandidate(r.problem.specification,best.candidate);
            f=fsd.synthesis.plotActuationSynthesisResult(r,[]); profile off; close(f);
            info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveActuationSweep","solveActuationCore"])));
        end
    end
end
