classdef TestPackagingEvaluation < matlab.unittest.TestCase
    properties (TestParameter)
        Direction={-1,1}
        BoundaryOffset={-1e-5,1e-5}
    end
    methods (TestClassSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'));
        end
    end
    methods (Test)
        function realBumpAndReboundCollision(t,Direction)
            [d,g]=packagingMotionFixture(Direction*.04);
            nominal=fsd.packaging.evaluate(d,g,struct('mode',"NOMINAL",'requested_m',[]),[]);
            t.verifyEqual(nominal.status,"CLEAR_SAMPLED");
            grid=[-.04;0;.04]; sweep=fsd.kinematics.solveBumpSweep(g,grid,'m');
            original=sweep; plan=struct('mode',"BUMP",'requested_m',grid);
            profile clear; profile on;
            r=fsd.packaging.evaluate(d,g,plan,sweep); fsd.packaging.validateResult(r);
            profile off; p=profile('info'); names=string({p.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBump","fsolve","solveActuation","boundedDirectSearch"])));
            t.verifyEqual(r.status,"COLLISION_DETECTED"); t.verifyTrue(r.coverage.complete);
            index=3; if Direction<0, index=1; end
            t.verifyEqual(r.checks{index}.status,"COLLISION_DETECTED");
            t.verifyEqual(r.minimumObservedDistance_m,0); t.verifyEqual(sweep,original);
            t.verifyEqual(r.source,original);
            r.checks{index}.status="CLEAR_SAMPLED";
            t.verifyError(@()fsd.packaging.validateResult(r),'fsd:packaging:InvalidResult');
        end
        function interiorMinimumAndMissedBetweenSamples(t)
            [d,g]=packagingMotionFixture(.04);
            grid=[0;.04;.08]; source=fsd.kinematics.solveBumpSweep(g,grid,'m');
            r=fsd.packaging.evaluate(d,g,struct('mode',"BUMP",'requested_m',grid),source);
            t.verifyEqual(r.status,"COLLISION_DETECTED"); t.verifyEqual(r.worstCheckIndex,2);
            grid=[0;.08]; source=fsd.kinematics.solveBumpSweep(g,grid,'m');
            r=fsd.packaging.evaluate(d,g,struct('mode',"BUMP",'requested_m',grid),source);
            t.verifyEqual(r.status,"CLEAR_SAMPLED");
            t.verifyTrue(any(contains(r.limitations,'between requested samples')));
            t.verifyEqual(r.coverage.requestedSamples,2);
        end
        function failedMissingAndTamperedNativePose(t)
            [d,g]=packagingMotionFixture(.04); grid=[0;.5];
            sweep=fsd.kinematics.solveBumpSweep(g,grid,'m'); t.assertFalse(sweep.allConverged);
            plan=struct('mode',"BUMP",'requested_m',grid);
            r=fsd.packaging.evaluate(d,g,plan,sweep);
            t.verifyEqual(r.status,"INCOMPLETE"); t.verifyFalse(r.coverage.complete);
            t.verifyEqual(r.coverage.failedSamples,find(~sweep.converged));
            r=fsd.packaging.evaluate(d,g,plan,[]);
            t.verifyEqual(r.status,"INCOMPLETE"); t.verifyEqual(r.coverage.resolvedSamples,0);
            bad=sweep; bad.results=rmfield(bad.results,'uprightPose');
            t.verifyError(@()fsd.packaging.evaluate(d,g,plan,bad),'fsd:kinematics:InvalidBumpSweepResult');
        end
        function marginAboveBelowAndUnknownDimensions(t,BoundaryOffset)
            [base,g]=packagingMotionFixture(.04); d=base.definitionSI;
            a=packagingVolumeFixture('A','SPHERE',.01,[0 0 1]);
            b=packagingVolumeFixture('B','SPHERE',.01,[.025+BoundaryOffset 0 1]);
            d.volumes={a;b}; p=d.pairs{1}; p.first="A"; p.second="B"; d.pairs={p};
            definition=fsd.packaging.createDefinition(d);
            r=fsd.packaging.evaluate(definition,g,struct('mode',"NOMINAL",'requested_m',[]),[]);
            expected="CLEAR_SAMPLED"; if BoundaryOffset<0, expected="LOW_CLEARANCE"; end
            t.verifyEqual(r.status,expected); t.verifyEqual(r.checks{1}.margin_m,BoundaryOffset,'AbsTol',1e-14);
            v=b.definitionSI; v.dimensions=[]; d.volumes{2}=fsd.packaging.createVolume(v,'m');
            r=fsd.packaging.evaluate(fsd.packaging.createDefinition(d),g,struct('mode',"NOMINAL",'requested_m',[]),[]);
            t.verifyEqual(r.status,"INCOMPLETE"); t.verifyTrue(isnan(r.minimumObservedDistance_m));
        end
        function explicitArmConnection(t)
            [base,g]=packagingMotionFixture(.04); d=base.definitionSI;
            v=packagingVolumeFixture('TUBE','CAPSULE',[.005 1],[0 0 0]);
            % Construct radius-only SEGMENT before invoking the canonical factory.
            x=v.definitionSI; x.binding=struct('mode',"SEGMENT",'cornerId',"FL", ...
                'pointIds',["FL_UCA_FWD_CHASSIS";"FL_UBJ"]);
            x.componentType="TUBE"; x.dimensions=.005; d.volumes{1}=fsd.packaging.createVolume(x,'m');
            d.pairs{1}.first="TUBE"; definition=fsd.packaging.createDefinition(d);
            sweep=fsd.kinematics.solveBumpSweep(g,.02,'m');
            [resolved,diagnostics,~]=fsd.packaging.resolveVolumes(definition,g,sweep.results(1));
            t.verifyEqual(diagnostics(1),"RESOLVED");
            tube=resolved{1}.definitionSI; midpoint=tube.transform(1:3,4)';
            half=tube.transform(1:3,3)'*tube.dimensions(2)/2;
            t.verifyEqual(midpoint-half,fsd.model.getPoint(g,'FL_UCA_FWD_CHASSIS'),'AbsTol',1e-12);
            t.verifyEqual(midpoint+half,sweep.results(1).state.ubj_m,'AbsTol',1e-12);
        end
        function jointExemptionCannotHideRimOrChassis(t)
            [base,g]=packagingMotionFixture(.04); d=base.definitionSI;
            a=d.volumes{1}.definitionSI; a.componentType="JOINT";
            d.volumes{1}=fsd.packaging.createVolume(a,'m');
            e=struct('id',"JOINT_CONTACT",'firstComponent',a.componentId,'secondComponent',"OBSTACLE", ...
                'reason',"Synthetic explicit local shared joint",'source',"Software fixture");
            d.pairs{1}.exception=e;
            t.verifyError(@()fsd.packaging.createDefinition(d),'fsd:packaging:InvalidDefinition');
            b=d.volumes{2}.definitionSI; b.componentType="UPRIGHT";
            d.volumes{2}=fsd.packaging.createVolume(b,'m'); definition=fsd.packaging.createDefinition(d);
            r=fsd.packaging.evaluate(definition,g,struct('mode',"NOMINAL",'requested_m',[]),[]);
            t.verifyEqual(r.checks{1}.status,"EXEMPT_CONTACT"); t.verifyEqual(r.status,"NOT_EVALUATED");
            t.verifyEqual(r.coverage.exemptChecks,1); t.verifyFalse(r.coverage.complete);
        end
        function fixedInsideOutsideRegions(t)
            [base,g]=packagingMotionFixture(.04); d=base.definitionSI; p=fsd.model.getPoint(g,'FL_UBJ');
            v=packagingVolumeFixture('REGION','OBB',[.1 .1 .1],p); x=v.definitionSI; x.role="FREE_REGION";
            d.volumes={fsd.packaging.createVolume(x,'m')}; d.pairs={};
            region=struct('id',"REGION_CHECK",'cornerId',"FL",'pointId',"FL_UBJ",'mode',"INSIDE", ...
                'volumeId',"REGION",'target_m',[],'tolerance_m',[],'clearance_m',.01, ...
                'source',"Independent centered-box fixture",'provenance',"ASSUMED software case");
            d.regions={region}; definition=fsd.packaging.createDefinition(d);
            r=fsd.packaging.evaluate(definition,g,struct('mode',"NOMINAL",'requested_m',[]),[]);
            t.verifyEqual(r.status,"CLEAR_SAMPLED"); t.verifyEqual(r.regions{1}.margin_m,.04,'AbsTol',1e-12);
            d.regions{1}.mode="OUTSIDE";
            r=fsd.packaging.evaluate(fsd.packaging.createDefinition(d),g,struct('mode',"NOMINAL",'requested_m',[]),[]);
            t.verifyEqual(r.status,"LOW_CLEARANCE");
            region.mode="FIXED"; region.volumeId=""; region.target_m=p; region.tolerance_m=1e-6; region.clearance_m=[];
            d.regions={region};
            r=fsd.packaging.evaluate(fsd.packaging.createDefinition(d),g,struct('mode',"NOMINAL",'requested_m',[]),[]);
            t.verifyEqual(r.status,"CLEAR_SAMPLED");
        end
    end
end
