classdef TestVehicleParameters < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function setup(testCase)
            oldPath = path; testCase.addTeardown(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function totalMassModeAndIdentity(testCase)
            v = vehicleFixture();
            testCase.verifyEqual(v.totalMass_kg,100);
            testCase.verifyEqual(v.cg_m,[1,0,.3]);
            testCase.verifyEqual(v.sprungMass_kg,86);
            testCase.verifyTrue(fsd.model.validateVehicleParameters(v));
            testCase.verifyTrue(fsd.model.validateVehicleIdentity(fsd.model.vehicleIdentity(v)));
        end
        function componentDriverFuelBallastComposition(testCase)
            [d,u] = componentDefinition();
            v = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(v.totalMass_kg,270);
            testCase.verifyEqual(v.cg_m,[232,4,97]/270,"AbsTol",1e-14);
            testCase.verifyEqual(v.massSourceKind,"DERIVED");
            testCase.verifyTrue(fsd.model.validateVehicleParameters(v));
        end
        function vehicleAloneAndDifferentDriver(testCase)
            [d,u] = componentDefinition(); d.components = d.components(1);
            alone = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(alone.totalMass_kg,200);
            d.components(2) = struct("id","DRIVER_B","mass",80,"cg",[1,0,.6], ...
                "includes","DRIVER","sourceKind","ASSUMED");
            withDriver = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(withDriver.totalMass_kg,280);
            testCase.verifyEqual(withDriver.cg_m,[240,0,108]/280,"AbsTol",1e-14);
            testCase.verifyNotEqual(alone.identity,withDriver.identity);
        end
        function ballastIsIndependentComponent(testCase)
            [d,u] = componentDefinition();
            d.components(4) = struct("id","BALLAST","mass",10,"cg",[0,0,.1], ...
                "includes","BALLAST","sourceKind","KNOWN");
            v = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(v.totalMass_kg,280);
            testCase.verifyEqual(v.cg_m,[232,4,98]/280,"AbsTol",1e-14);
        end
        function missingComponentPositionPreservesKnownCoordinates(testCase)
            [d,u] = componentDefinition(); d.components(2).cg = [NaN,.1,NaN];
            v = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(v.totalMass_kg,270);
            testCase.verifyTrue(all(isnan(v.cg_m([1,3]))));
            testCase.verifyEqual(v.cg_m(2),4/270,"AbsTol",1e-15);
            testCase.verifyEqual(v.cgSourceKind(1),"UNAVAILABLE");
        end
        function overlappingInventoryAndDuplicateIdsRejected(testCase)
            [d,u] = componentDefinition(); d.components(1).includes = ["BASE","FUEL"];
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
            [d,u] = componentDefinition(); d.components(2).id = "BASE";
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
        end
        function modesCannotBeMixed(testCase)
            [~,d,u] = vehicleFixture(); d.components = struct("id","DRIVER","mass",60, ...
                "cg",[1,0,.5],"includes","DRIVER","sourceKind","KNOWN");
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
        end
        function fractionsDeriveXAndDetectContradiction(testCase)
            [~,d,u] = vehicleFixture(); d.cg = [NaN,NaN,.3]; d.frontWeightFraction = .6;
            v = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(v.cg_m(1),.8,"AbsTol",1e-15);
            testCase.verifyTrue(isnan(v.cg_m(2))); testCase.verifyEqual(v.cgSourceKind(1),"DERIVED");
            d.rearWeightFraction = .5;
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
            d.rearWeightFraction = .4; d.cg(1) = 1;
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
        end
        function unitsAndGravityAreExplicit(testCase)
            [v,d,u] = vehicleFixture();
            d.wheelbase = 2000; d.frontTrack = 1000; d.rearTrack = 1000; d.cg = [1000,0,300];
            u.length = "mm"; mm = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(mm.identity,v.identity);
            d.gravity_mps2 = 5; other = fsd.model.createVehicleParameters(d,u);
            testCase.verifyEqual(other.definitionSI.gravity_mps2,5);
            d = rmfield(d,"gravity_mps2");
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
        end
        function unknownUnsprungAndInvalidMasses(testCase)
            [~,d,u] = vehicleFixture(); d.unsprungMass(2) = NaN;
            v = fsd.model.createVehicleParameters(d,u);
            testCase.verifyTrue(isnan(v.sprungMass_kg));
            testCase.verifyTrue(isnan(v.unsprungMass_kg(2)));
            d.unsprungMass = [40,40,40,0];
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
            d.unsprungMass = [0,0,0,0]; d.totalMass = -1;
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
            d.totalMass = Inf;
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
        end
        function payloadMutationAndMetadataIdentity(testCase)
            v = vehicleFixture(); bad = v; bad.totalMass_kg = 101;
            testCase.verifyError(@() fsd.model.validateVehicleParameters(bad),"fsd:model:InvalidVehicleParameters");
            bad = v; bad.cg_m(2) = .1;
            testCase.verifyError(@() fsd.model.validateVehicleParameters(bad),"fsd:model:InvalidVehicleParameters");
            v.metadata.displayName = "Renamed";
            testCase.verifyTrue(fsd.model.validateVehicleParameters(v));
            testCase.verifyEqual(fsd.model.vehicleIdentity(v),v.identity);
        end
        function matRoundTripAndContactValidation(testCase)
            v = vehicleFixture(); file = [tempname,'.mat'];
            testCase.addTeardown(@() delete(file)); save(file,"v"); stored = load(file,"v");
            testCase.verifyTrue(fsd.model.validateVehicleParameters(stored.v));
            [~,d,u] = vehicleFixture(); d.contactPoints = repmat([0,0,0],4,1);
            testCase.verifyError(@() fsd.model.createVehicleParameters(d,u),"fsd:model:InvalidVehicleParameters");
        end
    end
end

function [d,u] = componentDefinition()
[~,d,u] = vehicleFixture(); d = rmfield(d,["totalMass","cg","includes"]);
d.massMode = "COMPONENT_MASSES";
d.components = [struct("id","BASE","mass",200,"cg",[.8,0,.3],"includes","BASE", ...
    "sourceKind","KNOWN");struct("id","DRIVER","mass",60,"cg",[1,.1,.6], ...
    "includes","DRIVER","sourceKind","ASSUMED");struct("id","FUEL","mass",10, ...
    "cg",[1.2,-.2,.1],"includes","FUEL","sourceKind","KNOWN")];
end
