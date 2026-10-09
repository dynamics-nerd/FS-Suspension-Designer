classdef TestGlobalStaticEquilibrium < matlab.unittest.TestCase
    % Analytical expected values and independent finite differences, SI.
    methods (Test)
        function symmetricBenchmark(t)
            [s,o] = globalStaticFixture;
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,zeros(7,1),o);
            t.verifyEqual(r.selectedIndex,1);
            a = r.alternatives{1}; q = a.state;
            t.verifyTrue(a.converged); t.verifyEqual(a.stability,"LOCAL_STABLE_MINIMUM");
            t.verifyEqual(q.q,[-.005;zeros(6,1)],"AbsTol",1e-8);
            t.verifyEqual(q.normalForces_N,repmat(500,4,1),"AbsTol",1e-5);
            t.verifyEqual(q.crossweightActualSumFraction,.5,"AbsTol",1e-9);
            t.verifyEqual([q.gravityEnergy_J,q.springEnergy_J,q.tireEnergy_J,q.potentialEnergy_J], ...
                [590,100,5,695],"AbsTol",1e-6);
            t.verifyLessThan(norm(q.worldMomentResidual_Nm),1e-7);
            for i = 1:4
                t.verifyEqual(q.corners{i}.spring.springAxialForce_N,1000,"AbsTol",1e-5);
                t.verifyEqual(q.corners{i}.springWheelResistance_N,500,"AbsTol",1e-5);
                t.verifyEqual(q.corners{i}.tire.tireCompression_m,.005,"AbsTol",1e-9);
            end
            t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,s));
        end
        function prescribedStateIsNotSolution(t)
            s = globalStaticFixture; a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;zeros(6,1)]);
            t.verifyEqual(a.status,"EVALUATED_NOT_SOLVED");
            t.verifyTrue(fsd.analysis.validateGlobalStaticState(a,s));
            t.verifyEqual(a.rideHeights_m,.095,"AbsTol",1e-12);
        end
        function rotationOrderAndFiniteMoments(t)
            s = globalStaticFixture; q = [-.02;.07;-.04;repmat(.001,4,1)];
            a = fsd.analysis.evaluateGlobalStaticState(s,q);
            X = [1,0,0;0,cos(q(3)),-sin(q(3));0,sin(q(3)),cos(q(3))];
            Y = [cos(q(2)),0,sin(q(2));0,1,0;-sin(q(2)),0,cos(q(2))];
            t.verifyEqual(a.rotationMatrix,X*Y,"AbsTol",1e-14);
            t.verifyGreaterThan(norm(X*Y-Y*X),.001);
            for i = 1:4
                nominal = fsd.model.getPoint(s.sources{i}.geometry,s.cornerIds(i)+"_WHEEL_CENTER");
                expected = X*Y*(nominal+[0,0,q(i+3)])'+[0;0;q(1)];
                t.verifyEqual(a.corners{i}.wheelCenterWorld_m,expected',"AbsTol",1e-12);
            end
            t.verifyEqual(a.residual(2),-cos(q(3))*a.worldMomentResidual_Nm(2),"AbsTol",1e-8);
            t.verifyEqual(a.residual(3),-a.worldMomentResidual_Nm(1),"AbsTol",1e-8);
        end
        function independentEnergyGradient(t)
            [s,o] = globalStaticFixture; q = [-.015;.002;-.003;[.001;-.002;.003;-.001]];
            a = fsd.analysis.evaluateGlobalStaticState(s,q); numerical = zeros(7,1);
            for i = 1:7
                h = 1e-6*o.coordinateScales(i); left = q; right = q;
                left(i) = left(i)-h; right(i) = right(i)+h;
                l = fsd.analysis.evaluateGlobalStaticState(s,left);
                r = fsd.analysis.evaluateGlobalStaticState(s,right);
                numerical(i) = (r.potentialEnergy_J-l.potentialEnergy_J)/(2*h);
            end
            t.verifyEqual(a.residual,numerical,"AbsTol",2e-5);
            t.verifyEqual(a.residual(1),a.weight_N-sum(a.normalForces_N),"AbsTol",1e-10);
        end
        function forwardCgPitch(t)
            [s,o] = globalStaticFixture(repmat(.05,4,1),zeros(4,1),[.8,0,.3]);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[-.005;zeros(6,1)],o);
            t.verifyEqual(r.selectedIndex,1);
            a = r.alternatives{1}.state;
            % Front needs more support: more front bump, front chassis lower (theta<0).
            t.verifyLessThan(a.pitch_rad,0); t.verifyGreaterThan(a.axleLoads_N(1),1000);
            t.verifyGreaterThan(mean(a.q(4:5)),mean(a.q(6:7)));
            t.verifyLessThan(norm(a.worldMomentResidual_Nm),1e-7);
        end
        function rightCgRoll(t)
            [s,o] = globalStaticFixture(repmat(.05,4,1),zeros(4,1),[1,.08,.3]);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[-.005;zeros(6,1)],o);
            t.verifyEqual(r.selectedIndex,1);
            a = r.alternatives{1}.state;
            t.verifyLessThan(a.roll_rad,0); t.verifyGreaterThan(a.sideLoads_N(2),1000);
            t.verifyLessThan(norm(a.worldMomentResidual_Nm),1e-7);
        end
        function asymmetricPreloadEmergentCrossweight(t)
            [s,o] = globalStaticFixture([.055;.045;.045;.055]);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[-.005;zeros(6,1)],o);
            t.verifyEqual(r.selectedIndex,1);
            a = r.alternatives{1}.state;
            t.verifyGreaterThan(abs(a.crossweightActualSumFraction-.5),.01);
            t.verifyLessThan(norm(a.worldMomentResidual_Nm),1e-7);
        end
        function tireCompliance(t)
            [s,o] = globalStaticFixture(repmat(.05,4,1),zeros(4,1),[1,0,.3],50000);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,zeros(7,1),o);
            t.verifyEqual(r.alternatives{1}.state.heave_m,-.01,"AbsTol",1e-8);
            t.verifyEqual(r.alternatives{1}.state.q(4:7),zeros(4,1),"AbsTol",1e-8);
            % Per-corner series rate: 1/(1/(ks*MR^2)+1/kt).
            delta = 1e-5; q = r.alternatives{1}.state.q;
            kw = 1/(1/5000+1/50000);
            % Local z balance permits dz/dh=-kt/(kt+ks*MR^2).
            dq = [delta;0;0;repmat(-50000/(50000+5000)*delta,4,1)];
            a = fsd.analysis.evaluateGlobalStaticState(s,q+dq);
            t.verifyEqual(a.normalForces_N,repmat(500-kw*delta,4,1),"AbsTol",1e-7);
        end
        function unsprungMassMovingCg(t)
            s = globalStaticFixture(repmat(.05,4,1),[2;3;4;5]);
            p = fsd.analysis.prepareGlobalStaticSystem(s);
            t.verifyEqual(p.sprungMass_kg,186);
            t.verifyEqual(186*p.sprungCgBody_m+[2,3,4,5]*p.nominalWheelCentersBody_m, ...
                200*[1,0,.3],"AbsTol",1e-12);
            q = [-.02;0;0;[.004;.002;-.003;.001]];
            a = fsd.analysis.evaluateGlobalStaticState(s,q);
            expectedZ = .3+q(1)+[2,3,4,5]*q(4:7)/200;
            t.verifyEqual(a.totalCgWorld_m(3),expectedZ,"AbsTol",1e-12);
            t.verifyEqual(a.residual(1),2000-sum(a.normalForces_N),"AbsTol",1e-9);
        end
        function airAndTransition(t)
            s = globalStaticFixture;
            a = fsd.analysis.evaluateGlobalStaticState(s,[.02;zeros(6,1)]);
            t.verifyEqual(a.normalForces_N,zeros(4,1));
            t.verifyEqual(a.corners{1}.tire.contactStatus,"AIRBORNE");
            t.verifyEqual(a.corners{1}.tire.tireStoredEnergy_J,0);
            a = fsd.analysis.evaluateGlobalStaticState(s,zeros(7,1));
            t.verifyFalse(a.bilateralHessianAvailable);
            t.verifyEqual(a.corners{1}.tire.contactStatus,"CONTACT_TRANSITION");
        end
        function nearZeroContactIsUnresolved(t)
            s = globalStaticFixture;
            a = fsd.analysis.evaluateGlobalStaticState(s,[-eps(.25);zeros(6,1)]);
            t.verifyEqual(a.corners{1}.tire.contactStatus,"CONTACT_NUMERICALLY_UNRESOLVED");
            t.verifyGreaterThan(a.normalForces_N(1),0); % no silent clipping of tiny positive forces
            t.verifyFalse(a.bilateralHessianAvailable);
        end
        function crossweightReferenceNotImposed(t)
            [s,o,sources,tires,v] = globalStaticFixture([.055;.045;.045;.055]);
            lc = fsd.model.createVehicleLoadCase(v,struct("mode","CROSSWEIGHT_SPECIFIED", ...
                "crossweight",.5,"sourceKind","KNOWN"));
            s = fsd.model.createGlobalStaticSystem(v,lc,sources,tires,s.options);
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[-.005;zeros(6,1)],o);
            a = r.alternatives{1}.state;
            t.verifyGreaterThan(abs(a.crossweightActualSumFraction-.5),.01);
            t.verifyEqual(s.loadCase.definitionSI.crossweightFraction,.5);
            t.verifyEqual(a.comparisonV09.reference.cornerLoads_N,repmat(500,4,1),"AbsTol",1e-8);
            t.verifyTrue(a.comparisonV09.referenceNotImposed);
        end
        function unreachableAndSearchBoundary(t)
            [s,o] = globalStaticFixture; o.bounds(1,:) = [.01,.03];
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[.02;zeros(6,1)],o);
            t.verifyEmpty(r.alternatives); t.verifyTrue(isnan(r.selectedIndex));
            [s,o] = globalStaticFixture; o.bounds(1,1) = -.005;
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,[-.005;zeros(6,1)],o);
            t.verifyEqual(r.attempts{1}.solution.status,"ARTIFICIAL_SEARCH_BOUNDARY");
        end
        function deduplicateMultistart(t)
            [s,o] = globalStaticFixture;
            seeds = [zeros(7,1),[-.005;zeros(6,1)]];
            r = fsd.analysis.solveGlobalStaticEquilibrium(s,seeds,o);
            t.verifyEqual(numel(r.attempts),2); t.verifyEqual(numel(r.alternatives),1);
            t.verifyEqual(r.rootCompleteness,"SUPPLIED_SEEDS_ONLY");
        end
        function invalidOutsidePath(t)
            s = globalStaticFixture;
            a = fsd.analysis.evaluateGlobalStaticState(s,[-.005;0;0;.08;0;0;0]);
            t.verifyFalse(a.feasible); t.verifyTrue(isnan(a.potentialEnergy_J));
            t.verifyTrue(all(isnan(a.residual)));
        end
    end
end
