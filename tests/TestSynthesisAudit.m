classdef TestSynthesisAudit < matlab.unittest.TestCase
    properties
        Result
        Failure
    end
    properties (TestParameter)
        Option={"MaxIterations","StepTolerance","MaxContinuationStep_m"}
        Attack={"ELIGIBLE","SCORE","CLASS","STAGE","ERROR","MESSAGE","COUNT", ...
            "SWEEP","QUALITY","AVAILABILITY","ASSESSMENT","HISTORY","STATS","SELECTION"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
            [s,o]=synthesisFixture(); t.Result=fsd.synthesis.runInverseSearch(s,o);
            t.Failure=fsd.synthesis.runInverseSearch(synthesisFailureFixture(),struct('maxEvaluations',1));
        end
    end
    methods (Test)
        function originalAndIndependentEffectiveDefaults(t)
            r=t.Result; t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
            expected=struct('MaxContinuationStep_m',.005,'FunctionTolerance',1e-12,'StepTolerance',1e-12, ...
                'OptimalityTolerance',1e-12,'MaxIterations',200,'MaxFunctionEvaluations',2000);
            t.verifyEqual(r.execution.solverOptions,expected);
            for e=r.search.records'
                t.verifyEqual(e{1}.execution.solverOptions,expected);
                t.verifyEqual(e{1}.bumpEvidence.execution,e{1}.execution);
            end
        end
        function changedOptionRejected(t,Option)
            r=t.Result; s=r.problem; plan=s.plan;
            if Option=="MaxIterations", plan.solverOptions.(Option)=1;
            else, plan.solverOptions.(Option)=plan.solverOptions.(Option)*2; end
            r.problem=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
            e=r.search.records{r.selectedIndex};
            t.verifyError(@() fsd.synthesis.validateSynthesisEvaluation(e,r.problem),'fsd:synthesis:InvalidEvaluation');
            t.verifyError(@() fsd.synthesis.compareSynthesisCandidates(r),'fsd:synthesis:InvalidResult');
            t.verifyError(@() fsd.synthesis.plotSynthesisResult(r),'fsd:synthesis:InvalidResult');
            if Option=="MaxIterations"
                fresh=fsd.synthesis.evaluateSynthesisCandidate(r.problem,e.u,e.evaluationId);
                t.verifyTrue(e.eligible); t.verifyFalse(fresh.eligible); t.verifyEqual(fresh.classification,"SOLVER_FAILED");
            end
        end
        function normalizedEquivalentOptions(t)
            r=t.Result; s=r.problem; plan=struct('travel_m',s.plan.travel_m,'solverOptions',struct('MaxIterations',200.9));
            r.problem=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
            plan.solverOptions=struct('UnknownOption',1);
            t.verifyError(@() fsd.synthesis.createDesignSpace(s.seed,s.specification,plan),'fsd:kinematics:InvalidOptions');
        end
        function superficialCoordinatedTamper(t)
            r=t.Result; s=r.problem; plan=s.plan; plan.solverOptions.FunctionTolerance=1e-8;
            r.problem=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            r.execution.solverOptions=plan.solverOptions;
            for i=1:numel(r.search.records), r.search.records{i}.execution=r.execution; end
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
        end
        function mixedPlansAndAssessments(t)
            r=t.Result; s=r.problem; plan=s.plan; plan.solverOptions.MaxIterations=1;
            other=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            fresh=fsd.synthesis.evaluateSynthesisCandidate(other,r.search.records{1}.u,1);
            r.search.records{1}=fresh;
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
            r=t.Result; r.search.records{1}.assessment=fresh.assessment;
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
        end
        function changedGridGeometrySpecification(t)
            r=t.Result; s=r.problem; plan=s.plan; plan.travel_m=plan.travel_m/2;
            r.problem=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
            r=t.Result; g=s.seed; g.hardpoints.xyz_m(4,1)=g.hardpoints.xyz_m(4,1)+.001;
            r.problem=fsd.synthesis.createDesignSpace(g,s.specification,s.plan);
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
            r=t.Result; d=s.specification.definitionSI; td=d.targets.definitionSI.targets{1}.definitionSI;
            td.tolerance=1; d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(td,'rad','m')});
            r.problem=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
        end
        function requiredPhysicalReproducer(t)
            r=t.Failure; s=r.problem; e=r.search.records{1};
            t.verifyTrue(fsd.model.validateDoubleWishboneGeometry(s.seed));
            g=fsd.synthesis.buildCandidateGeometry(s,s.initial_m);
            sweep=fsd.kinematics.solveBumpSweep(g,0,'m',s.plan.solverOptions);
            t.verifyTrue(sweep.allConverged);
            t.verifyError(@() fsd.analysis.analyzeBumpSweep(g,sweep),'fsd:analysis:DegenerateCasterProjection');
            t.verifyEqual(e.failureStage,"ANALYSIS"); t.verifyEqual(e.exceptionId,"fsd:analysis:DegenerateCasterProjection");
            t.verifyEqual(e.classification,"ANALYSIS_FAILED"); t.verifyTrue(e.bumpEvidence.sweep.allConverged);
            t.verifyEmpty(e.candidate); t.verifyEmpty(e.assessment); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyEqual(r.search.evaluationCount,1); t.verifyEqual(r.search.attemptCount,1);
            t.verifyEqual(r.statistics.physicalBumpSweeps,1); t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyTrue(fsd.synthesis.validateSynthesisEvaluation(e,s)); t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function multipleFailuresCacheBudgetAndImmutability(t)
            s=t.Failure.problem; before=s; o=struct('maxEvaluations',5,'maxIterations',5,'seeds',[.5,.5]); original=o;
            r=fsd.synthesis.runInverseSearch(s,o); repeat=fsd.synthesis.runInverseSearch(s,o);
            t.verifyEqual(s,before); t.verifyEqual(o,original);
            t.verifyEqual(r.search.history,repeat.search.history);
            t.verifyEqual(r.search.evaluationCount,5); t.verifyEqual(r.statistics.physicalBumpSweeps,5);
            t.verifyEqual(r.search.stopReason,"MAX_EVALUATIONS"); t.verifyEmpty(r.feasibleIndices);
            t.verifyTrue(all(cellfun(@(e) e.classification=="ANALYSIS_FAILED",r.search.records)));
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
            cache=fsd.synthesis.runInverseSearch(s,struct('maxIterations',1,'seeds',[.5,.5],'minimumStep',.25));
            t.verifyGreaterThan(cache.search.cacheHitCount,0);
            t.verifyEqual(cache.statistics.physicalBumpSweeps,cache.search.evaluationCount);
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(cache));
        end
        function failedBuilderThenEligible(t)
            s=synthesisFailureFixture("BUILDER"); r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',5));
            t.verifyEqual(r.search.records{1}.classification,"INVALID_GEOMETRY");
            t.verifyEqual(r.search.records{1}.exceptionId,"fsd:synthesis:DegenerateWishbone");
            t.verifyEqual(r.search.records{1}.solverCalls,0); t.verifyNotEmpty(r.feasibleIndices);
            t.verifyTrue(any(cellfun(@(h) h.acceptanceCriterion=="HARD_FEASIBILITY_FOUND",r.search.history)));
            t.verifyEqual(r.statistics.physicalBumpSweeps,r.search.evaluationCount-1);
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function upstreamBumpExceptionAndUnknownErrors(t)
            s=t.Result.problem; u=fsd.synthesis.normalizeVariables(s,s.initial_m);
            e=synthesisAuditTestCall(s,u,1,"fsd:kinematics:InvalidWheelAxisOrientation");
            t.verifyEqual(e.failureStage,"BUMP"); t.verifyEqual(e.solverStatus,"EXCEPTION");
            t.verifyEqual(e.evidenceStatus,"GEOMETRY_ONLY"); t.verifyEmpty(e.bumpEvidence.sweep);
            t.verifyEmpty(e.candidate); t.verifyEmpty(e.assessment); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyEqual(e.solverCalls,1); t.verifyTrue(fsd.synthesis.validateSynthesisEvaluation(e,s));
            for id=["MATLAB:nonExistentField","fsd:kinematics:MissingOptimizationToolbox","fsd:test:Unexpected"]
                t.verifyError(@() synthesisAuditTestCall(s,u,1,id),id);
            end
            e.quality=struct(); t.verifyError(@() fsd.synthesis.validateSynthesisEvaluation(e,s),'fsd:synthesis:InvalidEvaluation');
        end
        function unexpectedAnalysisErrorEscapes(t)
            s=t.Result.problem; u=fsd.synthesis.normalizeVariables(s,s.initial_m);
            t.verifyError(@() synthesisAuditTestCall(s,u,1,"MATLAB:nonExistentField","ANALYSIS"),'MATLAB:nonExistentField');
            % An injected known ID alone cannot certify an analysis failure:
            % actual native evidence does not reproduce this projection error.
            e=synthesisAuditTestCall(s,u,1,"fsd:analysis:DegenerateCasterProjection","ANALYSIS");
            t.verifyError(@() fsd.synthesis.validateSynthesisEvaluation(e,s),'fsd:synthesis:InvalidEvaluation');
        end
        function failureAttacks(t,Attack)
            r=t.Failure; e=r.search.records{1};
            switch Attack
                case "ELIGIBLE", e.eligible=true;
                case "SCORE", e.score=0;
                case "CLASS", e.classification="SAMPLED_FEASIBLE";
                case "STAGE", e.failureStage="BUMP";
                case "ERROR", e.exceptionId="fsd:analysis:DegenerateToeProjection";
                case "MESSAGE", e.exceptionMessage="False diagnostic";
                case "COUNT", e.solverCalls=0;
                case "SWEEP", e.bumpEvidence.sweep=t.Result.search.records{1}.bumpEvidence.sweep;
                case "QUALITY", e.quality.referenceRcond=-1;
                case "AVAILABILITY", e.evidenceStatus="ASSESSED";
                case "ASSESSMENT", e.assessment=t.Result.search.records{1}.assessment;
                case "HISTORY", r.search.history{1}.reason="SAMPLED_FEASIBLE";
                case "STATS", r.statistics.physicalBumpSweeps=0;
                case "SELECTION", r.selectedIndex=1; r.feasibleIndices=1;
            end
            r.search.records{1}=e;
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
        end
        function matRoundTripAndPlanTamper(t)
            file=string(tempname)+".mat"; t.addTeardown(@() delete(file));
            for r={t.Result,t.Failure}
                value=r{1}; save(file,'value'); loaded=load(file,'value'); value=loaded.value;
                t.verifyTrue(fsd.synthesis.validateSynthesisResult(value));
                s=value.problem; plan=s.plan; plan.solverOptions.MaxIterations=1;
                value.problem=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
                t.verifyError(@() fsd.synthesis.validateSynthesisResult(value),'fsd:synthesis:InvalidResult');
            end
        end
        function validatorsNeverSolve(t)
            profile clear; profile on;
            fsd.synthesis.validateSynthesisEvaluation(t.Result.search.records{1},t.Result.problem);
            fsd.synthesis.validateSynthesisResult(t.Result); fsd.synthesis.validateSynthesisResult(t.Failure);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","fzero"])));
        end
    end
end
