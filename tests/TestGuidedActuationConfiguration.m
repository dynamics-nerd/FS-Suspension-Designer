classdef TestGuidedActuationConfiguration < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old));
            root=fileparts(fileparts(mfilename('fullpath'))); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function atomicNativeConfigurationAndUnchangedGeometry(t)
            [p,args]=guidedActuationFixture(); old=p;
            r=fsdui.perform(request(p,args));
            t.verifyTrue(fsd.project.validateEngineeringProject(r.project));
            t.verifyEqual(r.project.definition.resources.geometries,old.definition.resources.geometries);
            t.verifyEqual(r.project.definition.results,old.definition.results);
            a=r.project.definition.resources.actuations{1}; m=r.project.definition.resources.mechanicals{1};
            t.verifyEqual(a.identity,m.actuationIdentity);
            t.verifyTrue(fsdui.validateOperationResponse(request(p,args),r));
        end
        function noConfigurationSolves(t)
            [p,args]=guidedActuationFixture(); profile clear; profile on;
            cleanup=onCleanup(@()profile('off'));
            fsdui.perform(request(p,args)); profile off; data=profile('info');
            names=string({data.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","solveActuation","runActuationInverseSearch","fsolve"])));
        end
        function metadataAndBoundaryRoundTrip(t)
            [~,~,s]=guidedActuationFixture();
            [rows,m,c,r]=fsdui.actuationRows(s.seedActuation,s.seedMechanical);
            args=fsdui.actuationConfiguration('FL','PUSHROD','UPRIGHT','YZ_PLANE',rows,true, ...
                'LINEAR_ASYMMETRIC',m,c,r);
            a=fsd.model.createActuationGeometry(s.seed,args.definition,args.lengthUnit);
            mechanical=fsd.model.createSpringDamperModel(a,args.mechanicalDefinition,args.units);
            t.verifyEqual(a.identity,s.seedActuation.identity);
            t.verifyEqual(mechanical.identity,s.seedMechanical.identity);
            t.verifyEqual(a.metadata.parameterProvenance.ROD_ROCKER.sourceKind,"ASSUMED");
        end
        function blankDoesNotBecomeZero(t)
            [~,~,s]=guidedActuationFixture();
            [rows,m,c,r]=fsdui.actuationRows(s.seedActuation,s.seedMechanical); rows{1,2}='';
            t.verifyError(@()fsdui.actuationConfiguration('FL','PUSHROD','UPRIGHT','YZ_PLANE',rows,true, ...
                'LINEAR_ASYMMETRIC',m,c,r),'fsd:ui:ActuationInput');
        end
        function genuineAlternativeConfigurationRejected(t)
            [p,args]=guidedActuationFixture(); other=args; other.definition.damper.chassisPoint(2)=other.definition.damper.chassisPoint(2)+.001;
            alternative=fsdui.perform(request(p,other));
            t.verifyError(@()fsdui.validateOperationResponse(request(p,args),alternative),'fsd:ui:SemanticMismatch');
        end
        function explicitMechanicalRemovalIsAtomic(t)
            [p,args]=guidedActuationFixture(); response=fsdui.perform(request(p,args)); p=response.project;
            args.mechanicalDefinition=[]; response=fsdui.perform(request(p,args));
            t.verifyEmpty(response.project.definition.resources.mechanicals);
            t.verifyNumElements(response.project.definition.resources.actuations,1);
        end
    end
end
function q=request(project,args)
q=struct('operationId',1,'epoch',0,'action',"ACTUATION_CONFIG",'project',project,'arguments',args);
q=fsdui.workerRequest(q);
end
