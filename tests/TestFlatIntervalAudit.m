classdef TestFlatIntervalAudit < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function setup(testCase)
            previous = path; testCase.addTeardown(@() path(previous));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function shortFlatAndInclusiveEndpoints(testCase)
            m = springDamperFixture(0); z = [-.04;-.025;-.01];
            r = local(m,z,.5*z);
            testCase.verifyEqual(r.flatIntervals_m,[z(1:2)';z(2:3)']);
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyFalse(r.selectionAvailable);
            testCase.verifyEqual(r.status,"FLAT_EQUILIBRIUM_INTERVAL");
            testCase.verifyTrue(fsd.analysis.validateCornerStaticEquilibrium(r));
        end
        function mandatoryFlatSizesStructuralComplexity(testCase)
            m = springDamperFixture(0);
            for count = [21,101,501,2001]
                z = linspace(-.04,-.01,count)'; r = local(m,z,.5*z);
                testCase.verifyEqual(r.rootCount,0);
                testCase.verifySize(r.flatIntervals_m,[count-1,2]);
                d = r.flatIntervalFilterDiagnostics;
                testCase.verifyEqual(d.algorithm,"SORTED_INTERVAL_SWEEP");
                testCase.verifyEqual(d.rootComparisonCount,count);
                testCase.verifyEqual(d.intervalAdvanceCount,count-1);
                testCase.verifyLessThanOrEqual(d.rootComparisonCount+d.intervalAdvanceCount,2*count);
            end
        end
        function descendingSweepSameSetAndOriginalIntervalOrder(testCase)
            m = springDamperFixture(0); z = linspace(-.04,-.01,21)';
            ascending = local(m,z,.5*z); z = flipud(z); descending = local(m,z,.5*z);
            testCase.verifyEqual(descending.rootCount,0);
            testCase.verifyEqual(descending.flatIntervals_m,flipud(ascending.flatIntervals_m));
            testCase.verifyEqual(descending.flatIntervalFilterDiagnostics,ascending.flatIntervalFilterDiagnostics);
        end
        function isolatedRootsOnBothSidesRemainSorted(testCase)
            m = springDamperFixture(0); z = (-.09:.01:-.01)';
            c = [.003;.006;.003;-.004;-.004;-.004;.003;.006;.003];
            r = local(m,z,c);
            testCase.verifyEqual([r.roots.equilibriumWheelTravel_m],[-.08,-.02],"AbsTol",1e-12);
            testCase.verifyEqual(r.flatIntervals_m,[-.06,-.05;-.05,-.04],"AbsTol",1e-12);
            testCase.verifyEqual(r.rootCount,2);
            testCase.verifyEqual([r.roots.localStabilityStatus],repmat("LOCAL_NON_RESTORING",1,2));
            reverse = local(m,flipud(z),flipud(c));
            testCase.verifyEqual([reverse.roots.equilibriumWheelTravel_m], ...
                [r.roots.equilibriumWheelTravel_m],"AbsTol",1e-12);
        end
        function separatedFlatsDoNotBridgeValidRegion(testCase)
            m = springDamperFixture(0); z = (-.11:.01:-.01)';
            c = [-.004;-.004;-.004;.003;.006;.003;-.004;-.004;-.004;-.004;-.004];
            r = local(m,z,c);
            testCase.verifyEqual(r.rootCount,1);
            testCase.verifyEqual(r.roots.equilibriumWheelTravel_m,-.07,"AbsTol",1e-12);
            testCase.verifyTrue(all(r.flatIntervals_m(:,2) <= -.09+1e-12 | ...
                r.flatIntervals_m(:,1) >= -.05-1e-12));
        end
        function flatBeforeInvalidLimitPreservesGap(testCase)
            [~,a,~,d,u] = springDamperFixture(0);
            d.damper.maximumLength = a.damper.staticLength_m+.006;
            m = fsd.model.createSpringDamperModel(a,d,u);
            z = [-.04;-.03;-.02;-.01]; c = [-.004;-.004;-.004;-.012];
            r = local(m,z,c);
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyEqual(r.validSampleMask,[true;true;true;false]);
            testCase.verifyEqual(r.flatIntervals_m,[-.04,-.03;-.03,-.02]);
            testCase.verifyFalse(r.validSegmentMask(3));
        end
        function pointIntervalRemainsOneRootNotFlat(testCase)
            m = springDamperFixture(0); z = [-.04;-.025;-.01];
            p = fsd.analysis.analyzePrescribedSpringDamperPath(m,z,.5*z,0, ...
                struct("length","m","velocity","m/s"));
            r = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,0, ...
                struct("travelInterval_m",[-.025,-.025]));
            testCase.verifyEqual(r.rootCount,1);
            testCase.verifyEmpty(r.flatIntervals_m);
            testCase.verifyEqual(r.equilibriumWheelTravel_m,-.025);
        end
        function unseatedPrefixBeforeFailureDoesNotInventFlat(testCase)
            [m,a,g] = springDamperFixture(0);
            b = fsd.kinematics.solveBumpSweep(g,[-.02;-.015;-.01;.5;.02],"m");
            s = fsd.kinematics.solveActuationSweep(a,b);
            aa = fsd.analysis.analyzeActuationSweep(a,s);
            p = fsd.analysis.analyzeSpringDamperSweep(m,a,s,aa,0,"m/s");
            r = fsd.analysis.solveCornerStaticEquilibrium(m,a,p,0);
            testCase.verifyEqual(s.results(5).status,"NOT_ATTEMPTED");
            % Historical source marks MR unavailable for this failed sweep;
            % axial unseating is NOT evidence of a validated wheel-force flat.
            testCase.verifyEqual(p.springStatus(1:3),repmat("SPRING_UNSEATED",3,1));
            testCase.verifyTrue(all(isnan(p.damperMotionRatio)));
            testCase.verifyFalse(any(r.validSampleMask(4:5)));
            testCase.verifyFalse(any(r.validSegmentMask(3:4)));
            testCase.verifyEmpty(r.flatIntervals_m);
            testCase.verifyEqual(r.rootCount,0);
            testCase.verifyFalse(r.selectionAvailable);
            testCase.verifyTrue(fsd.analysis.validateCornerStaticEquilibrium(r));
        end
        function adversarialFlatsRootsAndDiagnosticsRejected(testCase)
            m = springDamperFixture(0); z = [-.04;-.025;-.01]; r = local(m,z,.5*z);
            for i = 1:4
                bad = r;
                switch i
                    case 1, bad.flatIntervals_m(1,1) = -.05;
                    case 2, bad.rootCount = 1;
                    case 3, bad.roots = bad.selectedRoot;
                    case 4, bad.flatIntervalFilterDiagnostics.intervalAdvanceCount = 0;
                end
                testCase.verifyError(@() fsd.analysis.validateCornerStaticEquilibrium(bad), ...
                    "fsd:analysis:InvalidCornerEquilibrium");
            end
        end
    end
end

function result = local(model,z,c)
p = fsd.analysis.analyzePrescribedSpringDamperPath(model,z,c,0, ...
    struct("length","m","velocity","m/s"));
result = fsd.analysis.solveCornerStaticEquilibrium(model,[],p,0);
end
