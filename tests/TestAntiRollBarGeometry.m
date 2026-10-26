classdef TestAntiRollBarGeometry < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function nominalClosureAndVirtualWorkOracle(t)
            [bar,sources]=fixture(true); p=fsd.analysis.prepareAntiRollBar(bar,sources); r=fsd.analysis.evaluateAntiRollBar(p,[0;0]);
            t.verifyEqual(r.armAngles_rad,[.1;.3],'AbsTol',1e-14); t.verifyEqual(r.angleFirst_per_m,[-10;-10],'AbsTol',1e-12);
            t.verifyEqual(r.torque_Nm,20,'AbsTol',1e-12); t.verifyEqual(r.linkForces_N,[-200;200],'AbsTol',1e-10);
            t.verifyEqual(r.appliedGeneralizedForce_N,[-200;200],'AbsTol',1e-10);
            t.verifyEqual(r.driverForces_N(:,3),r.appliedGeneralizedForce_N,'AbsTol',1e-10);
            t.verifyNumElements(r.closureEnds,2); t.verifyEqual(r.closureEnds{1}.status,"AVAILABLE");
            t.verifyEqual(r.tangent_N_per_m,10000*[1,-1;-1,1],'AbsTol',1e-8);
            heave=fsd.analysis.evaluateAntiRollBar(p,[.01;.01]);
            t.verifyEqual(heave.torque_Nm,20,'AbsTol',1e-11); t.verifyEqual(heave.energy_J,2,'AbsTol',1e-12);
            t.verifyEqual(sum(heave.resistance_N),0,'AbsTol',1e-9);
        end
        function geometricTermAndIndependentEnergyDerivatives(t)
            [bar,sources]=fixture(true); p=fsd.analysis.prepareAntiRollBar(bar,sources); z=[.007;-.004];
            r=fsd.analysis.evaluateAntiRollBar(p,z); h=2e-7; grad=zeros(2,1); H=zeros(2);
            for i=1:2
                e=zeros(2,1); e(i)=h; lo=fsd.analysis.evaluateAntiRollBar(p,z-e); hi=fsd.analysis.evaluateAntiRollBar(p,z+e);
                grad(i)=(hi.energy_J-lo.energy_J)/(2*h); H(:,i)=(hi.resistance_N-lo.resistance_N)/(2*h);
            end
            t.verifyEqual(grad,r.resistance_N,'AbsTol',2e-6); t.verifyEqual(H,r.tangent_N_per_m,'AbsTol',2e-3);
            t.verifyGreaterThan(norm(r.geometricTangent_N_per_m),1);
            t.verifyEqual(r.driverForces_N(:,3),r.appliedGeneralizedForce_N,'AbsTol',1e-8);
            t.verifyEqual(r.tangent_N_per_m,r.tangent_N_per_m','AbsTol',1e-12);
        end
        function unequalArmsMatchIndependentTrigonometricOracle(t)
            [bar,sources]=fixture(true); d=bar.definition; radii=[.1;.14]; lengths=[.2;.25];
            d.parameters.armPoints_m(:,1)=radii; d.parameters.driverPoints_m(:,1)=radii;
            d.parameters.driverPoints_m(:,3)=-lengths; d.parameters.linkLengths_m=lengths;
            bar=fsd.model.createAntiRollBar(d);
            for side=1:2, sources{side}.points_m=d.parameters.driverPoints_m(side,:)+sources{side}.wheelTravel_m*[0,0,1]; end
            p=fsd.analysis.prepareAntiRollBar(bar,sources); z=[.006;-.003]; r=fsd.analysis.evaluateAntiRollBar(p,z);
            % Separate planar circle formula, not the production closure kernel.
            angle=@(q)atan2(2*radii.*(lengths-q),2*radii.^2)- ...
                acos((2*radii.^2+(lengths-q).^2-lengths.^2)./hypot(2*radii.^2,2*radii.*(lengths-q)));
            energy=@(q).5*100*(diff(d.parameters.installationAngles_rad+angle(q)))^2;
            t.verifyEqual(r.armAngles_rad,d.parameters.installationAngles_rad+angle(z),'AbsTol',1e-13);
            t.verifyEqual(r.energy_J,energy(z),'AbsTol',1e-12);
            h=3e-6; gradient=zeros(2,1); H=zeros(2);
            for i=1:2
                ei=zeros(2,1); ei(i)=h; gradient(i)=(energy(z+ei)-energy(z-ei))/(2*h);
                for j=1:2
                    ej=zeros(2,1); ej(j)=h;
                    H(i,j)=(energy(z+ei+ej)-energy(z+ei-ej)-energy(z-ei+ej)+energy(z-ei-ej))/(4*h^2);
                end
            end
            t.verifyEqual(r.resistance_N,gradient,'AbsTol',2e-5); t.verifyEqual(r.tangent_N_per_m,H,'AbsTol',.02);
            t.verifyNotEqual(r.angleFirst_per_m(1),r.angleFirst_per_m(2));
        end
        function reflectionAndLeftRightExchangePreservePhysicalWork(t)
            [bar,sources]=fixture(true); d=bar.definition; z=[.004;-.003];
            a=fsd.analysis.evaluateAntiRollBar(fsd.analysis.prepareAntiRollBar(bar,sources),z);
            mirror=diag([1,-1,1]);
            for key=["armPoints_m","driverPoints_m","supports_m"], d.parameters.(key)=flipud(d.parameters.(key))*mirror; end
            d.parameters.installationAngles_rad=flipud(d.parameters.installationAngles_rad);
            d.parameters.freeAngle_rad=-d.parameters.freeAngle_rad;
            sources=flipud(sources); for i=1:2, sources{i}.points_m=sources{i}.points_m*mirror; end
            b=fsd.analysis.evaluateAntiRollBar(fsd.analysis.prepareAntiRollBar(fsd.model.createAntiRollBar(d),sources),flipud(z));
            t.verifyEqual(b.energy_J,a.energy_J,'AbsTol',1e-12); t.verifyEqual(b.resistance_N,flipud(a.resistance_N),'AbsTol',1e-8);
            t.verifyEqual(b.tangent_N_per_m,rot90(a.tangent_N_per_m,2),'AbsTol',1e-7);
        end
        function endpointForcesDoNotCertifyBilateralTangent(t)
            [bar,sources]=fixture(false); p=fsd.analysis.prepareAntiRollBar(bar,sources);
            r=fsd.analysis.evaluateAntiRollBar(p,[-.04;0]); t.verifyTrue(r.available);
            t.verifyFalse(r.bilateralCurvatureAvailable); t.verifyTrue(all(isnan(r.tangent_N_per_m),'all'));
            t.verifyTrue(all(isfinite(r.candidateTangent_N_per_m),'all'));
            m=fsd.analysis.antiRollBarModalResponse(r,[1;-1],[0;0],[],'m');
            t.verifyTrue(isnan(m.tangentStiffness)); t.verifyEqual(m.tangentStatus,"BILATERAL_CURVATURE_UNAVAILABLE");
            p=bar.definition.parameters; e=fsd.geometry.antiRollBarClosure(p,1,[.3,-.5,0],0,0);
            t.verifyFalse(e.available); t.verifyEqual(e.status,"SINGULAR_OR_ILL_CONDITIONED");
        end
        function reversedAxisIsPhysicallyEquivalent(t)
            [bar,sources]=fixture(true); z=[.004;-.003]; a=fsd.analysis.evaluateAntiRollBar(fsd.analysis.prepareAntiRollBar(bar,sources),z);
            d=bar.definition; d.parameters.axisDirection_unit=-d.parameters.axisDirection_unit;
            d.parameters.installationAngles_rad=-d.parameters.installationAngles_rad;
            d.parameters.freeAngle_rad=-d.parameters.freeAngle_rad;
            d.parameters.armAngleDomain_rad=-fliplr(d.parameters.armAngleDomain_rad);
            b=fsd.analysis.evaluateAntiRollBar(fsd.analysis.prepareAntiRollBar(fsd.model.createAntiRollBar(d),sources),z);
            t.verifyEqual(b.energy_J,a.energy_J,'AbsTol',1e-12); t.verifyEqual(b.resistance_N,a.resistance_N,'AbsTol',1e-9);
            t.verifyEqual(b.driverForces_N,a.driverForces_N,'AbsTol',1e-9); t.verifyEqual(b.torque_Nm,-a.torque_Nm,'AbsTol',1e-12);
        end
        function gapsAndLimitsDoNotBecomeValidInterpolation(t)
            [bar,sources]=fixture(false); sources{1}.validSamples=true(101,1); sources{1}.validSamples(49:53)=false;
            p=fsd.analysis.prepareAntiRollBar(bar,sources); r=fsd.analysis.evaluateAntiRollBar(p,[0;0]);
            t.verifyFalse(r.available); t.verifyEqual(r.status,"FAILED_OR_DISCONNECTED_DRIVER_PATH");
            t.verifyNumElements(p.paths{1}.closureStates,101); t.verifyEmpty(p.paths{1}.closureStates{50});
            r=fsd.analysis.evaluateAntiRollBar(p,[.06;0]); t.verifyEqual(r.status,"OUT_OF_DOMAIN");
            d=bar.definition; d.parameters.armAngleDomain_rad=[.09,.11;.29,.31];
            p=fsd.analysis.prepareAntiRollBar(fsd.model.createAntiRollBar(d),sources);
            t.verifyEqual(p.readiness.status,"MISSING_DATA");
        end
        function rollAndSecantHaveExplicitMovementConditions(t)
            [bar,sources]=fixture(false); p=fsd.analysis.prepareAntiRollBar(bar,sources); r=fsd.analysis.evaluateAntiRollBar(p,[0;0]);
            m=fsd.analysis.antiRollBarModalResponse(r,[.6;-.6],[0;0],0,'rad');
            t.verifyEqual(m.tangentStiffness,14400,'AbsTol',1e-8); t.verifyTrue(isnan(m.secantStiffness));
            d=antiRollBarInputs; eq=fsd.model.createAntiRollBar(d); a=fsd.analysis.evaluateAntiRollBar(eq,[0;0]);
            b=fsd.analysis.evaluateAntiRollBar(eq,[.006;-.006]);
            sec=fsd.analysis.antiRollBarSecantResponse(a,b,[.6;-.6],.01,'rad');
            t.verifyEqual(sec.stiffness,14400,'AbsTol',1e-9);
        end
        function geometryDoesNotRequireConstitutiveData(t)
            [bar,sources]=fixture(false); d=bar.definition; d.stiffnessMode="UNKNOWN"; d.parameters.kTheta_Nm_per_rad=[];
            d.parameters.supports_m=[];
            p=fsd.analysis.prepareAntiRollBar(fsd.model.createAntiRollBar(d),sources);
            t.verifyEqual(p.readiness.status,"MISSING_DATA");
            state=fsd.analysis.evaluateAntiRollBarKinematics(p,[.001;-.001]); t.verifyTrue(state.available);
            for i=1:2, t.verifyLessThan(abs(state.ends{i}.closureResidual_m),1e-12); end
            points=fsd.geometry.antiRollBarPoints(p.bar,state); t.verifyTrue(all(isnan(points.xyz_m(7:8,:)),'all'));
            state.armPoints_m=state.armPoints_m(1,:);
            t.verifyError(@()fsd.geometry.antiRollBarPoints(p.bar,state),'fsd:geometry:InvalidAntiRollBar');
        end
        function existingMaterialPointTransformsSupplyAllDrivers(t)
            [g,a]=actuationFixture; native=fsd.kinematics.solveBump(g,.001,'m');
            t.assertTrue(native.converged); rocker=fsd.kinematics.solveActuation(a,native);
            d=antiRollBarInputs('COAXIAL_TORSION'); d.parameters.driverPoints_m(1,:)=[.02,.03,.04];
            d.referenceFrame=g.referenceFrame;
            for body=["ROCKER","UPRIGHT","UCA","LCA"]
                d.drivers(1)=body; bar=fsd.model.createAntiRollBar(d);
                s=struct('geometry',g,'actuation',a,'state',rocker);
                point=fsd.kinematics.antiRollBarDriverPoint(bar,1,s); t.verifyTrue(all(isfinite(point)));
                if body=="ROCKER"
                    axis=a.rocker.axis; offset=d.parameters.driverPoints_m(1,:)-axis.point_m;
                    t.verifyEqual(dot(point-axis.point_m,axis.direction_unit),dot(offset,axis.direction_unit),'AbsTol',1e-14);
                    t.verifyEqual(norm(point-axis.point_m),norm(offset),'AbsTol',1e-14);
                end
            end
        end
        function degeneraciesAreExplicit(t)
            d=antiRollBarInputs('COAXIAL_TORSION'); p=d.parameters;
            % Driver on shaft: circle/sphere intersection leaves all angles free.
            point=[0,-.5,0]; p.linkLengths_m(1)=.1;
            e=fsd.geometry.antiRollBarClosure(p,1,point,0,0);
            t.verifyFalse(e.available); t.verifyEqual(e.status,"ALL_ANGLES");
            p.linkLengths_m(1)=.01; e=fsd.geometry.antiRollBarClosure(p,1,[10,-.5,0],0,0);
            t.verifyFalse(e.available); t.verifyTrue(startsWith(e.status,"NO_INTERSECTION"));
            p.armPoints_m(1,:)=[1e200,-.5,0]; e=fsd.geometry.antiRollBarClosure(p,1,[1e200,-.5,-.2],0,0);
            t.verifyFalse(e.available); t.verifyEqual(e.status,"NUMERICALLY_UNRESOLVED");
        end
    end
end
function [bar,sources]=fixture(preload)
d=antiRollBarInputs('COAXIAL_TORSION');
if preload
    d.referenceMode="DECLARED_FREE"; d.parameters.freeAngle_rad=0;
    d.provenance.freeAngle_rad=struct('sourceKind',"ASSUMED",'sourceNote',"Explicit independent preload case");
end
bar=fsd.model.createAntiRollBar(d); z=linspace(-.04,.04,101)'; sources=cell(2,1);
for i=1:2
    sources{i}=struct('kind',"PrescribedArbDriverPath",'wheelTravel_m',z, ...
        'points_m',d.parameters.driverPoints_m(i,:)+z*[0,0,1], ...
        'sourceKind',"ASSUMED",'sourceNote',"Independent linear driver oracle; not a solved suspension trajectory");
end
end
