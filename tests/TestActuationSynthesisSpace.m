classdef TestActuationSynthesisSpace < matlab.unittest.TestCase
    properties (TestParameter)
        Architecture={"PUSHROD","PULLROD"}
        Corner={"FL","FR","RL","RR"}
        Role={"ACTUATION_ROD_SUSPENSION","ACTUATION_ROD_ROCKER","DAMPER_ROCKER","DAMPER_CHASSIS","ROCKER_AXIS_POINT"}
        Component={1,2,3}
        Mode={"YZ_PLANE","XZ_PLANE","CUSTOM"}
        Corruption={"SEED","POINTS","VARIABLE","AXIS_MAP","PLAN","ALIAS","BOUND","SPEC"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function nativeSeedsAndAllCorners(t,Architecture,Corner)
            [s,~]=actuationSynthesisFixture(Architecture,Corner); before=s;
            t.verifyTrue(fsd.synthesis.validateActuationDesignSpace(s));
            [a,m,changes]=fsd.synthesis.buildActuationCandidate(s,s.initial_m);
            t.verifyEqual(a,s.seedActuation); t.verifyEqual(m,s.seedMechanical); t.verifyEmpty(changes);
            t.verifyEqual(s,before); t.verifyEqual(s.seed.cornerId,Corner);
            t.verifyEqual(s.seedActuation.actuationType,Architecture);
            t.verifyEqual(s.seedActuation.cornerGeometryIdentity,fsd.model.geometryIdentity(s.seed));
        end
        function everyNativeRoleCoordinate(t,Role,Component,Mode)
            [g,a]=actuationFixture(Mode); points=nativePoints(a); roles=fsd.model.actuationDesignPointRoles(); row=find(roles==Role);
            p=parameter(g.cornerId,Role,Component,points(row,Component));
            spec=fsd.model.createDesignSpecification(struct('id',"COORDINATE",'parameters',{{p}}));
            [~,dependent]=max(abs(a.rocker.axis.direction_unit));
            create=@()fsd.synthesis.createActuationDesignSpace(g,a,[],spec,struct('travel_m',0));
            if row==5 && Component==dependent
                t.verifyError(create,'fsd:synthesis:InvalidInput'); return;
            end
            s=create(); before=s; [changed,~,changes,diagnostics]=fsd.synthesis.buildActuationCandidate(s,s.initial_m+.001);
            expected=points; expected(row,Component)=expected(row,Component)+.001;
            if row==5
                others=setdiff(1:3,dependent); u=a.rocker.axis.direction_unit;
                expected(5,dependent)=-sum(expected(5,others).*u(others))/u(dependent);
            end
            t.verifyEqual(nativePoints(changed),expected,'AbsTol',2e-14); % native axis point rounds 14 decimals
            t.verifyEqual(changed.cornerGeometryIdentity,a.cornerGeometryIdentity);
            t.verifyNotEqual(changed.identity,a.identity); t.verifyNotEmpty(changes);
            t.verifyEqual(changed.rocker.axis.direction_unit,a.rocker.axis.direction_unit);
            t.verifyEqual(s,before); t.verifyEqual(diagnostics.collisionStatus,"NOT_CHECKED");
            t.verifyTrue(fsd.model.validateActuationGeometry(changed));
        end
        function gettersAndLegacyRegistryShape(t)
            s=actuationSynthesisFixture(); points=nativePoints(s.seedActuation);
            for j=1:5
                t.verifyEqual(fsd.model.getActuationDesignPoint(s.seedActuation,s.pointIds(j)),points(j,:));
                scope=fsd.model.designScope('HARDPOINT',s.pointIds(j),'FL'); t.verifyEqual(scope.id,s.pointIds(j));
            end
            t.verifyError(@()fsd.model.getActuationDesignPoint(s.seedActuation,'FL_UBJ'),'fsd:model:UnknownActuationDesignPoint');
            old=fsd.model.createDesignCandidate(struct('id',"LEGACY",'geometries',{{s.seed}}));
            empty=fsd.model.createDesignCandidate(struct('id',"LEGACY",'geometries',{{s.seed}},'actuations',{{}}));
            t.verifyEqual(old,empty); t.verifyFalse(isfield(old.definitionSI,'actuations'));
            t.verifyNumElements(fsd.model.requiredHardpointRoles(),10);
        end
        function nominalActuationRegistryIsValidated(t)
            s=actuationSynthesisFixture(); a=s.seedActuation;
            c=fsd.model.createDesignCandidate(struct('id',"REGISTRY",'geometries',{{s.seed}},'actuations',{{a}}));
            t.verifyTrue(fsd.analysis.validateDesignCandidate(c));
            t.verifyEqual(c.identity.definitionSI.actuations,{a.identity});
            t.verifyError(@()fsd.model.createDesignCandidate(struct('id',"DUP",'actuations',{{a;a}})), ...
                'fsd:model:InvalidDesignDefinition');
        end
        function fixedPointsAndCoordinatesCannotMove(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI;
            p=d.parameters{1}.definitionSI; p.id="FIXED_MOUNT"; p.type="FIXED"; p.bounds=[]; p.comparisonTolerance=.1;
            d.parameters{end+1,1}=fsd.model.createDesignParameter(p,'m');
            t.verifyError(@()rebuildActuationSpace(s,d),'fsd:synthesis:InvalidInput');
            d=s.specification.definitionSI;
            points=nativePoints(s.seedActuation);
            c=fsd.model.createDesignConstraint(struct('id',"MOUNT_FIXED",'type',"HARDPOINT_FIXED",'strength',"HARD", ...
                'scope',d.parameters{1}.definitionSI.scope,'position',points(4,:), ...
                'comparisonTolerance',.1,'sourceNote',"Explicit immutable point control"),'m');
            d.constraints{end+1,1}=c;
            t.verifyError(@()rebuildActuationSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function duplicateCoordinatesRejected(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; p=d.parameters{1}.definitionSI; p.id="DUPLICATE";
            d.parameters{end+1,1}=fsd.model.createDesignParameter(p,'m');
            t.verifyError(@()rebuildActuationSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function frozenCoordinatesAndNormalization(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI; p=d.parameters{1}.definitionSI;
            p.bounds=[p.value,p.value]; d.parameters{1}=fsd.model.createDesignParameter(p,'m'); s=rebuildActuationSpace(s,d);
            u=fsd.synthesis.normalizeActuationVariables(s,s.initial_m); t.verifyEqual(u(1),0);
            t.verifyEqual(fsd.synthesis.denormalizeActuationVariables(s,u),s.initial_m);
            t.verifyError(@()fsd.synthesis.denormalizeActuationVariables(s,[.1;.5]),'fsd:synthesis:InvalidInput');
            t.verifyEqual(fsd.synthesis.denormalizeActuationVariables(s,[0;1]),s.upper_m);
            t.verifyError(@()fsd.synthesis.denormalizeActuationVariables(s,[-.1;0]),'fsd:synthesis:InvalidInput');
        end
        function suspensionMutationIsExplicitlyUnsupported(t)
            s=actuationSynthesisFixture(); d=s.specification.definitionSI;
            d.parameters{1}=parameter('FL','UCA_FWD_CHASSIS',1,s.seed.hardpoints.xyz_m(1,1));
            t.verifyError(@()rebuildActuationSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function tamperedSpace(t,Corruption)
            s=actuationSynthesisFixture();
            switch Corruption
                case "SEED", s.seed.hardpoints.xyz_m(1,1)=0;
                case "POINTS", s.seedPoints_m(1,1)=1;
                case "VARIABLE", s.variables{1}.row=1;
                case "AXIS_MAP", s.dependentAxisComponent=2;
                case "PLAN", s.plan.travel_m=[0;0];
                case "ALIAS", s.sourceIds{2}="OLD";
                case "BOUND", s.lower_m(:)=0;
                case "SPEC", s.specification.definitionSI.compositeScore=false;
            end
            t.verifyError(@()fsd.synthesis.validateActuationDesignSpace(s),'fsd:synthesis:InvalidActuationDesignSpace');
        end
        function mechanicalModelIsRequiredAndCompatible(t)
            s=actuationSynthesisFixture();
            t.verifyError(@()fsd.synthesis.createActuationDesignSpace(s.seed,s.seedActuation,[],s.specification, ...
                rmfield(s.plan,'wheelVelocity_m_per_s')),'fsd:synthesis:MissingMechanicalModel');
            [~,~,m]=actuationSynthesisSeed('PULLROD');
            t.verifyError(@()fsd.synthesis.createActuationDesignSpace(s.seed,s.seedActuation,m,s.specification,s.plan), ...
                'fsd:synthesis:InvalidInput');
            t.verifyError(@()fsd.synthesis.createActuationDesignSpace(s.seed,s.seedActuation,s.seedMechanical, ...
                s.specification,rmfield(s.plan,'wheelVelocity_m_per_s')),'fsd:synthesis:InvalidInput');
        end
    end
end

function p = parameter(corner,role,column,value)
bindings=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
p=fsd.model.createDesignParameter(struct('id',"VARIABLE",'quantity',"LENGTH", ...
    'scope',fsd.model.designScope('HARDPOINT',string(corner)+"_"+role,corner), ...
    'type',"FREE",'binding',bindings(column),'value',value,'bounds',value+[-.01,.01], ...
    'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Explicit test coordinate"),'m');
end

function points = nativePoints(a)
points=[a.suspensionAttachment.pointStatic_m;a.rocker.actuationRodPoint.pointStatic_m; ...
    a.rocker.damperPoint.pointStatic_m;a.damper.chassisPoint.point_m;a.rocker.axis.point_m];
end
