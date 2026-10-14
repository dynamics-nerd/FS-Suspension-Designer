classdef TestEngineeringProjectIntegration < matlab.unittest.TestCase
    properties
        Example
    end
    properties (TestParameter)
        Change={"TARGET","CONSTRAINT","OPTIONS","ACTUATION_SEED"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples')); t.Example=vehicleConceptProjectExample(false);
        end
    end
    methods (Test)
        function realEndToEndBenchmark(t)
            e=t.Example; r=e.result.nativePayload; native=e.nativeReference.result;
            t.verifyEqual(r.search.evaluationCount,8); t.verifyEqual(r.statistics.bumpSweeps,8);
            t.verifyEqual(r.statistics.actuationSweeps,8); t.verifyEqual(r.statistics.mechanicalAnalyses,8);
            t.verifyEqual(r.search.records{1}.score,.231415023063,'AbsTol',1e-12);
            best=r.search.records{r.selectedIndex}; t.verifyEqual(best.score,0);
            t.verifyEqual(best.actuationIdentity,native.search.records{native.selectedIndex}.actuationIdentity);
            t.verifyEqual(best.mechanicalEvidence.analysis.wheelRateTotal_N_per_m, ...
                e.nativeReference.directResponse.wheelRateTotal_N_per_m,'AbsTol',1e-7);
            t.verifyNotEqual(best.actuationIdentity,r.search.records{1}.actuationIdentity);
            t.verifyEqual(best.geometry,r.problem.seed); t.verifyEqual(e.externalPhysicalSweepInvocations,22);
            t.verifyEqual(e.workflowBumpSweeps,9); t.verifyEqual(e.workflowActuationSweeps,8);
            t.verifyTrue(any(cellfun(@(q)q.definitionSI.strength=="HARD",r.problem.specification.definitionSI.targets.definitionSI.targets)));
            t.verifyTrue(any(cellfun(@(q)q.definitionSI.strength=="SOFT",r.problem.specification.definitionSI.targets.definitionSI.targets)));
        end
        function conceptAndHistoryPersist(t)
            e=t.Example; t.verifyEqual(e.partial.definition.derivations{1}.values{1}.value,270);
            t.verifyEmpty(e.partial.definition.resources.geometries); t.verifyEmpty(e.partial.definition.derivations{1}.vehicle);
            t.verifyEqual(e.loaded,e.numericalRevision);
            t.verifyEqual(fsd.project.resultCompatibility(e.result,e.massRevision).status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(fsd.project.resultCompatibility(e.result,e.loaded).status,"STALE");
        end
        function relevantSynthesisChangesAreStale(t,Change)
            e=t.Example; original=e.result; p=e.project; scenario=p.definition.scenarios{1};
            if scenario.definition.id~="ACT_DESIGN", scenario=p.definition.scenarios{2}; end
            d=scenario.definition; resources=p.definition.resources;
            switch Change
                case "TARGET"
                    spec=d.specification.definitionSI; q=spec.targets.definitionSI.targets{1}.definitionSI; q.value=q.value+.01;
                    ts=spec.targets.definitionSI.targets; ts{1}=fsd.model.createDesignTarget(q,q.unit,'m');
                    spec.targets=fsd.model.createSuspensionDesignTargets(ts); d.specification=fsd.model.createDesignSpecification(spec);
                case "CONSTRAINT"
                    spec=d.specification.definitionSI; q=spec.constraints{1}.definitionSI; q.comparisonTolerance=.0001;
                    spec.constraints{1}=fsd.model.createDesignConstraint(q,'m'); d.specification=fsd.model.createDesignSpecification(spec);
                case "OPTIONS", d.options.initialStep=.125;
                case "ACTUATION_SEED"
                    s=e.nativeReference.space; x=s.initial_m; x(1)=x(1)+.001;
                    [a,m]=fsd.synthesis.buildActuationCandidate(s,x); resources.actuations={a}; resources.mechanicals={m};
            end
            bump=p.definition.scenarios{cellfun(@(s)s.definition.id=="FL_BUMP",p.definition.scenarios)};
            revised=fsd.project.reviseEngineeringProject(p,struct('resources',resources, ...
                'scenarios',{{fsd.project.createEngineeringScenario(d);bump}}));
            t.verifyEqual(fsd.project.resultCompatibility(e.result,revised).status,"STALE");
            t.verifyEqual(e.result.projectRevision,2); t.verifyEqual(e.result,original);
            t.verifyEqual(e.result.nativePayload.problem,e.nativeReference.space);
        end
        function nativeMatRemainsNative(t)
            root=fileparts(fileparts(mfilename('fullpath'))); file=fullfile(root,'output','actuation-synthesis-example.mat');
            loaded=load(file,'result'); t.verifyTrue(fsd.synthesis.validateActuationSynthesisResult(loaded.result));
            t.verifyError(@()fsd.project.loadEngineeringProject(file),'fsd:project:InvalidInput');
        end
    end
end
