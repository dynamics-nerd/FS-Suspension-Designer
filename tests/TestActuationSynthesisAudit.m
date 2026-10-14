classdef TestActuationSynthesisAudit < matlab.unittest.TestCase
    properties (TestParameter)
        ParameterRole={"FIXED","RANGE","FREE"}
        InvalidPlan={"DUPLICATE","VELOCITY","OPTIONS","MISSING_VELOCITY"}
        Regime={"UNSEATED","COIL_BIND","DAMPER_LIMIT"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function knownMechanicalParametersAreNotOptimizationVariables(t,ParameterRole)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI;
            p=struct('id',"KNOWN_RATE",'quantity',"STIFFNESS",'scope',fsd.model.designScope('COMPONENT','MECH','FL'), ...
                'type',ParameterRole,'binding',"SPRING_RATE",'value',30000,'availability',"ASSUMED", ...
                'sourceKind',"ASSUMED",'sourceNote',"Explicit test-only known rate constraint");
            if ParameterRole=="FIXED", p.comparisonTolerance=0; else, p.bounds=[25000,35000]; end
            d.parameters{end+1,1}=fsd.model.createDesignParameter(p,'N/m');
            if ParameterRole=="FREE"
                t.verifyError(@()rebuildActuationSpace(s,d),'fsd:synthesis:InvalidInput'); return;
            end
            s=rebuildActuationSpace(s,d); t.verifyNumElements(s.variables,2);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.75;.25]);
            t.verifyEqual(e.mechanical.spring.rate_N_per_m,30000); t.verifyTrue(e.eligible);
            t.verifyEqual(e.assessment.parameterAssessments{3}.status,"SAMPLED_PASS");
        end
        function invalidNumericalPlansRejected(t,InvalidPlan)
            s=actuationSynthesisFixture(); p=s.plan;
            switch InvalidPlan
                case "DUPLICATE", p.travel_m=[0;0];
                case "VELOCITY", p.wheelVelocity_m_per_s=NaN;
                case "OPTIONS", p.solverOptions.UndeclaredOption=1;
                case "MISSING_VELOCITY", p=rmfield(p,'wheelVelocity_m_per_s');
            end
            id='fsd:synthesis:InvalidInput'; if InvalidPlan=="OPTIONS", id='fsd:kinematics:InvalidOptions'; end
            t.verifyError(@()rebuildActuationSpace(s,s.specification.definitionSI,p),id);
        end
        function dependentAxisCoordinatesCannotBeFrozenIndirectly(t)
            [g,a]=actuationFixture('CUSTOM'); point=a.rocker.axis.point_m;
            free=struct('id',"AXIS_X",'quantity',"LENGTH",'scope',fsd.model.designScope('HARDPOINT','FL_ROCKER_AXIS_POINT','FL'), ...
                'type',"FREE",'binding',"HARDPOINT_X",'value',point(1),'bounds',point(1)+[-.01,.01], ...
                'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit line-coordinate test");
            fixed=free; fixed.id="AXIS_Z_FIXED"; fixed.type="FIXED"; fixed.binding="HARDPOINT_Z";
            fixed.value=point(3); fixed.bounds=[]; fixed.comparisonTolerance=.1;
            spec=fsd.model.createDesignSpecification(struct('id',"INDIRECT_FIXED", ...
                'parameters',{{fsd.model.createDesignParameter(free,'m');fsd.model.createDesignParameter(fixed,'m')}}));
            t.verifyError(@()fsd.synthesis.createActuationDesignSpace(g,a,[],spec,struct('travel_m',0)), ...
                'fsd:synthesis:InvalidInput');
        end
        function scalarRockerTargetDoesNotNeedAnMrStencil(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            q=targets{3}.definitionSI; q.x=0; d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(q,'rad','m')});
            p=s.plan; p.travel_m=0; p.wheelVelocity_m_per_s=0;
            s=rebuildActuationSpace(s,d,p); e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]);
            t.verifyTrue(e.eligible); t.verifyEqual(e.assessment.targetAssessments{1}.status,"SAMPLED_PASS");
            t.verifyTrue(isnan(e.actuationEvidence.analysis.damperMotionRatio));
            t.verifyTrue(isfinite(e.actuationEvidence.analysis.rockerAngle_rad));
        end
        function mechanicalRegimesPreserveNativeSemantics(t,Regime)
            s=actuationSynthesisFixture(); [~,a,~,~,md,units]=actuationSynthesisSeed;
            if Regime=="UNSEATED", md.spring.preloadCompression=0; end
            if Regime=="COIL_BIND", md.spring.solidHeight=.179; end
            if Regime=="DAMPER_LIMIT", md.damper.minimumLength=.20; end
            m=fsd.model.createSpringDamperModel(a,md,units); d=s.specification.definitionSI;
            targets=d.targets.definitionSI.targets; targets=targets(cellfun(@(q)q.definitionSI.sourceType=="ACTUATION",targets));
            d.targets=fsd.model.createSuspensionDesignTargets(targets); s=rebuildActuationSpace(s,d,s.plan,a,m);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]); w=e.mechanicalEvidence.analysis;
            if Regime=="UNSEATED"
                subset=w.springStatus=="SPRING_UNSEATED"; t.verifyTrue(any(subset));
                t.verifyEqual(w.springAxialForce_N(subset),zeros(sum(subset),1));
            else
                t.verifyFalse(e.eligible); t.verifyEqual(e.classification,"MECHANICAL_LIMIT_FAILED");
                t.verifyTrue(any(~w.feasibleRelativeToProvidedLimits));
            end
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisEvaluation(e,s));
        end
        function explicitVelocityAndPassiveDamping(t)
            s=actuationSynthesisFixture(); p=s.plan; p.wheelVelocity_m_per_s=linspace(-.1,.1,numel(p.travel_m))';
            s=rebuildActuationSpace(s,s.specification.definitionSI,p); e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]);
            w=e.mechanicalEvidence.analysis;
            t.verifyEqual(w.inputWheelVelocity_m_per_s,p.wheelVelocity_m_per_s);
            t.verifyEqual(w.damperVelocity_m_per_s,w.damperMotionRatio.*p.wheelVelocity_m_per_s,'AbsTol',1e-12);
            t.verifyGreaterThanOrEqual(w.damperAxialResistance_N.*w.damperVelocity_m_per_s,0);
        end
        function inputUnitsConvertOnlyAtFactories(t)
            [g,a,m,d,md,units]=actuationSynthesisSeed;
            d.suspensionAttachment.point=1000*d.suspensionAttachment.point;
            d.rocker.axis.point=1000*d.rocker.axis.point; d.rocker.actuationRodPoint=1000*d.rocker.actuationRodPoint;
            d.rocker.damperPoint=1000*d.rocker.damperPoint; d.damper.chassisPoint=1000*d.damper.chassisPoint;
            other=fsd.model.createActuationGeometry(g,d,'mm');
            t.verifyEqual(other.rocker.axis.point_m,a.rocker.axis.point_m,'AbsTol',1e-14);
            t.verifyEqual(other.damper.staticLength_m,a.damper.staticLength_m,'AbsTol',1e-14);
            md.spring.rate=30; md.spring.freeLength=200; md.spring.preloadCompression=20;
            units.length="mm"; units.springRate="N/mm";
            converted=fsd.model.createSpringDamperModel(other,md,units);
            t.verifyEqual(converted.spring,m.spring); t.verifyEqual(converted.damper,m.damper);
        end
        function noMechanicalSeedDoesNotFabricateResponse(t)
            s=actuationSynthesisFixture('PULLROD','RR',false);
            e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]);
            t.verifyTrue(e.eligible); t.verifyEmpty(e.mechanical); t.verifyEmpty(e.mechanicalEvidence);
            t.verifyNumElements(e.assessment.targetAssessments,3);
        end
        function unknownProgrammingFailureEscapes(t)
            t.verifyError(@()actuationUnknownBuilderCall(actuationSynthesisFixture()),'MATLAB:nonExistentField');
        end
        function directActingHasNoFakePhysicalAdapter(t)
            [g,~,~,d]=actuationSynthesisSeed; d.actuationType="DIRECT_ACTING";
            t.verifyError(@()fsd.model.createActuationGeometry(g,d,'m'),'fsd:model:InvalidActuationDefinition');
        end
        function unavailableHardWheelRateCannotBeRescuedBySoft(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            for j=1:numel(targets)
                q=targets{j}.definitionSI; q.x=.01;
                if q.metricId=="TANGENT_WHEEL_RATE", q.strength="HARD"; end
                targets{j}=fsd.model.createDesignTarget(q,q.unit,'m');
            end
            d.targets=fsd.model.createSuspensionDesignTargets(targets); p=s.plan;
            p.travel_m=.01+[-1e-9;0;1e-9]; p.wheelVelocity_m_per_s=0;
            s=rebuildActuationSpace(s,d,p); e=fsd.synthesis.evaluateActuationCandidate(s,[.5;.5]);
            t.verifyEqual(e.hardFeasibility,"INDETERMINATE_HARD_REQUIREMENTS");
            t.verifyTrue(isfinite(e.assessment.compositeScore)); t.verifyFalse(e.eligible); t.verifyTrue(isnan(e.score));
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisEvaluation(e,s));
        end
        function failedBuilderIsCachedWithoutPhysicalEvidence(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI;
            values=[-.5,.25]; goals=[-.4,.4]; bindings=["HARDPOINT_Y","HARDPOINT_Z"];
            for j=1:2
                q=d.parameters{j}.definitionSI;
                q.scope=fsd.model.designScope('HARDPOINT','FL_ACTUATION_ROD_SUSPENSION','FL');
                q.binding=bindings(j); q.value=values(j); q.bounds=[values(j),goals(j)];
                d.parameters{j}=fsd.model.createDesignParameter(q,'m');
            end
            s=rebuildActuationSpace(s,d);
            r=fsd.synthesis.runActuationInverseSearch(s,struct('maxEvaluations',10,'maxIterations',4, ...
                'initialStep',1,'minimumStep',1,'seeds',[1,1;1,1]));
            failed=find(cellfun(@(e)~e.geometryValid,r.search.records)); t.verifyNumElements(failed,1);
            e=r.search.records{failed}; t.verifyEqual(e.exceptionId,"fsd:synthesis:ZeroLengthActuationRod");
            t.verifyEmpty(e.bumpEvidence); t.verifyEmpty(e.actuationEvidence); t.verifyEmpty(e.mechanicalEvidence);
            hits=cellfun(@(h)h.cacheHit && h.evaluationId==failed,r.search.history); t.verifyTrue(any(hits));
            t.verifyEqual(r.statistics.builderFailures,1);
            t.verifyEqual(r.statistics.bumpSweeps,r.search.evaluationCount-1);
            t.verifyEqual(r.statistics.actuationSweeps,r.search.evaluationCount-1);
            t.verifyTrue(fsd.synthesis.validateActuationSynthesisResult(r));
        end
        function legacyResultsRemainValidWithNoRegistry(t)
            s=steeringSynthesisFixture();
            r=fsd.synthesis.runSteeringInverseSearch(s,struct('maxEvaluations',1));
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisResult(r));
            t.verifyFalse(isfield(r.search.records{1}.candidate.definitionSI,'actuations'));
        end
    end
end
