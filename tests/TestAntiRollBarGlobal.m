classdef TestAntiRollBarGlobal < matlab.unittest.TestCase
    methods(TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods(Test)
        function absentBarsPreserveHistoricalRepresentationAndState(t)
            s=globalStaticFixture; same=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{});
            t.verifyEqual(same,s); t.verifyFalse(isfield(same,'antiRollBars'));
            q=[-.005;zeros(6,1)]; t.verifyEqual(fsd.analysis.evaluateGlobalStaticState(same,q),fsd.analysis.evaluateGlobalStaticState(s,q));
            d=antiRollBarInputs('COAXIAL_TORSION'); d.referenceFrame=s.sources{1}.geometry.referenceFrame;
            geometric=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{fsd.model.createAntiRollBar(d)});
            t.verifyError(@()fsd.analysis.prepareGlobalStaticSystem(geometric),'fsd:analysis:InvalidAntiRollBar');
        end
        function frontRearAndBothNominalEquilibrium(t)
            [s,o]=globalStaticFixture;
            for mode=["FRONT","REAR","BOTH"]
                bars={fsd.model.createAntiRollBar(antiRollBarInputs('EQUIVALENT_LINEAR','FRONT'))};
                if mode=="REAR", bars={fsd.model.createAntiRollBar(antiRollBarInputs('EQUIVALENT_LINEAR','REAR'))}; end
                if mode=="BOTH", bars{2}=fsd.model.createAntiRollBar(antiRollBarInputs('EQUIVALENT_LINEAR','REAR')); end
                coupled=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,bars);
                r=fsd.analysis.solveGlobalStaticEquilibrium(coupled,[-.005;zeros(6,1)],o);
                t.assertEqual(r.selectedIndex,1); state=r.alternatives{1}.state;
                t.verifyEqual(state.normalForces_N,500*ones(4,1),'AbsTol',1e-6);
                t.verifyEqual(state.potentialEnergy_J,695,'AbsTol',1e-6);
                t.verifyEqual(state.antiRollBarEnergy_J,0,'AbsTol',1e-20);
                t.verifyEqual(r.alternatives{1}.stability,"LOCAL_STABLE_MINIMUM");
                t.verifyTrue(fsd.analysis.validateGlobalStaticEquilibrium(r,coupled));
            end
        end
        function independentCoupledGradientAndHessian(t)
            s=globalStaticFixture; b=fsd.model.createAntiRollBar(antiRollBarInputs);
            coupled=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{b});
            q=[-.015;.002;-.003;.001;-.002;.003;-.001];
            old=fsd.analysis.evaluateGlobalStaticState(s,q); state=fsd.analysis.evaluateGlobalStaticState(coupled,q);
            delta=q(5)-q(4); expected=zeros(7,1); expected(4:5)=10000*delta*[-1;1];
            t.verifyEqual(state.residual-old.residual,expected,'AbsTol',1e-10);
            h=2e-7; numerical=zeros(7,1);
            for i=1:7
                e=zeros(7,1); e(i)=h; a=fsd.analysis.evaluateGlobalStaticState(coupled,q-e); c=fsd.analysis.evaluateGlobalStaticState(coupled,q+e);
                numerical(i)=(c.potentialEnergy_J-a.potentialEnergy_J)/(2*h);
            end
            t.verifyEqual(state.residual,numerical,'AbsTol',3e-5);
            H=state.candidateHessian-old.candidateHessian; expectedH=zeros(7); expectedH(4:5,4:5)=10000*[1,-1;-1,1];
            t.verifyEqual(H,expectedH,'AbsTol',1e-9);
            t.verifyEqual(state.worldForceResidual_N,old.worldForceResidual_N);
            t.verifyEqual(state.worldMomentResidual_Nm,old.worldMomentResidual_Nm);
        end
        function preloadedBarChangesCrossweightThroughCoupledSolve(t)
            [s,o]=globalStaticFixture; d=antiRollBarInputs; d.referenceMode="DECLARED_FREE";
            d.parameters.freeDeflection_m=.003; d.provenance.freeDeflection_m=struct('sourceKind',"ASSUMED",'sourceNote',"Explicit preload test");
            coupled=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{fsd.model.createAntiRollBar(d)});
            r=fsd.analysis.solveGlobalStaticEquilibrium(coupled,[-.005;zeros(6,1)],o); t.assertEqual(r.selectedIndex,1);
            a=r.alternatives{1}; t.verifyLessThan(norm(a.state.worldMomentResidual_Nm),1e-7);
            t.verifyGreaterThan(abs(a.state.crossweightActualSumFraction-.5),1e-4);
            t.verifyGreaterThan(a.state.antiRollBars{1}.energy_J,0);
        end
        function airborneWheelRemainsMechanicallyConnected(t)
            s=globalStaticFixture; d=antiRollBarInputs; d.referenceMode="DECLARED_FREE";
            d.parameters.freeDeflection_m=.01; d.provenance.freeDeflection_m=struct('sourceKind',"ASSUMED",'sourceNote',"Disconnected ground is not disconnected bar");
            coupled=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{fsd.model.createAntiRollBar(d)});
            state=fsd.analysis.evaluateGlobalStaticState(coupled,[.02;0;0;.005;0;0;0]);
            t.verifyEqual(state.corners{1}.tire.normalForce_N,0); t.verifyEqual(state.corners{1}.tire.contactStatus,"AIRBORNE");
            t.verifyNotEqual(state.antiRollBars{1}.resistance_N(1),0);
        end
        function knownThreeContactEquilibriumKeepsAirborneBarForce(t)
            s=globalStaticFixture; normal=[0;800;800;400]; q=[-.005;0;0;.008;-.003;-.003;.001];
            points=zeros(4,3);
            for i=1:4, g=s.sources{i}.geometry; points(i,:)=fsd.model.getPoint(g,g.cornerId+"_WHEEL_CENTER"); end
            cg=[normal'*points(:,1:2)/2000,.3];
            % Independent wheel equilibrium: ks*MR*(preload+MR*z)+rARB=N.
            % kARB=10000, free=-.02, delta=zR-zL -> rARB=[-90;+90].
            preload=(normal-[-90;90;0;0])/10000-.5*q(4:7);
            [s,o]=globalStaticFixture(preload,zeros(4,1),cg);
            d=antiRollBarInputs; d.referenceMode="DECLARED_FREE"; d.parameters.freeDeflection_m=-.02;
            d.provenance.freeDeflection_m=struct('sourceKind',"ASSUMED",'sourceNote',"Independent three-contact equilibrium oracle");
            s=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{fsd.model.createAntiRollBar(d)});
            result=fsd.analysis.solveGlobalStaticEquilibrium(s,q,o); t.assertEqual(result.selectedIndex,1);
            a=result.alternatives{1}; t.verifyEqual(a.state.normalForces_N,normal,'AbsTol',1e-7);
            t.verifyEqual(a.state.antiRollBars{1}.resistance_N,[-90;90],'AbsTol',1e-9);
            t.verifyEqual(a.state.corners{1}.tire.contactStatus,"AIRBORNE");
            t.verifyLessThan(norm(a.state.residual),1e-6); t.verifyLessThan(norm(a.state.worldMomentResidual_Nm),1e-6);
            t.verifyEqual(a.stability,"LOCAL_STABLE_MINIMUM");
        end
        function activeDomainBoundaryDoesNotCertifySmoothStability(t)
            [s,o]=globalStaticFixture; d=antiRollBarInputs; d.parameters.wheelTravelDomain_m=[-.05,0;-.05,.05];
            o.selection="LOWEST_ENERGY_STABLE";
            s=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{fsd.model.createAntiRollBar(d)});
            result=fsd.analysis.solveGlobalStaticEquilibrium(s,[-.005;zeros(6,1)],o);
            t.assertNumElements(result.alternatives,1); a=result.alternatives{1};
            t.verifyFalse(a.state.bilateralHessianAvailable); t.verifyEqual(a.stability,"STABILITY_NOT_EVALUABLE");
            t.verifyTrue(isnan(result.selectedIndex));
        end
        function activeCouplingDomainRejectsWithoutClipping(t)
            s=globalStaticFixture; d=antiRollBarInputs; d.parameters.deflectionDomain_m=[-.001,.001];
            coupled=fsd.model.createGlobalStaticSystem(s.vehicle,s.loadCase,s.sources,s.tires,s.options,{fsd.model.createAntiRollBar(d)});
            a=fsd.analysis.evaluateGlobalStaticState(coupled,[-.005;0;0;.01;0;0;0]);
            t.verifyFalse(a.feasible); t.verifyTrue(isnan(a.potentialEnergy_J));
            t.verifyEqual(a.antiRollBars{1}.status,"OUT_OF_DOMAIN");
        end
    end
end
