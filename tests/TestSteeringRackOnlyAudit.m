classdef TestSteeringRackOnlyAudit < matlab.unittest.TestCase
    %TESTSTEERINGRACKONLYAUDIT V14-F-01, native ASSUMED fixture, no fake sources.
    properties (TestParameter)
        Scenario={"RACK4","ACK2","BUMP_HARD"}
        HardCase={"PASS","FAIL","UNKNOWN"}
        Coverage={"PARTIAL","NONE"}
        Control={"MIXED","MIXED_HARD","ROLL","HARD_ONLY","DISABLED"}
        Attack={"SPEC","ASSESSMENT","BUMP_OPTIONS","RACK_OPTIONS","PLAN"}
        Edit={"WEIGHT","TOLERANCE"}
        FailureFamily={"BUMP","RACK"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old));
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function endToEnd(t,Scenario)
            [s,original]=rackOnlySpace(Scenario);
            t.verifyEqual(s.specification,original);
            t.verifyTrue(original.definitionSI.compositeScore);
            t.verifyTrue(fsd.synthesis.validateSteeringDesignSpace(s));
            targets=original.definitionSI.targets.definitionSI.targets;
            expectedCount=4; if Scenario=="ACK2", expectedCount=2; end
            if Scenario=="BUMP_HARD", expectedCount=5; end
            t.verifyNumElements(targets,expectedCount);
            for j=1:2
                sub=s.cornerSpaces{j}.specification.definitionSI;
                t.verifyFalse(sub.compositeScore);
                t.verifyFalse(any(cellfun(@(q) q.definitionSI.strength=="SOFT",sub.targets.definitionSI.targets)));
            end
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',3,'maxIterations',1, ...
                'initialStep',.25,'minimumStep',.25));
            t.verifyGreaterThanOrEqual(r.search.evaluationCount,1);
            t.verifyLessThanOrEqual(r.search.evaluationCount,3);
            t.verifyEqual(r.statistics.rackSweeps,r.search.evaluationCount);
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,3*r.search.evaluationCount);
            t.verifyNotEqual(r.search.records{1}.steeringIdentity,r.search.records{2}.steeringIdentity);
            t.verifyNotEqual(r.search.records{1}.axleIdentity,r.search.records{2}.axleIdentity);
            t.verifyEqual(s.specification,original);
            for j=1:numel(r.search.records)
                e=r.search.records{j};
                t.verifyTrue(fsd.model.validateSteeringSystemGeometry(e.steering));
                t.verifyTrue(e.eligible); t.verifyTrue(isfinite(e.score));
                t.verifyGreaterThan(e.score,0); % Zero tolerance, actual steer is nonzero.
                t.verifyEqual(e.assessment.specificationIdentity,original.identity);
                t.verifyEqual(cellfun(@(a) a.id,e.assessment.targetAssessments), ...
                    cellfun(@(q) q.definitionSI.id,targets));
                t.verifyEqual(e.score,independentRackScore(s,e),'AbsTol',1e-12);
                t.verifyTrue(e.physical{4}.sweep.allConverged);
                t.verifyEqual(e.steering.rearAxleX_m,1.6);
                t.verifyTrue(isnan(e.physical{4}.analysis.ackermannAngleError_rad(3)));
            end
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
            repeated=fsd.synthesis.runSteeringInverseSearch(s,r.search.options);
            t.verifyEqual(repeated.search.keys,r.search.keys);
            t.verifyEqual(repeated.selectedIndex,r.selectedIndex);
            t.verifyEqual(repeated.search.stopReason,r.search.stopReason);
            file=[tempname,'.mat']; t.addTeardown(@() delete(file)); save(file,'r');
            loaded=load(file,'r'); t.verifyEqual(loaded.r,r);
            profile clear; profile on;
            fsd.synthesis.validateSteeringSynthesisResult(loaded.r);
            fsd.synthesis.validateSteeringSynthesisEvaluation(r.search.records{1},s);
            fsd.analysis.evaluateDesignCandidate(original,r.search.records{1}.candidate);
            fsd.synthesis.compareSteeringSynthesisCandidates(r,[1;2]);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveRack","solveAxleRoll","solveCornerPath"])));
        end
        function hardGateSeparateFromRackScore(t,HardCase)
            [s,~]=rackOnlySpace("BUMP_HARD"); d=s.specification.definitionSI;
            targets=d.targets.definitionSI.targets; q=targets{1}.definitionSI;
            if HardCase=="FAIL"
                q.value=1; q.tolerance=0;
                % Excellent SOFT controls must never rescue a HARD failure.
                for j=2:numel(targets)
                    soft=targets{j}.definitionSI; soft.tolerance=1;
                    targets{j}=fsd.model.createDesignTarget(soft,'rad','m');
                end
            elseif HardCase=="UNKNOWN"
                q.x=.02; % Exact requested sample absent, no fabricated BUMP state.
            end
            targets{1}=fsd.model.createDesignTarget(q,'rad','m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildSteeringSpace(s,d);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            t.verifyTrue(isfinite(e.assessment.compositeScore));
            t.verifyEqual(e.assessment.compositeScore,independentRackScore(s,e),'AbsTol',1e-12);
            if HardCase=="PASS"
                t.verifyTrue(e.eligible); t.verifyGreaterThan(e.score,0);
                t.verifyEqual(e.assessment.targetAssessments{1}.status,"SAMPLED_PASS");
            else
                t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
                if HardCase=="FAIL"
                    t.verifyEqual(e.classification,"HARD_CONSTRAINT_FAILED");
                    t.verifyEqual(e.assessment.compositeScore,0);
                else
                    t.verifyEqual(e.hardFeasibility,"INDETERMINATE_HARD_REQUIREMENTS");
                    t.verifyEqual(e.assessment.targetAssessments{1}.status,"NOT_EVALUATED");
                end
            end
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function incompleteRackNeverInventsScore(t,Coverage)
            [s,~]=rackOnlySpace("ACK2"); d=s.specification.definitionSI;
            targets=d.targets.definitionSI.targets; q=targets{2}.definitionSI;
            if Coverage=="PARTIAL"
                q.type="CURVE_TARGET"; q.x=[.003;.01]; q.value=0;
                expected="PARTIALLY_EVALUATED";
            else
                q.x=0; expected="NOT_EVALUATED";
            end
            targets{2}=fsd.model.createDesignTarget(q,'rad','m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildSteeringSpace(s,d);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            t.verifyEqual(e.assessment.targetAssessments{2}.status,expected);
            t.verifyEqual(e.softScoreStatus,"UNAVAILABLE_COVERAGE");
            t.verifyTrue(isnan(e.assessment.compositeScore)); t.verifyTrue(isnan(e.score));
            t.verifyFalse(e.eligible); t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function previouslyAcceptedContracts(t,Control)
            s=steeringSynthesisFixture(Control=="ROLL"); d=s.specification.definitionSI;
            targets=d.targets.definitionSI.targets;
            if Control=="MIXED_HARD" || Control=="HARD_ONLY"
                q=targets{1}.definitionSI; q.id="HARD_BUMP"; q.strength="HARD";
                hard=fsd.model.createDesignTarget(q,'rad','m');
                if Control=="HARD_ONLY", targets={hard}; d.compositeScore=false;
                else, targets{end+1,1}=hard; end
            elseif Control=="ROLL"
                targets=targets(cellfun(@(q) q.definitionSI.sourceType~="BUMP",targets));
            elseif Control=="DISABLED"
                targets=targets(cellfun(@(q) q.definitionSI.sourceType=="RACK",targets));
                d.compositeScore=false;
            end
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildSteeringSpace(s,d);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            t.verifyTrue(e.eligible); t.verifyEqual(s.specification.definitionSI,d);
            if d.compositeScore, t.verifyTrue(isfinite(e.score));
            else, t.verifyTrue(isnan(e.score)); t.verifyEqual(e.softScoreStatus,"NOT_REQUESTED"); end
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function publicFactoryStillRejectsNoSoft(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI;
            d.targets=fsd.model.createSuspensionDesignTargets({});
            t.verifyError(@() fsd.model.createDesignSpecification(d),'fsd:model:InvalidDesignDefinition');
        end
        function literalOriginalReproducer(t)
            s=steeringSynthesisFixture(); before=s; d=s.specification.definitionSI;
            targets=d.targets.definitionSI.targets;
            d.targets=fsd.model.createSuspensionDesignTargets( ...
                targets(cellfun(@(q) q.definitionSI.sourceType=="RACK",targets)));
            spec=fsd.model.createDesignSpecification(d);
            space=fsd.synthesis.createSteeringDesignSpace(s.seedAxle.leftGeometry,s.seedAxle.rightGeometry, ...
                s.seedSteering,spec,s.plan,s.symmetryLinks);
            t.verifyEqual(s,before); t.verifyEqual(space.specification,spec);
            t.verifyNumElements(space.specification.definitionSI.targets.definitionSI.targets,4);
            t.verifyTrue(fsd.synthesis.validateSteeringDesignSpace(space));
        end
        function rackOnlyCacheUsesRealScore(t)
            [s,~]=rackOnlySpace("RACK4"); u=fsd.synthesis.normalizeSteeringVariables(s,s.initial_m);
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',5,'maxIterations',2, ...
                'initialStep',1,'minimumStep',1,'seeds',u'));
            t.verifyGreaterThan(r.statistics.cacheHits,0);
            t.verifyEqual(r.statistics.totalPhysicalSweepInvocations,3*r.search.evaluationCount);
            t.verifyTrue(isfinite(r.search.records{r.selectedIndex}.score));
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
        end
        function unsupportedRackStillRejected(t)
            [s,~]=rackOnlySpace("RACK4"); d=s.specification.definitionSI;
            targets=d.targets.definitionSI.targets; q=targets{1}.definitionSI;
            q.requiredSourceIdentity=s.seedSteering.identity;
            targets{1}=fsd.model.createDesignTarget(q,'rad','m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets);
            t.verifyError(@() rebuildSteeringSpace(s,d),'fsd:synthesis:UnsupportedTarget');
        end
        function unsupportedHardNeverDiscarded(t)
            [s,~]=rackOnlySpace("RACK4"); d=s.specification.definitionSI;
            q=struct('id',"UNSUPPORTED_HARD",'metricId',"CORNER_LOAD",'sourceId',"LOADS", ...
                'sourceType',"STATIC_LOADS",'scope',fsd.model.designScope('CORNER','FL'), ...
                'type',"POINT_TARGET",'strength',"HARD",'independentVariable',"NONE", ...
                'value',300,'tolerance',1,'sourceNote',"Explicit rejection control, not FS load");
            targets=d.targets.definitionSI.targets; targets{end+1,1}=fsd.model.createDesignTarget(q,'N','1');
            d.targets=fsd.model.createSuspensionDesignTargets(targets);
            t.verifyError(@() rebuildSteeringSpace(s,d),'fsd:synthesis:UnsupportedTarget');
        end
        function staleEvidenceRejected(t,Attack)
            [s,~]=rackOnlySpace("RACK4");
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',1));
            if Attack=="SPEC"
                d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
                q=targets{1}.definitionSI; q.value=1;
                targets{1}=fsd.model.createDesignTarget(q,'rad','m');
                d.targets=fsd.model.createSuspensionDesignTargets(targets); r.problem=rebuildSteeringSpace(s,d);
            elseif Attack=="ASSESSMENT"
                r.search.records{1}.assessment.specificationIdentity=s.cornerSpaces{1}.specification.identity;
            else
                p=s.plan;
                if Attack=="BUMP_OPTIONS"
                    p.leftBump.solverOptions.MaxIterations=1;
                elseif Attack=="RACK_OPTIONS"
                    p.rack.solverOptions.MaxContinuationStep_m=.002;
                else
                    p.rack.travel_m=[-.003;0;.003];
                end
                r.problem=rebuildSteeringSpace(s,s.specification.definitionSI,p);
                r.execution.plan=r.problem.plan; r.search.records{1}.execution.plan=r.problem.plan;
            end
            profile clear; profile on;
            t.verifyError(@() fsd.synthesis.validateSteeringSynthesisResult(r),'fsd:synthesis:InvalidSteeringResult');
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveRack","solveAxleRoll"])));
        end
        function changedWeightsAndTolerancesUseOriginalSpec(t,Edit)
            [s,original]=rackOnlySpace("RACK4"); e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            d=original.definitionSI; targets=d.targets.definitionSI.targets; q=targets{1}.definitionSI;
            if Edit=="WEIGHT", q.weight=100; else, q.tolerance=1; end
            targets{1}=fsd.model.createDesignTarget(q,'rad','m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets); changed=rebuildSteeringSpace(s,d);
            a=fsd.analysis.evaluateDesignCandidate(changed.specification,e.candidate);
            probe=e; probe.assessment=a;
            t.verifyEqual(a.compositeScore,independentRackScore(changed,probe),'AbsTol',1e-12);
            t.verifyNotEqual(a.compositeScore,e.assessment.compositeScore);
            t.verifyError(@() fsd.analysis.validateDesignAssessment(e.assessment,changed.specification,e.candidate), ...
                'fsd:analysis:InvalidDesignAssessment');
            t.verifyError(@() fsd.synthesis.validateSteeringSynthesisEvaluation(e,changed),'fsd:synthesis:InvalidSteeringEvaluation');
            t.verifyEqual(s.specification,original);
        end
        function recoverablePhysicalFailurePreservesRackTargets(t,FailureFamily)
            [s,~]=rackOnlySpace("RACK4"); p=s.plan;
            if FailureFamily=="BUMP", p.leftBump.solverOptions.MaxIterations=1;
            else, p.rack.solverOptions.MaxIterations=1; end
            s=rebuildSteeringSpace(s,s.specification.definitionSI,p);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.5);
            t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyNumElements(e.assessment.targetAssessments,4);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function unknownErrorStillEscapes(t)
            [s,~]=rackOnlySpace("RACK4");
            t.verifyError(@() steeringUnknownBuilderCall(s),'MATLAB:nonExistentField');
        end
        function originalMixedBenchmarkIntact(t)
            b=steeringSynthesisExample(false); r=b.result;
            t.verifyEqual(r.search.evaluationCount,3);
            t.verifyEqual([r.statistics.leftBumpSweeps+r.statistics.rightBumpSweeps,r.statistics.rackSweeps],[6,3]);
            t.verifyEqual(r.search.records{1}.score,.441327900783,'AbsTol',1e-12);
            t.verifyEqual(r.search.records{r.selectedIndex}.score,0);
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
        end
    end
end

function [space,spec] = rackOnlySpace(scenario)
seed=steeringSynthesisFixture(); d=seed.specification.definitionSI;
allTargets=d.targets.definitionSI.targets;
% Independent explicit fixture indices: FL/FR heading and both Ackermann points.
indices=[2,4,5,6]; if scenario=="ACK2", indices=[5,6]; end
targets=allTargets(indices);
for j=1:numel(targets)
    q=targets{j}.definitionSI; q.tolerance=0;
    targets{j}=fsd.model.createDesignTarget(q,'rad','m');
end
if scenario=="BUMP_HARD"
    q=allTargets{1}.definitionSI; q.strength="HARD";
    targets=[{fsd.model.createDesignTarget(q,'rad','m')};targets(:)];
end
d.targets=fsd.model.createSuspensionDesignTargets(targets); spec=fsd.model.createDesignSpecification(d);
space=fsd.synthesis.createSteeringDesignSpace(seed.seedAxle.leftGeometry,seed.seedAxle.rightGeometry, ...
    seed.seedSteering,spec,seed.plan,seed.symmetryLinks);
end

function score = independentRackScore(space,e)
% POINT_TARGET oracle from native angles, not projected definitions/assessment RMS.
targets=space.specification.definitionSI.targets.definitionSI.targets;
analysis=e.physical{4}.analysis; grid=space.plan.rack.travel_m; numerator=0; denominator=0;
for j=1:numel(targets)
    q=targets{j}.definitionSI; if q.strength~="SOFT", continue; end
    assert(q.sourceType=="RACK" && q.type=="POINT_TARGET");
    k=find(grid==q.x); assert(isscalar(k));
    if q.metricId=="ACKERMANN_ANGLE_ERROR"
        actual=analysis.ackermannAngleError_rad(k);
    elseif q.scope.id=="FL"
        actual=analysis.roadWheelAngleLeft_rad(k);
    else
        actual=analysis.roadWheelAngleRight_rad(k);
    end
    v=max(abs(actual-q.value)-q.tolerance,0)/q.normalizationScale;
    numerator=numerator+q.weight*v^2; denominator=denominator+q.weight;
end
score=sqrt(numerator/denominator);
end
