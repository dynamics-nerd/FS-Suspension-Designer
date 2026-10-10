classdef TestDesignMechanicalDiagnostics < matlab.unittest.TestCase
    properties (TestParameter)
        LimitedMetric = {"DAMPER_COMPRESSION","MOTION_RATIO","SPRING_AXIAL_FORCE","TANGENT_WHEEL_RATE"}
        Quality = {"INSUFFICIENT_SAMPLES","ILL_CONDITIONED","NUMERICAL_RESOLUTION"}
    end
    methods (Test)
        function mandatoryCoilBindExcessPreservesNativeReason(t)
            [~,act,~,d,u] = springDamperFixture(); d.spring.solidHeight = .179;
            model = fsd.model.createSpringDamperModel(act,d,u);
            [a,r] = assessment(model,[-.01;0;.01],"MOTION_RATIO",.01,.5);
            t.verifyEqual(r.springSeatSeparation_m(3),.175,"AbsTol",1e-14);
            t.verifyEqual(r.springSolidStatus(3),"COIL_BIND_EXCEEDED");
            t.verifyEqual(r.motionRatioStatus(3),"AVAILABLE");
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
            t.verifyEqual(a.targetAssessments{1}.reasons,"COIL_BIND_EXCEEDED");
            t.verifyEqual(a.hardFeasibility,"INDETERMINATE_HARD_REQUIREMENTS");
        end
        function exceededLimitsRetainSpecificReasonForAllDependentMetrics(t,LimitedMetric)
            [~,act,~,d,u] = springDamperFixture(); d.spring.solidHeight = .179;
            % Concurrent travel failure: documented priority retains coil bind first.
            d.damper.minimumLength = act.damper.staticLength_m-.003;
            model = fsd.model.createSpringDamperModel(act,d,u);
            [a,r] = assessment(model,[-.01;0;.01],LimitedMetric,.01,0);
            t.verifyEqual(r.damperTravelStatus(3),"DAMPER_TRAVEL_LIMIT_EXCEEDED");
            t.verifyEqual(a.targetAssessments{1}.reasons,"COIL_BIND_EXCEEDED");
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
            t.verifyFalse(a.targetAssessments{1}.valid);
        end
        function damperTravelAloneIsNotReplacedByAvailableMR(t,LimitedMetric)
            [~,act,~,d,u] = springDamperFixture();
            d.damper.minimumLength = act.damper.staticLength_m-.003;
            model = fsd.model.createSpringDamperModel(act,d,u);
            [a,r] = assessment(model,[-.01;0;.01],LimitedMetric,.01,0);
            t.verifyEqual(r.motionRatioStatus(3),"AVAILABLE");
            t.verifyEqual(a.targetAssessments{1}.reasons,"DAMPER_TRAVEL_LIMIT_EXCEEDED");
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
        end
        function coilBoundarySuppressesWheelRateButNotFiniteAxialForce(t)
            [~,act,~,d,u] = springDamperFixture(); d.spring.solidHeight = .18;
            model = fsd.model.createSpringDamperModel(act,d,u); z = [-.01;0;.01];
            [a,r] = assessment(model,z,"TANGENT_WHEEL_RATE",0,7500);
            t.verifyEqual(r.springSolidStatus(2),"COIL_BIND_LIMIT");
            t.verifyEqual(a.targetAssessments{1}.reasons,"COIL_BIND_LIMIT");
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
            a = assessment(model,z,"SPRING_AXIAL_FORCE",0,600);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            a = assessment(model,z,"SPRING_AXIAL_FORCE",0,601);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_FAIL");
        end
        function unseatedSpringIsValidZeroForceNotInventedFailure(t)
            model = springDamperFixture(.002); z = [-.01;0;.01];
            [a,r] = assessment(model,z,"SPRING_AXIAL_FORCE",-.01,0);
            t.verifyEqual(r.springStatus(1),"SPRING_UNSEATED");
            t.verifyEqual(a.targetAssessments{1}.actual,0);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            a = assessment(model,z,"TANGENT_WHEEL_RATE",-.01,0);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            a = assessment(model,z,"SPRING_AXIAL_FORCE",-.01,100);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_FAIL");
        end
        function derivativeQualityReasonsRemainMetricSpecific(t,Quality)
            model = springDamperFixture(); z = [0;.01];
            if Quality == "ILL_CONDITIONED", z = [-.01;0;eps];
            elseif Quality == "NUMERICAL_RESOLUTION", z = .01+[-1e-13;0;1e-13]; end
            [a,r] = assessment(model,z,"TANGENT_WHEEL_RATE",z(2),7500,.5*z+3*z.^2);
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
            t.verifyEqual(a.targetAssessments{1}.reasons,"UNAVAILABLE_"+Quality);
            if Quality == "NUMERICAL_RESOLUTION"
                t.verifyEqual(r.motionRatioStatus(2),"AVAILABLE");
                a = assessment(model,z,"MOTION_RATIO",z(2),.5+6*z(2),.5*z+3*z.^2);
                % Native MR is usable, but this deliberately tight 1e-9 target
                % need not pass on a tiny grid. Never loosen it to hide roundoff.
                t.verifyTrue(a.targetAssessments{1}.valid);
                t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_FAIL");
                t.verifyEqual(a.targetAssessments{1}.reasons,"AVAILABLE");
            else
                a = assessment(model,z,"MOTION_RATIO",z(2),.5);
                t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
                t.verifyEqual(a.targetAssessments{1}.reasons,"UNAVAILABLE_"+Quality);
            end
        end
        function nativeIllConditionedActuationIsNotPromoted(t)
            [g,act] = actuationFixture("YZ_PLANE","UPRIGHT","PUSHROD","TANGENT_POSITIVE");
            [~,~,~,d,u] = springDamperFixture(); model = fsd.model.createSpringDamperModel(act,d,u);
            [a,r] = production(model,act,g,[-.0002;-.0001;0],"DAMPER_COMPRESSION",0);
            t.verifyTrue(r.path.converged(3)); t.verifyTrue(r.path.isIllConditioned(3));
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
            t.verifyEqual(a.targetAssessments{1}.reasons,"UNAVAILABLE_ILL_CONDITIONED");
        end
        function upstreamFailureAndNotAttemptedKeepNativeStatus(t)
            [model,act,g] = springDamperFixture(); z = [0;.5;.6];
            for x = [.5,.6]
                [a,r] = production(model,act,g,z,"SPRING_AXIAL_FORCE",x);
                j = find(z == x);
                t.verifyFalse(r.path.converged(j));
                t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
                t.verifyEqual(a.targetAssessments{1}.reasons,r.source.sweep.results(j).status);
                t.verifyNotEqual(a.targetAssessments{1}.reasons,"UNAVAILABLE_NATIVE_RESULT");
            end
        end
        function validKnownLawAndHardFailRemainUnchanged(t)
            [a,r] = assessment(springDamperFixture(),[-.01;0;.01],"TANGENT_WHEEL_RATE",0,7500);
            t.verifyEqual(r.wheelRateTotal_N_per_m,repmat(7500,3,1),"AbsTol",1e-8);
            t.verifyEqual(a.targetAssessments{1}.status,"SAMPLED_PASS");
            t.verifyEqual(a.targetAssessments{1}.reasons,"AVAILABLE");
            t.verifyEqual(a.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
            a = assessment(springDamperFixture(),[-.01;0;.01],"TANGENT_WHEEL_RATE",0,7400);
            t.verifyEqual(a.hardFeasibility,"INFEASIBLE_FOR_SPECIFICATION");
        end
        function invalidSeatGeometryHasPriorityOverDamperTravel(t)
            [~,act,~,d,u] = springDamperFixture();
            % Explicit adversarial bounds/lengths, not a real spring recommendation.
            d.spring.freeLength = .05;
            d.damper.minimumLength = act.damper.staticLength_m-.03;
            model = fsd.model.createSpringDamperModel(act,d,u);
            [a,r] = assessment(model,[0;.04;.08],"MOTION_RATIO",.08,.5);
            t.verifyLessThan(r.springSeatSeparation_m(3),0);
            t.verifyEqual(r.springSolidStatus(3),"INVALID_SPRING_SEAT_GEOMETRY");
            t.verifyEqual(r.damperTravelStatus(3),"DAMPER_TRAVEL_LIMIT_EXCEEDED");
            t.verifyEqual(a.targetAssessments{1}.reasons,"INVALID_SPRING_SEAT_GEOMETRY");
            t.verifyEqual(a.targetAssessments{1}.status,"NOT_EVALUATED");
        end
    end
end

function [a,r] = production(model,act,g,z,metric,x)
sw = fsd.kinematics.solveActuationSweep(act,fsd.kinematics.solveBumpSweep(g,z,"m"));
native = fsd.analysis.analyzeActuationSweep(act,sw);
r = fsd.analysis.analyzeSpringDamperSweep(model,act,sw,native);
c = fsd.model.createDesignCandidate(struct("id","PRODUCTION_DIAGNOSTIC","sources",{{ ...
    struct("id","MECH_FL","type","MECHANICAL","model",model,"auxiliary",act,"result",r)}}));
target = designTargetFixture("POINT_TARGET",metric,struct("x",x,"value",0,"tolerance",1e-9,"strength","HARD"));
a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
end

function [a,r] = assessment(model,z,metric,x,value,compression)
if nargin < 6, compression = .5*z; end
r = fsd.analysis.analyzePrescribedSpringDamperPath(model,z,compression,0,struct("length","m","velocity","m/s"));
c = fsd.model.createDesignCandidate(struct("id","MECHANICAL_AUDIT","sources",{{ ...
    struct("id","MECH_FL","type","MECHANICAL","model",model,"result",r)}}));
target = designTargetFixture("POINT_TARGET",metric,struct("x",x,"value",value,"tolerance",1e-9,"strength","HARD"));
a = fsd.analysis.evaluateDesignCandidate(designSpecificationFixture(target),c);
end
