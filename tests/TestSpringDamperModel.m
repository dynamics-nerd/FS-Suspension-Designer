classdef TestSpringDamperModel < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function setup(testCase)
            originalPath = path;
            testCase.addTeardown(@() path(originalPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function staticSeatGeometryAndIdentity(testCase)
            [m,a] = springDamperFixture();
            testCase.verifyTrue(fsd.model.validateSpringDamperModel(m));
            testCase.verifyTrue(fsd.model.validateSpringDamperIdentity(m.identity));
            testCase.verifyEqual(m.derivedStaticGeometry.springSeatSeparationStatic_m,0.18,"AbsTol",1e-14);
            testCase.verifyEqual(m.derivedStaticGeometry.springSeatOffset_m,0.18-a.damper.staticLength_m,"AbsTol",1e-14);
            testCase.verifyFalse(isfield(a,"spring"));
        end
        function signedSeatOffset(testCase)
            [~,a,~,d,u] = springDamperFixture();
            d.spring.freeLength = 0.10;
            m = fsd.model.createSpringDamperModel(a,d,u);
            testCase.verifyLessThan(m.derivedStaticGeometry.springSeatOffset_m,0);
        end
        function unitsEquivalent(testCase)
            [m,a,~,d,u] = springDamperFixture();
            d.spring.rate = d.spring.rate/1000;
            d.spring.freeLength = d.spring.freeLength*1000;
            d.spring.preloadCompression = d.spring.preloadCompression*1000;
            d.damper.compressionCoefficient = d.damper.compressionCoefficient/1000;
            d.damper.reboundCoefficient = d.damper.reboundCoefficient/1000;
            u.length = "mm"; u.springRate = "N/mm";
            u.dampingCoefficient = "N/(mm/s)"; u.velocity = "mm/s";
            other = fsd.model.createSpringDamperModel(a,d,u);
            testCase.verifyEqual(m.identity,other.identity);
            testCase.verifyEqual(fsd.model.convertMechanicalUnits(30000,"wheelRate","N/m","N/mm"),30);
        end
        function parameterChangesChangeIdentityMetadataDoesNot(testCase)
            [m,a,~,d,u] = springDamperFixture();
            d.metadata.note = "Display only";
            other = fsd.model.createSpringDamperModel(a,d,u);
            testCase.verifyEqual(other.identity,m.identity);
            d.spring.rate = 40000;
            other = fsd.model.createSpringDamperModel(a,d,u);
            testCase.verifyNotEqual(other.identity,m.identity);
            d.spring.rate = 30000; d.damper.reboundCoefficient = 2600;
            other = fsd.model.createSpringDamperModel(a,d,u);
            testCase.verifyNotEqual(other.identity,m.identity);
        end
        function rejectsInvalidSpringAndDamperParameters(testCase)
            [~,a,~,d,u] = springDamperFixture();
            for rate = [0,-1,NaN,Inf]
                bad = d; bad.spring.rate = rate;
                expected = "fsd:model:InvalidSpringDamperModel";
                if ~isfinite(rate), expected = "MATLAB:expectedFinite"; end
                testCase.verifyError(@() fsd.model.createSpringDamperModel(a,bad,u),expected);
            end
            bad = d; bad.spring.preloadCompression = -1;
            testCase.verifyError(@() fsd.model.createSpringDamperModel(a,bad,u),"fsd:model:InvalidSpringDamperModel");
            bad = d; bad.spring.preloadCompression = bad.spring.freeLength;
            testCase.verifyError(@() fsd.model.createSpringDamperModel(a,bad,u),"fsd:model:InvalidSpringDamperModel");
            bad = d; bad.damper.reboundCoefficient = -1;
            testCase.verifyError(@() fsd.model.createSpringDamperModel(a,bad,u),"fsd:model:InvalidSpringDamperModel");
            bad = d; bad.spring.rate = [1,2];
            testCase.verifyError(@() fsd.model.createSpringDamperModel(a,bad,u),"fsd:model:InvalidSpringDamperModel");
        end
        function rejectsBoundsUnitsAndIdentityManipulation(testCase)
            [m,a,~,d,u] = springDamperFixture();
            bad = d; bad.damper.minimumLength = 0.2; bad.damper.maximumLength = 0.1;
            testCase.verifyError(@() fsd.model.createSpringDamperModel(a,bad,u),"fsd:model:InvalidSpringDamperModel");
            bad = d; bad.spring.solidHeight = 0;
            testCase.verifyError(@() fsd.model.createSpringDamperModel(a,bad,u),"fsd:model:InvalidSpringDamperModel");
            u.velocity = "km/h";
            testCase.verifyError(@() fsd.model.createSpringDamperModel(a,d,u),"fsd:model:InvalidMechanicalUnit");
            m.spring.rate_N_per_m = m.spring.rate_N_per_m+1;
            testCase.verifyError(@() fsd.model.validateSpringDamperModel(m),"fsd:model:InvalidSpringDamperModel");
        end
        function validatesTabulatedCharacteristics(testCase)
            [~,a,~,d,u] = springDamperFixture();
            d.damper = struct("modelType","TABULATED_FORCE_VELOCITY", ...
                "compressionTable",[0,0;0.1,100;0.2,90], ...
                "reboundTable",[0,0;0.1,200;0.2,250]);
            m = fsd.model.createSpringDamperModel(a,d,u);
            testCase.verifyTrue(fsd.model.validateSpringDamperModel(m));
            cases = {[0,1;0.1,100],[0,0;0,100],[0,0;0.1,-1],[0,0]};
            for i = 1:numel(cases)
                d.damper.compressionTable = cases{i};
                testCase.verifyError(@() fsd.model.createSpringDamperModel(a,d,u),"fsd:model:InvalidSpringDamperModel");
            end
        end
        function matRoundTrip(testCase)
            [model,~,geometry] = springDamperFixture();
            file = string(tempname)+".mat";
            testCase.addTeardown(@() delete(file));
            save(file,"model","geometry");
            loaded = load(file,"model","geometry");
            testCase.verifyEqual(loaded.model,model);
            testCase.verifyTrue(fsd.model.validateSpringDamperModel(loaded.model));
            testCase.verifyTrue(fsd.model.validateDoubleWishboneGeometry(loaded.geometry));
        end
    end
end
