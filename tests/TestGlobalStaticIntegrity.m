classdef TestGlobalStaticIntegrity < matlab.unittest.TestCase
    properties (TestParameter)
        tamperField = {"heave","pitch","roll","travel","normal","tireCompression", ...
            "springForce","mass","cg","crossweight","contact","equilibrium", ...
            "energy","forceResidual","momentResidual","identity","stability"}
    end
    methods (Test)
        function reconstructedPayloadRejectsTampering(t,tamperField)
            [s,o] = globalStaticFixture;
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[-.005;zeros(6,1)],o);
            a = r.attempts{1}.solution; state = a.state;
            switch tamperField
                case "heave", state.q(1) = state.q(1)+.001;
                case "pitch", state.q(2) = state.q(2)+.001;
                case "roll", state.q(3) = state.q(3)+.001;
                case "travel", state.q(4) = state.q(4)+.001;
                case "normal", state.normalForces_N(1) = 501;
                case "tireCompression", state.corners{1}.tire.tireCompression_m = .006;
                case "springForce", state.corners{1}.spring.springAxialForce_N = 1001;
                case "mass", state.sprungMass_kg = 201;
                case "cg", state.totalCgWorld_m(1) = .9;
                case "crossweight", state.crossweightActualSumFraction = .6;
                case "contact", state.corners{1}.tire.contactStatus = "AIRBORNE";
                case "equilibrium", a.converged = false;
                case "energy", state.potentialEnergy_J = state.potentialEnergy_J+1;
                case "forceResidual", state.worldForceResidual_N = 1;
                case "momentResidual", state.worldMomentResidual_Nm(1) = 1;
                case "identity", state.systemIdentity.vehicle.totalMass_kg = 201;
                case "stability", a.stability = "NON_RESTORING_STATIONARY_POINT";
            end
            a.state = state; r.attempts{1}.solution = a;
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(r,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
        end
        function unitsAndTireIdentity(t)
            s = globalStaticFixture; tire = s.tires{1};
            d = struct("cornerId","FL","modelType","LINEAR_VERTICAL_UNILATERAL", ...
                "stiffness",100,"unloadedRadius",250,"sourceKind","ASSUMED","sourceNote","Benchmark");
            a = fsd.model.createVerticalTireModel(d,struct("length","mm","stiffness","N/mm"));
            t.verifyEqual(a.identity,tire.identity);
            a.stiffness_N_per_m = 200000;
            t.verifyError(@() fsd.model.validateVerticalTireModel(a),"fsd:model:InvalidVerticalTireModel");
        end
        function noDefaultStiffness(t)
            d = struct("cornerId","FL","modelType","LINEAR_VERTICAL_UNILATERAL", ...
                "unloadedRadius",.25,"sourceKind","KNOWN","sourceNote","Test");
            t.verifyError(@() fsd.model.createVerticalTireModel(d,struct("length","m","stiffness","N/m")), ...
                "fsd:model:InvalidVerticalTireModel");
        end
        function invalidTireParameters(t)
            d = struct("cornerId","FL","modelType","LINEAR_VERTICAL_UNILATERAL", ...
                "stiffness",100000,"unloadedRadius",.25,"sourceKind","KNOWN","sourceNote","Test");
            for v = [0,-1,NaN,Inf]
                bad = d; bad.stiffness = v;
                t.verifyError(@() fsd.model.createVerticalTireModel(bad,struct("length","m","stiffness","N/m")), ...
                    "fsd:model:InvalidVerticalTireModel");
            end
            bad = d; bad.cornerId = "FRONT_LEFT";
            t.verifyError(@() fsd.model.createVerticalTireModel(bad,struct("length","m","stiffness","N/m")), ...
                "fsd:model:InvalidVerticalTireModel");
        end
        function unknownMassesNotZero(t)
            [s,~,sources,tires,~,lc] = globalStaticFixture;
            d = s.vehicle.definitionSI; d.unsprungMass = [NaN;0;0;0];
            v = fsd.model.createVehicleParameters(d,struct("length","m","mass","kg","gravity","m/s^2"));
            lc = fsd.model.createVehicleLoadCase(v,lc.definitionSI);
            t.verifyError(@() fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options), ...
                "fsd:model:InvalidGlobalStaticSystem");
            o = s.options; o.massApproximation = "ZERO_UNSPRUNG_APPROXIMATION";
            z = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,o);
            t.verifyEqual(z.unsprungMass_kg,zeros(4,1));
        end
        function cornerMixing(t)
            [s,~,sources,tires,v,lc] = globalStaticFixture; sources{2} = sources{1};
            t.verifyError(@() fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options), ...
                "fsd:model:InvalidGlobalStaticSystem");
        end
        function sourceManipulation(t)
            s = globalStaticFixture; s.sources{1}.mechanical.springAxialForce_N(1) = 1234;
            t.verifyError(@() fsd.analysis.prepareGlobalStaticSystem(s),"fsd:analysis:InvalidSpringDamperAnalysis");
        end
        function physicalIdentityChange(t)
            s = globalStaticFixture; changed = s;
            d = struct("cornerId","FL","modelType","LINEAR_VERTICAL_UNILATERAL", ...
                "stiffness",120000,"unloadedRadius",.25,"sourceKind","ASSUMED","sourceNote","Test");
            changed.tires{1} = fsd.model.createVerticalTireModel(d,struct("length","m","stiffness","N/m"));
            changed = fsd.model.createGlobalStaticSystem(changed.vehicle,changed.loadCase,changed.sources,changed.tires,changed.options);
            t.verifyNotEqual(changed.identity,s.identity);
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;zeros(6,1)]);
            t.verifyError(@() fsd.analysis.validateGlobalStaticState(a,changed),"fsd:analysis:InvalidGlobalStaticState");
        end
        function metadataAndMat(t)
            s = globalStaticFixture; changed = s; changed.vehicle.metadata.label = "Human display";
            changed.sources{1}.geometry.metadata.label = "New label";
            c = fsd.model.createGlobalStaticSystem(changed.vehicle,changed.loadCase,changed.sources,changed.tires,changed.options);
            t.verifyEqual(c.identity,s.identity);
            path = string(tempname)+".mat"; cleanup = onCleanup(@() delete(path));
            save(path,"s"); loaded = load(path); t.verifyEqual(loaded.s,s);
        end
        function inputDimensionsAndBudgets(t)
            [s,o] = globalStaticFixture;
            t.verifyError(@() fsd.analysis.evaluateGlobalStaticState(s,zeros(1,7)),"fsd:analysis:InvalidGlobalStaticInput");
            t.verifyError(@() fsd.analysis.evaluateGlobalStaticState(s,nan(7,1)),"fsd:analysis:InvalidGlobalStaticInput");
            t.verifyError(@() fsd.analysis.solveGlobalStaticEquilibrium(s,zeros(7,1),struct()),"fsd:analysis:InvalidGlobalStaticInput");
            o.forceTolerance_N = -1;
            t.verifyError(@() fsd.analysis.solveGlobalStaticEquilibrium(s,zeros(7,1),o),"fsd:analysis:InvalidGlobalStaticInput");
        end
    end
end
