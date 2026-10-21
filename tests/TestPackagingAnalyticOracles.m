classdef TestPackagingAnalyticOracles < matlab.unittest.TestCase
    % Closed-form checks for the three observed approximate Navigation gaps.
    % Synthetic SI data, not dimensions or clearances recommended for a vehicle.
    methods (TestClassSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'));
        end
    end
    methods (Test)
        function rotatedBoxSphereDirectClamp(t)
            angle=.3; c=cos(angle); s=sin(angle); R=[c 0 s;0 1 0;-s 0 c];
            a=packagingVolumeFixture('A','OBB',[.8 1.2 2.2],[0 0 0],R);
            b=packagingVolumeFixture('B','SPHERE',.2,[3.1 .1 -.7]);
            % In box coordinates only X is beyond its positive face.
            localX=3.1*c+.7*s; localZ=3.1*s-.7*c;
            t.assertLessThan(abs(localZ),1.1);
            expected=localX-.4-.2;
            r=fsd.packaging.distance(a,b);
            t.verifyEqual(r.distance_m,expected,'AbsTol',1e-12);
        end
        function capsuleAabbEndpointIsIndependentMinimum(t)
            angle=.3; c=cos(angle); s=sin(angle); half=.8;
            a=packagingVolumeFixture('A','CAPSULE',[.2 1.6],[0 0 0],[c 0 s;0 1 0;-s 0 c]);
            b=packagingVolumeFixture('B','AABB',[.8 1.2 2.2],[3.1 .1 -.7]);
            % Whole segment lies left of X=2.7. Below Z=.4 distance decreases
            % towards +t; in the upper-face interval the quadratic stationary
            % parameter is beyond the endpoint, so t=+.8 is the minimum.
            stationary=2.7*s+.4*c; t.assertGreaterThan(stationary,half);
            expected=hypot(2.7-half*s,half*c-.4)-.2;
            r=fsd.packaging.distance(a,b);
            t.verifyEqual(r.distance_m,expected,'AbsTol',1e-12);
        end
        function rotatedBoxCapsuleMonotoneEndpoint(t)
            angle=1.1; c=cos(angle); s=sin(angle); R=[c 0 s;0 1 0;-s 0 c]; half=.8;
            a=packagingVolumeFixture('A','OBB',[.8 1.2 2.2],[0 0 0],R);
            b=packagingVolumeFixture('B','CAPSULE',[.2 1.6],[3.1 .1 -.7],R');
            % Both active coordinates remain beyond positive box faces over
            % the whole closed segment. Squared distance is convex and still
            % decreasing at +half; no interior parameter can be its minimum.
            x0=3.1*c+.7*s; z0=3.1*s-.7*c;
            ux=-sin(2*angle); uz=cos(2*angle);
            dx=x0+half*ux-.4; dz=z0+half*uz-1.1;
            t.assertGreaterThan(dx,0); t.assertGreaterThan(dz,0);
            t.assertLessThan(dx*ux+dz*uz,0);
            expected=hypot(dx,dz)-.2;
            r=fsd.packaging.distance(a,b);
            t.verifyEqual(r.distance_m,expected,'AbsTol',1e-12);
        end
    end
end
