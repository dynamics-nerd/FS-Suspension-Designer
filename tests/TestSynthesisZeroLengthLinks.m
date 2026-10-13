classdef TestSynthesisZeroLengthLinks < matlab.unittest.TestCase
    properties (TestParameter)
        Arm={"UCA","LCA"}
        Appearance={"dark","light"}
        Attack={"IDENTIFIER","STAGE","CLASS","ELIGIBLE","SCORE","VECTOR", ...
            "GEOMETRY","BUMP","COUNTER","SELECTED","SNAPSHOT"}
    end
    properties
        Spaces
        InvalidSpaces
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; visible=get(groot,'DefaultFigureVisible'); t.addTeardown(@() path(old));
            t.addTeardown(@() set(groot,'DefaultFigureVisible',visible));
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src')); set(groot,'DefaultFigureVisible','off');
            for arm=["UCA","LCA"]
                t.Spaces.(arm)=zeroLengthLinkFixture(arm);
                t.InvalidSpaces.(arm)=zeroLengthLinkFixture(arm,"ALL_INVALID");
            end
        end
    end
    methods (Test)
        function individualPreservesNativeDiagnosis(t,Arm)
            s=t.Spaces.(Arm); joint=3; if Arm=="LCA", joint=6; end
            proposed=s.seed; v=s.variables{1}; proposed.hardpoints.xyz_m(v.row,1)=s.upper_m;
            id=expectedIdentifier(Arm); message="";
            try
                fsd.model.validateDoubleWishboneGeometry(proposed);
            catch cause
                t.verifyEqual(string(cause.identifier),id); message=string(cause.message);
            end
            t.assertGreaterThan(strlength(message),0);
            e=fsd.synthesis.evaluateSynthesisCandidate(s,1,17);
            t.verifyEqual(e.evaluationId,17); t.verifyEqual(e.u,1); t.verifyEqual(e.x_m,s.upper_m);
            t.verifyEqual(proposed.hardpoints.xyz_m(v.row,:),s.seed.hardpoints.xyz_m(joint,:));
            t.verifyEqual(e.exceptionId,id); t.verifyEqual(e.exceptionMessage,message);
            t.verifyEqual(e.failureStage,"BUILDER"); t.verifyEqual(e.classification,"INVALID_GEOMETRY");
            t.verifyEqual(e.evidenceStatus,"NO_GEOMETRY"); t.verifyFalse(e.geometryValid); t.verifyFalse(e.eligible);
            t.verifyTrue(isnan(e.score)); t.verifyEmpty(e.geometry); t.verifyEmpty(e.geometryIdentity);
            t.verifyEmpty(e.candidate); t.verifyEmpty(e.assessment); t.verifyEmpty(e.bumpEvidence);
            t.verifyEqual(e.solverCalls,0); t.verifyEqual(e.solverStatus,"NOT_ATTEMPTED");
            t.verifyEqual(e.execution.solverOptions,s.plan.solverOptions);
            t.verifyTrue(fsd.synthesis.validateSynthesisEvaluation(e,s));
        end
        function originalSearchAndCounters(t,Arm)
            s=t.Spaces.(Arm); before=s;
            r=fsd.synthesis.runInverseSearch(s,originalOptions());
            t.verifyEqual(s,before); t.verifyEqual(r.search.evaluationCount,2);
            t.verifyEqual(r.search.attemptCount,3); t.verifyEqual(r.search.cacheHitCount,1);
            t.verifyEqual(r.search.stopReason,"MINIMUM_STEP");
            t.verifyEqual(r.search.options.maxEvaluations-r.search.evaluationCount,0);
            t.verifyTrue(r.search.records{1}.geometryValid); t.verifyEqual(r.search.records{2}.exceptionId,expectedIdentifier(Arm));
            t.verifyEqual(r.statistics.physicalBumpSweeps,1); t.verifyEqual(r.search.records{2}.solverCalls,0);
            t.verifyEqual(r.search.history{3}.evaluationId,2); t.verifyEqual(r.search.history{3}.reason,"INVALID_GEOMETRY");
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function continuesAfterInvalidProposal(t,Arm)
            s=t.Spaces.(Arm); o=originalOptions(); o.maxEvaluations=3; o.seeds=.5;
            r=fsd.synthesis.runInverseSearch(s,o);
            t.verifyEqual(r.search.evaluationCount,3);
            t.verifyEqual(r.search.records{2}.exceptionId,expectedIdentifier(Arm));
            t.verifyTrue(r.search.records{3}.geometryValid); t.verifyNotEmpty(r.search.records{3}.candidate);
            t.verifyEqual(r.search.records{3}.u,.5); t.verifyEqual(r.statistics.physicalBumpSweeps,2);
            t.verifyFalse(r.search.records{2}.eligible); t.verifyNotEqual(r.selectedIndex,2);
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function exhaustedBudgetAfterFailure(t,Arm)
            o=originalOptions(); o.seeds=.5;
            r=fsd.synthesis.runInverseSearch(t.Spaces.(Arm),o);
            t.verifyEqual(r.search.stopReason,"MAX_EVALUATIONS"); t.verifyEqual(r.search.evaluationCount,2);
            t.verifyEqual(r.search.attemptCount,3); t.verifyEqual(r.statistics.physicalBumpSweeps,1);
            t.verifyEqual(r.search.records{2}.exceptionId,expectedIdentifier(Arm));
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function repeatedFailureUsesCache(t,Arm)
            o=originalOptions(); o.maxEvaluations=3; o.seeds=[.5;1]; o.maxIterations=3;
            r=fsd.synthesis.runInverseSearch(t.Spaces.(Arm),o);
            hits=cellfun(@(h) h.evaluationId==2 && h.cacheHit,r.search.history);
            t.verifyGreaterThanOrEqual(nnz(hits),2); t.verifyEqual(r.search.evaluationCount,3);
            t.verifyEqual(r.statistics.physicalBumpSweeps,2); t.verifyFalse(r.search.records{2}.eligible);
            t.verifyEqual(r.search.records{2}.exceptionId,expectedIdentifier(Arm));
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function allInvalidHasZeroRealSweeps(t,Arm)
            s=t.InvalidSpaces.(Arm); o=originalOptions(); o.seeds=1;
            profile clear; profile on; r=fsd.synthesis.runInverseSearch(s,o); profile off;
            info=profile('info'); t.verifyEqual(sweepCalls(info),0);
            t.verifyEqual(r.search.evaluationCount,2); t.verifyGreaterThan(r.search.cacheHitCount,0);
            t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyEqual(r.statistics.physicalBumpSweeps,0);
            t.verifyEqual(r.search.records{1}.exceptionId,"fsd:synthesis:DegenerateWishbone");
            t.verifyEqual(r.search.records{2}.exceptionId,expectedIdentifier(Arm));
            t.verifyTrue(all(cellfun(@(e) ~e.geometryValid && ~e.eligible && isnan(e.score),r.search.records)));
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function validatorsHaveNoPhysicalCalls(t,Arm)
            s=t.Spaces.(Arm); r=fsd.synthesis.runInverseSearch(s,originalOptions());
            profile clear; profile on;
            fsd.synthesis.validateSynthesisEvaluation(r.search.records{2},s); fsd.synthesis.validateSynthesisResult(r);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","fzero"])));
        end
        function tamperedRecordRejected(t,Arm,Attack)
            s=t.Spaces.(Arm); r=fsd.synthesis.runInverseSearch(s,originalOptions()); e=r.search.records{2};
            switch Attack
                case "IDENTIFIER", e.exceptionId="fsd:model:UnknownPhysicalLookingError";
                case "STAGE", e.failureStage="BUMP";
                case "CLASS", e.classification="SAMPLED_FEASIBLE";
                case "ELIGIBLE", e.eligible=true;
                case "SCORE", e.score=0;
                case "VECTOR", e.x_m=s.initial_m;
                case "GEOMETRY", e.geometry=s.seed; e.geometryIdentity=s.seedIdentity;
                case "BUMP", e.bumpEvidence=struct('sweep',[]);
                case "COUNTER", e.solverCalls=1;
                case "SELECTED", r.selectedIndex=2;
                case "SNAPSHOT", e.execution.solverOptions.MaxIterations=1;
            end
            if Attack~="SELECTED"
                t.verifyError(@() fsd.synthesis.validateSynthesisEvaluation(e,s),'fsd:synthesis:InvalidEvaluation');
            end
            r.search.records{2}=e;
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
        end
        function matRoundTrip(t,Arm)
            r=fsd.synthesis.runInverseSearch(t.InvalidSpaces.(Arm),originalOptions());
            file=string(tempname)+".mat"; t.addTeardown(@() delete(file)); save(file,'r'); loaded=load(file,'r');
            t.verifyEqual(loaded.r,r); t.verifyTrue(fsd.synthesis.validateSynthesisResult(loaded.r));
            t.verifyEqual(loaded.r.search.records{2}.exceptionId,expectedIdentifier(Arm));
            t.verifyEqual(loaded.r.search.records{2}.execution.solverOptions,r.problem.plan.solverOptions);
        end
        function plotNoEligibleAndPng(t,Arm,Appearance)
            r=fsd.synthesis.runInverseSearch(t.InvalidSpaces.(Arm),originalOptions());
            folder=fullfile(fileparts(fileparts(mfilename('fullpath'))),'output','v0.12-f04-qa',Arm);
            reports=synthesisPlotAuditCheck(r,folder,Appearance); t.verifyNumElements(reports,2);
            t.verifyEmpty(r.feasibleIndices); t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
            t.verifyEqual(r.search.records{2}.exceptionId,expectedIdentifier(Arm));
        end
        function aftPickupAlsoRecovered(t,Arm)
            [s,u]=zeroLengthLinkFixture(Arm,"ORIGINAL","AFT");
            e=fsd.synthesis.evaluateSynthesisCandidate(s,u);
            t.verifyEqual(e.exceptionId,expectedIdentifier(Arm)); t.verifyEqual(e.failureStage,"BUILDER");
            t.verifyFalse(e.eligible); t.verifyEqual(e.solverCalls,0);
            t.verifyTrue(fsd.synthesis.validateSynthesisEvaluation(e,s));
        end
        function unknownBuilderErrorEscapes(t)
            s=t.Spaces.UCA;
            t.verifyError(@() zeroLengthBuilderFailureCall(s,0,1),'MATLAB:nonExistentField');
            t.verifyError(@() fsd.synthesis.boundedDirectSearch(0,true,struct('maxEvaluations',1), ...
                @(u,id) zeroLengthBuilderFailureCall(s,u,id),@(u) u),'MATLAB:nonExistentField');
        end
        function principalBenchmarkAndClosedFindings(t)
            [s,o]=synthesisFixture(); profile clear; profile on; r=fsd.synthesis.runInverseSearch(s,o); profile off;
            info=profile('info'); t.verifyEqual(sweepCalls(info),7); t.verifyEqual(r.search.evaluationCount,7);
            t.verifyEqual(r.statistics.physicalBumpSweeps,7); t.verifyEqual(r.search.stopReason,"SCORE_TARGET_REACHED");
            t.verifyEqual(r.search.records{1}.x_m,[.360;.340]);
            t.verifyEqual(r.search.records{r.selectedIndex}.x_m,[.365;.345],'AbsTol',1e-12);
            t.verifyEqual(r.search.records{1}.score,.101722096447,'AbsTol',1e-12);
            t.verifyEqual(r.search.records{r.selectedIndex}.score,0);
            plan=s.plan; plan.solverOptions.MaxIterations=1;
            changed=r; changed.problem=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(changed),'fsd:synthesis:InvalidResult');
            failed=fsd.synthesis.runInverseSearch(synthesisFailureFixture(),struct('maxEvaluations',1));
            t.verifyEqual(failed.search.records{1}.exceptionId,"fsd:analysis:DegenerateCasterProjection");
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(failed));
            one=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1));
            f=fsd.synthesis.plotSynthesisResult(one); t.addTeardown(@() close(f)); t.verifyNotEmpty(f);
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(one));
        end
    end
end

function id = expectedIdentifier(arm)
id="fsd:model:ZeroLengthUcaLink";
if arm=="LCA", id="fsd:model:ZeroLengthLcaLink"; end
end
function o = originalOptions()
o=struct('maxEvaluations',2,'initialStep',1,'minimumStep',1);
end
function count = sweepCalls(info)
names=string({info.FunctionTable.FunctionName}); calls=info.FunctionTable(contains(names,'solveBumpSweep'));
count=sum([calls.NumCalls]);
end
