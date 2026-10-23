classdef TestGuidedActuationSynthesis < matlab.unittest.TestCase
    properties
        Project
        BeforeSearch
        Result
        Definition
    end
    methods(TestClassSetup)
        function nativeInputs(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [p,args,s,options]=guidedActuationFixture(); c=fsdui.Controller(p); cleanup=onCleanup(@()c.close());
            c.run('ACTUATION_CONFIG',args,false);
            c.run('BUMP',struct('scope',"FL",'plan',struct('travel_m',[-.01;0;.01]),'resultId',"INDEPENDENT_BUMP"),false);
            scenario=fsd.project.createEngineeringScenario(struct('id',"UI_ACT_SEARCH_FL",'engine',"ACTUATION_SYNTHESIS", ...
                'scope',fsd.model.designScope('CORNER','FL'),'specification',s.specification,'plan',s.plan,'options',options));
            t.Definition=scenario.definition;
            c.run('SPECIFICATION',struct('definition',t.Definition),false); t.BeforeSearch=c.Project;
            c.run('SYNTHESIS',struct('scenarioId',"UI_ACT_SEARCH_FL",'resultId',"NATIVE_SEARCH"),false);
            t.Project=c.Project; t.Result=c.LastValue;
        end
    end
    methods(Test)
        function declarationRoundTripPreservesNativeSpecification(t)
            [targets,p,cs]=fsdui.actuationSearchRows(t.Definition);
            d=fsdui.actuationSearchDefinition('FL',targets,p,cs,t.Definition.plan,t.Definition.options,true,t.Definition);
            t.verifyEqual(d.specification,t.Definition.specification);
            t.verifyEqual(d.plan,t.Definition.plan);
        end
        function newRowsUseDeclaredEngineeringUnits(t)
            [targets,p,cs]=fsdui.actuationSearchRows(t.Definition);
            d=fsdui.actuationSearchDefinition('FL',targets,p,cs,t.Definition.plan,t.Definition.options,true,[]);
            t.verifyEqual(d.specification.definitionSI.parameters{1}.definitionSI.value, ...
                t.Definition.specification.definitionSI.parameters{1}.definitionSI.value,'AbsTol',1e-15);
            s=fsd.project.prepareEngineeringScenario(t.BeforeSearch,"UI_ACT_SEARCH_FL");
            t.verifyEqual(s.readiness.status,"READY");
        end
        function editedTargetRetainsPhysicalAnnotations(t)
            original=t.Definition; sd=original.specification.definitionSI;
            target=sd.targets.definitionSI.targets{1}; q=target.definitionSI;
            q.numericalTolerance=.002; q.physicalUncertainty=.003;
            target=fsd.model.createDesignTarget(q,'1','m');
            targets=sd.targets.definitionSI.targets; targets{1}=target;
            sd.targets=fsd.model.createSuspensionDesignTargets(targets); original.specification=fsd.model.createDesignSpecification(sd);
            [rows,p,cs]=fsdui.actuationSearchRows(original); rows{1,15}='Changed explanation';
            d=fsdui.actuationSearchDefinition('FL',rows,p,cs,original.plan,original.options,true,original);
            result=d.specification.definitionSI.targets.definitionSI.targets{1}.definitionSI;
            t.verifyEqual(result.numericalTolerance,.002); t.verifyEqual(result.physicalUncertainty,.003);
        end
        function adoptionPreservesSuspensionAndLedger(t)
            index=changedCandidate(t.Result); e=t.Result.nativePayload.search.records{index};
            c=fsdui.Controller(t.Project); cleanup=onCleanup(@()c.close());
            c.run('ACTUATION_ADOPT',struct('resultId',t.Result.id,'index',index),false); p=c.Project;
            t.verifyEqual(p.definition.resources.geometries,t.Project.definition.resources.geometries);
            t.verifyEqual(p.definition.results,t.Project.definition.results);
            t.verifyEqual(p.definition.resources.actuations{1},e.actuation);
            t.verifyEqual(p.definition.resources.mechanicals{1},e.mechanical);
            reports=fsd.project.resultCompatibilities(p);
            ids=cellfun(@(r)string(r.id),p.definition.results);
            t.verifyEqual(reports{ids=="INDEPENDENT_BUMP_FL"}.status,"REUSABLE_DEPENDENCIES");
            t.verifyEqual(reports{ids=="NATIVE_SEARCH"}.status,"STALE");
            t.verifyError(@()fsd.project.adoptActuationCandidate(p,t.Result,index),'fsd:project:InvalidAdoption');
        end
        function genuineOtherCandidateCannotSatisfyAdoption(t)
            index=changedCandidate(t.Result);
            owner=operation(t.Project,'ACTUATION_ADOPT',struct('resultId',t.Result.id,'index',1));
            other=owner; other.arguments.index=index; response=fsdui.perform(other);
            t.verifyTrue(fsd.project.validateEngineeringProject(response.project));
            t.verifyError(@()fsdui.validateOperationResponse(owner,response),'fsd:ui:SemanticMismatch');
        end
        function genuineSearchAtOtherBudgetIsRejected(t)
            owner=operation(t.BeforeSearch,'SYNTHESIS',struct('scenarioId',"UI_ACT_SEARCH_FL",'resultId',"ALTERNATE"));
            d=t.Definition; d.options.maxEvaluations=2; p=fsdui.upsertScenario(t.BeforeSearch,fsd.project.createEngineeringScenario(d));
            other=operation(p,'SYNTHESIS',owner.arguments); response=fsdui.perform(other);
            t.verifyTrue(fsd.project.validateEngineeringProject(response.project));
            t.verifyError(@()fsdui.validateOperationResponse(owner,response),'fsd:ui:SemanticMismatch');
        end
        function comparisonDoesNotResolvePhysicalMechanisms(t)
            profile clear; profile on; cleanup=onCleanup(@()profile('off'));
            e=fsdui.actuationEvidence(t.Result,changedCandidate(t.Result));
            fsd.synthesis.compareActuationSynthesisCandidates(t.Result.nativePayload,[1,changedCandidate(t.Result)]);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyNotEmpty(e.rows);
            t.verifyFalse(any(contains(names,["solveBump","solveActuation","fsolve","runActuationInverseSearch"])));
        end
        function invalidIndexIsRejected(t)
            t.verifyError(@()fsd.project.adoptActuationCandidate(t.Project,t.Result,NaN),'fsd:project:InvalidAdoption');
        end
        function knownMechanicalConstraintsKeepTheirNativeBindingAndUnits(t)
            d=t.Definition; sd=d.specification.definitionSI;
            p=fsd.model.createDesignParameter(struct('id',"KNOWN_RATE",'quantity',"STIFFNESS", ...
                'scope',fsd.model.designScope('COMPONENT','MECH','FL'),'binding',"SPRING_RATE", ...
                'type',"FIXED",'value',30,'comparisonTolerance',0,'availability',"ASSUMED", ...
                'sourceKind',"ASSUMED",'sourceNote',"Existing synthetic spring, fixed input"),'N/mm');
            sd.parameters{end+1,1}=p; d.specification=fsd.model.createDesignSpecification(sd);
            [targets,rows,cs]=fsdui.actuationSearchRows(d);
            actual=fsdui.actuationSearchDefinition('FL',targets,rows,cs,d.plan,d.options,true,d);
            t.verifyEqual(actual.specification,d.specification);
            t.verifyEqual(actual.targetOrigins,d.targetOrigins);
        end
    end
end
function index=changedCandidate(result)
records=result.nativePayload.search.records;
index=find(cellfun(@(e)e.eligible && ~isempty(e.changes),records),1);
assert(~isempty(index),'fsd:tests:MissingChangedCandidate','Native fixture must have an eligible changed candidate.');
end
function q=operation(p,action,args)
q=fsdui.workerRequest(struct('operationId',11,'epoch',0,'action',string(action),'project',p,'arguments',args));
end
