classdef TestGlobalStaticSelection < matlab.unittest.TestCase
    properties (TestParameter)
        category = {"LOCAL_STABLE_MINIMUM","NON_RESTORING_STATIONARY_POINT", ...
            "MARGINAL_OR_DEGENERATE","STABILITY_NOT_EVALUABLE"}
        nonstable = {"NON_RESTORING_STATIONARY_POINT","MARGINAL_OR_DEGENERATE","STABILITY_NOT_EVALUABLE"}
        invalidEnergy = {NaN,Inf,-Inf,1i}
    end
    methods (Test)
        function singletonPolicy(t,category)
            [s,o,q] = globalSelectionFixture(category);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            t.assertEqual(numel(r.alternatives),1);
            t.verifyEqual(r.status,"UNIQUE_FOUND_EQUILIBRIUM");
            t.verifyEqual(r.alternatives{1}.stability,category);
            if category == "LOCAL_STABLE_MINIMUM"
                t.verifyEqual(r.selectedIndex,1);
            else
                t.verifyTrue(isnan(r.selectedIndex));
            end
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,s));
            if category == "NON_RESTORING_STATIONARY_POINT"
                % Audit reference on the same sampled path, not a physical tolerance.
                t.verifyEqual(min(r.alternatives{1}.scaledHessianEigenvalues_J),-5.892181916,"AbsTol",1e-7);
                state = r.alternatives{1}.state;
                D = diag(o.coordinateScales);
                [V,E] = eig(D*state.candidateHessian*D);
                [~,j] = min(diag(E));
                dq = D*V(:,j)*1e-3; % dimensionless test perturbation, no solver budget change
                plus = fsd.analysis.evaluateGlobalStaticState(s,state.q+dq);
                minus = fsd.analysis.evaluateGlobalStaticState(s,state.q-dq);
                t.verifyLessThan(plus.potentialEnergy_J,state.potentialEnergy_J);
                t.verifyLessThan(minus.potentialEnergy_J,state.potentialEnergy_J);
            elseif category == "STABILITY_NOT_EVALUABLE"
                t.verifyEqual(r.alternatives{1}.state.corners{1}.bounds.springSolidStatus,"COIL_BIND_LIMIT");
                t.verifyFalse(r.alternatives{1}.state.bilateralHessianAvailable);
            end
        end
        function uniqueOnlyUnchanged(t,category)
            [s,o,q] = globalSelectionFixture(category);
            stablePolicy = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            o.selection = "UNIQUE_ONLY";
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            t.verifyEqual(r.selectedIndex,1);
            t.verifyEqual(r.alternatives,stablePolicy.alternatives);
            t.verifyEqual(r.attempts{1}.solution,stablePolicy.attempts{1}.solution);
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,s));
        end
        function forgedSingletonRejected(t,nonstable)
            [s,o,q] = globalSelectionFixture(nonstable);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            t.assertTrue(isnan(r.selectedIndex)); r.selectedIndex = 1;
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(r,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
        end
        function zeroRoots(t)
            [s,o] = globalStaticFixture; o.selection = "LOWEST_ENERGY_STABLE";
            o.bounds(1,:) = [.01,.03];
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[.02;zeros(6,1)],o);
            t.verifyEmpty(r.alternatives); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyEqual(r.status,"NO_GLOBAL_EQUILIBRIUM_FOUND");
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,s));
        end
        function noEligibleAmongMany(t)
            labels = ["NON_RESTORING_STATIONARY_POINT","MARGINAL_OR_DEGENERATE","STABILITY_NOT_EVALUABLE"];
            [a,k,status] = selectFound(labels,[1,2,3]);
            t.verifyEqual(numel(a),3); t.verifyTrue(isnan(k));
            t.verifyEqual(status,"MULTIPLE_FOUND_EQUILIBRIA");
        end
        function onlyStableDespiteLowerNonstableEnergy(t)
            [a,k] = selectFound(["NON_RESTORING_STATIONARY_POINT","LOCAL_STABLE_MINIMUM"],[-100,10]);
            t.verifyEqual(k,2); t.verifyEqual(a{1}.state.potentialEnergy_J,-100);
        end
        function minimumAmongSeveralStable(t)
            [a,k] = selectFound(repmat("LOCAL_STABLE_MINIMUM",1,3),[5,2,8]);
            t.verifyEqual(k,2); t.verifyEqual(numel(a),3);
        end
        function exactTieAndDistinctFloatingEnergies(t)
            labels = repmat("LOCAL_STABLE_MINIMUM",1,2);
            [~,k] = selectFound(labels,[2,2]); t.verifyTrue(isnan(k));
            [~,k] = selectFound(labels,[2+eps(2),2]); t.verifyEqual(k,2);
            [~,k] = selectFound(labels,[2,2+eps(2)]); t.verifyEqual(k,1);
        end
        function invalidEligibleEnergyCannotCertifyMinimum(t,invalidEnergy)
            labels = repmat("LOCAL_STABLE_MINIMUM",1,2);
            [~,k] = selectFound(labels,[invalidEnergy,2]); t.verifyTrue(isnan(k));
            [~,k] = selectFound("LOCAL_STABLE_MINIMUM",invalidEnergy); t.verifyTrue(isnan(k));
            [~,k] = selectFound(["STABILITY_NOT_EVALUABLE","LOCAL_STABLE_MINIMUM"],[invalidEnergy,2]);
            t.verifyEqual(k,2); % invalid energy of an ineligible alternative is irrelevant
        end
        function deduplicationAndFailurePreserved(t)
            o = selectionOptions;
            a = attempt("LOCAL_STABLE_MINIMUM",5,zeros(7,1));
            b = a; b.solution.state.q(1) = o.positionTolerance_m/2;
            failed = attempt("STABILITY_NOT_EVALUABLE",NaN,ones(7,1));
            failed.solution.converged = false;
            [found,k] = globalSelectionTestCall({a;b;failed},o);
            t.verifyEqual(found,{a.solution}); t.verifyEqual(k,1);
            [found,k] = globalSelectionTestCall({failed;b;a},o);
            t.verifyEqual(found,{b.solution}); t.verifyEqual(k,1);
            [found,k,status] = globalSelectionTestCall({failed},o);
            t.verifyEmpty(found); t.verifyTrue(isnan(k));
            t.verifyEqual(status,"NO_GLOBAL_EQUILIBRIUM_FOUND");
        end
        function multipleMarginalPhysicalRoots(t)
            [s,o,q] = globalSelectionFixture("MARGINAL_OR_DEGENERATE");
            other = q; other(4) = .047;
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[q,other],o);
            t.assertEqual(numel(r.alternatives),2); t.verifyTrue(isnan(r.selectedIndex));
            t.verifyEqual(cellfun(@(a) a.stability,r.alternatives),repmat("MARGINAL_OR_DEGENERATE",2,1));
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,s));
        end
        function stableAndNonRestoringValidator(t)
            [s,o,q] = globalSelectionFixture("NON_RESTORING_STATIONARY_POINT");
            z = (.075-sqrt(.020625))/2;
            other = [-.005-z;0;0;repmat(z,4,1)];
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[q,other],o);
            t.assertEqual(numel(r.alternatives),2); t.verifyEqual(r.selectedIndex,2);
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,s));
            bad = r; bad.selectedIndex = 1;
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(bad,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
            bad = r; bad.solverOptions.selection = "UNIQUE_ONLY";
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(bad,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
        end
        function distinctStablePhysicalRootsAndOrder(t)
            [s,o,seeds] = globalSelectionFixture("DOUBLE_WELL");
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,seeds,o);
            t.assertEqual(numel(r.alternatives),2);
            t.verifyEqual(cellfun(@(a) a.stability,r.alternatives),repmat("LOCAL_STABLE_MINIMUM",2,1));
            t.verifyLessThan(r.alternatives{2}.state.potentialEnergy_J,r.alternatives{1}.state.potentialEnergy_J);
            t.verifyEqual(r.selectedIndex,2);
            t.verifyEqual(r.alternatives{2}.state.q(4:7),repmat(-.015,4,1),"AbsTol",2e-6);
            reversed = fsd.analysis.solveGlobalStaticEquilibrium(s,[seeds(:,2),seeds(:,1),seeds(:,2)],o);
            t.verifyEqual(numel(reversed.alternatives),2); t.verifyEqual(reversed.selectedIndex,1);
            t.verifyEqual(reversed.alternatives{1}.state.q,r.alternatives{2}.state.q,"AbsTol",1e-9);
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(reversed,s));
            bad = r; bad.selectedIndex = 1;
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(bad,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
        end
        function changedPolicyAndCoordinatedReportingRejected(t)
            [s,o,q] = globalSelectionFixture("NON_RESTORING_STATIONARY_POINT");
            o.selection = "UNIQUE_ONLY";
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            t.assertEqual(r.selectedIndex,1);
            r.solverOptions.selection = "LOWEST_ENERGY_STABLE";
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(r,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
            r.status = "UNIQUE_FOUND_EQUILIBRIUM";
            r.performance.reporting = struct("selected",true,"stability","LOCAL_STABLE_MINIMUM");
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(r,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
            r.attempts{1}.solution.stability = "LOCAL_STABLE_MINIMUM";
            r.alternatives{1}.stability = "LOCAL_STABLE_MINIMUM";
            t.verifyError(@() fsd.analysis.validateGlobalStaticEquilibrium(r,s), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
        end
        function actualMechanismStablePolicy(t)
            originalPath = path; cleanup = onCleanup(@() path(originalPath));
            root = fileparts(fileparts(mfilename("fullpath")));
            addpath(fullfile(root,"examples"));
            e = globalStaticEquilibriumExample(false);
            o = e.options; o.selection = "LOWEST_ENERGY_STABLE";
            r = fsd.analysis.solveGlobalStaticEquilibrium(e.system,[-.005;zeros(6,1)],o);
            t.assertEqual(numel(r.alternatives),1);
            t.verifyEqual(r.alternatives{1}.stability,"LOCAL_STABLE_MINIMUM");
            t.verifyEqual(r.selectedIndex,1);
            t.verifyEqual(r.alternatives,e.result.alternatives);
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,e.system));
        end
        function noSelectionMatAndPlot(t)
            [s,o,q] = globalSelectionFixture("NON_RESTORING_STATIONARY_POINT");
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,q,o);
            t.assertTrue(isnan(r.selectedIndex));
            file = string(tempname)+".mat"; cleanup = onCleanup(@() delete(file));
            save(file,"s","r"); loaded = load(file);
            t.verifyEqual(loaded.r,r); t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(loaded.r,loaded.s));
            before = findall(groot,"Type","figure");
            t.verifyError(@() fsd.analysis.plotGlobalStaticEquilibrium(s,r), ...
                "fsd:analysis:InvalidGlobalStaticEquilibrium");
            t.verifyEqual(findall(groot,"Type","figure"),before);
            try
                fsd.analysis.plotGlobalStaticEquilibrium(s,r);
            catch exception
                t.verifyTrue(contains(exception.message,"No alternative selected under LOWEST_ENERGY_STABLE"));
            end
        end
    end
end

function o = selectionOptions()
o = struct("selection","LOWEST_ENERGY_STABLE","positionTolerance_m",1e-9,"angleTolerance_rad",1e-9);
end

function a = attempt(stability, energy, q)
% Minimal isolated selector payload, deliberately NOT a valid physical result.
a = struct("solution",struct("converged",true,"stability",stability, ...
    "state",struct("q",q,"potentialEnergy_J",energy)));
end

function [alternatives,k,status] = selectFound(labels,energies)
attempts = cell(numel(labels),1);
for i = 1:numel(labels)
    attempts{i} = attempt(labels(i),energies(i),[i;zeros(6,1)]);
end
[alternatives,k,status] = globalSelectionTestCall(attempts,selectionOptions);
end
