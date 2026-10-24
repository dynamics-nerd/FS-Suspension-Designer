classdef TestTirePhysics < matlab.unittest.TestCase
    % Algebraic oracles, not fits to a real tire or MathWorks equivalence.
    % The synthetic case uses declared SI parameters. Expectations below use
    % the defining lambda polynomial, independently of production responseCore.
    methods(TestClassSetup)
        function sourcePath(t)
            old=path; t.addTeardown(@()path(old));
            root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'));
        end
    end
    methods(Test)
        function referenceSmallSlipSlopes(t)
            tire=physicsTire(); h=1e-7;
            lateral=fsd.tire.evaluate(tire,state(800,[-h;h],0,0));
            longitudinal=fsd.tire.evaluate(tire,state(800,0,[-h;h],0));
            camber=fsd.tire.evaluate(tire,state(800,0,0,[-h;h]));
            t.verifyEqual(diff(lateral.Fy_N)/(2*h),-12000,'AbsTol',1e-7);
            % kappa/(1+kappa) has central-difference error O(h^2).
            t.verifyEqual(diff(longitudinal.Fx_N)/(2*h),16000,'AbsTol',1e-6);
            t.verifyEqual(diff(camber.Fy_N)/(2*h),900,'AbsTol',1e-7);
            t.verifyEqual(lateral.Fx_N,zeros(2,1));
        end

        function combinedPolynomialOracleAndCircularBound(t)
            tire=physicsTire();
            a=[.01;.06;-.12;.18]; b=[.01;.08;-.18;.3]; g=[0;.03;-.05;.08];
            r=fsd.tire.evaluate(tire,state(800,a,b,g));
            % L=mu0*Fz*(1-q*gamma^2), fixed reference load.
            L=1.2*800*(1-2*g.^2);
            dx=16000*b./(1+b); dy=(-12000*tan(a)+900*g)./(1+b);
            demand=hypot(dx,dy); lambda=L./(2*demand);
            f=ones(size(lambda)); sliding=lambda<1;
            f(sliding)=lambda(sliding).*(2-lambda(sliding));
            t.verifyEqual(r.Fx_N,dx.*f,'AbsTol',5e-12);
            t.verifyEqual(r.Fy_N,dy.*f,'AbsTol',5e-12);
            t.verifyLessThanOrEqual(hypot(r.Fx_N,r.Fy_N),L);
            t.verifyEqual(r.status(:,1:2),repmat("AVAILABLE",4,2));
        end

        function transitionAtLambdaOneIsContinuous(t)
            tire=physicsTire(); L=960; C=12000;
            % Pure lateral demand C*tan(alpha)=L/2 at the transition.
            multipliers=[1-1e-7;1;1+1e-7]; demand=L/2*multipliers;
            a=atan(demand/C); r=fsd.tire.evaluate(tire,state(800,a,0,0));
            lambda=L./(2*demand); f=ones(3,1);
            f(3)=lambda(3)*(2-lambda(3));
            t.verifyEqual(r.Fy_N,-demand.*f,'AbsTol',1e-11);
            t.verifyEqual(r.Fy_N(2),-L/2,'AbsTol',1e-11);
            slopes=diff(r.Fy_N)./diff(a);
            expectedSlope=-C*(1+(L/(2*C))^2);
            t.verifyEqual(slopes,repmat(expectedSlope,2,1),'RelTol',1e-6);
        end

        function declaredLoadPowersAreIndependent(t)
            [~,d]=physicsTire();
            d.force.capacityLoad="POWER"; d.force.lateralLoad="POWER";
            d.force.longitudinalLoad="POWER";
            tire=fsd.tire.create(d); z=[400;800;1600];
            % Capacity exponent .8 differs from stiffness exponents .6/1.1.
            a=.08; b=.1; r=fsd.tire.evaluate(tire,state(z,a,b,0));
            L=1.2*800*(z/800).^.8;
            ca=12000*(z/800).^.6; ck=16000*(z/800).^1.1;
            dx=ck*b/(1+b); dy=-ca*tan(a)/(1+b);
            lambda=L./(2*hypot(dx,dy)); f=lambda.*(2-lambda);
            t.assertLessThan(lambda,ones(3,1));
            t.verifyEqual(r.Fx_N,dx.*f,'AbsTol',5e-12);
            t.verifyEqual(r.Fy_N,dy.*f,'AbsTol',5e-12);
        end

        function thrustDoesNotStandInForCapacityEffect(t)
            [base,d]=physicsTire();
            d.force.parameters.qGamma_per_rad2=0;
            unchangedCapacity=fsd.tire.create(d);
            % At small gamma and zero slip, force is the unsaturated thrust.
            a=fsd.tire.evaluate(base,state(800,0,0,.01));
            b=fsd.tire.evaluate(unchangedCapacity,state(800,0,0,.01));
            t.verifyEqual(a.Fy_N,9,'AbsTol',1e-12);
            t.verifyEqual(a.Fy_N,b.Fy_N);
            % At large demand, q changes the force limit, not Cgamma.
            a=fsd.tire.evaluate(base,state(800,.2,.3,.2));
            b=fsd.tire.evaluate(unchangedCapacity,state(800,.2,.3,.2));
            t.verifyLessThan(hypot(a.Fx_N,a.Fy_N),hypot(b.Fx_N,b.Fy_N));
            t.verifyEqual(a.Fy_N/a.Fx_N,b.Fy_N/b.Fx_N,'AbsTol',1e-14);
        end

        function nonpositiveCamberCapacityIsNotClipped(t)
            [~,d]=physicsTire(); d.force.parameters.qGamma_per_rad2=100;
            tire=fsd.tire.create(d);
            r=fsd.tire.evaluate(tire,state(800,.03,0,[.1;.15]));
            t.verifyEqual(r.status(:,1:2),repmat("OUT_OF_DOMAIN",2,2));
            t.verifyTrue(all(isnan([r.Fx_N;r.Fy_N])));
        end

        function kappaSingularityIsExplicit(t)
            tire=physicsTire();
            r=fsd.tire.evaluate(tire,state(800,0,[-1.1;-1;-.99],0));
            t.verifyEqual(r.status(1:2,1:2),repmat("INVALID_INPUT",2,2));
            t.verifyTrue(all(isnan(r.Fx_N(1:2))));
            t.verifyEqual(r.status(3,1:2),["AVAILABLE","AVAILABLE"]);
            t.verifyLessThan(abs(r.Fx_N(3)),960);
            [~,d]=physicsTire(); d.force.domain.kappa=[-1,.5];
            t.verifyError(@()fsd.tire.create(d),'fsd:tire:InvalidDefinition');
        end

        function physicalZerosAndNoContactAreDistinct(t)
            tire=physicsTire(); r=fsd.tire.evaluate(tire,state([800;0],[0;.1],[0;.1],0));
            t.verifyEqual([r.Fx_N,r.Fy_N],zeros(2,2));
            t.verifyEqual(r.status(1,1:2),["AVAILABLE","AVAILABLE"]);
            t.verifyEqual(r.status(2,1:2),["NO_CONTACT","NO_CONTACT"]);
            t.verifyTrue(r.assumptionBased);
            t.verifyEqual(r.evidence,"ASSUMPTION_BASED");
            t.verifyEqual(r.provenance,tire.definition.provenance);
        end

        function unavailableIsNaNAndNotZero(t)
            empty=fsd.tire.create(struct('id',"DIMENSIONS_PENDING"));
            r=fsd.tire.evaluate(empty,state(800,0,0,0));
            t.verifyEqual(r.status(1,1:2),["NOT_SUPPORTED","NOT_SUPPORTED"]);
            t.verifyTrue(all(isnan([r.Fx_N,r.Fy_N])));
            report=fsd.tire.readiness(empty,state(800,0,0,0));
            t.verifyEqual(report.status,"UNSUPPORTED");
            [~,d]=physicsTire(); d.force.parameters.Calpha_N_per_rad=[];
            incomplete=fsd.tire.create(d); r=fsd.tire.evaluate(incomplete,state(800,.03,0,0));
            t.verifyEqual(r.status(1,1:2),["MISSING_DATA","MISSING_DATA"]);
            t.verifyTrue(all(isnan([r.Fx_N,r.Fy_N])));
            t.verifyTrue(contains(r.diagnostics(1,2),"PARAMETER:Calpha_N_per_rad"));
        end

        function readinessRequiresOnlyConsumedStiffness(t)
            [~,d]=physicsTire(); d.force.parameters.Ckappa_N=[];
            tire=fsd.tire.create(d); q=struct('channels',"Fy",'domainPolicy',"REJECT");
            report=fsd.tire.readiness(tire,state(800,.03,0,0),q);
            t.verifyEqual(report.status,"READY");
            report=fsd.tire.readiness(tire,state(800,.03,.02,0),q);
            t.verifyEqual(report.status,"MISSING_DATA");
            t.verifyTrue(any(contains(report.missing,"PARAMETER:Ckappa_N")));
            t.verifyError(@()fsd.tire.evaluate(tire,state(800,.03,.02,0),q),'fsd:tire:NotReady');
        end

        function referenceOnlyAndDeclaredDomainAreEnforced(t)
            [~,d]=physicsTire(); d.force.capacityLoad="REFERENCE_ONLY";
            tire=fsd.tire.create(d); s=state([800;801],.03,0,0);
            r=fsd.tire.evaluate(tire,s);
            t.verifyEqual(r.status(:,2),["AVAILABLE";"OUT_OF_DOMAIN"]);
            t.verifyTrue(isnan(r.Fy_N(2)));
            report=fsd.tire.readiness(tire,s,struct('domainPolicy',"REJECT"));
            t.verifyEqual(report.status,"OUT_OF_DOMAIN");
            [~,d]=physicsTire(); d.force.domain.alpha_rad=[];
            tire=fsd.tire.create(d); r=fsd.tire.evaluate(tire,state(800,0,0,0));
            t.verifyEqual(r.status(1,2),"MISSING_DATA");
            t.verifyTrue(contains(r.diagnostics(1,2),"DOMAIN:alpha_rad"));
        end

        function unsupportedRequestedMomentIsExplicit(t)
            tire=physicsTire(); q=struct('channels',"Mz",'domainPolicy',"REJECT");
            report=fsd.tire.readiness(tire,state(800,.03,0,0),q);
            t.verifyEqual(report.status,"UNSUPPORTED");
            t.verifyError(@()fsd.tire.evaluate(tire,state(800,.03,0,0),q),'fsd:tire:NotReady');
            % A ready force must not hide a simultaneously requested moment.
            q.channels=["Fx","Mz"];
            report=fsd.tire.readiness(tire,state(800,.03,0,0),q);
            t.verifyNotEqual(report.status,"READY");
        end

        function vectorAndScalarAreIdenticalWithoutCartesianExpansion(t)
            tire=physicsTire(); a=[-.12,0,.09]; b=[-.2,0,.2];
            r=fsd.tire.evaluate(tire,state(800,a,b,.03));
            t.verifySize(r.Fx_N,[3,1]);
            t.verifyEqual(r.states.alpha_rad,a');
            t.verifyEqual(r.states.Fz_N,800*ones(3,1));
            for k=1:3
                one=fsd.tire.evaluate(tire,state(800,a(k),b(k),.03));
                t.verifyEqual(r.Fx_N(k),one.Fx_N);
                t.verifyEqual(r.Fy_N(k),one.Fy_N);
                t.verifyEqual(r.status(k,:),one.status);
            end
            t.verifyError(@()fsd.tire.evaluate(tire,state([800;900],a,b,0)), ...
                'fsd:tire:InvalidStates');
        end

        function lateralAndCamberReflectionPreservesLongitudinalForce(t)
            tire=physicsTire(); r=fsd.tire.evaluate(tire,state(800,[.1;-.1],.12,[.06;-.06]));
            t.verifyEqual(r.Fx_N(1),r.Fx_N(2),'AbsTol',1e-12);
            t.verifyEqual(r.Fy_N(1),-r.Fy_N(2),'AbsTol',1e-12);
            g=.07;
            right=fsd.tire.contactFrame([-1,0,0],[0,cos(g),sin(g)],"FR");
            left=fsd.tire.contactFrame([-1,0,0],[0,-cos(g),sin(g)],"FL");
            expected=diag([-1,-1,1]);
            t.verifyEqual(right.rotationContactToGlobal,expected,'AbsTol',1e-14);
            t.verifyEqual(left.rotationContactToGlobal,expected,'AbsTol',1e-14);
            t.verifyEqual(right.gamma_rad,g,'AbsTol',1e-14);
            t.verifyEqual(left.gamma_rad,-g,'AbsTol',1e-14);
            t.verifyEqual(det(left.rotationContactToGlobal),1,'AbsTol',1e-14);
        end

        function inclinedRoadFrameRemainsProperAndAxisSignIndependent(t)
            n=[.1,.2,1]; h=[-1,.3,.2]; axis=[.03,1,.08];
            a=fsd.tire.contactFrame(h,axis,"RR",n);
            b=fsd.tire.contactFrame(h,-axis,"RR",n);
            R=a.rotationContactToGlobal;
            t.verifyEqual(R'*R,eye(3),'AbsTol',1e-14);
            t.verifyEqual(det(R),1,'AbsTol',1e-14);
            t.verifyEqual(R(:,3),n'/norm(n),'AbsTol',1e-14);
            t.verifyEqual(a.gamma_rad,b.gamma_rad,'AbsTol',1e-14);
            t.verifyError(@()fsd.tire.contactFrame([0,0,1],axis,"RR"),'fsd:tire:InvalidFrame');
        end
    end
end

function [tire,d]=physicsTire()
% Deliberately synthetic, not representative of a Formula Student tire.
p=struct('Fz0_N',800,'mu0',1.2,'Calpha_N_per_rad',12000, ...
    'Ckappa_N',16000,'Cgamma_N_per_rad',900,'n',.8, ...
    'pAlpha',.6,'pKappa',1.1,'qGamma_per_rad2',2);
provenance=struct();
for name=string(fieldnames(p))'
    provenance.(name)=struct('sourceKind',"ASSUMED", ...
        'sourceNote',"Synthetic algebraic test case; not measured tire data.");
end
force=struct('family',"DUGOFF_REDUCED_1",'parameters',p, ...
    'domain',struct('Fz_N',[0,2000],'alpha_rad',[-.5,.5], ...
        'kappa',[-.99,.5],'gamma_rad',[-.3,.3]), ...
    'capacityLoad',"CONSTANT_MU",'lateralLoad',"CONSTANT", ...
    'longitudinalLoad',"CONSTANT",'camberThrust',"LINEAR_CONSTANT", ...
    'camberCapacity',"QUADRATIC");
d=struct('id',"SYNTHETIC_PHYSICS",'name',"Algebraic verification only", ...
    'level',"GENERIC",'force',force,'provenance',provenance, ...
    'evidence',"ASSUMPTION_BASED",'note',"Not a tire recommendation.");
tire=fsd.tire.create(d);
end

function s=state(z,a,k,g)
s=struct('Fz_N',z,'alpha_rad',a,'kappa',k,'gamma_rad',g);
end
