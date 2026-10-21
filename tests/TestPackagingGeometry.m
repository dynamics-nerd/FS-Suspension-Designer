classdef TestPackagingGeometry < matlab.unittest.TestCase
    % Independent Euclidean cases; tolerances verify floating-point math only.
    properties (TestParameter)
        Separation={3,2,1}
        Primitive={'SPHERE','CAPSULE','AABB','OBB'}
    end
    methods (TestClassSetup)
        function paths(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'));
        end
    end
    methods (Test)
        function spheres(t,Separation)
            a=packagingVolumeFixture('A','SPHERE',1,[0 0 0]);
            b=packagingVolumeFixture('B','SPHERE',1,[Separation 0 0]);
            r=fsd.packaging.distance(a,b);
            t.verifyEqual(r.intersection,Separation<=2);
            t.verifyEqual(r.distance_m,max(0,Separation-2),'AbsTol',1e-12);
            if Separation>2
                t.verifyEqual(r.witnesses_m,[1 0 0;Separation-1 0 0],'AbsTol',1e-12);
            else
                t.verifyTrue(all(isnan(r.witnesses_m),'all'));
            end
        end
        function capsuleParallelCrossedAndPointLimits(t)
            a=packagingVolumeFixture('A','CAPSULE',[.1 2],[0 0 0]);
            b=packagingVolumeFixture('B','CAPSULE',[.1 2],[1 0 0]);
            r=fsd.packaging.distance(a,b); t.verifyEqual(r.distance_m,.8,'AbsTol',1e-12);
            R=[0 0 1;0 1 0;-1 0 0];
            b=packagingVolumeFixture('B','CAPSULE',[.1 2],[0 0 0],R);
            r=fsd.packaging.distance(a,b); t.verifyTrue(r.intersection); t.verifyEqual(r.distance_m,0);
            a=packagingVolumeFixture('A','CAPSULE',[.1 0],[0 0 0]);
            b=packagingVolumeFixture('B','SPHERE',.2,[1 0 0]);
            r=fsd.packaging.distance(a,b); t.verifyEqual(r.distance_m,.7,'AbsTol',1e-12);
        end
        function segmentIndependentCases(t)
            [d,p,q]=fsd.packaging.segmentDistance([-1 0 0],[1 0 0],[0 -1 2],[0 1 2]);
            t.verifyEqual(d,2); t.verifyEqual(p,[0 0 0]); t.verifyEqual(q,[0 0 2]);
            [d,~,~]=fsd.packaging.segmentDistance([0 0 0],[0 0 0],[1 0 0],[2 0 0]); t.verifyEqual(d,1);
            [d,~,~]=fsd.packaging.segmentDistance([0 0 0],[0 0 0],[0 3 4],[0 3 4]); t.verifyEqual(d,5);
            [d,~,~]=fsd.packaging.segmentDistance([0 0 0],[2 0 0],[1 1 0],[3 1 0]); t.verifyEqual(d,1);
            % Near-parallel crossing: endpoint-only fallback would miss zero.
            [d,~,~]=fsd.packaging.segmentDistance([-1 0 0],[1 0 0],[-1 -1e-10 0],[1 1e-10 0]);
            t.verifyLessThan(d,1e-15);
        end
        function sphereAndCapsuleAgainstRotatedBox(t)
            angle=pi/4; R=[cos(angle) -sin(angle) 0;sin(angle) cos(angle) 0;0 0 1];
            box=packagingVolumeFixture('BOX','OBB',[2 2 2],[0 0 0],R);
            centre=(R*[3;0;0])'; a=packagingVolumeFixture('A','SPHERE',.25,centre);
            r=fsd.packaging.distance(a,box); t.verifyEqual(r.distance_m,1.75,'AbsTol',1e-12);
            a=packagingVolumeFixture('A','CAPSULE',[.25 4],centre);
            r=fsd.packaging.distance(a,box); t.verifyEqual(r.distance_m,1.75,'AbsTol',1e-12);
            a=packagingVolumeFixture('A','CAPSULE',[.25 4],[0 0 0]);
            r=fsd.packaging.distance(a,box); t.verifyTrue(r.intersection);
        end
        function boxVertexEdgeAndTangency(t)
            a=packagingVolumeFixture('A','AABB',[2 2 2],[0 0 0]);
            b=packagingVolumeFixture('B','AABB',[2 2 2],[3 4 0]);
            r=fsd.packaging.distance(a,b); t.verifyEqual(r.distance_m,sqrt(5),'AbsTol',1e-12);
            b=packagingVolumeFixture('B','AABB',[2 2 2],[2 0 0]);
            r=fsd.packaging.distance(a,b); t.verifyTrue(r.intersection); t.verifyEqual(r.distance_m,0);
            R=[cos(pi/4) -sin(pi/4) 0;sin(pi/4) cos(pi/4) 0;0 0 1];
            b=packagingVolumeFixture('B','OBB',[2 2 2],[4 0 0],R);
            r=fsd.packaging.distance(a,b); t.verifyEqual(r.distance_m,3-sqrt(2),'AbsTol',1e-12);
            t.verifyTrue(r.broadPhaseSeparated);
            t.verifyEqual(norm(diff(r.witnesses_m)),r.distance_m,'AbsTol',1e-12);
        end
        function unitRoundTripAndInvalidInputs(t,Primitive)
            dimensions=1; if Primitive=="CAPSULE", dimensions=[1 2]; elseif ismember(Primitive,["AABB","OBB"]), dimensions=[1 2 3]; end
            a=packagingVolumeFixture('A',Primitive,dimensions,[1 2 3]); d=a.definitionSI;
            d.dimensions=d.dimensions*1000; d.transform(1:3,4)=d.transform(1:3,4)*1000;
            b=fsd.packaging.createVolume(d,'mm'); t.verifyEqual(a,b);
            d=a.definitionSI; d.dimensions(1)=NaN;
            t.verifyError(@()fsd.packaging.createVolume(d,'m'),'fsd:packaging:InvalidVolume');
            d=a.definitionSI; d.dimensions(1)=-1;
            t.verifyError(@()fsd.packaging.createVolume(d,'m'),'fsd:packaging:InvalidVolume');
            d=a.definitionSI; d.transform(1,1)=2;
            t.verifyError(@()fsd.packaging.createVolume(d,'m'),'fsd:geometry:InvalidRotationMatrix');
            d=a.definitionSI; d.transform(1,1)=-1;
            t.verifyError(@()fsd.packaging.createVolume(d,'m'),'fsd:geometry:InvalidRotationMatrix');
        end
        function unsupportedMissingAndFreeSpace(t)
            a=packagingVolumeFixture('A','SPHERE',[],[0 0 0]); b=packagingVolumeFixture('B','SPHERE',1,[3 0 0]);
            r=fsd.packaging.distance(a,b); t.verifyEqual(r.status,"INCOMPLETE"); t.verifyTrue(isnan(r.distance_m));
            a=packagingVolumeFixture('A','CYLINDER',[1 2],[0 0 0]);
            r=fsd.packaging.distance(a,b); t.verifyEqual(r.status,"NOT_EVALUATED"); t.verifyTrue(isnan(r.distance_m));
            d=b.definitionSI; d.componentType="RIM_INTERIOR";
            t.verifyError(@()fsd.packaging.createVolume(d,'m'),'fsd:packaging:InvalidVolume');
            d.role="FREE_REGION"; free=fsd.packaging.createVolume(d,'m');
            t.verifyError(@()fsd.packaging.distance(a,free),'fsd:packaging:FreeRegion');
        end
        function finiteInputsCannotCreateInfiniteClearance(t)
            % Valid finite declarations outside a resolvable arithmetic range
            % are incomplete, never an invented infinitely safe clearance.
            a=packagingVolumeFixture('A','SPHERE',1,[realmax/1.1 0 0]);
            b=packagingVolumeFixture('B','SPHERE',1,[-realmax/1.1 0 0]);
            r=fsd.packaging.distance(a,b);
            t.verifyEqual(r.status,"INCOMPLETE"); t.verifyTrue(isnan(r.distance_m));
        end
        function explicitDiameterIsBoundaryConversion(t)
            a=packagingVolumeFixture('A','CAPSULE',[.1 2],[0 0 0]); d=a.definitionSI;
            d.dimensions=[200 2000];
            t.verifyEqual(fsd.packaging.createVolume(d,'mm','DIAMETER'),a);
            d=a.definitionSI; d.shape="OBB"; d.dimensions=[1 2 3];
            t.verifyError(@()fsd.packaging.createVolume(d,'m','DIAMETER'),'fsd:packaging:InvalidVolume');
        end
        function rigidTransformAndReflectionPreserveDistance(t)
            a=packagingVolumeFixture('A','CAPSULE',[.1 2],[0 0 0]);
            b=packagingVolumeFixture('B','OBB',[1 1 1],[2 0 0]);
            angle=.7; R=[cos(angle) -sin(angle) 0;sin(angle) cos(angle) 0;0 0 1];
            T=[R,[3;4;5];0 0 0 1];
            da=a.definitionSI; db=b.definitionSI;
            da.transform=T*da.transform; db.transform=T*db.transform;
            r=fsd.packaging.distance(fsd.packaging.createVolume(da,'m'),fsd.packaging.createVolume(db,'m'));
            t.verifyEqual(r.distance_m,1.4,'AbsTol',1e-12);
            % Reflect parent points AND local Y axis: det remains +1. No
            % reflection matrix is accepted as a physical rigid rotation.
            M=diag([1 -1 1]);
            da.transform(1:3,1:3)=M*da.transform(1:3,1:3)*M;
            db.transform(1:3,1:3)=M*db.transform(1:3,1:3)*M;
            da.transform(1:3,4)=M*da.transform(1:3,4); db.transform(1:3,4)=M*db.transform(1:3,4);
            r=fsd.packaging.distance(fsd.packaging.createVolume(da,'m'),fsd.packaging.createVolume(db,'m'));
            t.verifyEqual(r.distance_m,1.4,'AbsTol',1e-12);
            db.frame.id="OTHER_FRAME";
            t.verifyError(@()fsd.packaging.distance(fsd.packaging.createVolume(da,'m'), ...
                fsd.packaging.createVolume(db,'m')),'fsd:packaging:FrameMismatch');
        end
        function navigationIndependentOracle(t)
            t.assumeTrue(logical(license('test','Navigation_Toolbox')) && exist('collisionSphere','file')~=0);
            % Away from the documented 1e-5m boundary; no tangency oracle claim.
            a=packagingVolumeFixture('A','CAPSULE',[.2 1],[0 0 0]);
            b=packagingVolumeFixture('B','OBB',[.6 .8 1],[2 .3 .4]);
            nativeA=collisionCapsule(.2,1); nativeB=collisionBox(.6,.8,1);
            nativeB.Pose=b.definitionSI.transform;
            [collision,separation,witnesses]=checkCollision(nativeA,nativeB);
            r=fsd.packaging.distance(a,b);
            t.verifyFalse(logical(collision)); t.verifyEqual(r.distance_m,separation,'AbsTol',1e-7);
            t.verifyEqual(norm(diff(witnesses,1,2)),separation,'AbsTol',1e-7);
            nativeB.Pose=eye(4); [collision,separation,witnesses]=checkCollision(nativeA,nativeB);
            t.verifyTrue(logical(collision)); t.verifyTrue(isnan(separation)); t.verifyTrue(all(isnan(witnesses),'all'));
            [collision,separation,~]=checkCollision(nativeA,nativeB,UsePenetration=true);
            t.verifyTrue(logical(collision)); t.verifyLessThan(separation,0);
        end
        function navigationDeclaredConvexTypes(t)
            t.assumeTrue(logical(license('test','Navigation_Toolbox')) && exist('collisionMesh','file')~=0);
            sphere=collisionSphere(.25); sphere.Pose=[eye(3),[2;0;0];0 0 0 1];
            vertices=[-1 -1 -1;1 -1 -1;-1 1 -1;1 1 -1;-1 -1 1;1 -1 1;-1 1 1;1 1 1]/2;
            geometries={collisionBox(1,1,1),collisionCylinder(.5,2),collisionMesh(vertices)};
            for j=1:numel(geometries)
                [collision,separation,witnesses]=checkCollision(geometries{j},sphere);
                t.verifyFalse(logical(collision)); t.verifyEqual(separation,1.25,'AbsTol',1e-7);
                t.verifyEqual(norm(diff(witnesses,1,2)),1.25,'AbsTol',1e-7);
            end
            % Mesh convexity is deliberate: it is the cube's hull, not a
            % promise of support for concave rim/CAD geometry in production.
        end
    end
end
