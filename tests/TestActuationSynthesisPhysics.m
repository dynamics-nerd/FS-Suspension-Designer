classdef TestActuationSynthesisPhysics < matlab.unittest.TestCase
    properties (TestParameter)
        Architecture={"PUSHROD","PULLROD"}
        Corner={"FL","FR","RL","RR"}
        Body={"UPRIGHT","UCA","LCA"}
        Degeneracy={"ROD_LENGTH","DAMPER_LENGTH","ROD_LEVER","DAMPER_LEVER"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function freshNativePhysicsAndMechanicalAssociation(t,Architecture,Corner)
            s=actuationSynthesisFixture(Architecture,Corner); original=s;
            e=fsd.synthesis.evaluateActuationCandidate(s,[.75;.25]);
            t.verifyTrue(e.eligible); t.verifyEqual(e.geometry,s.seed);
            t.verifyNotEqual(e.actuationIdentity,s.seedActuation.identity);
            t.verifyNotEqual(e.mechanicalIdentity,s.seedMechanical.identity);
            t.verifyEqual(e.mechanical.spring,s.seedMechanical.spring); t.verifyEqual(e.mechanical.damper,s.seedMechanical.damper);
            t.verifyEqual(e.mechanical.actuationIdentity,e.actuationIdentity);
            b=fsd.kinematics.solveBumpSweep(e.geometry,s.plan.travel_m,'m',s.plan.solverOptions);
            a=fsd.kinematics.solveActuationSweep(e.actuation,b);
            q=fsd.analysis.analyzeActuationSweep(e.actuation,a);
            m=fsd.analysis.analyzeSpringDamperSweep(e.mechanical,e.actuation,a,q,s.plan.wheelVelocity_m_per_s,'m/s');
            t.verifyEqual(e.actuationEvidence.analysis.damperMotionRatio,q.damperMotionRatio,'AbsTol',1e-10);
            t.verifyEqual(e.actuationEvidence.sweep.rockerAngle_rad,a.rockerAngle_rad,'AbsTol',1e-10);
            t.verifyEqual(e.mechanicalEvidence.analysis.wheelRateTotal_N_per_m,m.wheelRateTotal_N_per_m,'AbsTol',1e-7);
            t.verifyEqual(s,original); t.verifyTrue(fsd.synthesis.validateActuationSynthesisEvaluation(e,s));
        end
        function rigidAttachmentsRockerAndLinks(t,Architecture,Body)
            [g,~,~,d,md,units]=actuationSynthesisSeed(Architecture);
            d.suspensionAttachment.body=Body;
            if Body=="UCA", d.suspensionAttachment.point(3)=.35; end
            if Body=="LCA", d.suspensionAttachment.point(3)=.15; end
            a=fsd.model.createActuationGeometry(g,d,'m'); m=fsd.model.createSpringDamperModel(a,md,units);
            s=actuationSynthesisFixture(Architecture); s=rebuildActuationSpace(s,s.specification.definitionSI,s.plan,a,m);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.75;.25]); sweep=e.actuationEvidence.sweep;
            t.verifyTrue(sweep.allConverged);
            initialDistance=norm(e.actuation.rocker.actuationRodPoint.pointStatic_m-e.actuation.rocker.damperPoint.pointStatic_m);
            u=e.actuation.rocker.axis.direction_unit; axisPoint=e.actuation.rocker.axis.point_m;
            rodRadius=norm(cross(e.actuation.rocker.actuationRodPoint.pointStatic_m-axisPoint,u));
            joint="UBJ"; if Body=="LCA", joint="LBJ"; end
            pointId=g.cornerId+"_"+joint;
            initialAttachmentDistance=norm(a.suspensionAttachment.pointStatic_m-fsd.model.getPoint(g,pointId));
            for j=1:numel(sweep.results)
                r=sweep.results(j); state=r.sourceResult.state;
                jointPoint=state.xyz_m(state.pointIds==pointId,:);
                t.verifyEqual(norm(r.suspensionAttachmentCurrent_m-jointPoint),initialAttachmentDistance,'AbsTol',2e-9);
                t.verifyEqual(norm(r.suspensionAttachmentCurrent_m-r.rockerRodPointCurrent_m), ...
                    e.actuation.actuationRod.staticLength_m,'AbsTol',2e-9);
                t.verifyEqual(norm(r.rockerRodPointCurrent_m-r.rockerDamperPointCurrent_m),initialDistance,'AbsTol',2e-12);
                t.verifyEqual(norm(cross(r.rockerRodPointCurrent_m-axisPoint,u)),rodRadius,'AbsTol',2e-12);
                t.verifyEqual(r.damperCompression_m,e.actuation.damper.staticLength_m-r.damperLength_m,'AbsTol',2e-14);
            end
        end
        function independentDerivativesAndFullWheelRate(t,Architecture)
            s=actuationSynthesisFixture(Architecture); p=s.plan; p.travel_m=.01+[-1e-4;0;1e-4];
            p.wheelVelocity_m_per_s=0; s=rebuildActuationSpace(s,s.specification.definitionSI,p);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.75;.25]); a=e.actuation; w=e.mechanicalEvidence.analysis;
            [c,mr,curvature,rate,theta]=actuationSynthesisReference(a,.01,30000,.02);
            t.verifyEqual(e.actuationEvidence.sweep.damperCompression_m(2),c,'AbsTol',2e-9);
            t.verifyEqual(e.actuationEvidence.sweep.rockerAngle_rad(2),theta,'AbsTol',1e-10);
            t.verifyEqual(e.actuationEvidence.analysis.damperMotionRatio(2),mr,'AbsTol',2e-5);
            t.verifyEqual(w.wheelRateStatus(2),"AVAILABLE");
            t.verifyEqual(w.wheelRateTotal_N_per_m(2),rate,'AbsTol',.5); % 3-point truncation at 1e-4 m
            t.verifyEqual(w.springAxialForce_N(2),30000*max(.02+c,0),'AbsTol',1e-7);
            t.verifyEqual(w.wheelRateTotal_N_per_m,w.wheelRateElastic_N_per_m+w.wheelRateGeometric_N_per_m,'AbsTol',1e-10);
            t.verifyGreaterThan(abs(600*curvature),1); % full model is not k*MR^2
            step=1e-5; lengths=zeros(2,1);
            for j=1:2
                z=.01+(2*j-3)*step; b=fsd.kinematics.solveBump(s.seed,z,'m'); r=fsd.kinematics.solveActuation(a,b);
                t.verifyTrue(r.converged); lengths(j)=r.damperLength_m;
            end
            fd=-(lengths(2)-lengths(1))/(2*step);
            t.verifyEqual(fd,mr,'AbsTol',2e-6); t.verifyEqual(e.actuationEvidence.analysis.damperMotionRatio(2),fd,'AbsTol',2e-5);
        end
        function genuineDistinctArchitecturesAndProgressivity(t)
            [g,push,m]=actuationSynthesisSeed('PUSHROD'); [~,pull]=actuationSynthesisSeed('PULLROD');
            t.verifyNotEqual(push.rocker.axis.point_m,pull.rocker.axis.point_m);
            t.verifyNotEqual(push.damper.chassisPoint.point_m,pull.damper.chassisPoint.point_m);
            t.verifyEqual(push.cornerGeometryIdentity,pull.cornerGeometryIdentity);
            [~,~,pushCurvature]=actuationSynthesisReference(push,0,30000,.02);
            [~,~,pullCurvature]=actuationSynthesisReference(pull,0,30000,.02);
            t.verifyLessThan(pushCurvature,0); t.verifyGreaterThan(pullCurvature,0);
            b=fsd.kinematics.solveBumpSweep(g,[-.01;0;.01],'m');
            ap=fsd.kinematics.solveActuationSweep(push,b); al=fsd.kinematics.solveActuationSweep(pull,b);
            t.verifyTrue(ap.allConverged && al.allConverged);
            t.verifyNotEqual(ap.damperCompression_m,al.damperCompression_m);
            t.verifyEqual(m.spring.rate_N_per_m,30000); % explicitly ASSUMED data
        end
        function negativeMotionRatioRemainsSigned(t)
            s=actuationSynthesisFixture(); [g,~,~,d,md,units]=actuationSynthesisSeed;
            d.damper.chassisPoint(2)=-.22; a=fsd.model.createActuationGeometry(g,d,'m');
            m=fsd.model.createSpringDamperModel(a,md,units); def=s.specification.definitionSI;
            q=def.parameters{1}.definitionSI; q.value=-.22; q.bounds=q.value+[-.01,.01];
            def.parameters{1}=fsd.model.createDesignParameter(q,'m'); s=rebuildActuationSpace(s,def,s.plan,a,m);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]); analysis=e.actuationEvidence.analysis;
            t.verifyLessThan(analysis.staticDamperMotionRatio,0);
            t.verifyEqual(analysis.installationRatio,abs(analysis.damperMotionRatio));
            w=e.mechanicalEvidence.analysis;
            t.verifyEqual(w.springWheelResistance_N,w.springAxialForce_N.*w.damperMotionRatio,'AbsTol',1e-9);
            t.verifyLessThan(w.springWheelResistance_N(5),0);
        end
        function unresolvedCurvatureNeverBecomesElasticRate(t)
            s=actuationSynthesisFixture(); p=s.plan; p.travel_m=.01+[-1e-9;0;1e-9]; p.wheelVelocity_m_per_s=0;
            d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            for j=1:numel(targets)
                q=targets{j}.definitionSI; q.x=.01;
                unit=q.unit; targets{j}=fsd.model.createDesignTarget(q,unit,'m');
            end
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildActuationSpace(s,d,p);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]); w=e.mechanicalEvidence.analysis;
            t.verifyTrue(e.actuationEvidence.sweep.allConverged);
            t.verifyEqual(w.wheelRateStatus(2),"UNAVAILABLE_NUMERICAL_RESOLUTION");
            t.verifyTrue(isnan(w.wheelRateTotal_N_per_m(2))); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisEvaluation(e,s));
        end
        function physicalFailuresAndNativeGaps(t)
            s=actuationSynthesisFixture(); p=s.plan; p.travel_m=[-.02;0;.4]; p.wheelVelocity_m_per_s=0;
            s=rebuildActuationSpace(s,s.specification.definitionSI,p);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]);
            t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyFalse(e.bumpEvidence.sweep.allConverged); t.verifyFalse(e.actuationEvidence.sweep.allConverged);
            t.verifyTrue(any(isnan(e.actuationEvidence.sweep.damperCompression_m)));
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisEvaluation(e,s));
        end
        function knownDegenerateBuildersUseNoSolves(t,Degeneracy)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI;
            if Degeneracy=="ROD_LENGTH"
                role="ACTUATION_ROD_SUSPENSION"; columns=[2,3]; goal=s.seedPoints_m(2,:);
                expected="fsd:synthesis:ZeroLengthActuationRod";
            elseif Degeneracy=="DAMPER_LENGTH"
                role="DAMPER_CHASSIS"; columns=[1,2,3]; goal=s.seedPoints_m(3,:);
                expected="fsd:synthesis:ZeroLengthActuationDamper";
            elseif Degeneracy=="ROD_LEVER"
                role="ACTUATION_ROD_ROCKER"; columns=2; goal=s.seedPoints_m(5,:);
                expected="fsd:model:RockerLeverArmDegenerate";
            else
                role="DAMPER_ROCKER"; columns=3; goal=s.seedPoints_m(5,:);
                expected="fsd:model:RockerDamperLeverArmDegenerate";
            end
            d.parameters=cell(numel(columns),1); values=zeros(numel(columns),1); bindings=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
            point=fsd.model.getActuationDesignPoint(s.seedActuation,"FL_"+role);
            for j=1:numel(columns)
                column=columns(j); values(j)=goal(column);
                p=struct('id',"VARIABLE_"+j,'quantity',"LENGTH",'scope',fsd.model.designScope('HARDPOINT',"FL_"+role,'FL'), ...
                    'type',"FREE",'binding',bindings(column),'value',point(column),'bounds',sort([point(column),goal(column)]), ...
                    'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit native degeneracy control");
                d.parameters{j}=fsd.model.createDesignParameter(p,'m');
            end
            s=rebuildActuationSpace(s,d); u=fsd.synthesis.normalizeActuationVariables(s,values);
            profile clear; profile on; e=fsd.synthesis.evaluateActuationCandidate(s,u); profile off;
            info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","solveBump","solveActuationSweep"])));
            t.verifyEqual(e.exceptionId,expected); t.verifyFalse(e.geometryValid); t.verifyFalse(e.eligible);
            t.verifyEmpty(e.bumpEvidence); t.verifyEmpty(e.actuationEvidence); t.verifyEmpty(e.mechanicalEvidence);
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisEvaluation(e,s));
        end
    end
end
