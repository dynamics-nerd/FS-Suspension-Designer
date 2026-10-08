classdef TestSpringDamperIntegration < matlab.unittest.TestCase
    methods (TestMethodSetup)
        function setup(testCase)
            originalPath = path;
            testCase.addTeardown(@() path(originalPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"src"));
        end
    end
    methods (Test)
        function plotsNineViewsWithNaNGaps(testCase)
            [~,a,s,k] = testCase.sweep([-10;0;10]);
            [~,~,~,definition,units] = springDamperFixture();
            definition.damper.minimumLength = a.damper.staticLength_m-0.002;
            definition.damper.maximumLength = a.damper.staticLength_m+0.002;
            m = fsd.model.createSpringDamperModel(a,definition,units);
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,s,k);
            fig = figure("Visible","off");
            testCase.addTeardown(@() close(fig));
            h = fsd.analysis.plotSpringDamperSweep(r,m,a,fig);
            testCase.verifyNumElements(h.axes,9);
            testCase.verifyTrue(all(isgraphics(h.axes)));
            testCase.verifyTrue(any(isnan(r.wheelRateTotal_N_per_m)));
            curves = findobj(h.axes(4),"Type","line");
            testCase.verifyEqual(curves(1).YData(:),r.wheelRateTotal_N_per_m/1000,"AbsTol",1e-12);
        end
        function productionConsumesExistingMR(testCase)
            [m,a,s,k] = testCase.sweep([-10;0;10]);
            changed = s;
            changed.requestedWheelTravel_m(1) = changed.requestedWheelTravel_m(1)+0.001;
            testCase.verifyError(@() fsd.analysis.analyzeSpringDamperSweep(m,a,changed,k), ...
                "fsd:kinematics:InvalidActuationSweepResult");
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,s,k,0.1,"m/s");
            testCase.verifyEqual(r.damperMotionRatio,k.damperMotionRatio);
            testCase.verifyEqual(r.springAxialForce_N,30000*(0.02+s.damperCompression_m),"AbsTol",1e-10);
            testCase.verifyEqual(r.wheelRateTotal_N_per_m, ...
                r.wheelRateElastic_N_per_m+r.wheelRateGeometric_N_per_m);
            testCase.verifyTrue(fsd.analysis.validateSpringDamperSweepAnalysis(r,m,a));
            testCase.verifyNotEqual(r.wheelRateTotal_N_per_m,r.wheelRateElastic_N_per_m);
        end
        function scalarIsAxialOnlyAndUsesActualLength(testCase)
            [m,a,g] = springDamperFixture();
            ar = fsd.kinematics.solveActuation(a,fsd.kinematics.solveBump(g,8,"mm"));
            r = fsd.analysis.analyzeSpringDamperState(m,ar,-100,"mm/s");
            testCase.verifyTrue(fsd.analysis.validateSpringDamperStateAnalysis(r,m));
            testCase.verifyEqual(r.state.damperLength_m,ar.damperLength_m);
            testCase.verifyEqual(r.state.springSeatSeparation_m, ...
                ar.damperLength_m+m.derivedStaticGeometry.springSeatOffset_m);
            testCase.verifyEqual(r.state.damperAxialResistance_N,-250);
            testCase.verifyTrue(isnan(r.state.springWheelResistance_N));
            testCase.verifyTrue(isnan(r.state.wheelRateTotal_N_per_m));
            r.state.springStoredEnergy_J = 0;
            testCase.verifyError(@() fsd.analysis.validateSpringDamperStateAnalysis(r,m),"fsd:analysis:InvalidSpringDamperAnalysis");
        end
        function failureGapHasNoConstitutiveResponseOrInterpolation(testCase)
            [m,a,g] = springDamperFixture();
            bump = fsd.kinematics.solveBumpSweep(g,[0;500;10],"mm");
            s = fsd.kinematics.solveActuationSweep(a,bump);
            k = fsd.analysis.analyzeActuationSweep(a,s);
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,s,k,0.1,"m/s");
            testCase.verifyEqual(r.derivativeStatus,repmat("UNAVAILABLE_PATH_GAP",3,1));
            testCase.verifyTrue(isfinite(r.springAxialForce_N(1)));
            testCase.verifyTrue(all(isnan(r.springAxialForce_N(2:3))));
            testCase.verifyTrue(all(isnan(r.wheelRateTotal_N_per_m)));
            testCase.verifyTrue(all(isnan(r.damperAxialResistance_N)));
            testCase.verifyTrue(isnan(r.metrics.maximumSpringAxialForce_N));
            testCase.verifyTrue(isnan(r.metrics.maximumCompression_m));
            testCase.verifyTrue(isnan(r.metrics.maximumExtension_m));
            testCase.verifyTrue(fsd.analysis.validateSpringDamperSweepAnalysis(r,m,a));
            scalar = fsd.analysis.analyzeSpringDamperState(m,s.results(2));
            testCase.verifyTrue(isnan(scalar.state.springAxialForce_N));
        end
        function nonmonotonicProductionPathRetainsAxialOnly(testCase)
            [m,a,s,k] = testCase.sweep([0;10;0]);
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,s,k);
            testCase.verifyTrue(all(isfinite(r.springAxialForce_N)));
            testCase.verifyTrue(all(isnan(r.springWheelResistance_N)));
            testCase.verifyTrue(all(isnan(r.damperAxialResistance_N)));
            testCase.verifyFalse(r.staticReferenceAvailable);
        end
        function illConditionedActuationSuppressesPathProjection(testCase)
            [g,a] = actuationFixture("YZ_PLANE","UPRIGHT","PUSHROD","TANGENT_POSITIVE");
            [~,~,~,d,u] = springDamperFixture();
            m = fsd.model.createSpringDamperModel(a,d,u);
            b = fsd.kinematics.solveBumpSweep(g,[-0.2;-0.1;0],"mm");
            s = fsd.kinematics.solveActuationSweep(a,b);
            k = fsd.analysis.analyzeActuationSweep(a,s);
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,s,k,0.1,"m/s");
            testCase.verifyTrue(s.allConverged);
            testCase.verifyTrue(s.results(3).isIllConditioned);
            testCase.verifyEqual(r.derivativeStatus,repmat("UNAVAILABLE_ILL_CONDITIONED",3,1));
            testCase.verifyTrue(all(isnan(r.wheelRateTotal_N_per_m)));
            testCase.verifyTrue(all(isfinite(r.springAxialForce_N)));
        end
        function sourcesFromAnotherSweepOrModelRejected(testCase)
            [m,a,s,k] = testCase.sweep([-10;0;10]);
            [~,~,~,otherAnalysis] = testCase.sweep([-9;0;9]);
            testCase.verifyError(@() fsd.analysis.analyzeSpringDamperSweep(m,a,s,otherAnalysis), ...
                "fsd:analysis:InvalidActuationSweepAnalysis");
            k.achievedWheelTravel_m(1) = k.achievedWheelTravel_m(1)+0.001;
            testCase.verifyError(@() fsd.analysis.analyzeSpringDamperSweep(m,a,s,k), ...
                "fsd:analysis:InvalidActuationSweepAnalysis");
            [~,~,~,d,u] = springDamperFixture();
            d.spring.rate = 40000; otherModel = fsd.model.createSpringDamperModel(a,d,u);
            k = fsd.analysis.analyzeActuationSweep(a,s);
            r = fsd.analysis.analyzeSpringDamperSweep(m,a,s,k);
            testCase.verifyError(@() fsd.analysis.validateSpringDamperSweepAnalysis(r,otherModel,a), ...
                "fsd:analysis:InvalidSpringDamperAnalysis");
            bad = r; bad.inputWheelVelocity_m_per_s = [0;0];
            testCase.verifyError(@() fsd.analysis.validateSpringDamperSweepAnalysis(bad,m,a), ...
                "fsd:analysis:InvalidSpringDamperAnalysis");
        end
        function pushrodPullrodMechanicalLawSameIdentityDistinct(testCase)
            [m,a,g,d,u] = springDamperFixture();
            [~,~,definition] = actuationFixture();
            definition.actuationType = "PULLROD";
            pull = fsd.model.createActuationGeometry(g,definition,"m");
            pm = fsd.model.createSpringDamperModel(pull,d,u);
            source = fsd.kinematics.solveBump(g,8,"mm");
            ar = fsd.kinematics.solveActuation(a,source);
            pr = fsd.kinematics.solveActuation(pull,source);
            r = fsd.analysis.analyzeSpringDamperState(m,ar);
            p = fsd.analysis.analyzeSpringDamperState(pm,pr);
            testCase.verifyEqual(r.state,p.state);
            testCase.verifyNotEqual(m.identity,pm.identity);
            testCase.verifyError(@() fsd.analysis.analyzeSpringDamperState(m,pr), ...
                "fsd:analysis:SpringDamperIdentityMismatch");
        end
        function independentFourCornersAndAsymmetricTravel(testCase)
            [~,~,definition] = actuationFixture();
            [~,~,~,mechanics,u] = springDamperFixture();
            identities = cell(4,1); index = 0;
            for axleId = ["FRONT","REAR"]
                axle = translationAxleFixture(axleId);
                travel = fsd.kinematics.solveAxleTravel(axle,[8,-6],"mm");
                testCase.assertTrue(travel.converged);
                for side = ["left","right"]
                    index = index+1;
                    geo = axle.(side+"Geometry"); def = definition;
                    if side == "right", def = testCase.reflectDefinition(def); end
                    act = fsd.model.createActuationGeometry(geo,def,"m");
                    mechanics.spring.rate = 30000+1000*index;
                    model = fsd.model.createSpringDamperModel(act,mechanics,u);
                    ar = fsd.kinematics.solveActuation(act,travel.(side+"Result"));
                    response = fsd.analysis.analyzeSpringDamperState(model,ar);
                    if side == "right"
                        leftModel = springDamperFixture();
                        testCase.verifyError(@() fsd.analysis.analyzeSpringDamperState(leftModel,ar), ...
                            "fsd:analysis:SpringDamperIdentityMismatch");
                    end
                    testCase.verifyEqual(response.state.springAxialForce_N, ...
                        mechanics.spring.rate*(0.02+ar.damperCompression_m),"AbsTol",1e-8);
                    testCase.verifyTrue(isnan(response.state.wheelRateTotal_N_per_m));
                    identities{index} = model.identity;
                end
            end
            testCase.verifyEqual(string(cellfun(@(x) x.cornerId,identities,"UniformOutput",false)), ...
                ["FL";"FR";"RL";"RR"]);
        end
        function bodyRollAndSteeringConsumeActualStates(testCase)
            [m,a,~] = springDamperFixture();
            axle = translationAxleFixture();
            for phi = [-1,1]
                roll = fsd.kinematics.solveAxleRoll(axle,phi,0,"deg","m");
                testCase.assertTrue(roll.converged);
                ar = fsd.kinematics.solveActuation(a,roll.axleTravelResult.leftResult);
                response = fsd.analysis.analyzeSpringDamperState(m,ar);
                testCase.verifyEqual(response.state.damperCompression_m,ar.damperCompression_m);
                testCase.verifyTrue(isnan(response.state.wheelRateTotal_N_per_m));
            end
            steering = fsd.model.createSteeringSystem(axle,1.6,"m");
            steer = fsd.kinematics.solveSteering(steering,5,8,"mm");
            testCase.assertTrue(steer.converged);
            ar = fsd.kinematics.solveActuation(a,steer.leftResult);
            response = fsd.analysis.analyzeSpringDamperState(m,ar);
            testCase.verifyEqual(response.state.damperLength_m,ar.damperLength_m);
            testCase.verifyTrue(fsd.analysis.validateSpringDamperStateAnalysis(response,m));
            testCase.verifyTrue(isnan(response.state.springWheelResistance_N));
        end
    end
    methods (Static, Access = private)
        function [m,a,s,k] = sweep(targets)
            [m,a,g] = springDamperFixture();
            b = fsd.kinematics.solveBumpSweep(g,targets,"mm");
            s = fsd.kinematics.solveActuationSweep(a,b);
            k = fsd.analysis.analyzeActuationSweep(a,s);
        end
        function d = reflectDefinition(d)
            d.suspensionAttachment.point(2) = -d.suspensionAttachment.point(2);
            d.rocker.axis.point(2) = -d.rocker.axis.point(2);
            d.rocker.actuationRodPoint(2) = -d.rocker.actuationRodPoint(2);
            d.rocker.damperPoint(2) = -d.rocker.damperPoint(2);
            d.damper.chassisPoint(2) = -d.damper.chassisPoint(2);
        end
    end
end
