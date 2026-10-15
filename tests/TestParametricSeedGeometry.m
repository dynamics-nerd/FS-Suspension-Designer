classdef TestParametricSeedGeometry < matlab.unittest.TestCase
    properties (TestParameter)
        Corner={"FL","FR","RL","RR"}
        Orientation={[0,0,0],[.03,-.07,.11],[-.04,.08,-.1]}
        Failure={"ZERO_SPAN","NEGATIVE_RADIUS","COINCIDENT_BALLS","COLLINEAR_UPRIGHT","OUTBOARD_PIVOTS","COLLINEAR_ARM","HARD_FIXED","HARD_BOX"}
        Attack={"XYZ","WC","AXIS","UBJ","LBJ","UCA","LCA","FRAME","CORNER","PROVENANCE","IDENTITY","DEFINITION","REFERENCE","BOUNDS","DIAGNOSTICS","QUALITY","DERIVATIONS","SYMMETRY"}
    end
    methods (TestMethodSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
        end
    end
    methods (Test)
        function independentGoldenCoordinates(t,Corner)
            f=parametricSeedFixture(Corner); seed=fsd.construction.buildParametricSeed(f.definition,f.references);
            expected=[-.12,-.38,.36;.10,-.42,.34;.03,-.60,.42;-.11,-.39,.14; ...
                .12,-.41,.16;-.02,-.60,.08;.04,-.39,.25;.05,-.57,.23;0,-.65,.25;0,-.65,0];
            s=1; if ismember(Corner,["FR","RR"]), s=-1; end
            expected(:,2)=expected(:,2)*s;
            if ismember(Corner,["RL","RR"])
                expected(:,1)=expected(:,1)+1.6;
                moving=[3,6,8,9,10]; expected(moving,2)=expected(moving,2)+(1.3-1.2)/2*s;
            end
            t.verifyEqual(seed.nominalStatus,"VALID"); g=seed.geometries{1};
            t.verifyEqual(g.hardpoints.xyz_m,expected,'AbsTol',1e-14);
            t.verifyTrue(fsd.model.validateDoubleWishboneGeometry(g)); t.verifyFalse(seed.consistency.hasMismatch);
            t.verifyEqual(seed.sampledStatus,"NOT_CHECKED"); t.verifyTrue(all(g.hardpoints.sourceKind=="DERIVED",'all'));
            t.verifyTrue(fsd.construction.validateParametricSeedResult(seed));
        end
        function uprightOrientationAndReflection(t,Orientation)
            f=parametricSeedFixture('FRONT'); d=f.definition;
            for j=1:3, ids=["NOMINAL_TOE","NOMINAL_CAMBER","UPRIGHT_CLOCKING"]; d=replaceSeedDecision(d,ids(j),Orientation(j)); end
            seed=fsd.construction.buildParametricSeed(d,f.references); t.assertEqual(seed.nominalStatus,"VALID");
            left=seed.geometries{1}; right=seed.geometries{2};
            t.verifyEqual(right,fsd.geometry.reflectDoubleWishboneGeometry(left));
            for g={left,right}
                t.verifyEqual(fsd.analysis.toeFromWheelAxis(g{1}.wheel.wheelAxis,g{1}.cornerId),Orientation(1),'AbsTol',1e-12);
                t.verifyEqual(fsd.analysis.camberFromWheelAxis(g{1}.wheel.wheelAxis,g{1}.cornerId),Orientation(2),'AbsTol',1e-12);
                contact=fsd.analysis.geometricWheelContact(g{1}); t.verifyEqual(contact.point_m, ...
                    fsd.model.getPoint(g{1},g{1}.cornerId+"_CONTACT_PATCH"),'AbsTol',1e-12);
            end
            R=seed.frames{1}.rotationMatrix; t.verifyEqual(R'*R,eye(3),'AbsTol',1e-12); t.verifyEqual(det(R),1,'AbsTol',1e-12);
            xyz=left.hardpoints.xyz_m([3,6,8],:); expected=[.03,.05,.17;-.02,.05,-.17;.05,.08,-.02];
            t.verifyEqual(norm(xyz(1,:)-xyz(2,:)),norm(expected(1,:)-expected(2,:)),'AbsTol',1e-12);
            t.verifyEqual(norm(xyz(3,:)-xyz(2,:)),norm(expected(3,:)-expected(2,:)),'AbsTol',1e-12);
            S=diag([1,-1,1]); t.verifyEqual(seed.frames{2}.rotationMatrix,S*R*S,'AbsTol',1e-12);
        end
        function independentFrontPairDoesNotForceSymmetry(t)
            f=parametricSeedFixture('FRONT'); [~,right]=parametricSeedInputs('FR',.004);
            d=f.definition.definitionSI; d.symmetry="NONE"; d.rightParameters=right.definitionSI.parameters;
            seed=fsd.construction.buildParametricSeed(fsd.construction.createParametricSeedDefinition(d),f.references);
            t.verifyEqual(seed.nominalStatus,"VALID");
            mirror=fsd.geometry.reflectDoubleWishboneGeometry(seed.geometries{1});
            t.verifyNotEqual(seed.geometries{2}.hardpoints.xyz_m,mirror.hardpoints.xyz_m);
            t.verifyEqual(seed.geometries{2}.hardpoints.xyz_m(1:2,3)-mirror.hardpoints.xyz_m(1:2,3),[.004;.004],'AbsTol',1e-14);
        end
        function invalidNominalAndMissingAreSeparate(t,Failure)
            f=parametricSeedFixture(); d=f.definition;
            switch Failure
                case "ZERO_SPAN", d=replaceSeedDecision(d,'UCA_SPAN',0);
                case "NEGATIVE_RADIUS", d=replaceSeedDecision(d,'WHEEL_EFFECTIVE_RADIUS',-.1);
                case "COINCIDENT_BALLS"
                    for item=["X","OUTBOARD","Z"]
                        ps=d.definitionSI.parameters; i=cellfun(@(p)p.definitionSI.id=="UBJ_"+item,ps);
                        d=replaceSeedDecision(d,"LBJ_"+item,ps{i}.definitionSI.value);
                    end
                case "COLLINEAR_UPRIGHT"
                    d=replaceSeedDecision(d,'TIE_OUT_X',.005); d=replaceSeedDecision(d,'TIE_OUT_OUTBOARD',-.05); d=replaceSeedDecision(d,'TIE_OUT_Z',0);
                case "OUTBOARD_PIVOTS", d=replaceSeedDecision(d,'UCA_LATERAL',.7);
                case "COLLINEAR_ARM"
                    d=replaceSeedDecision(d,'UCA_LATERAL',.6); d=replaceSeedDecision(d,'UCA_HEIGHT',.42);
                    d=replaceSeedDecision(d,'UCA_LATERAL_DELTA',0); d=replaceSeedDecision(d,'UCA_HEIGHT_DELTA',0);
                case {"HARD_FIXED","HARD_BOX"}
                    input=struct('id',"CONTRADICTION",'scope',fsd.model.designScope('HARDPOINT','FL_UBJ','FL'), ...
                        'strength',"HARD",'sourceNote',"Deliberate test contradiction");
                    if Failure=="HARD_FIXED", input.type="HARDPOINT_FIXED"; input.position=[0,0,0]; input.comparisonTolerance=0;
                    else, input.type="AXIS_ALIGNED_BOX"; input.bounds=zeros(3,2); end
                    dd=d.definitionSI; dd.constraints={fsd.model.createDesignConstraint(input,'m')}; d=fsd.construction.createParametricSeedDefinition(dd);
            end
            seed=fsd.construction.buildParametricSeed(d,f.references);
            t.verifyNotEqual(seed.nominalStatus,"VALID"); t.verifyEmpty(seed.geometries); t.verifyNotEmpty(seed.diagnostics);
            t.verifyEqual(seed.sampledStatus,"NOT_CHECKED"); t.verifyTrue(fsd.construction.validateParametricSeedResult(seed));
        end
        function threeExplicitVariantsHaveDifferentPhysics(t)
            f=parametricSeedFixture(); seeds=cell(3,1); curves=zeros(3,3);
            for j=1:3
                [~,definition]=parametricSeedInputs('FL',.003*(j-1));
                seeds{j}=fsd.construction.buildParametricSeed(definition,f.references);
                check=fsd.project.checkParametricSeedBump(seeds{j},struct('travel_m',[-.01;0;.01]));
                t.verifyEqual(check.status,"SAMPLED_PASS"); curves(j,:)=check.sources{1}.analysis.camber_rad';
            end
            t.verifyNotEqual(seeds{1}.identity,seeds{2}.identity); t.verifyNotEqual(seeds{2}.identity,seeds{3}.identity);
            t.verifyGreaterThan(norm(curves(1,:)-curves(2,:)),1e-5); t.verifyGreaterThan(norm(curves(2,:)-curves(3,:)),1e-5);
            t.verifyEqual(seeds{1},fsd.construction.buildParametricSeed(f.definition,f.references));
        end
        function nominallyValidButSampledInfeasible(t)
            f=parametricSeedFixture(); seed=fsd.construction.buildParametricSeed(f.definition,f.references);
            plan=struct('travel_m',[0;.8;.9],'solverOptions',struct('MaxIterations',3,'MaxContinuationStep_m',.1));
            check=fsd.project.checkParametricSeedBump(seed,plan);
            t.verifyEqual(seed.nominalStatus,"VALID"); t.verifyEqual(check.status,"SAMPLED_INCOMPLETE");
            t.verifyTrue(any(~check.sources{1}.sweep.converged)); t.verifyTrue(any(isnan(check.sources{1}.analysis.camber_rad)));
            t.verifyTrue(fsd.project.validateParametricSeedBump(check,seed));
        end
        function coordinateAndEvidenceAttacksRejected(t,Attack)
            f=parametricSeedFixture('FRONT'); seed=fsd.construction.buildParametricSeed(f.definition,f.references); copy=seed;
            switch Attack
                case {"XYZ","WC","UBJ","LBJ","UCA","LCA"}
                    row=1; if Attack=="WC", row=9; elseif Attack=="UBJ", row=3; elseif Attack=="LBJ", row=6; elseif Attack=="LCA", row=4; end
                    copy.geometries{1}.hardpoints.xyz_m(row,1)=copy.geometries{1}.hardpoints.xyz_m(row,1)+.001;
                case "AXIS", copy.geometries{1}.wheel.wheelAxis=[.01,-1,0];
                case "FRAME", copy.frames{1}.rotationMatrix=eye(3)*2;
                case "CORNER", copy.geometries{1}.cornerId="FR";
                case "PROVENANCE", copy.geometries{1}.hardpoints.sourceKind(:)="KNOWN";
                case "IDENTITY", copy.identity.geometries{1}.hardpointXyz_m(1,1)=1;
                case "DEFINITION", copy.definition=replaceSeedDecision(copy.definition,'UCA_HEIGHT',.36);
                case "REFERENCE", copy.referenceParameters{1}.definitionSI.value=2;
                case "BOUNDS", copy.definition.definitionSI.parameters{1}.definitionSI.bounds=[0,0];
                case "DIAGNOSTICS", copy.diagnostics="FORGED";
                case "QUALITY", copy.sampledStatus="SAMPLED_PASS";
                case "DERIVATIONS", copy.derivations{1}.inputIds{1}="FAKE";
                case "SYMMETRY", copy.definition.definitionSI.symmetry="NONE";
            end
            t.verifyError(@()fsd.construction.validateParametricSeedResult(copy),'fsd:construction:InvalidSeedResult');
        end
        function validButWrongTrackIsNotConceptMatch(t)
            f=parametricSeedFixture('FRONT'); seed=fsd.construction.buildParametricSeed(f.definition,f.references);
            gs=seed.geometries; gs{2}.hardpoints.xyz_m(:,2)=gs{2}.hardpoints.xyz_m(:,2)+.01;
            t.verifyTrue(fsd.model.validateDoubleWishboneGeometry(gs{2}));
            report=fsd.construction.checkConceptGeometryConsistency(gs,f.references); t.verifyTrue(report.hasMismatch);
            rows=report.checks; t.verifyEqual(rows(string({rows.id})=="FRONT_TRACK").status,"MISMATCH");
            t.verifyEqual(rows(string({rows.id})=="REAR_TRACK").status,"UNKNOWN");
            t.verifyEqual(rows(string({rows.id})=="UNLOADED_RADIUS_AS_EFFECTIVE_RADIUS").status,"NOT_APPLICABLE");
        end
    end
end
