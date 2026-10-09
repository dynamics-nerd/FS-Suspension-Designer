classdef TestStaticVehicleLoads < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function setup(testCase)
            oldPath = path; testCase.addTeardown(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function mandatoryNonuniqueFamily(testCase)
            v = vehicleFixture(); r = loads(v,"UNDERDETERMINED");
            testCase.verifyEqual(r.status,"CORNER_LOADS_UNDERDETERMINED");
            testCase.verifyTrue(all(isnan(r.cornerLoads_N)));
            testCase.verifyEqual(r.family.degreeOfFreedom,1);
            testCase.verifyEqual(r.family.cornerLoadBounds_N,repmat([0,500],4,1),"AbsTol",1e-10);
            for delta = [-250,-100,0,123,250]
                N = [250+delta;250-delta;250-delta;250+delta];
                testCase.verifyEqual(r.family.matrixA*N,r.family.rhs,"AbsTol",1e-10);
                lambda = (N(1)-r.family.particular_N(1))/r.family.nullDirection(1);
                testCase.verifyEqual(r.family.particular_N+lambda*r.family.nullDirection,N,"AbsTol",1e-10);
            end
        end
        function longitudinalFractionAndCGHeight(testCase)
            [~,d,u] = vehicleFixture(); d.cg(1) = .8;
            v = fsd.model.createVehicleParameters(d,u); r = loads(v,"UNDERDETERMINED");
            testCase.verifyEqual([r.frontAxleLoad_N,r.rearAxleLoad_N],[600,400],"AbsTol",1e-10);
            d.cg(3) = 2; high = loads(fsd.model.createVehicleParameters(d,u),"UNDERDETERMINED");
            testCase.verifyEqual(high.family.cornerLoadBounds_N,r.family.cornerLoadBounds_N,"AbsTol",1e-10);
            testCase.verifyEqual(high.frontAxleLoad_N,r.frontAxleLoad_N,"AbsTol",1e-10);
        end
        function unequalTracksLateralCGCrossweightBenchmark(testCase)
            [~,d,u] = vehicleFixture(); d.frontTrack = 1.2; d.rearTrack = 1; d.cg = [.8,.06,.5];
            v = fsd.model.createVehicleParameters(d,u);
            c = fsd.model.createVehicleLoadCase(v,struct("mode","CROSSWEIGHT_SPECIFIED", ...
                "crossweight",.55,"sourceKind","KNOWN"));
            r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
            % Independent elimination: front total600, rear400, FR+RL550,
            % -.6*FL+.6*FR-.5*RL+.5*RR=60.
            expected = [250;350;200;200];
            testCase.verifyEqual(r.cornerLoads_N,expected,"AbsTol",1e-10);
            testCase.verifyEqual(r.crossweightFraction,.55,"AbsTol",1e-14);
            testCase.verifyTrue(r.fourContactBalanceSatisfied);
            testCase.verifyTrue(fsd.analysis.validateStaticVehicleLoads(r,v,c));
        end
        function fiftyPercentCWIsNotFiftyPercentFront(testCase)
            [~,d,u] = vehicleFixture(); d.cg(1) = .8; v = fsd.model.createVehicleParameters(d,u);
            c = fsd.model.createVehicleLoadCase(v,struct("mode","CROSSWEIGHT_SPECIFIED", ...
                "crossweight",50,"sourceKind","TARGET"),struct("force","N","crossweight","%"));
            r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
            testCase.verifyEqual(r.cornerLoads_N,[300;300;200;200],"AbsTol",1e-10);
            testCase.verifyEqual(r.frontAxleLoad_N/1000,.6,"AbsTol",1e-14);
        end
        function infeasibleCrossweightAndOutsideSupport(testCase)
            [~,d,u] = vehicleFixture(); d.cg(1) = .2; v = fsd.model.createVehicleParameters(d,u);
            c = fsd.model.createVehicleLoadCase(v,struct("mode","CROSSWEIGHT_SPECIFIED", ...
                "crossweight",0,"sourceKind","TARGET"));
            d.cg(2) = .45; v = fsd.model.createVehicleParameters(d,u);
            c = fsd.model.createVehicleLoadCase(v,c.definitionSI);
            r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
            testCase.verifyEqual(r.status,"INFEASIBLE_CROSSWEIGHT");
            testCase.verifyTrue(all(isnan(r.cornerLoads_N)));
            d.cg = [1,1,.3]; outside = loads(fsd.model.createVehicleParameters(d,u),"UNDERDETERMINED");
            testCase.verifyEqual(outside.status,"NO_FEASIBLE_FOUR_CONTACT_LOADS");
            testCase.verifyFalse(outside.family.feasible);
        end
        function assumedSymmetryMustBeCompatible(testCase)
            v = vehicleFixture(); r = loads(v,"ASSUMED_SYMMETRIC_BASELINE");
            testCase.verifyEqual(r.cornerLoads_N,repmat(250,4,1),"AbsTol",1e-10);
            testCase.verifyEqual(r.cornerLoadSourceKind,"ASSUMED");
            [~,d,u] = vehicleFixture(); d.cg(2) = .1; v = fsd.model.createVehicleParameters(d,u);
            r = loads(v,"ASSUMED_SYMMETRIC_BASELINE");
            testCase.verifyEqual(r.status,"SYMMETRY_ASSUMPTION_INCOMPATIBLE");
            testCase.verifyTrue(all(isnan(r.cornerLoads_N)));
        end
        function measuredValuesAndDiscrepancyPreserved(testCase)
            v = vehicleFixture();
            c = fsd.model.createVehicleLoadCase(v,struct("mode","MEASURED_CORNER_LOADS", ...
                "measuredCornerLoads",[300;200;200;300],"sourceKind","KNOWN"));
            r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
            testCase.verifyEqual(r.status,"MEASURED_LOADS_CONSISTENT");
            testCase.verifyEqual(r.crossweightFraction,.4);
            testCase.verifyEqual(r.inferredCG_m(1:2),[1,0]);
            c = fsd.model.createVehicleLoadCase(v,struct("mode","MEASURED_CORNER_LOADS", ...
                "measuredCornerLoads",[310;200;200;300],"sourceKind","KNOWN"));
            r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
            testCase.verifyEqual(r.cornerLoads_N,[310;200;200;300]);
            testCase.verifyEqual(r.balanceResidual(1),10);
            testCase.verifyEqual(r.status,"MEASURED_LOADS_INCONSISTENT");
            testCase.verifyEqual(r.crossweightFraction,.4);
            testCase.verifyEqual(r.complementaryDiagonalFraction,.61);
            testCase.verifyTrue(all(isnan(r.supportForce_N)));
        end
        function kgEquivalentUsesDeclaredGravity(testCase)
            [~,d,u] = vehicleFixture(); d.gravity_mps2 = 5; v = fsd.model.createVehicleParameters(d,u);
            c = fsd.model.createVehicleLoadCase(v,struct("mode","MEASURED_CORNER_LOADS", ...
                "measuredCornerLoads",[25;25;25;25],"sourceKind","KNOWN"), ...
                struct("force","kg_equivalent","crossweight","fraction"));
            r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
            testCase.verifyEqual(r.cornerLoads_N,repmat(125,4,1));
            testCase.verifyEqual(r.totalNormalDemand_N,500);
        end
        function missingLateralCGStillHasAxleLoads(testCase)
            [~,d,u] = vehicleFixture(); d.cg(2) = NaN; v = fsd.model.createVehicleParameters(d,u);
            r = loads(v,"UNDERDETERMINED");
            testCase.verifyEqual([r.frontAxleLoad_N,r.rearAxleLoad_N],[500,500]);
            testCase.verifyTrue(all(isnan(r.cornerLoads_N)));
            testCase.verifyEqual(r.family.degreeOfFreedom,2);
        end
        function sprungUnsprungSupportNotAxialForce(testCase)
            v = vehicleFixture(); r = loads(v,"ASSUMED_SYMMETRIC_BASELINE");
            testCase.verifyEqual(r.supportForce_N,[230;220;210;200],"AbsTol",1e-10);
            [~,d,u] = vehicleFixture(); d.unsprungMass(1) = NaN; v = fsd.model.createVehicleParameters(d,u);
            r = loads(v,"ASSUMED_SYMMETRIC_BASELINE");
            testCase.verifyTrue(isnan(r.supportForce_N(1)));
            testCase.verifyEqual(r.cornerLoads_N,repmat(250,4,1),"AbsTol",1e-10);
        end
        function explicitContactsAreNotWheelCenters(testCase)
            [~,d,u] = vehicleFixture();
            d.contactPoints = [0,-.6,0;0,.6,0;2,-.5,0;2,.5,0]; d.cg = [.8,.06,.3];
            v = fsd.model.createVehicleParameters(d,u);
            c = fsd.model.createVehicleLoadCase(v,struct("mode","CROSSWEIGHT_SPECIFIED", ...
                "crossweight",.55,"sourceKind","KNOWN"));
            r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
            testCase.verifyEqual(r.family.matrixA(3,:),[-.6,.6,-.5,.5]);
            d.contactPoints(:,1) = d.contactPoints(:,1)+.1;
            d.cg(1) = NaN; d.rearWeightFraction = .4;
            v = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(v.cg_m(1),.9,"AbsTol",1e-14);
            r = loads(v,"UNDERDETERMINED");
            testCase.verifyEqual(r.frontAxleLoad_N,600,"AbsTol",1e-10);
        end
        function validatorsRejectLoadMutations(testCase)
            v = vehicleFixture(); r = loads(v,"ASSUMED_SYMMETRIC_BASELINE");
            for scenario = 1:7
                bad = r;
                switch scenario
                    case 1, bad.cornerLoads_N(1) = 251;
                    case 2, bad.frontAxleLoad_N = 501;
                    case 3, bad.rearAxleLoad_N = 501;
                    case 4, bad.crossweightFraction = .6;
                    case 5, bad.family.nullDirection(1) = 0;
                    case 6, bad.supportForce_N(1) = 250;
                    case 7, bad.vehicleIdentity.totalMass_kg = 99;
                end
                testCase.verifyError(@() fsd.analysis.validateStaticVehicleLoads(bad,v),"fsd:analysis:InvalidStaticLoads");
            end
            [~,d,u] = vehicleFixture(); d.totalMass = 101; other = fsd.model.createVehicleParameters(d,u);
            testCase.verifyError(@() fsd.analysis.validateStaticVehicleLoads(r,other),"fsd:model:InvalidVehicleParameters");
        end
        function caseComparisonAndPlotIndeterminate(testCase)
            [v,d,u] = vehicleFixture(); a = loads(v,"UNDERDETERMINED");
            d.totalMass = 110; w = fsd.model.createVehicleParameters(d,u); b = loads(w,"UNDERDETERMINED");
            c = fsd.analysis.compareStaticVehicleCases(v,a,w,b);
            testCase.verifyEqual(c.deltaTotalMass_kg,10);
            testCase.verifyEqual(c.deltaFrontAxleLoad_N,50,"AbsTol",1e-10);
            testCase.verifyTrue(all(isnan(c.deltaCornerLoads_N)));
            f = figure("Visible","off"); testCase.addTeardown(@() close(f));
            h = fsd.analysis.plotStaticVehicleLoads(v,a,f);
            testCase.verifyEmpty(findobj(h.axes(2),"Type","bar"));
        end
    end
end

function r = loads(v,mode)
source = "DERIVED"; if mode == "ASSUMED_SYMMETRIC_BASELINE", source = "ASSUMED"; end
c = fsd.model.createVehicleLoadCase(v,struct("mode",mode,"sourceKind",source));
r = fsd.analysis.analyzeStaticVehicleLoads(v,c);
end
