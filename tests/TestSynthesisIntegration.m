classdef TestSynthesisIntegration < matlab.unittest.TestCase
    properties (TestParameter)
        Metric={"CAMBER","TOE","BUMP_STEER","CASTER","KPI"}
        Attack={"VECTOR","FIXED_HP","BOUNDS","IDENTITY","SPEC","ASSESSMENT","SCORE","SOLVER", ...
            "CLASSIFICATION","HISTORY","SELECTION","STOP","CACHE_KEY","ELIGIBLE","QUALITY","ORDER","TIMING"}
    end
    properties
        Result
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
            [s,o]=synthesisFixture(); t.Result=fsd.synthesis.runInverseSearch(s,o);
        end
    end
    methods (Test)
        function realReachableImprovement(t)
            r=t.Result; first=r.search.records{1}; best=r.search.records{r.selectedIndex};
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
            t.verifyLessThan(best.score,first.score); t.verifyLessThan(best.score,1e-8);
            t.verifyEqual(best.x_m,r.problem.initial_m+.005,'AbsTol',1e-12);
            t.verifyNotEqual(first.geometryIdentity,best.geometryIdentity);
            t.verifyEqual(best.geometry.hardpoints.xyz_m(3:end,:),r.problem.seed.hardpoints.xyz_m(3:end,:));
            t.verifyEqual(best.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
            t.verifyGreaterThan(numel(r.feasibleIndices),1);
        end
        function sourcesRebuilt(t)
            r=t.Result;
            for i=1:numel(r.search.records)
                e=r.search.records{i}; s=e.candidate.definitionSI.sources{1};
                t.verifyEqual(s.sweep.geometryIdentity,e.geometryIdentity);
                t.verifyEqual(s.result.geometryIdentity,e.geometryIdentity);
                t.verifyEqual(s.sweep.requestedWheelTravel_m,r.problem.plan.travel_m);
                if i>1, t.verifyNotEqual(s.sweep.geometryIdentity,r.problem.seedIdentity); end
            end
            a=r.search.records{1}.assessment.targetAssessments{1}.actual;
            b=r.search.records{r.selectedIndex}.assessment.targetAssessments{1}.actual;
            t.verifyGreaterThan(norm(a-b),1e-5);
        end
        function closureQualityIndependentDerivative(t)
            e=t.Result.search.records{1}; g=e.geometry; c=g.cornerId;
            names=c+"_"+["UCA_FWD_CHASSIS";"UCA_AFT_CHASSIS";"LCA_FWD_CHASSIS";"LCA_AFT_CHASSIS";"TIE_ROD_INBOARD"];
            joints=c+"_"+["UBJ";"UBJ";"LBJ";"LBJ";"TIE_ROD_OUTBOARD"];
            p=zeros(5,3); b=p;
            for i=1:5, p(i,:)=fsd.model.getPoint(g,names(i)); b(i,:)=fsd.model.getPoint(g,joints(i)); end
            wc=fsd.model.getPoint(g,c+"_WHEEL_CENTER"); lengths=vecnorm(b-p,2,2); scale=max(lengths);
            h=1e-6; J=zeros(5); % verification perturbation only, not a production tolerance
            for j=1:5
                q=zeros(1,5); q(j)=h; plus=perturbedLengths(q,b,wc,p,lengths,scale);
                q(j)=-h; minus=perturbedLengths(q,b,wc,p,lengths,scale); J(:,j)=(plus-minus)/(2*h);
            end
            t.verifyEqual(e.quality.referenceRcond,rcond(J),'AbsTol',1e-8);
            t.verifyEqual(e.quality.referenceOrientation,sign(det(J)));
        end
        function realProfile(t)
            profile clear; profile on;
            e=fsd.synthesis.evaluateSynthesisCandidate(t.Result.problem,[.75;.75]);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            calls=info.FunctionTable(contains(names,'solveBumpSweep'));
            t.verifyEqual(sum([calls.NumCalls]),1); t.verifyGreaterThan(e.timing_s.solver,0);
            profile clear; profile on; fsd.synthesis.validateSynthesisResult(t.Result); profile off;
            info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","solveSteering"])));
        end
        function physicalDeterminism(t)
            r=t.Result; repeated=fsd.synthesis.runInverseSearch(r.problem,r.search.options);
            t.verifyEqual(repeated.search.history,r.search.history);
            t.verifyEqual(repeated.selectedIndex,r.selectedIndex);
            for i=1:numel(r.search.records)
                a=r.search.records{i}; b=repeated.search.records{i};
                t.verifyEqual(a.geometryIdentity,b.geometryIdentity);
                t.verifyEqual(a.assessment,b.assessment); t.verifyEqual(a.quality,b.quality);
            end
        end
        function eachSupportedMetric(t,Metric)
            s=t.Result.problem; d=s.specification.definitionSI; td=d.targets.definitionSI.targets{1}.definitionSI;
            td.metricId=Metric; d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(td,'rad','m')});
            s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
            e=fsd.synthesis.evaluateSynthesisCandidate(s,[.5;.5]);
            t.verifyEqual(e.assessment.targetAssessments{1}.domainCoverage,1); t.verifyTrue(e.eligible);
        end
        function adversarialResult(t,Attack)
            r=t.Result; i=r.selectedIndex;
            switch Attack
                case "VECTOR", r.search.records{i}.x_m(1)=r.search.records{i}.x_m(1)+.001;
                case "FIXED_HP", r.search.records{i}.geometry.hardpoints.xyz_m(3,3)=.5;
                case "BOUNDS", r.problem.lower_m(1)=0;
                case "IDENTITY", r.search.records{i}.geometryIdentity=r.problem.seedIdentity;
                case "SPEC", r.problem.specification.definitionSI.targets.definitionSI.targets{1}.definitionSI.value(:)=0;
                case "ASSESSMENT", r.search.records{i}.assessment.targetAssessments{1}.domainCoverage=.5;
                case "SCORE", r.search.records{i}.score=10;
                case "SOLVER", r.search.records{i}.solverStatus="NOT_REQUIRED";
                case "CLASSIFICATION", r.search.records{i}.classification="INVALID_GEOMETRY";
                case "HISTORY", r.search.history{1}.accepted=false;
                case "SELECTION", r.selectedIndex=1;
                case "STOP", r.search.stopReason="GLOBAL_OPTIMUM";
                case "CACHE_KEY", r.search.keys{i}(:)=0;
                case "ELIGIBLE", r.search.records{i}.eligible=false;
                case "QUALITY", r.search.records{i}.quality.rcond(:)=1;
                case "ORDER", r.search.records{i}.evaluationId=1;
                case "TIMING", r.search.records{i}.timing_s.solver=-1;
            end
            t.verifyError(@() fsd.synthesis.validateSynthesisResult(r),'fsd:synthesis:InvalidResult');
        end
        function impossibleHard(t)
            s=t.Result.problem; d=s.specification.definitionSI;
            td=d.targets.definitionSI.targets{1}.definitionSI; td.id="IMPOSSIBLE"; td.strength="HARD"; td.value=ones(3,1); td.tolerance=zeros(3,1);
            d.targets=fsd.model.createSuspensionDesignTargets([d.targets.definitionSI.targets;{fsd.model.createDesignTarget(td,'rad','m')}]);
            s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
            r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',5));
            t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyTrue(all(cellfun(@(e) e.classification=="HARD_CONSTRAINT_FAILED",r.search.records)));
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function hardOutsideDomain(t)
            s=t.Result.problem; d=s.specification.definitionSI;
            td=d.targets.definitionSI.targets{1}.definitionSI; td.id="OUTSIDE"; td.strength="HARD"; td.x=[-.02;0;.02]; td.tolerance=ones(3,1);
            d.targets=fsd.model.createSuspensionDesignTargets([d.targets.definitionSI.targets;{fsd.model.createDesignTarget(td,'rad','m')}]);
            s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
            r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',3));
            t.verifyEmpty(r.feasibleIndices); t.verifyEqual(r.search.records{1}.classification,"INDETERMINATE");
            t.verifyEqual(r.search.records{1}.assessment.targetAssessments{3}.status,"PARTIALLY_EVALUATED");
        end
        function missingSoftCoverage(t)
            s=t.Result.problem; plan=s.plan; plan.travel_m=[0;.01]; s=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',3));
            t.verifyTrue(isnan(r.selectedIndex)); t.verifyEqual(r.search.records{1}.classification,"NOT_EVALUABLE");
            t.verifyEqual(r.search.records{1}.assessment.targetAssessments{1}.domainCoverage,.5);
        end
        function noScoreNoWinner(t)
            s=t.Result.problem; d=s.specification.definitionSI; d.compositeScore=false;
            s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
            r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',3));
            t.verifyTrue(isnan(r.selectedIndex)); t.verifyNotEmpty(r.feasibleIndices);
        end
        function noFreeVariables(t)
            s=t.Result.problem; d=s.specification.definitionSI; d.parameters={};
            s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
            r=fsd.synthesis.runInverseSearch(s);
            t.verifyEqual(r.search.evaluationCount,1); t.verifyEqual(r.search.stopReason,"NO_FREE_VARIABLES");
        end
        function frozenNoImprovement(t)
            s=t.Result.problem; d=s.specification.definitionSI;
            for i=1:2
                p=d.parameters{i}.definitionSI; p.bounds=[p.value,p.value]; d.parameters{i}=fsd.model.createDesignParameter(p,'m');
            end
            s=fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan);
            r=fsd.synthesis.runInverseSearch(s); t.verifyEqual(r.search.evaluationCount,1);
            t.verifyEqual(r.search.records{1}.geometryIdentity,s.seedIdentity);
        end
        function unsupportedBeforeSearch(t)
            s=t.Result.problem; d=s.specification.definitionSI; td=d.targets.definitionSI.targets{1}.definitionSI;
            td.sourceType="ROLL"; td.independentVariable="ROLL_ANGLE"; td.conditions=struct('axleHeave_m',0);
            d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(td,'rad','rad')});
            t.verifyError(@() fsd.synthesis.createDesignSpace(s.seed,fsd.model.createDesignSpecification(d),s.plan),'fsd:synthesis:UnsupportedTarget');
        end
        function solverFailures(t)
            s=t.Result.problem; plan=s.plan; plan.travel_m=[0;.5;.6]; plan.solverOptions.MaxContinuationStep_m=1;
            s=fsd.synthesis.createDesignSpace(s.seed,s.specification,plan);
            r=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',3));
            t.verifyEmpty(r.feasibleIndices); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyTrue(all(cellfun(@(e) e.solverStatus=="PARTIAL_OR_FAILED",r.search.records)));
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(r));
        end
        function degenerateGeometry(t)
            s=synthesisFixture(1); d=s.specification.definitionSI; p=d.parameters{1}.definitionSI; p.bounds=[-.12,.1];
            d.parameters{1}=fsd.model.createDesignParameter(p,'m');
            % Make the remaining components identical to the aft pickup: X=upper bound becomes coincident.
            seed=s.seed; seed.hardpoints.xyz_m(1,2:3)=seed.hardpoints.xyz_m(2,2:3);
            s=fsd.synthesis.createDesignSpace(seed,fsd.model.createDesignSpecification(d),s.plan);
            e=fsd.synthesis.evaluateSynthesisCandidate(s,1);
            t.verifyEqual(e.classification,"INVALID_GEOMETRY"); t.verifyEmpty(e.candidate); t.verifyFalse(e.eligible);
            t.verifyTrue(fsd.synthesis.validateSynthesisEvaluation(e,s));
        end
        function serialization(t)
            file=string(tempname)+".mat"; t.addTeardown(@() delete(file)); r=t.Result; save(file,'r'); loaded=load(file,'r');
            t.verifyTrue(fsd.synthesis.validateSynthesisResult(loaded.r)); t.verifyEqual(loaded.r,r);
        end
        function comparison(t)
            r=t.Result; c=fsd.synthesis.compareSynthesisCandidates(r,[1;r.selectedIndex]);
            t.verifyNumElements(c.assessments,2); t.verifyEmpty(c.hardpointChanges{1}); t.verifyNumElements(c.hardpointChanges{2},2);
        end
    end
end

function residual = perturbedLengths(q,b,wc,p,lengths,scale)
R=fsd.geometry.rotationVectorToMatrix(q(3:5));
current=(R*(b-wc)')'+wc+[q(1:2)*scale,0];
residual=(vecnorm(current-p,2,2)-lengths)./lengths;
end
