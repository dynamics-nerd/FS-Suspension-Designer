classdef TestStaticLoadAudit < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function setup(testCase)
            previous = path; testCase.addTeardown(@() path(previous));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function mandatoryBoundaryReproductions(testCase)
            xy = [0,-.5;2,.5;1,-.5];
            expected = [1000,0,0,0;0,0,0,1000;500,0,500,0];
            for i = 1:3
                v = atCG(xy(i,:)); r = analyze(v,"UNDERDETERMINED");
                verifyPoint(testCase,v,r,expected(i,:)');
            end
        end
        function allFourVertices(testCase)
            xy = [0,-.5;0,.5;2,-.5;2,.5];
            for i = 1:4
                v = atCG(xy(i,:)); r = analyze(v,"UNDERDETERMINED");
                expected = zeros(4,1); expected(i) = 1000;
                verifyPoint(testCase,v,r,expected);
            end
        end
        function allFourEdges(testCase)
            xy = [0,0;2,0;1,-.5;1,.5];
            expected = [500,500,0,0;0,0,500,500;500,0,500,0;0,500,0,500];
            for i = 1:4
                v = atCG(xy(i,:)); r = analyze(v,"UNDERDETERMINED");
                verifyPoint(testCase,v,r,expected(i,:)');
            end
        end
        function genuinelyInsideAndOutside(testCase)
            for distance = [1e-10,1e-7]
                inside = analyze(atCG([1,.5-distance]),"UNDERDETERMINED");
                outside = analyze(atCG([1,.5+distance]),"UNDERDETERMINED");
                testCase.verifyTrue(inside.family.feasible);
                testCase.verifyEqual(inside.family.admissibleDimension,1);
                testCase.verifyFalse(outside.family.feasible);
                testCase.verifyEqual(outside.status,"NO_FEASIBLE_FOUR_CONTACT_LOADS");
                testCase.verifyGreaterThan(diff(-outside.family.rawLambdaInterval_N), ...
                    outside.family.lambdaBoundaryBudget_N);
            end
        end
        function unresolvedRepresentationalBoundary(testCase)
            v = atCG([1,.5+eps(.5)]); r = analyze(v,"UNDERDETERMINED");
            testCase.verifyTrue(r.family.feasible);
            testCase.verifyEqual(r.family.intervalClassification,"POINT_WITHIN_ROUNDOFF");
            testCase.verifyEqual(r.family.degreeOfFreedom,1);
            verifyBalance(testCase,v,r.family.endpointLoads_N(:,1),1e-9);
        end
        function unequalTracksAndNonDefaultGravity(testCase)
            [~,d,u] = vehicleFixture(); d.frontTrack = 1.2; d.rearTrack = .8;
            d.gravity_mps2 = 5; d.cg = [1,-.5,.3];
            v = fsd.model.createVehicleParameters(d,u); r = analyze(v,"UNDERDETERMINED");
            verifyPoint(testCase,v,r,[250;0;250;0]);
            d.cg(2) = -.5-1e-9;
            r = analyze(fsd.model.createVehicleParameters(d,u),"UNDERDETERMINED");
            testCase.verifyFalse(r.family.feasible);
        end
        function nonRectangularExplicitContactEdgesAndVertices(testCase)
            [~,d,u] = vehicleFixture();
            d.contactPoints = [0,-.6,0;.1,.7,0;2,-.4,0;2.2,.5,0];
            for i = 1:4
                d.cg = d.contactPoints(i,:)+[0,0,.3];
                v = fsd.model.createVehicleParameters(d,u); r = analyze(v,"UNDERDETERMINED");
                expected = zeros(4,1); expected(i) = 1000;
                verifyPoint(testCase,v,r,expected);
            end
            edges = [1,2;2,4;4,3;3,1];
            for i = 1:4
                d.cg = mean(d.contactPoints(edges(i,:),:),1)+[0,0,.3];
                v = fsd.model.createVehicleParameters(d,u); r = analyze(v,"UNDERDETERMINED");
                expected = zeros(4,1); expected(edges(i,:)) = 500;
                verifyPoint(testCase,v,r,expected);
            end
        end
        function conditioningChangesArithmeticBudget(testCase)
            [~,d,u] = vehicleFixture(); a = analyze(atCG([1,0]),"UNDERDETERMINED");
            d.frontTrack = 1e-3; d.rearTrack = 1e-3;
            b = analyze(fsd.model.createVehicleParameters(d,u),"UNDERDETERMINED");
            testCase.verifyGreaterThan(b.family.loadRoundoff_N,a.family.loadRoundoff_N);
            testCase.verifyLessThan(b.family.reciprocalCondition,a.family.reciprocalCondition);
            testCase.verifyEqual(a.forceTolerance_N,b.forceTolerance_N);
        end
        function crossweightBothLimitsAndTransitions(testCase)
            v = atCG([.4,0]);
            for limit = [.3,.7]
                direction = sign(.5-limit);
                for cw = [limit,limit+direction*1e-10,limit-direction*eps(limit)]
                    r = analyze(v,"CROSSWEIGHT_SPECIFIED",cw);
                    testCase.verifyEqual(r.status,"CALCULATED_CORNER_LOADS");
                    testCase.verifyGreaterThanOrEqual(min(r.cornerLoads_N),0);
                    testCase.verifyEqual(r.loadCase.definitionSI.crossweightFraction,cw);
                    verifyBalance(testCase,v,r.cornerLoads_N,1e-9);
                    testCase.verifyEqual(sum(r.cornerLoads_N([2,3])),1000*cw,"AbsTol",1e-9);
                    testCase.verifyTrue(fsd.analysis.validateStaticVehicleLoads(r,v));
                end
                for cw = [limit-direction*1e-10,limit-direction*.01]
                    r = analyze(v,"CROSSWEIGHT_SPECIFIED",cw);
                    testCase.verifyEqual(r.status,"INFEASIBLE_CROSSWEIGHT");
                    testCase.verifyTrue(all(isnan(r.cornerLoads_N)));
                    testCase.verifyTrue(all(isnan(r.supportForce_N)));
                end
            end
        end
        function exactNegativeNormalReproduction(testCase)
            v = atCG([.4,0]); requested = .3-1e-10;
            r = analyze(v,"CROSSWEIGHT_SPECIFIED",requested);
            testCase.verifyEqual(r.status,"INFEASIBLE_CROSSWEIGHT");
            testCase.verifyEqual(r.loadCase.definitionSI.crossweightFraction,requested);
            testCase.verifyEqual(r.candidateCornerLoads_N(3),-5e-8,"AbsTol",1e-12);
            testCase.verifyLessThan(r.normalRoundoffBudget_N,5e-8);
            testCase.verifyTrue(all(isnan(r.cornerLoads_N)));
            testCase.verifyTrue(all(isnan(r.supportForce_N)));
        end
        function originalMeasurementsExactlyPreserved(testCase)
            v = atCG([1,0]);
            for tiny = [1e-12,1e-9,0]
                measurement = [tiny;500;500;0]; r = analyze(v,"MEASURED_CORNER_LOADS",measurement);
                testCase.verifyEqual(r.cornerLoads_N,measurement);
                testCase.verifyEqual(r.candidateCornerLoads_N,measurement);
                testCase.verifyEqual(r.loadCase.definitionSI.measuredCornerLoads_N,measurement);
                testCase.verifyTrue(fsd.analysis.validateStaticVehicleLoads(r,v));
            end
        end
        function measuredDiscrepanciesAreNotCorrected(testCase)
            v = atCG([1,0]);
            measurements = [250,250,250,250;251,250,250,250; ...
                300,300,200,200;300,200,300,200];
            residuals = [0,0,0;1,0,-.5;0,-200,0;0,0,-100];
            for i = 1:4
                r = analyze(v,"MEASURED_CORNER_LOADS",measurements(i,:)');
                testCase.verifyEqual(r.cornerLoads_N,measurements(i,:)');
                testCase.verifyEqual(r.balanceResidual,residuals(i,:)');
                if i > 1
                    testCase.verifyEqual(r.status,"MEASURED_LOADS_INCONSISTENT");
                    testCase.verifyTrue(all(isnan(r.supportForce_N)));
                end
            end
            testCase.verifyError(@() analyze(v,"MEASURED_CORNER_LOADS",[-1;500;500;0]), ...
                "fsd:model:InvalidVehicleParameters");
        end
        function negativeSupportIsNotClipped(testCase)
            [~,d,u] = vehicleFixture(); d.unsprungMass = [25+5e-9,25,25,25-5e-9];
            v = fsd.model.createVehicleParameters(d,u); r = analyze(v,"ASSUMED_SYMMETRIC_BASELINE");
            testCase.verifyLessThan(r.candidateSupportForce_N(1),-4.9e-8);
            testCase.verifyEqual(r.supportStatus(1),"NEGATIVE_LOCAL_SUPPORT_DEMAND");
            testCase.verifyTrue(isnan(r.supportForce_N(1)));
            testCase.verifyEqual(r.supportForce_N(2:3),[0;0],"AbsTol",1e-10);
            testCase.verifyGreaterThan(r.supportForce_N(4),0);
        end
        function supportRoundoffIsExplicitlyUnresolved(testCase)
            [~,d,u] = vehicleFixture(); d.unsprungMass = [25+eps(25),24,25,25];
            v = fsd.model.createVehicleParameters(d,u);
            r = analyze(v,"MEASURED_CORNER_LOADS",repmat(250,4,1));
            testCase.verifyLessThan(r.candidateSupportForce_N(1),0);
            testCase.verifyGreaterThanOrEqual(r.candidateSupportForce_N(1),-r.supportRoundoffBudget_N(1));
            testCase.verifyEqual(r.supportStatus(1),"LOCAL_SUPPORT_NUMERICALLY_UNRESOLVED");
            testCase.verifyTrue(isnan(r.supportForce_N(1)));
            testCase.verifyEqual(r.supportForce_N(3:4),[0;0]);
        end
        function infeasibleLoadsCannotBecomeLocalDemand(testCase)
            v = atCG([.4,0]); bad = analyze(v,"CROSSWEIGHT_SPECIFIED",.3-1e-10);
            m = springDamperFixture(0); z = [-.04;-.025;-.01];
            p = fsd.analysis.analyzePrescribedSpringDamperPath(m,z,.5*z,0, ...
                struct("length","m","velocity","m/s"));
            testCase.verifyError(@() fsd.analysis.solveCornerStaticEquilibrium(m,[],p,bad.supportForce_N(3)), ...
                "fsd:analysis:InvalidCornerEquilibrium");
            v = atCG([1,0]); measured = analyze(v,"MEASURED_CORNER_LOADS",[0;500;500;0]);
            zero = fsd.analysis.solveCornerStaticEquilibrium(m,[],p,measured.supportForce_N(1));
            testCase.verifyEqual(zero.status,"FLAT_EQUILIBRIUM_INTERVAL");
            testCase.verifyFalse(zero.selectionAvailable);
        end
        function validatorsRejectBoundaryAndMeasurementAttacks(testCase)
            v = atCG([0,-.5]); r = analyze(v,"UNDERDETERMINED");
            for i = 1:5
                bad = r;
                switch i
                    case 1, bad.family.lambdaInterval_N(1) = bad.family.lambdaInterval_N(1)+1;
                    case 2, bad.family.feasible = false;
                    case 3, bad.status = "NO_FEASIBLE_FOUR_CONTACT_LOADS";
                    case 4, bad.family.endpointLoads_N(2,1) = -1e-8;
                    case 5, bad.family.lambdaBoundaryBudget_N = 1;
                end
                testCase.verifyError(@() fsd.analysis.validateStaticVehicleLoads(bad,v), ...
                    "fsd:analysis:InvalidStaticLoads");
            end
            v = atCG([.4,0]); r = analyze(v,"CROSSWEIGHT_SPECIFIED",.3-1e-10);
            bad = r; bad.status = "CALCULATED_CORNER_LOADS"; bad.cornerLoads_N = r.candidateCornerLoads_N;
            bad.supportForce_N = zeros(4,1);
            testCase.verifyError(@() fsd.analysis.validateStaticVehicleLoads(bad,v),"fsd:analysis:InvalidStaticLoads");
            v = atCG([1,0]); r = analyze(v,"MEASURED_CORNER_LOADS",[1e-12;500;500;0]);
            bad = r; bad.cornerLoads_N(1) = 0;
            testCase.verifyError(@() fsd.analysis.validateStaticVehicleLoads(bad,v),"fsd:analysis:InvalidStaticLoads");
            bad = r; bad.loadCase.identity.operatingConfiguration = "OTHER";
            testCase.verifyError(@() fsd.analysis.validateStaticVehicleLoads(bad,v),"fsd:model:InvalidVehicleParameters");
        end
    end
end

function vehicle = atCG(xy)
[~,d,u] = vehicleFixture(); d.cg = [xy,.3]; d.unsprungMass = zeros(1,4);
vehicle = fsd.model.createVehicleParameters(d,u);
end

function result = analyze(vehicle,mode,value)
definition = struct("mode",mode,"sourceKind","KNOWN");
if mode == "ASSUMED_SYMMETRIC_BASELINE", definition.sourceKind = "ASSUMED"; end
if nargin > 2
    if mode == "CROSSWEIGHT_SPECIFIED", definition.crossweight = value;
    else, definition.measuredCornerLoads = value; end
end
loadCase = fsd.model.createVehicleLoadCase(vehicle,definition);
result = fsd.analysis.analyzeStaticVehicleLoads(vehicle,loadCase);
end

function verifyPoint(testCase,vehicle,result,expected)
testCase.verifyTrue(result.family.feasible);
testCase.verifyEqual(result.status,"CORNER_LOADS_UNDERDETERMINED");
testCase.verifyEqual(result.family.degreeOfFreedom,1);
testCase.verifyEqual(result.family.admissibleDimension,0);
testCase.verifyEqual(diff(result.family.lambdaInterval_N),0);
testCase.verifyEqual(result.family.endpointLoads_N,[expected,expected],"AbsTol",1e-9);
testCase.verifyGreaterThanOrEqual(min(result.family.endpointLoads_N,[],"all"),0);
testCase.verifyTrue(all(isnan(result.cornerLoads_N))); % no implicit fourth condition
verifyBalance(testCase,vehicle,result.family.endpointLoads_N(:,1),1e-9);
testCase.verifyTrue(fsd.analysis.validateStaticVehicleLoads(result,vehicle));
end

function verifyBalance(testCase,vehicle,normal,tolerance)
weight = vehicle.totalMass_kg*vehicle.definitionSI.gravity_mps2;
testCase.verifyEqual(sum(normal),weight,"AbsTol",tolerance);
testCase.verifyEqual(vehicle.contactPoints_m(:,1)'*normal,weight*vehicle.cg_m(1),"AbsTol",tolerance);
testCase.verifyEqual(vehicle.contactPoints_m(:,2)'*normal,weight*vehicle.cg_m(2),"AbsTol",tolerance);
end
