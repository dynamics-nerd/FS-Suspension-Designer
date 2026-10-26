classdef TestAntiRollBarEnergy < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function partialResourceDoesNotInventData(t)
            b=fsd.model.createAntiRollBar(struct('id',"PARTIAL"));
            t.verifyTrue(fsd.model.validateAntiRollBar(b)); t.verifyEmpty(b.definition.parameters.linearStiffness_N_per_m);
            t.verifyEqual(fsd.model.antiRollBarReadiness(b,'MECHANICAL').status,"MISSING_DATA");
            r=fsd.analysis.evaluateAntiRollBar(b,[0;0]); t.verifyFalse(r.available); t.verifyTrue(isnan(r.energy_J));
        end
        function coupledEquivalentOracleAndHeave(t)
            b=fsd.model.createAntiRollBar(antiRollBarInputs); r=fsd.analysis.evaluateAntiRollBar(b,[.01;-.01]);
            t.verifyEqual(r.energy_J,2,'AbsTol',1e-14);
            t.verifyEqual(r.resistance_N,[200;-200],'AbsTol',1e-12);
            t.verifyEqual(r.tangent_N_per_m,10000*[1,-1;-1,1]);
            heave=fsd.analysis.evaluateAntiRollBar(b,[.01;.01]); t.verifyEqual(heave.energy_J,0);
            t.verifyTrue(isnan(r.torque_Nm)); t.verifyTrue(all(isnan(r.linkForces_N)));
        end
        function asymmetricHeaveIsNotUniversallyZero(t)
            d=antiRollBarInputs; d.parameters.weights=[-1;2]; b=fsd.model.createAntiRollBar(d);
            r=fsd.analysis.evaluateAntiRollBar(b,[.01;.01]);
            t.verifyEqual(r.energy_J,.5,'AbsTol',1e-14); t.verifyEqual(r.resistance_N,[-100;200],'AbsTol',1e-12);
        end
        function installedReferenceIsNotUniversalZero(t)
            d=antiRollBarInputs; d.parameters.installationWheelTravel_m=[.01;-.01]; b=fsd.model.createAntiRollBar(d);
            t.verifyEqual(fsd.analysis.evaluateAntiRollBar(b,[.01;-.01]).energy_J,0);
            t.verifyEqual(fsd.analysis.evaluateAntiRollBar(b,[0;0]).energy_J,2,'AbsTol',1e-14);
            d=antiRollBarInputs('COAXIAL_TORSION'); b=fsd.model.createAntiRollBar(d);
            r=fsd.analysis.evaluateAntiRollBarTorsion(b,[.1,.3;.1,.4]);
            t.verifyEqual(r.freeAngle_rad,.2,'AbsTol',1e-15);
            t.verifyEqual(r.torque_Nm,[0;10],'AbsTol',1e-12);
            t.verifyEqual(r.energy_J,[0;.5],'AbsTol',1e-14);
        end
        function explicitPreloadPreservesEffortDuringCommonRotation(t)
            d=antiRollBarInputs('COAXIAL_TORSION'); d.referenceMode="DECLARED_FREE";
            d.parameters.freeAngle_rad=.1; d.provenance.freeAngle_rad=source(); b=fsd.model.createAntiRollBar(d);
            r=fsd.analysis.evaluateAntiRollBarTorsion(b,[.1,.3;.2,.4]);
            t.verifyEqual(r.torque_Nm,[10;10],'AbsTol',1e-12); t.verifyEqual(r.armTorques_Nm,[10,-10;10,-10],'AbsTol',1e-12);
        end
        function independentGradientAndHessian(t)
            b=fsd.model.createAntiRollBar(antiRollBarInputs); z=[.007;-.003]; r=fsd.analysis.evaluateAntiRollBar(b,z);
            h=1e-6; gradient=zeros(2,1); H=zeros(2);
            for k=1:2
                e=zeros(2,1); e(k)=h; left=fsd.analysis.evaluateAntiRollBar(b,z-e); right=fsd.analysis.evaluateAntiRollBar(b,z+e);
                gradient(k)=(right.energy_J-left.energy_J)/(2*h); H(:,k)=(right.resistance_N-left.resistance_N)/(2*h);
            end
            t.verifyEqual(gradient,r.resistance_N,'AbsTol',1e-8); t.verifyEqual(H,r.tangent_N_per_m,'AbsTol',1e-6);
        end
        function sectionLawsAndInverseSizing(t)
            d=antiRollBarInputs('COAXIAL_TORSION'); d.stiffnessMode="CIRCULAR_SHAFT"; d.section="SOLID";
            d.parameters.kTheta_Nm_per_rad=[]; d.parameters.G_Pa=8e10; d.parameters.outerDiameter_m=.01; d.parameters.effectiveLength_m=.5;
            for key=["G_Pa","outerDiameter_m","effectiveLength_m"], d.provenance.(key)=source(); end
            a=fsd.analysis.antiRollBarStiffness(fsd.model.createAntiRollBar(d));
            t.verifyEqual(a.kTheta_Nm_per_rad,8e10*pi*.01^4/(32*.5),'RelTol',1e-14);
            d.parameters.outerDiameter_m=.02; twice=fsd.analysis.antiRollBarStiffness(fsd.model.createAntiRollBar(d));
            t.verifyEqual(twice.kTheta_Nm_per_rad/a.kTheta_Nm_per_rad,16,'RelTol',1e-14);
            d.section="TUBULAR"; d.parameters.innerDiameter_m=.01; d.provenance.innerDiameter_m=source();
            tube=fsd.analysis.antiRollBarStiffness(fsd.model.createAntiRollBar(d));
            t.verifyEqual(tube.kTheta_Nm_per_rad,8e10*pi*(.02^4-.01^4)/(32*.5),'RelTol',1e-14);
            sized=fsd.analysis.sizeAntiRollBarSection(tube.kTheta_Nm_per_rad,8e10,.5,.01);
            t.verifyEqual(sized.outerDiameter_m,.02,'AbsTol',1e-15);
            d.parameters.effectiveLength_m=1; longer=fsd.analysis.antiRollBarStiffness(fsd.model.createAntiRollBar(d));
            t.verifyEqual(longer.kTheta_Nm_per_rad,tube.kTheta_Nm_per_rad/2,'RelTol',1e-14);
        end
        function numericInputsAndDomainsAreCanonical(t)
            d=antiRollBarInputs; d.parameters.linearStiffness_N_per_m=int32(10000);
            b=fsd.model.createAntiRollBar(d); t.verifyClass(b.definition.parameters.linearStiffness_N_per_m,'double');
            t.verifyTrue(fsd.model.validateAntiRollBar(b));
            d.parameters.linearStiffness_N_per_m=uint64(flintmax)+uint64(1);
            t.verifyError(@()fsd.model.createAntiRollBar(d),'fsd:model:InvalidAntiRollBar');
            r=fsd.analysis.evaluateAntiRollBar(b,[.06;0]); t.verifyEqual(r.status,"OUT_OF_DOMAIN");
            d=antiRollBarInputs('COAXIAL_TORSION'); d.parameters.axisDirection_unit=[1,2,3]; d.parameters.supports_m=[]; d.parameters.armPoints_m=[];
            t.verifyTrue(fsd.model.validateAntiRollBar(fsd.model.createAntiRollBar(d)));
        end
    end
end
function s=source()
s=struct('sourceKind',"ASSUMED",'sourceNote',"Independent synthetic test, not FS data");
end
