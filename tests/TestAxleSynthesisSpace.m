classdef TestAxleSynthesisSpace < matlab.unittest.TestCase
    properties (TestParameter)
        Axle={"FRONT","REAR"}
        Component={1,2,3}
        Side={1,2}
        BadU={NaN,Inf,-.1,1.1}
        Span={1e-12,1e-6,1,1e6}
        Corruption={"BOUND","MAPPING","LINK","PLAN","IDENTITY","VARIABLE","FRAME"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@() path(old)); addpath(fullfile(fileparts(fileparts(mfilename('fullpath'))),'src'));
        end
    end
    methods (Test)
        function allTwentyFourCoordinates(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; parameters=cell(0,1);
            seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; labels=["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"];
            for side=1:2
                g=seeds{side};
                for row=[1,2,4,5]
                    for axis=1:3
                        p=d.parameters{side}.definitionSI; p.id=g.cornerId+"_R"+row+"_A"+axis;
                        p.scope=fsd.model.designScope('HARDPOINT',g.hardpoints.ids(row),g.cornerId);
                        p.binding=labels(axis); p.value=g.hardpoints.xyz_m(row,axis); p.bounds=p.value+[-.01,.01];
                        parameters{end+1,1}=fsd.model.createDesignParameter(p,'m'); %#ok<AGROW>
                    end
                end
            end
            d.parameters=parameters; s=rebuildAxleSpace(s,d);
            t.verifyNumElements(s.variables,24); t.verifyTrue(all(s.active));
            t.verifyEqual(fsd.synthesis.buildAxleCandidate(s,s.initial_m),s.seedAxle);
        end
        function mixedScales(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI;
            p=d.parameters{1}.definitionSI; p.bounds=p.value+[-1e-10,1e-10]; d.parameters{1}=fsd.model.createDesignParameter(p,'m');
            p=d.parameters{2}.definitionSI; p.bounds=[-1e6,1e6]; d.parameters{2}=fsd.model.createDesignParameter(p,'m');
            s=rebuildAxleSpace(s,d); u=[.123;.789]; x=fsd.synthesis.denormalizeAxleVariables(s,u);
            t.verifyEqual(fsd.synthesis.normalizeAxleVariables(s,x),u,'AbsTol',1e-6);
        end
        function hardFixedInboardCannotMove(t,Side)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; g=s.seedAxle.leftGeometry;
            if Side==2, g=s.seedAxle.rightGeometry; end
            c=d.constraints{Side}.definitionSI; c.scope=fsd.model.designScope('HARDPOINT',g.hardpoints.ids(1),g.cornerId);
            c.position=g.hardpoints.xyz_m(1,:); c.comparisonTolerance=.1; d.constraints{Side}=fsd.model.createDesignConstraint(c,'m');
            t.verifyError(@() rebuildAxleSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function fixedSeedContradiction(t,Side)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; c=d.constraints{Side}.definitionSI;
            c.position(3)=c.position(3)+.01; d.constraints{Side}=fsd.model.createDesignConstraint(c,'m');
            t.verifyError(@() rebuildAxleSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function boxesOnReconstructedCorners(t,Side)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; g=s.seedAxle.leftGeometry;
            if Side==2, g=s.seedAxle.rightGeometry; end
            p=g.hardpoints.xyz_m(1,:);
            c=fsd.model.createDesignConstraint(struct('id',"BOX",'type',"AXIS_ALIGNED_BOX",'strength',"HARD", ...
                'scope',fsd.model.designScope('HARDPOINT',g.hardpoints.ids(1),g.cornerId), ...
                'bounds',[p'-[0;0;.005],p'+[0;0;.005]],'sourceNote',"Explicit nominal test box"),'m');
            d.constraints{end+1,1}=c; s=rebuildAxleSpace(s,d); u=[.5;.5]; u(Side)=.75;
            boundary=fsd.synthesis.evaluateAxleCandidate(s,u);
            t.verifyEqual(boundary.assessment.constraintAssessments{3}.status,"SAMPLED_PASS");
            u(Side)=1; outside=fsd.synthesis.evaluateAxleCandidate(s,u);
            t.verifyEqual(outside.assessment.constraintAssessments{3}.status,"SAMPLED_FAIL");
            t.verifyEqual(outside.classification,"HARD_CONSTRAINT_FAILED"); t.verifyFalse(outside.eligible);
        end
        function noncanonicalPlanRejected(t)
            s=axleSynthesisFixture(); p=s.plan; p.leftBump.travel_m=[0;.01;0];
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,p),'fsd:synthesis:InvalidInput');
            p=s.plan; p.roll=struct('angles_rad',[0;0],'axleHeave_m',0);
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,p),'fsd:synthesis:InvalidInput');
            p=s.plan; p.roll=struct('angles_rad',pi/2,'axleHeave_m',0);
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,p),'fsd:synthesis:InvalidInput');
        end
        function acceptedAxle(t,Axle)
            s=axleSynthesisFixture(false,Axle); t.verifyTrue(fsd.synthesis.validateAxleDesignSpace(s));
            t.verifyEqual(s.seedAxle.axleId,Axle); t.verifyNumElements(s.variables,2);
            t.verifyNotEqual(s.seedIdentity.leftGeometryIdentity,s.seedIdentity.rightGeometryIdentity);
        end
        function oneSeedNotInvented(t)
            s=axleSynthesisFixture();
            t.verifyError(@() fsd.synthesis.createAxleDesignSpace(s.seedAxle.leftGeometry,[],s.specification,s.plan), ...
                'fsd:model:InvalidGeometryType');
        end
        function incompatiblePair(t)
            s=axleSynthesisFixture(); rear=axleSynthesisFixture(false,"REAR");
            t.verifyError(@() fsd.synthesis.createAxleDesignSpace(s.seedAxle.leftGeometry,rear.seedAxle.rightGeometry,s.specification,s.plan), ...
                'fsd:model:InvalidAxleCorners');
        end
        function invalidSeed(t,Side)
            s=axleSynthesisFixture(); seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; seeds{Side}.hardpoints.xyz_m(1,1)=NaN;
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,s.plan,s.symmetryLinks,seeds),'fsd:model:NonFiniteCoordinate');
        end
        function frameMismatch(t)
            s=axleSynthesisFixture(); seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; seeds{2}.referenceFrame.originDescription="Another origin";
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,s.plan,s.symmetryLinks,seeds),'fsd:synthesis:InvalidInput');
        end
        function independentCoordinate(t,Side,Component)
            s=axleSynthesisFixture(false,"FRONT",Component); seed=s.seedAxle; x=s.initial_m; x(Side)=s.upper_m(Side);
            [a,changes]=fsd.synthesis.buildAxleCandidate(s,x); geoms={a.leftGeometry;a.rightGeometry}; seeds={seed.leftGeometry;seed.rightGeometry};
            for j=1:2
                expected=seeds{j}.hardpoints.xyz_m;
                if j==Side, expected(1,Component)=x(j); end
                t.verifyEqual(geoms{j}.hardpoints.xyz_m,expected);
                t.verifyEqual(geoms{j}.wheel,seeds{j}.wheel);
            end
            t.verifyEqual(s.seedAxle,seed); t.verifyNumElements(changes,1);
        end
        function selectedSymmetry(t,Component,Axle)
            s=axleSynthesisFixture(false,Axle,Component,true); t.verifyNumElements(s.variables,1);
            a=fsd.synthesis.buildAxleCandidate(s,s.upper_m); signValue=1; if Component==2, signValue=-1; end
            t.verifyEqual(a.rightGeometry.hardpoints.xyz_m(1,Component),signValue*a.leftGeometry.hardpoints.xyz_m(1,Component));
        end
        function intersectBothBounds(t,Component)
            s=axleSynthesisFixture(false,"FRONT",Component); d=s.specification.definitionSI;
            p=d.parameters{2}.definitionSI; p.bounds=p.value+[-.002,.003]; d.parameters{2}=fsd.model.createDesignParameter(p,'m');
            s=rebuildAxleSpace(s,d,s.plan,["FL_VARIABLE","FR_VARIABLE"]);
            expected=[p.bounds(1),p.bounds(2)]; if Component==2, expected=sort(-expected); end
            t.verifyEqual([s.lower_m,s.upper_m],expected);
            a=fsd.synthesis.buildAxleCandidate(s,s.upper_m);
            t.verifyGreaterThanOrEqual(a.rightGeometry.hardpoints.xyz_m(1,Component),p.bounds(1));
            t.verifyLessThanOrEqual(a.rightGeometry.hardpoints.xyz_m(1,Component),p.bounds(2));
        end
        function fixedCannotMoveIndirectly(t,Side)
            s=axleSynthesisFixture(false,"FRONT",3,true); d=s.specification.definitionSI; p=d.parameters{Side}.definitionSI;
            p.id=p.id+"_FIXED"; p.type="FIXED"; p.bounds=[]; p.comparisonTolerance=.1;
            d.parameters{end+1,1}=fsd.model.createDesignParameter(p,'m');
            t.verifyError(@() rebuildAxleSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function frozenPartner(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; p=d.parameters{2}.definitionSI;
            p.bounds=[p.value,p.value]; d.parameters{2}=fsd.model.createDesignParameter(p,'m');
            s=rebuildAxleSpace(s,d,s.plan,["FL_VARIABLE","FR_VARIABLE"]);
            t.verifyFalse(s.active); t.verifyEqual(fsd.synthesis.normalizeAxleVariables(s,s.initial_m),0);
            t.verifyError(@() fsd.synthesis.denormalizeAxleVariables(s,1),'fsd:synthesis:InvalidInput');
        end
        function duplicateBinding(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; p=d.parameters{1}.definitionSI; p.id="DUPLICATE";
            d.parameters{end+1,1}=fsd.model.createDesignParameter(p,'m');
            t.verifyError(@() rebuildAxleSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function duplicateLink(t)
            s=axleSynthesisFixture(false,"FRONT",3,true);
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,s.plan,repmat(s.symmetryLinks,2,1)),'fsd:synthesis:InvalidInput');
        end
        function wrongComponentLink(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; p=d.parameters{2}.definitionSI;
            p.binding="HARDPOINT_X"; p.value=.12; p.scope=fsd.model.designScope('HARDPOINT','FR_LCA_AFT_CHASSIS','FR'); p.bounds=[.11,.13];
            d.parameters{2}=fsd.model.createDesignParameter(p,'m');
            t.verifyError(@() rebuildAxleSpace(s,d,s.plan,["FL_VARIABLE","FR_VARIABLE"]),'fsd:synthesis:InvalidInput');
        end
        function asymmetricAllowedNotLinked(t)
            s=axleSynthesisFixture(); seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; seeds{2}.hardpoints.xyz_m(1,3)=.363;
            d=s.specification.definitionSI; p=d.parameters{2}.definitionSI; p.value=.363; d.parameters{2}=fsd.model.createDesignParameter(p,'m');
            s=rebuildAxleSpace(s,d,s.plan,strings(0,2),seeds); t.verifyNumElements(s.variables,2);
            t.verifyError(@() rebuildAxleSpace(s,d,s.plan,["FL_VARIABLE","FR_VARIABLE"]),'fsd:synthesis:InvalidInput');
        end
        function wheelAxisSymmetry(t)
            s=axleSynthesisFixture(); seeds={s.seedAxle.leftGeometry;s.seedAxle.rightGeometry}; seeds{2}.wheel.wheelAxis=[-.1,sqrt(.99),0];
            t.verifyError(@() rebuildAxleSpace(s,s.specification.definitionSI,s.plan,["FL_VARIABLE","FR_VARIABLE"],seeds),'fsd:synthesis:InvalidInput');
        end
        function normalizeSeedEndpoints(t)
            s=axleSynthesisFixture(); u=fsd.synthesis.normalizeAxleVariables(s,s.initial_m);
            t.verifyEqual(fsd.synthesis.denormalizeAxleVariables(s,u),s.initial_m);
            t.verifyEqual(fsd.synthesis.buildAxleCandidate(s,s.initial_m),s.seedAxle);
            t.verifyEqual(fsd.synthesis.denormalizeAxleVariables(s,[0;0]),s.lower_m);
            t.verifyEqual(fsd.synthesis.denormalizeAxleVariables(s,[1;1]),s.upper_m);
        end
        function roundTripScale(t,Span)
            s=axleSynthesisFixture(false,"FRONT",1); d=s.specification.definitionSI;
            for j=1:2
                p=d.parameters{j}.definitionSI; p.bounds=p.value+[-Span,Span]; d.parameters{j}=fsd.model.createDesignParameter(p,'m');
            end
            s=rebuildAxleSpace(s,d); u=[.731;.123]; x=fsd.synthesis.denormalizeAxleVariables(s,u);
            tolerance=8*eps(max(abs([s.lower_m;s.upper_m])))/min(s.upper_m-s.lower_m);
            t.verifyEqual(fsd.synthesis.normalizeAxleVariables(s,x),u,'AbsTol',tolerance);
        end
        function badNormalized(t,BadU)
            s=axleSynthesisFixture(); t.verifyError(@() fsd.synthesis.denormalizeAxleVariables(s,[BadU;.5]),'fsd:synthesis:InvalidInput');
        end
        function dimensions(t)
            s=axleSynthesisFixture(); t.verifyError(@() fsd.synthesis.denormalizeAxleVariables(s,.5),'fsd:synthesis:InvalidInput');
        end
        function sourceCannotAliasBothCorners(t)
            s=axleSynthesisFixture(); d=s.specification.definitionSI; targets=d.targets.definitionSI.targets;
            p=targets{2}.definitionSI; p.sourceId="BUMP_FL"; targets{2}=fsd.model.createDesignTarget(p,'rad','m');
            d.targets=fsd.model.createSuspensionDesignTargets(targets);
            t.verifyError(@() rebuildAxleSpace(s,d),'fsd:synthesis:InvalidInput');
        end
        function alteredSpace(t,Corruption)
            s=axleSynthesisFixture(false,"FRONT",3,true);
            switch Corruption
                case "BOUND", s.upper_m=.4;
                case "MAPPING", s.multiplier(2)=-1;
                case "LINK", s.symmetryLinks(1,2)="MISSING";
                case "PLAN", s.plan.leftBump.travel_m=[0;0];
                case "IDENTITY", s.seedIdentity.rightGeometryIdentity=s.seedIdentity.leftGeometryIdentity;
                case "VARIABLE", s.variables{1}.column=1;
                case "FRAME", s.seedAxle.rightGeometry.referenceFrame.originDescription="Different";
            end
            t.verifyError(@() fsd.synthesis.validateAxleDesignSpace(s),'fsd:synthesis:InvalidAxleDesignSpace');
        end
        function matAndImmutability(t)
            s=axleSynthesisFixture(false,"REAR",2,true); original=s;
            a=fsd.synthesis.buildAxleCandidate(s,s.upper_m); a.leftGeometry.hardpoints.xyz_m(1,1)=10;
            t.verifyEqual(s,original);
            file=string(tempname)+".mat"; t.addTeardown(@() delete(file)); save(file,'s'); loaded=load(file);
            t.verifyEqual(loaded.s,s); t.verifyTrue(fsd.synthesis.validateAxleDesignSpace(loaded.s));
        end
    end
end
