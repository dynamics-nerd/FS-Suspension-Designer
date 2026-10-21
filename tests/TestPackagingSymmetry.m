classdef TestPackagingSymmetry < matlab.unittest.TestCase
    methods (TestClassSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'));
        end
    end
    methods (Test)
        function nativeLeftRightBumpAndDeclaredSolids(t)
            [definition,left]=packagingMotionFixture(.04);
            right=fsd.geometry.reflectDoubleWishboneGeometry(left); d=definition.definitionSI; S=diag([1 -1 1]);
            for j=1:numel(d.volumes)
                v=d.volumes{j}.definitionSI;
                v.transform(1:3,1:3)=S*v.transform(1:3,1:3)*S;
                v.transform(1:3,4)=S*v.transform(1:3,4);
                if v.binding.mode~="FIXED", v.binding.cornerId="FR"; end
                d.volumes{j}=fsd.packaging.createVolume(v,'m');
            end
            mirrored=fsd.packaging.createDefinition(d); grid=[0;.04;.08];
            l=fsd.kinematics.solveBumpSweep(left,grid,'m'); r=fsd.kinematics.solveBumpSweep(right,grid,'m');
            t.assertTrue(l.allConverged && r.allConverged);
            plan=struct('mode',"BUMP",'requested_m',grid);
            L=fsd.packaging.evaluate(definition,left,plan,l); R=fsd.packaging.evaluate(mirrored,right,plan,r);
            tol=fsd.model.numericTolerances();
            t.verifyEqual(R.status,L.status); t.verifyEqual(R.worstCheckIndex,L.worstCheckIndex);
            for j=1:3
                t.verifyEqual(R.checks{j}.distance_m,L.checks{j}.distance_m,'AbsTol',tol.AbsTol_m);
                t.verifyEqual(R.states{j}.points.xyz_m,L.states{j}.points.xyz_m*S,'AbsTol',tol.AbsTol_m);
            end
            t.verifyEqual(R.states{2}.volumes{1}.definitionSI.transform(2,4), ...
                -L.states{2}.volumes{1}.definitionSI.transform(2,4),'AbsTol',tol.AbsTol_m);
        end
    end
end
