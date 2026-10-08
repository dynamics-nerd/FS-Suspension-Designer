classdef TestSpringDamperPhysics < matlab.unittest.TestCase
    properties (TestParameter)
        Grid = {(-0.01:0.002:0.01)',[-0.01;-0.007;-0.002;0;0.003;0.008;0.01],(0.01:-0.002:-0.01)'}
        Preload = {0,0.02}
    end
    methods (TestMethodSetup)
        function setup(testCase)
            originalPath = path;
            testCase.addTeardown(@() path(originalPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function quadraticIndependentBenchmark(testCase,Grid,Preload)
            m = springDamperFixture(Preload);
            z = Grid; a = 0.5; b = 3; c = a*z+b*z.^2;
            r = testCase.path(m,z,c,0);
            mr = a+2*b*z; x = max(Preload+c,0); f = 30000*x;
            testCase.verifyEqual(r.damperMotionRatio,mr,"AbsTol",2e-13);
            testCase.verifyEqual(r.motionRatioDerivative_per_m,repmat(2*b,size(z)),"AbsTol",3e-10);
            testCase.verifyEqual(r.springAxialForce_N,f,"AbsTol",1e-10);
            testCase.verifyEqual(r.springWheelResistance_N,f.*mr,"AbsTol",1e-9);
            kw = 30000*mr.^2+2*b*f;
            kw(Preload+c < 0) = 0;
            kw(Preload+c == 0) = NaN;
            testCase.verifyEqual(r.wheelRateTotal_N_per_m,kw,"AbsTol",2e-7);
        end
        function constantMRIndependentOfPreload(testCase)
            z = (-0.01:0.002:0.01)'; a = 0.6;
            for p = [0.01,0.03]
                r = testCase.path(springDamperFixture(p),z,a*z,0);
                testCase.verifyEqual(r.wheelRateTotal_N_per_m,repmat(30000*a^2,size(z)),"AbsTol",2e-7);
            end
        end
        function preloadChangesGeometricStiffness(testCase)
            z = [-0.01;0;0.01]; a = 0.5; b = 3;
            r1 = testCase.path(springDamperFixture(0.02),z,a*z+b*z.^2,0);
            r2 = testCase.path(springDamperFixture(0.03),z,a*z+b*z.^2,0);
            testCase.verifyEqual(r2.wheelRateTotal_N_per_m-r1.wheelRateTotal_N_per_m, ...
                repmat(30000*0.01*2*b,3,1),"AbsTol",1e-8);
            testCase.verifyEqual(r1.wheelRateElastic_N_per_m,r2.wheelRateElastic_N_per_m);
        end
        function independentEnergyAndForceFiniteDifferences(testCase)
            m = springDamperFixture(); z = (-0.01:0.002:0.01)';
            a = 0.5; b = 3; h = 1e-6;
            r = testCase.path(m,z,a*z+b*z.^2,0);
            energy = @(q) 0.5*30000*(0.02+a*q+b*q.^2).^2;
            force = @(q) 30000*(0.02+a*q+b*q.^2).*(a+2*b*q);
            expectedForce = (energy(z+h)-energy(z-h))/(2*h);
            expectedRate = (force(z+h)-force(z-h))/(2*h);
            testCase.verifyEqual(r.springWheelResistance_N,expectedForce,"AbsTol",2e-6);
            testCase.verifyEqual(r.wheelRateTotal_N_per_m,expectedRate,"AbsTol",2e-5);
        end
        function negativeTangentIsNotClamped(testCase)
            z = [-0.001;0;0.001]; c = 0.1*z-20*z.^2;
            r = testCase.path(springDamperFixture(),z,c,0);
            testCase.verifyLessThan(r.wheelRateTotal_N_per_m,zeros(3,1));
            testCase.verifyEqual(r.stiffnessDiagnostic,repmat("NEGATIVE_TANGENT_STIFFNESS",3,1));
        end
        function unseatingAndTransitionStillPermitDamping(testCase)
            z = [-0.01;0;0.01]; r = testCase.path(springDamperFixture(0),z,0.5*z,0.1);
            testCase.verifyEqual(r.springStatus,["SPRING_UNSEATED";"SPRING_ENGAGEMENT_TRANSITION";"SPRING_COMPRESSED"]);
            testCase.verifyEqual(r.springGap_m(1),0.005,"AbsTol",1e-14);
            testCase.verifyEqual(r.springLength_m(1),0.2);
            testCase.verifyEqual(r.springStoredEnergy_J(1:2),[0;0]);
            testCase.verifyEqual(r.wheelRateTotal_N_per_m(1),0);
            testCase.verifyTrue(isnan(r.wheelRateTotal_N_per_m(2)));
            testCase.verifyGreaterThan(r.damperDissipatedPower_W,zeros(3,1));
            testCase.verifyFalse(r.staticReferenceAvailable);
        end
        function zeroMRWithCurvatureRetainsGeometricStiffness(testCase)
            z = [-0.01;0;0.01]; r = testCase.path(springDamperFixture(),z,3*z.^2,0.1);
            testCase.verifyEqual(r.damperMotionRatio(2),0,"AbsTol",1e-15);
            testCase.verifyEqual(r.wheelRateElastic_N_per_m(2),0,"AbsTol",1e-12);
            testCase.verifyEqual(r.wheelRateTotal_N_per_m(2),3600,"AbsTol",1e-9);
        end
        function signedDampingAndPower(testCase)
            z = [-0.01;0;0.01]; v = [-0.2;0;0.1];
            r = testCase.path(springDamperFixture(),z,-0.5*z,v);
            vd = -0.5*v; coefficient = [1500;0;2500];
            testCase.verifyEqual(r.damperVelocity_m_per_s,vd,"AbsTol",1e-14);
            testCase.verifyEqual(r.damperAxialResistance_N,coefficient.*vd,"AbsTol",1e-10);
            testCase.verifyEqual(r.damperWheelResistance_N,-0.5*coefficient.*vd,"AbsTol",1e-10);
            testCase.verifyEqual(r.damperDissipatedPower_W,r.damperWheelResistance_N.*v,"AbsTol",1e-12);
            testCase.verifyGreaterThanOrEqual(r.damperDissipatedPower_W,zeros(3,1));
            testCase.verifyTrue(isnan(r.damperWheelLocalCoefficient_Ns_per_m(2)));
            testCase.verifyEqual(r.damperWheelCompressionCoefficient_Ns_per_m,repmat(375,3,1),"AbsTol",1e-12);
            testCase.verifyEqual(r.damperWheelReboundCoefficient_Ns_per_m,repmat(625,3,1),"AbsTol",1e-12);
        end
        function dampingVelocityNeverChangesWheelRate(testCase)
            m = springDamperFixture(); z = [-0.01;0;0.01];
            rest = testCase.path(m,z,0.5*z,0); moving = testCase.path(m,z,0.5*z,0.1);
            testCase.verifyEqual(rest.wheelRateTotal_N_per_m,moving.wheelRateTotal_N_per_m);
            testCase.verifyEqual(rest.damperAxialResistance_N,zeros(3,1));
        end
        function tabulatedInterpolationPassivityAndOutOfRange(testCase)
            [~,a,~,d,u] = springDamperFixture();
            d.damper = struct("modelType","TABULATED_FORCE_VELOCITY", ...
                "compressionTable",[0,0;0.1,100;0.2,90], ...
                "reboundTable",[0,0;0.1,200;0.2,250]);
            m = fsd.model.createSpringDamperModel(a,d,u);
            z = [-0.01;0;0.01];
            r = testCase.path(m,z,0.5*z,[0.1;-0.1;0.5]);
            testCase.verifyEqual(r.damperAxialResistance_N(1:2),[50;-100],"AbsTol",1e-10);
            testCase.verifyTrue(isnan(r.damperAxialResistance_N(3)));
            testCase.verifyEqual(r.damperStatus(3),"DAMPER_VELOCITY_OUT_OF_RANGE");
            testCase.verifyGreaterThanOrEqual(r.damperDissipatedPower_W(1:2),[0;0]);
            testCase.verifyTrue(all(isfinite(r.wheelRateTotal_N_per_m)));
            testCase.verifyTrue(isnan(r.metrics.maximumDissipatedPower_W));
            r = testCase.path(m,z,0.5*z,0.3);
            testCase.verifyEqual(r.damperAxialResistance_N,repmat(95,3,1),"AbsTol",1e-10);
        end
        function boundsAndCoilBindSuppressInvalidResponse(testCase)
            [~,a,~,d,u] = springDamperFixture();
            l0 = a.damper.staticLength_m;
            d.damper.minimumLength = l0-0.003; d.damper.maximumLength = l0+0.003;
            m = fsd.model.createSpringDamperModel(a,d,u);
            z = [-0.01;0;0.01]; r = testCase.path(m,z,0.5*z,0.1);
            testCase.verifyEqual(r.damperTravelStatus([1,3]),repmat("DAMPER_TRAVEL_LIMIT_EXCEEDED",2,1));
            testCase.verifyTrue(all(isnan(r.springAxialForce_N([1,3]))));
            testCase.verifyTrue(all(isfinite(r.damperLength_m)));
            d.damper = rmfield(d.damper,["minimumLength","maximumLength"]);
            d.spring.solidHeight = 0.18;
            m = fsd.model.createSpringDamperModel(a,d,u);
            r = testCase.path(m,z,0.5*z,0);
            testCase.verifyEqual(r.springSolidStatus, ...
                ["ABOVE_PROVIDED_SOLID_HEIGHT";"COIL_BIND_LIMIT";"COIL_BIND_EXCEEDED"]);
            testCase.verifyTrue(all(isnan(r.wheelRateTotal_N_per_m(2:3))));
            testCase.verifyEqual(r.springAxialForce_N(2),600,"AbsTol",1e-10);
            testCase.verifyTrue(isnan(r.springAxialForce_N(3)));
        end
        function absentBoundsAreUnknown(testCase)
            r = testCase.path(springDamperFixture(),[-0.01;0;0.01],[-0.005;0;0.005],0);
            testCase.verifyEqual(r.springSolidStatus,repmat("UNKNOWN",3,1));
            testCase.verifyEqual(r.damperTravelStatus,repmat("UNKNOWN",3,1));
            testCase.verifyTrue(isnan(r.metrics.minimumSpringSolidMargin_m));
        end
        function unavailableDerivativesDoNotInventWheelForces(testCase)
            m = springDamperFixture();
            paths = {[0;0.01],[0;0.01;0],[-0.01;0;eps]};
            statuses = ["UNAVAILABLE_INSUFFICIENT_SAMPLES", ...
                "UNAVAILABLE_NONMONOTONIC_WHEEL_TRAVEL","UNAVAILABLE_ILL_CONDITIONED"];
            for i = 1:numel(paths)
                z = paths{i}; r = testCase.path(m,z,0.5*z,0.1);
                testCase.verifyEqual(r.derivativeStatus,repmat(statuses(i),numel(z),1));
                testCase.verifyTrue(all(isnan(r.springWheelResistance_N)));
                testCase.verifyTrue(all(isfinite(r.springAxialForce_N)));
                testCase.verifyTrue(all(isnan(r.damperAxialResistance_N)));
            end
        end
        function unitVelocityAndPathCorrespondence(testCase)
            m = springDamperFixture(); z = [-0.01;0;0.01];
            r = testCase.path(m,z,0.5*z,0.1);
            other = fsd.analysis.analyzePrescribedSpringDamperPath(m,1000*z,500*z,100, ...
                struct("length","mm","velocity","mm/s"));
            testCase.verifyEqual(other.springAxialForce_N,r.springAxialForce_N,"AbsTol",1e-10);
            testCase.verifyEqual(other.damperAxialResistance_N,r.damperAxialResistance_N,"AbsTol",1e-10);
            testCase.verifyError(@() testCase.path(m,z,0.5*z,[0,1]),"fsd:analysis:InvalidSpringDamperAnalysis");
            testCase.verifyError(@() testCase.path(m,z,0.5*z,NaN),"MATLAB:expectedFinite");
            testCase.verifyError(@() testCase.path(m,z,[0;0],0),"fsd:analysis:InvalidSpringDamperAnalysis");
        end
        function migrationRequiresValidNominalSample(testCase)
            m = springDamperFixture(); z = [-0.01;0;0.01]; r = testCase.path(m,z,0.5*z+3*z.^2,0);
            testCase.verifyTrue(r.staticReferenceAvailable);
            testCase.verifyEqual(r.wheelRateMigration_N_per_m(2),0);
            z = [0.001;0.002;0.003]; r = testCase.path(m,z,0.5*z,0);
            testCase.verifyFalse(r.staticReferenceAvailable);
            testCase.verifyTrue(all(isnan(r.wheelRateMigration_N_per_m)));
        end
        function validatorRejectsEveryMechanicalAggregateFamily(testCase)
            m = springDamperFixture(); z = [-0.01;0;0.01]; r = testCase.path(m,z,0.5*z,0.1);
            testCase.verifyTrue(fsd.analysis.validateSpringDamperSweepAnalysis(r,m));
            names = ["springAxialForce_N","springStoredEnergy_J","springSeatSeparation_m", ...
                "damperAxialResistance_N","damperDissipatedPower_W","damperMotionRatio", ...
                "motionRatioDerivative_per_m","wheelRateElastic_N_per_m","wheelRateGeometric_N_per_m", ...
                "wheelRateTotal_N_per_m","wheelRateMigration_N_per_m"];
            for name = names
                bad = r; bad.(name)(1) = bad.(name)(1)+1;
                testCase.verifyError(@() fsd.analysis.validateSpringDamperSweepAnalysis(bad,m), ...
                    "fsd:analysis:InvalidSpringDamperAnalysis");
            end
            bad = r; bad.states(1).damperTravelStatus = "SAFE";
            testCase.verifyError(@() fsd.analysis.validateSpringDamperSweepAnalysis(bad,m),"fsd:analysis:InvalidSpringDamperAnalysis");
            bad = r; bad.metrics.maximumSpringAxialForce_N = 0;
            testCase.verifyError(@() fsd.analysis.validateSpringDamperSweepAnalysis(bad,m),"fsd:analysis:InvalidSpringDamperAnalysis");
            bad = r; bad.path.achievedWheelTravel_m(1) = 0;
            testCase.verifyError(@() fsd.analysis.validateSpringDamperSweepAnalysis(bad,m),"fsd:analysis:InvalidSpringDamperAnalysis");
        end
    end
    methods (Static, Access = private)
        function r = path(m,z,c,v)
            r = fsd.analysis.analyzePrescribedSpringDamperPath(m,z,c,v, ...
                struct("length","m","velocity","m/s"));
        end
    end
end
