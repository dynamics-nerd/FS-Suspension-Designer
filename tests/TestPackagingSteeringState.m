classdef TestPackagingSteeringState < matlab.unittest.TestCase
    methods (TestClassSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'));
        end
    end
    methods (Test)
        function nativeRackCornerUsesActualInnerJointWithoutNewSolve(t)
            g=threeDimensionalCornerFixture(); right=fsd.geometry.reflectDoubleWishboneGeometry(g);
            axle=fsd.model.createAxleGeometry(g,right); steering=fsd.model.createSteeringSystem(axle,1.6,'m');
            sweep=fsd.kinematics.solveRackSweep(steering,[-.002;0;.002],0,'m');
            t.assertTrue(sweep.allConverged);
            v=packagingVolumeFixture('ROD','CAPSULE',[],[0 0 0]); d=v.definitionSI;
            d.dimensions=.002; d.componentType="TUBE";
            d.binding=struct('mode',"SEGMENT",'cornerId',"FL", ...
                'pointIds',["FL_TIE_ROD_INBOARD";"FL_TIE_ROD_OUTBOARD"]);
            volume=fsd.packaging.createVolume(d,'m');
            definition=fsd.packaging.createDefinition(struct('id',"RACK_CORNER_ADAPTER", ...
                'volumes',{{volume}},'pairs',{{}},'regions',{{}}));
            profile clear; profile on; guard=onCleanup(@()profile('off'));
            for j=1:3
                native=sweep.results(j).leftResult;
                [resolved,diagnostics,points]=fsd.packaging.resolveVolumes(definition,g,native);
                t.verifyEqual(diagnostics,"RESOLVED");
                r=resolved{1}.definitionSI; centre=r.transform(1:3,4)'; half=r.dimensions(2)*r.transform(1:3,3)'/2;
                out=native.state.xyz_m(native.state.pointIds=="FL_TIE_ROD_OUTBOARD",:);
                t.verifyEqual(centre-half,native.tieRodInboardCurrent_m,'AbsTol',1e-12);
                t.verifyEqual(centre+half,out,'AbsTol',1e-12);
                t.verifyEqual(points.xyz_m(points.ids=="FL_TIE_ROD_INBOARD",:),native.tieRodInboardCurrent_m);
            end
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveSteering","solveRack","fsolve"])));
            t.verifyNotEqual(sweep.results(3).leftResult.tieRodInboardCurrent_m, ...
                fsd.model.getPoint(g,'FL_TIE_ROD_INBOARD'));
        end
    end
end
