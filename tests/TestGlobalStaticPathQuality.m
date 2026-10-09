classdef TestGlobalStaticPathQuality < matlab.unittest.TestCase
    methods (Test)
        function multipleRootsStableAndNonRestoring(t)
            [s,o] = globalStaticFixture(repmat(.05,4,1),zeros(4,1),[1,0,.3],100000,-10);
            other = (.075-sqrt(.020625))/2; % independent roots of cubic Fs*MR=500
            seeds = [[-.005;zeros(6,1)],[-.005-other;0;0;repmat(other,4,1)]];
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,seeds,o);
            t.verifyEqual(r.status,"MULTIPLE_FOUND_EQUILIBRIA");
            t.verifyTrue(isnan(r.selectedIndex)); t.verifyEqual(numel(r.alternatives),2);
            t.verifyEqual(r.alternatives{1}.stability,"NON_RESTORING_STATIONARY_POINT");
            t.verifyEqual(r.alternatives{2}.stability,"LOCAL_STABLE_MINIMUM");
            t.verifyEqual(r.alternatives{2}.state.q(4:7),repmat(other,4,1),"AbsTol",2e-6);
            o.selection = "LOWEST_ENERGY_STABLE";
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,seeds,o);
            t.verifyEqual(r.selectedIndex,2);
        end
        function failedKinematicSourceNoInterpolation(t)
            [s,~,sources,tires,v,lc] = globalStaticFixture;
            for i = 1:4
                a = sources{i}.actuation; g = sources{i}.geometry;
                bump = fsd.kinematics.solveBumpSweep(g,[-.02;0;.02;.31;.32],"m");
                sweep = fsd.kinematics.solveActuationSweep(a,bump);
                analysis = fsd.analysis.analyzeActuationSweep(a,sweep);
                sources{i}.mechanical = fsd.analysis.analyzeSpringDamperSweep( ...
                    sources{i}.springDamper,a,sweep,analysis,0,"m/s");
                sources{i}.pathKind = "ACTUATION_BUMP_3D";
            end
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            p = fsd.analysis.prepareGlobalStaticSystem(s);
            t.verifyEmpty(p.paths{1}.segments); % upstream MR globally unavailable on this failed sweep
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;zeros(6,1)]);
            t.verifyFalse(a.feasible);
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;0;0;.31;0;0;0]);
            t.verifyEqual(a.corners{1}.pathStatus,"SOURCE_FAILURE_PATH_GAP");
        end
        function incompatibleRockerBranchRejected(t)
            oldPath = path; cleanup = onCleanup(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"examples"));
            e = globalStaticEquilibriumExample(false); s = e.system;
            s.sources{1}.mechanical.source.sweep.results(51).rockerAngle_rad = pi;
            s = fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options);
            t.verifyError(@() fsd.analysis.prepareGlobalStaticSystem(s),"fsd:kinematics:InvalidActuationResult");
        end
        function coilBindSuppressesUnavailableEnergy(t)
            [s,~,sources,tires,v,lc] = globalStaticFixture;
            for i = 1:4
                model = sources{i}.springDamper; model.spring.solidHeight_m = .16;
                model.identity = fsd.model.springDamperIdentity(model);
                z = sources{i}.mechanical.path.achievedWheelTravel_m;
                sources{i}.springDamper = model;
                sources{i}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                    model,z,.5*z,0,struct("length","m","velocity","m/s"));
            end
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;zeros(6,1)]);
            t.verifyFalse(a.feasible); t.verifyTrue(isnan(a.potentialEnergy_J));
        end
        function threeContactsAndMarginalFreeWheel(t)
            [s,o,sources,tires,v,lc] = globalStaticFixture([0;.05;.05;.05],zeros(4,1),[4/3,.65/3,.3]);
            z = sources{1}.mechanical.path.achievedWheelTravel_m;
            sources{1}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                sources{1}.springDamper,z,-.5*z,0,struct("length","m","velocity","m/s"));
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            q = [-.04;0;0;.048;repmat(1/30,3,1)];
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            t.verifyEqual(r.selectedIndex,1);
            a = r.alternatives{1}; state = a.state;
            t.verifyEqual(state.normalForces_N,[0;repmat(2000/3,3,1)],"AbsTol",1e-8);
            t.verifyEqual(state.corners{1}.tire.contactStatus,"AIRBORNE");
            t.verifyGreaterThan(state.corners{1}.tire.tireGap_m,0);
            t.verifyEqual(a.stability,"MARGINAL_OR_DEGENERATE");
            t.verifyTrue(a.isIllConditioned);
            % CG outside the remaining support triangle demands a negative reaction.
            vd = v.definitionSI; vd.cg = [1,-.4,.3];
            v = fsd.model.createVehicleParameters(vd,struct("length","m","mass","kg","gravity","m/s^2"));
            lc = fsd.model.createVehicleLoadCase(v,lc.definitionSI);
            unsupported = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            demanded = [1,1,1;0,2,2;.65,-.65,.65]\[2000;2000;-800];
            t.verifyLessThan(min(demanded),0);
            failed = fsd.analysis.solveGlobalStaticEquilibrium(unsupported,q,o);
            t.verifyEmpty(failed.alternatives);
        end
        function curvatureUnresolvedStillEvaluatesForces(t)
            [s,~,sources,tires,v,lc] = globalStaticFixture;
            z = .01+[-1e-8;0;1e-8]; % MR resolved throughout; curvature fails F-01
            for i = 1:4
                sources{i}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                    sources{i}.springDamper,z,.5*z+3*z.^2,0,struct("length","m","velocity","m/s"));
                nominal = fsd.model.getPoint(sources{i}.geometry,sources{i}.geometry.cornerId+"_WHEEL_CENTER");
                sources{i}.idealWheelCenterPath_m = nominal+z*[0,0,1];
            end
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.02;0;0;repmat(.01,4,1)]);
            t.verifyTrue(a.feasible); t.verifyTrue(all(isfinite(a.residual)));
            t.verifyFalse(a.bilateralHessianAvailable);
        end
        function descendingPath(t)
            [s,o,sources,tires,v,lc] = globalStaticFixture;
            for i = 1:4
                z = flipud(sources{i}.mechanical.path.achievedWheelTravel_m);
                sources{i}.idealWheelCenterPath_m = flipud(sources{i}.idealWheelCenterPath_m);
                sources{i}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                    sources{i}.springDamper,z,.5*z,0,struct("length","m","velocity","m/s"));
            end
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,zeros(7,1),o);
            t.verifyEqual(r.alternatives{1}.state.q,[-.005;zeros(6,1)],"AbsTol",1e-8);
        end
        function duplicateTravelDoesNotBecomePath(t)
            [s,~,sources,tires,v,lc] = globalStaticFixture;
            for i = 1:4
                z = zeros(3,1);
                sources{i}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                    sources{i}.springDamper,z,z,0,struct("length","m","velocity","m/s"));
                sources{i}.idealWheelCenterPath_m = repmat(sources{i}.idealWheelCenterPath_m(31,:),3,1);
            end
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;zeros(6,1)]);
            t.verifyFalse(a.feasible); t.verifyTrue(isnan(a.potentialEnergy_J));
        end
        function limitsDoNotInventReactions(t)
            [s,~,sources,tires,v,lc] = globalStaticFixture;
            for i = 1:4
                model = sources{i}.springDamper;
                model.damper.minimumLength_m = model.derivedStaticGeometry.damperStaticLength_m+.001;
                model.identity = fsd.model.springDamperIdentity(model);
                z = sources{i}.mechanical.path.achievedWheelTravel_m;
                sources{i}.springDamper = model;
                sources{i}.mechanical = fsd.analysis.analyzePrescribedSpringDamperPath( ...
                    model,z,.5*z,0,struct("length","m","velocity","m/s"));
            end
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;zeros(6,1)]);
            t.verifyFalse(a.feasible); t.verifyTrue(all(isnan(a.residual)));
        end
        function actual3dMechanisms(t)
            oldPath = path; cleanup = onCleanup(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"examples"));
            e = globalStaticEquilibriumExample(false);
            t.verifyEqual(e.result.selectedIndex,1);
            a = e.result.alternatives{1}.state;
            t.verifyLessThan(norm(a.worldMomentResidual_Nm),1e-6);
            p = fsd.analysis.prepareGlobalStaticSystem(e.system);
            t.verifyNotEqual(p.paths{1}.originalWheelCenters_m(1,2),p.paths{1}.originalWheelCenters_m(51,2));
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(e.result,e.system));
        end
    end
end
