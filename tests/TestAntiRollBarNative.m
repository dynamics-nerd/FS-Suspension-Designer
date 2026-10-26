classdef TestAntiRollBarNative < matlab.unittest.TestCase
    properties(TestParameter)
        body={"ROCKER","UPRIGHT","UCA","LCA"}
    end
    properties
        Project
    end
    methods(TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            t.Project=globalStaticGuidedInputs;
        end
    end
    methods(Test)
        function nativePairedSourcesAndCanonicalState(t,body)
            p=t.Project; b=fsd.model.createAntiRollBar(geometricAntiRollBarInputs(p,'FRONT',body));
            samples=native(p,b,[0,0;.001,-.001;.002,-.002]);
            result=fsd.kinematics.solveAntiRollBarSweep(b,samples); t.verifyNumElements(result.states,3);
            for k=1:3
                state=result.states{k}; t.assertTrue(state.converged);
                t.verifyTrue(fsd.kinematics.validateAntiRollBarState(state,b));
                for i=1:2, t.verifyLessThan(abs(state.ends{i}.closureResidual_m),1e-9); end
            end
            initial=result.states{1}; t.verifyEqual(cellfun(@(e)e.angle_rad,initial.ends),[.1;.3],'AbsTol',1e-9);
            forged=result.states{2}; forged.ends{1}.branchSign=-forged.ends{1}.branchSign;
            t.verifyError(@()fsd.kinematics.validateAntiRollBarState(forged,b),'fsd:kinematics:InvalidAntiRollBar');
            crossed=samples(1,:)'; crossed{2}=samples{1,1};
            t.verifyError(@()fsd.kinematics.solveAntiRollBar(b,crossed),'fsd:kinematics:InvalidAntiRollBar');
        end
        function declaredBranchAndDomainFailuresStopContinuation(t)
            p=t.Project; d=geometricAntiRollBarInputs(p,'FRONT','UPRIGHT'); d.parameters.wheelTravelDomain_m=[-.005,.005;-.005,.005];
            b=fsd.model.createAntiRollBar(d); samples=native(p,b,[0,0;.01,-.01;0,0]);
            nominal=fsd.kinematics.solveAntiRollBar(b,samples(1,:)');
            branches=cellfun(@(e)e.branchSign,nominal.ends); wrong=fsd.kinematics.solveAntiRollBar(b,samples(1,:)',[0;0],-branches);
            t.verifyFalse(wrong.converged); t.verifyEqual(wrong.ends{1}.status,"BRANCH_MISMATCH");
            sweep=fsd.kinematics.solveAntiRollBarSweep(b,samples);
            t.verifyTrue(sweep.states{1}.converged); t.verifyFalse(sweep.states{2}.converged);
            t.verifyEqual(sweep.states{3}.kind,"AntiRollBarNotAttempted");
        end
    end
end
function samples=native(project,bar,z)
ids=["FL","FR"]; resources=project.definition.resources; samples=cell(size(z));
for side=1:2
    gs=resources.geometries; g=gs{cellfun(@(g)g.cornerId==ids(side),gs)};
    for k=1:size(z,1)
        state=fsd.kinematics.solveBump(g,z(k,side),'m'); assert(state.converged);
        source=struct('geometry',g,'state',state);
        if bar.definition.drivers(side)=="ROCKER"
            aa=resources.actuations; a=aa{cellfun(@(a)a.cornerId==ids(side),aa)};
            source.actuation=a; source.state=fsd.kinematics.solveActuation(a,state);
        end
        samples{k,side}=source;
    end
end
end
