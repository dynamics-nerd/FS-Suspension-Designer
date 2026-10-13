classdef TestSteeringSynthesisSpace < matlab.unittest.TestCase
    properties (TestParameter)
        Side={1,2}
        Role={"TIE_ROD_INBOARD","TIE_ROD_OUTBOARD"}
        Component={1,2,3}
        BadU={NaN,Inf,-.1,1.1}
        Corruption={"BOUND","MAP","ALIAS","GRID_SHAPE","REFERENCE","IDENTITY","VARIABLE","KIND"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old));
            addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
        end
    end
    methods (Test)
        function authorizedEndpointCoordinate(t,Side,Role,Component)
            s=steeringSynthesisFixture(false,false,Role,Component); before=s;
            x=s.initial_m; x(Side)=s.upper_m(Side);
            [model,changes,diagnostics]=fsd.synthesis.buildSteeringCandidate(s,x);
            geoms={model.frontAxleGeometry.leftGeometry;model.frontAxleGeometry.rightGeometry};
            seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry};
            for j=1:2
                expected=seeds{j}.hardpoints.xyz_m; row=seeds{j}.hardpoints.ids==seeds{j}.cornerId+"_"+Role;
                if j==Side, expected(row,Component)=x(j); end
                t.verifyEqual(geoms{j}.hardpoints.xyz_m,expected);
                t.verifyEqual(geoms{j}.wheel,seeds{j}.wheel);
            end
            t.verifyEqual(s,before); t.verifyNumElements(changes,1);
            t.verifyNotEqual(model.identity,s.seedSteering.identity);
            t.verifyTrue(all(diagnostics.tieRodLength_m>0));
            t.verifyEqual(diagnostics.rack,model.rackGeometry);
            t.verifyEqual(diagnostics.collisionStatus,"NOT_CHECKED");
        end
        function allAuthorizedCoordinates(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; parameters=cell(0,1);
            seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; binding=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
            for j=1:2
                g=seeds{j};
                for row=[1,2,4,5,7,8]
                    for axis=1:3
                        p=d.parameters{j}.definitionSI; p.id=g.cornerId+"_R"+row+"_A"+axis;
                        p.scope=fsd.model.designScope('HARDPOINT',g.hardpoints.ids(row),g.cornerId);
                        p.binding=binding(axis); p.value=g.hardpoints.xyz_m(row,axis); p.bounds=p.value+[-.01,.01];
                        parameters{end+1,1}=fsd.model.createDesignParameter(p,'m'); %#ok<AGROW>
                    end
                end
            end
            d.parameters=parameters; s=rebuildSteeringSpace(s,d,s.plan,strings(0,2));
            t.verifyNumElements(s.variables,36); t.verifyTrue(all(s.active));
            t.verifyEqual(fsd.synthesis.buildSteeringCandidate(s,s.initial_m),s.seedSteering);
        end
        function selectedSymmetry(t,Role,Component)
            s=steeringSynthesisFixture(false,true,Role,Component);
            t.verifyNumElements(s.variables,1); t.verifyNumElements(s.physicalVariables,2);
            model=fsd.synthesis.buildSteeringCandidate(s,s.upper_m); a=model.frontAxleGeometry;
            l=fsd.model.getPoint(a.leftGeometry,"FL_"+Role); r=fsd.model.getPoint(a.rightGeometry,"FR_"+Role);
            signValue=1; if Component==2, signValue=-1; end
            t.verifyEqual(r(Component),signValue*l(Component));
        end
        function rangeAndFrozenPartner(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; p=d.parameters{2}.definitionSI;
            p.type="RANGE"; p.bounds=[p.value,p.value]; d.parameters{2}=fsd.model.createDesignParameter(p,'m');
            s=rebuildSteeringSpace(s,d); t.verifyFalse(s.active);
            t.verifyEqual(fsd.synthesis.normalizeSteeringVariables(s,s.initial_m),0);
            t.verifyError(@() fsd.synthesis.denormalizeSteeringVariables(s,1),'fsd:synthesis:InvalidInput');
        end
        function hardFixedEndpointCannotMove(t,Side,Role)
            s=steeringSynthesisFixture(false,false,Role); d=s.specification.definitionSI;
            p=d.parameters{Side}.definitionSI; p.id=p.id+"_FIXED"; p.type="FIXED"; p.bounds=[]; p.comparisonTolerance=.1;
            d.parameters{end+1,1}=fsd.model.createDesignParameter(p,'m');
            t.verifyError(@() rebuildSteeringSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function hardFixedPointCannotMove(t,Side)
            s=steeringSynthesisFixture(false,false); d=s.specification.definitionSI;
            c=d.constraints{Side}.definitionSI; g=s.seedAxle.leftGeometry; if Side==2, g=s.seedAxle.rightGeometry; end
            c.scope=fsd.model.designScope('HARDPOINT',g.cornerId+"_TIE_ROD_OUTBOARD",g.cornerId);
            c.position=fsd.model.getPoint(g,c.scope.id); c.comparisonTolerance=.1;
            d.constraints{Side}=fsd.model.createDesignConstraint(c,'m');
            t.verifyError(@() rebuildSteeringSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function normalizationAndBounds(t,BadU)
            s=steeringSynthesisFixture(); u=fsd.synthesis.normalizeSteeringVariables(s,s.initial_m);
            t.verifyEqual(fsd.synthesis.denormalizeSteeringVariables(s,u),s.initial_m);
            t.verifyEqual(fsd.synthesis.denormalizeSteeringVariables(s,0),s.lower_m);
            t.verifyEqual(fsd.synthesis.denormalizeSteeringVariables(s,1),s.upper_m);
            t.verifyError(@() fsd.synthesis.denormalizeSteeringVariables(s,BadU),'fsd:synthesis:InvalidInput');
        end
        function spaceCorruption(t,Corruption)
            s=steeringSynthesisFixture();
            switch Corruption
                case "BOUND", s.lower_m=s.lower_m-.001;
                case "MAP", s.multiplier(2)=-1;
                case "ALIAS", s.sourceIds{4}="OTHER_RACK";
                case "GRID_SHAPE", s.plan.rack.travel_m=s.plan.rack.travel_m';
                case "REFERENCE", s.plan.referenceRackTravel_m=.001;
                case "IDENTITY", s.seedSteering.identity.rearAxleX_m=2;
                case "VARIABLE", s.variables{1}.row=7;
                case "KIND", s.kind="AxleSynthesisDesignSpace";
            end
            t.verifyError(@() fsd.synthesis.validateSteeringDesignSpace(s),'fsd:synthesis:InvalidSteeringDesignSpace');
        end
        function numericalPlansAndLimits(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI;
            for scenario=1:6
                p=s.plan;
                switch scenario
                    case 1, p.referenceRackTravel_m=.001;
                    case 2, p.rack.travel_m=[0;.003;0];
                    case 3, p.rack.travelLimits_m=[-.001,.001];
                    case 4, p.rack.travelLimits_m=[.001,.01];
                    case 5, p.rack.wheelTravel_m=0;
                    case 6, p.rack=rmfield(p.rack,'travelLimits_m');
                end
                t.verifyError(@() rebuildSteeringSpace(s,d,p),'fsd:synthesis:InvalidInput');
            end
        end
        function targetConditionsMustMatch(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            p=targets{2}.definitionSI; p.conditions.wheelTravel_m=[.001,0];
            targets{2}=fsd.model.createDesignTarget(p,'rad','m'); d.targets=fsd.model.createSuspensionDesignTargets(targets);
            t.verifyError(@() rebuildSteeringSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function seedsMustBeOneMechanism(t)
            s=steeringSynthesisFixture(); st=s.seedSteering; g=st.frontAxleGeometry.leftGeometry;
            g.hardpoints.xyz_m(8,1)=.051;
            st=fsd.model.createSteeringSystem(fsd.model.createAxleGeometry(g,st.frontAxleGeometry.rightGeometry),1.6,'m');
            t.verifyError(@() rebuildSteeringSpace(s,s.specification.definitionSI,s.plan,s.symmetryLinks, ...
                {s.seedAxle.leftGeometry;s.seedAxle.rightGeometry},st),'fsd:synthesis:InvalidInput');
        end
        function missingRearReferenceNeverInvented(t)
            s=steeringSynthesisFixture(); st=rmfield(s.seedSteering,'rearAxleX_m');
            t.verifyError(@() rebuildSteeringSpace(s,s.specification.definitionSI,s.plan,s.symmetryLinks, ...
                {s.seedAxle.leftGeometry;s.seedAxle.rightGeometry},st),'fsd:model:InvalidSteeringSystemGeometry');
        end
        function oldPublicSpacesKeepTheirScope(t)
            s=steeringSynthesisFixture(); c=s.cornerSpaces{1};
            t.verifyError(@() fsd.synthesis.createDesignSpace(c.seed,c.specification,c.plan),'fsd:synthesis:InvalidInput');
            t.verifyError(@() fsd.synthesis.createAxleDesignSpace(s.seedAxle.leftGeometry,s.seedAxle.rightGeometry, ...
                s.specification,rmfield(s.plan,{'rack','referenceRackTravel_m'})),'fsd:synthesis:UnsupportedTarget');
        end
        function nominalBoxViolationRetained(t)
            s=steeringSynthesisFixture(); d=s.specification.definitionSI; g=s.seedAxle.leftGeometry;
            point=fsd.model.getPoint(g,"FL_TIE_ROD_OUTBOARD");
            c=fsd.model.createDesignConstraint(struct('id',"PICKUP_BOX",'type',"AXIS_ALIGNED_BOX",'strength',"HARD", ...
                'scope',fsd.model.designScope('HARDPOINT','FL_TIE_ROD_OUTBOARD','FL'), ...
                'bounds',[.04,.051;point(2),point(2);point(3),point(3)],'sourceNote',"Explicit nominal test box"),'m');
            d.constraints{end+1,1}=c; s=rebuildSteeringSpace(s,d);
            e=fsd.synthesis.evaluateSteeringCandidate(s,.75);
            t.verifyEqual(e.classification,"HARD_CONSTRAINT_FAILED"); t.verifyFalse(e.eligible);
            t.verifyEqual(e.assessment.constraintAssessments{3}.status,"SAMPLED_FAIL");
            t.verifyTrue(fsd.synthesis.validateSteeringSynthesisEvaluation(e,s));
        end
        function matRoundTrip(t)
            s=steeringSynthesisFixture(); filename=[tempname,'.mat']; t.addTeardown(@() delete(filename));
            save(filename,'s'); loaded=load(filename,'s');
            t.verifyEqual(loaded.s,s); t.verifyTrue(fsd.synthesis.validateSteeringDesignSpace(loaded.s));
        end
    end
end
