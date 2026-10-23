classdef TestGuidedActuationAnalysis < matlab.unittest.TestCase
    properties
        Project
    end
    methods(TestClassSetup)
        function inputs(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [p,args]=guidedActuationFixture(); c=fsdui.Controller(p); cleanup=onCleanup(@()c.close());
            c.run('ACTUATION_CONFIG',args,false); t.Project=c.Project;
        end
    end
    methods(Test)
        function nativeMechanicsAndDisplayBoundary(t)
            c=fsdui.Controller(t.Project); cleanup=onCleanup(@()c.close());
            a=argumentsFor('MECHANICAL'); c.run('ACTUATION_RUN',a,false); r=c.LastValue;
            t.verifyEqual(r.engine,"MECHANICAL");
            t.verifyEqual(r.nativePayload.analysis.wheelRateTotal_N_per_m, ...
                r.nativePayload.analysis.wheelRateElastic_N_per_m+r.nativePayload.analysis.wheelRateGeometric_N_per_m);
            e=fsdui.actuationEvidence(r);
            t.verifyEqual(e.travel_mm,[-10;0;10],'AbsTol',1e-6);
            t.verifyEqual(e.values.ROCKER_DEG,rad2deg(r.nativePayload.actuationAnalysis.rockerAngle_rad));
            t.verifyEqual(e.values.RATE_N_MM,r.nativePayload.analysis.wheelRateTotal_N_per_m/1000);
            for j=1:3
                t.verifyTrue(contains(string(e.rows{j,13}),r.nativePayload.analysis.stiffnessDiagnostic(j)));
            end
            t.verifyEqual(c.Project.definition.resources.geometries,t.Project.definition.resources.geometries);
        end
        function actuationDoesNotInventMechanicalForces(t)
            c=fsdui.Controller(t.Project); cleanup=onCleanup(@()c.close());
            c.run('ACTUATION_RUN',argumentsFor('ACTUATION'),false);
            e=fsdui.actuationEvidence(c.LastValue);
            t.verifyEmpty(e.mechanical); t.verifyTrue(all(isnan(e.values.SPRING_N)));
            t.verifyEqual(string(e.rows(:,13)),repmat("NOT_REQUESTED",3,1));
        end
        function missingVelocityIsRejected(t)
            t.verifyError(@()fsdui.actuationPlan('-10 0 10','',true),'fsd:ui:ActuationInput');
            p=fsdui.actuationPlan('-10 0 10','0',true);
            t.verifyEqual(p.travel_m,[-.01;0;.01]); t.verifyEqual(p.wheelVelocity_m_per_s,0);
        end
        function genuineWrongEngineAndGridAreRejected(t)
            owner=operation(t.Project,argumentsFor('MECHANICAL'));
            alternate=owner; alternate.arguments=argumentsFor('ACTUATION');
            r=fsdui.perform(alternate); t.verifyTrue(fsd.project.validateEngineeringProject(r.project));
            t.verifyError(@()fsdui.validateOperationResponse(owner,r),'fsd:ui:SemanticMismatch');
            alternate=owner; alternate.arguments.plan.travel_m=[-.005;0;.005];
            r=fsdui.perform(alternate);
            t.verifyError(@()fsdui.validateOperationResponse(owner,r),'fsd:ui:SemanticMismatch');
        end
        function receivedEvidenceDoesNotRunPhysics(t)
            q=operation(t.Project,argumentsFor('MECHANICAL')); r=fsdui.perform(q);
            profile clear; profile on; cleanup=onCleanup(@()profile('off'));
            fsdui.validateOperationResponse(q,r); fsdui.actuationEvidence(r.value);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","solveActuation","fsolve","runActuationInverseSearch"])));
        end
    end
end
function a=argumentsFor(engine)
mechanical=string(engine)=="MECHANICAL";
a=struct('cornerId',"FL",'engine',string(engine),'plan',fsdui.actuationPlan('-10 0 10','0',mechanical),'resultId',"NEW_ANALYSIS");
end
function q=operation(p,a)
q=fsdui.workerRequest(struct('operationId',1,'epoch',0,'action',"ACTUATION_RUN",'project',p,'arguments',a));
end
