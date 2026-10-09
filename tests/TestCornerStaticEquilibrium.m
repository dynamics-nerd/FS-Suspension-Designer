classdef TestCornerStaticEquilibrium < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function setup(testCase)
            oldPath = path; testCase.addTeardown(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function independentLinearSupportAndResidual(testCase)
            m = springDamperFixture(); z = [-.01;0;.01]; p = prescribed(m,z,.5*z);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,330);
            testCase.verifyEqual(r.status,"UNIQUE_LOCAL_EQUILIBRIUM");
            testCase.verifyEqual(r.equilibriumWheelTravel_m,(330-300)/7500,"AbsTol",1e-14);
            testCase.verifyEqual(r.selectedRoot.tangentWheelRate_N_per_m,7500,"AbsTol",2e-7);
            testCase.verifyEqual(r.selectedRoot.localStabilityStatus,"LOCAL_RESTORING");
            testCase.verifyEqual(r.selectedRoot.method,"PATH_INTERPOLATED_EQUILIBRIUM");
            testCase.verifyEqual(r.selectedRoot.forceResidual_N,0,"AbsTol",1e-10);
            testCase.verifyEqual(r.selectedRoot.damperAxialResistance_N,0);
            testCase.verifyFalse(r.globalChassisEquilibriumSolved);
            testCase.verifyTrue(fsd.analysis.validateCornerStaticEquilibrium(r));
            % Nonlinear force, continuous root 0.004; expect the declared interpolant,
            % not an exact nonlinear root. Endpoint forces independently 300/425.04 N.
            nonlinear = prescribed(m,z,.5*z+3*z.^2);
            q = fsd.analysis.solveCornerStaticEquilibrium(m,[],nonlinear,346.59456);
            expectedInterpolant = .01*(346.59456-300)/(425.04-300);
            testCase.verifyEqual(q.rootCount,1);
            testCase.verifyEqual(q.equilibriumWheelTravel_m,expectedInterpolant,"AbsTol",1e-13);
            testCase.verifyGreaterThan(q.selectedRoot.interpolationForceErrorProxy_N,0);
            testCase.verifyEqual(q.selectedRoot.accuracyStatus,"HEURISTIC_ERROR_PROXY_NOT_A_BOUND");
        end
        function preloadMovesTravelNotDemand(testCase)
            z = (-.02:.005:.02)';
            m = springDamperFixture(.02); p = prescribed(m,z,.5*z);
            a = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,330);
            m = springDamperFixture(.03); p = prescribed(m,z,.5*z);
            b = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,330);
            testCase.verifyEqual(a.equilibriumWheelTravel_m,.004,"AbsTol",1e-13);
            testCase.verifyEqual(b.equilibriumWheelTravel_m,-.016,"AbsTol",1e-13);
            testCase.verifyEqual(a.targetSupport_N,b.targetSupport_N);
        end
        function multipleRootsAndSignedFullStiffness(testCase)
            m = springDamperFixture(); negativeRoot = (15-sqrt(345))/400;
            z = [-.02;negativeRoot;0;.01;.02]; p = prescribed(m,z,.5*z-10*z.^2);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,300);
            testCase.verifyEqual(r.rootCount,2);
            testCase.verifyEqual([r.roots.equilibriumWheelTravel_m],[negativeRoot,0],"AbsTol",1e-12);
            testCase.verifyEqual([r.roots.localStabilityStatus],["LOCAL_RESTORING","LOCAL_NON_RESTORING"]);
            testCase.verifyFalse(r.selectionAvailable);
            options = struct("rootSelection","NEAREST_REFERENCE","referenceTravel_m",0);
            selected = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,300,options);
            testCase.verifyEqual(selected.equilibriumWheelTravel_m,0,"AbsTol",1e-12);
            testCase.verifyEqual(selected.selectedRoot.localStabilityStatus,"LOCAL_NON_RESTORING");
        end
        function sampledTangencyIsMarginal(testCase)
            m = springDamperFixture(); t = (30-sqrt(1260))/1200;
            z = [-.012;t;0;.012]; c = .5*z-10*z.^2;
            demand = 30000*(.02+.5*t-10*t^2)*(.5-20*t);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],prescribed(m,z,c),demand);
            testCase.verifyEqual(r.rootCount,1);
            testCase.verifyEqual(r.equilibriumWheelTravel_m,t,"AbsTol",1e-12);
            testCase.verifyEqual(r.selectedRoot.localStabilityStatus,"LOCAL_MARGINAL_OR_DEGENERATE");
        end
        function noRootAndNoExtrapolation(testCase)
            m = springDamperFixture(); z = [-.01;0;.01]; p = prescribed(m,z,.5*z);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,1000);
            testCase.verifyEqual(r.status,"NO_EQUILIBRIUM_IN_VALID_TRAVEL");
            testCase.verifyTrue(isnan(r.equilibriumWheelTravel_m));
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,330,struct("travelInterval_m",[-.01,0]));
            testCase.verifyEqual(r.rootCount,0);
        end
        function flatUnseatedIntervalAndPositiveDemand(testCase)
            m = springDamperFixture(0); z = [-.03;-.02;-.01]; p = prescribed(m,z,.5*z);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,0);
            testCase.verifyEqual(r.status,"FLAT_EQUILIBRIUM_INTERVAL");
            testCase.verifyFalse(r.selectionAvailable);
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyNotEmpty(r.flatIntervals_m);
            singlePoint = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,0, ...
                struct("travelInterval_m",[-.02,-.02]));
            testCase.verifyEqual(singlePoint.rootCount,1);
            testCase.verifyEqual(singlePoint.equilibriumWheelTravel_m,-.02);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,100);
            testCase.verifyEqual(r.rootCount,0);
        end
        function negativeMRIsNotAbsoluteProjection(testCase)
            m = springDamperFixture(); z = [-.01;0;.01]; p = prescribed(m,z,-.5*z);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,300);
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyTrue(all(p.springWheelResistance_N < 0));
        end
        function F01CurvatureUnavailableDoesNotInvalidateForceRoot(testCase)
            m = springDamperFixture(); z = .01+[-1e-13;0;1e-13];
            p = prescribed(m,z,.5*z+3*z.^2);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,p.springWheelResistance_N(2));
            testCase.verifyGreaterThanOrEqual(r.rootCount,1);
            root = r.roots(abs([r.roots.equilibriumWheelTravel_m]-.01) < 1e-15);
            testCase.verifyEqual(root.localStabilityStatus,"STABILITY_NOT_EVALUABLE");
            testCase.verifyTrue(isnan(root.tangentWheelRate_N_per_m));
            testCase.verifyTrue(fsd.analysis.validateCornerStaticEquilibrium(r));
        end
        function MRUnavailableCannotCreateRoot(testCase)
            m = springDamperFixture(); z = .01+[-2e-14;0;2e-14];
            p = prescribed(m,z,.5*z+3*z.^2);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,425.04);
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyFalse(any(r.validSampleMask));
        end
        function strokeLimitsAreGapsNotInterpolation(testCase)
            [~,a,~,d,u] = springDamperFixture();
            d.damper.minimumLength = a.damper.staticLength_m-.001;
            d.damper.maximumLength = a.damper.staticLength_m+.001;
            m = fsd.model.createSpringDamperModel(a,d,u); z = [-.01;0;.01];
            p = prescribed(m,z,.5*z);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,310);
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyEqual(r.validSampleMask,[false;true;false]);
            testCase.verifyFalse(any(r.validSegmentMask));
        end
        function coilBindAndEngagementDoNotInventStiffness(testCase)
            [~,a,~,d,u] = springDamperFixture(); d.spring.solidHeight = .19;
            m = fsd.model.createSpringDamperModel(a,d,u); z = [-.01;0;.01];
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],prescribed(m,z,.5*z),300);
            testCase.verifyEqual(r.rootCount,0);
            m = springDamperFixture(0); p = prescribed(m,z,.5*z);
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,0);
            testCase.verifyGreaterThanOrEqual(r.rootCount,1);
            atZero = r.roots(abs([r.roots.equilibriumWheelTravel_m]) < 1e-12);
            testCase.verifyEqual(atZero.localStabilityStatus,"STABILITY_NOT_EVALUABLE");
        end
        function sourceFailureAndNotAttemptedRemainUnavailable(testCase)
            [m,a,g] = springDamperFixture();
            b = fsd.kinematics.solveBumpSweep(g,[-.01;0;.01;.5;.02],"m");
            s = fsd.kinematics.solveActuationSweep(a,b);
            aa = fsd.analysis.analyzeActuationSweep(a,s);
            p = fsd.analysis.analyzeSpringDamperSweep(m,a,s,aa,0,"m/s");
            r = fsd.analysis.solveCornerStaticEquilibrium(m,a,p,300);
            testCase.verifyEqual(s.results(5).status,"NOT_ATTEMPTED");
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyFalse(any(r.validSegmentMask));
        end
        function staticAndInvalidOptionsEnforced(testCase)
            m = springDamperFixture(); z = [-.01;0;.01];
            moving = fsd.analysis.analyzePrescribedSpringDamperPath(m,z,.5*z,.1, ...
                struct("length","m","velocity","m/s"));
            testCase.verifyError(@() fsd.analysis.solveCornerStaticEquilibrium(m,[],moving,300), ...
                "fsd:analysis:InvalidCornerEquilibrium");
            p = prescribed(m,z,.5*z);
            testCase.verifyError(@() fsd.analysis.solveCornerStaticEquilibrium(m,[],p,-1), ...
                "fsd:analysis:InvalidCornerEquilibrium");
            testCase.verifyError(@() fsd.analysis.solveCornerStaticEquilibrium(m,[],p,300, ...
                struct("rootSelection","FIRST_STABLE")),"fsd:analysis:InvalidCornerEquilibrium");
        end
        function descendingAndMechanicalUnits(testCase)
            m = springDamperFixture(); z = [.01;0;-.01];
            mm = fsd.analysis.analyzePrescribedSpringDamperPath(m,1000*z,500*z,0, ...
                struct("length","mm","velocity","mm/s"));
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],mm,330);
            testCase.verifyEqual(r.equilibriumWheelTravel_m,.004,"AbsTol",1e-13);
        end
        function adversarialRootPayloadsRejected(testCase)
            m = springDamperFixture(); z = [-.01;0;.01];
            p = prescribed(m,z,.5*z); r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,330);
            for scenario = 1:8
                bad = r;
                switch scenario
                    case 1, bad.roots(1).equilibriumWheelTravel_m = .005;
                    case 2, bad.roots(1).forceResidual_N = 1;
                    case 3, bad.roots(1).tangentWheelRate_N_per_m = -7500;
                    case 4, bad.roots(1).localStabilityStatus = "GLOBAL_STABLE";
                    case 5, bad.targetSupport_N = 340;
                    case 6, bad.cornerId = "FR";
                    case 7, bad.modelIdentity.cornerId = "FR";
                    case 8, bad.selectedRoot.springAxialForce_N = 0;
                end
                testCase.verifyError(@() fsd.analysis.validateCornerStaticEquilibrium(bad), ...
                    "fsd:analysis:InvalidCornerEquilibrium");
            end
            bad = r; bad.sourceMechanical.springWheelResistance_N(2) = 400;
            testCase.verifyError(@() fsd.analysis.validateCornerStaticEquilibrium(bad), ...
                "fsd:analysis:InvalidSpringDamperAnalysis");
        end
        function realIntegrationAndPlots(testCase)
            root = fileparts(fileparts(mfilename("fullpath"))); addpath(fullfile(root,"examples"));
            e = vehicleStaticEquilibriumExample(false);
            testCase.verifyTrue(e.equilibrium.selectionAvailable);
            testCase.verifyEqual(e.equilibrium.targetSupport_N,e.loads.supportForce_N(1));
            testCase.verifyTrue(fsd.analysis.validateCornerStaticEquilibrium(e.equilibrium,e.model,e.actuation,e.mechanical));
            testCase.verifyFalse(e.comparison.globalChassisEquilibriumSolved);
            f = figure("Visible","off"); testCase.addTeardown(@() close(f));
            h = fsd.analysis.plotCornerStaticEquilibrium(e.equilibrium,f);
            testCase.verifyTrue(isgraphics(h.axes,"axes"));
        end
    end
end

function result = prescribed(model,z,c)
result = fsd.analysis.analyzePrescribedSpringDamperPath(model,z,c,0,struct("length","m","velocity","m/s"));
end
