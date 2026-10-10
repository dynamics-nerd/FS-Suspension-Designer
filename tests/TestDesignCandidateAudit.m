classdef TestDesignCandidateAudit < matlab.unittest.TestCase
    properties
        Fixtures
    end
    properties (TestParameter)
        InvalidPair = {"BUMP_BUMP","BUMP_ACT","BUMP_MECH","ACT_MECH", ...
            "RACK_LEFT","RACK_RIGHT","ROLL_LEFT","ROLL_RIGHT","LOADS_LOADS", ...
            "LOADS_GLOBAL","GLOBAL_BUMP","GLOBAL_MECH","GEOMETRY_REF","VEHICLE_REF", ...
            "LOAD_CASE","ACTUATION_CONFIGURATION","MECHANICAL_CONFIGURATION","GLOBAL_ROAD", ...
            "SINGLE_GEOMETRY_REF","SINGLE_VEHICLE_REF"}
        ValidPair = {"SAME_BUMP","DIFFERENT_SWEEPS","BUMP_ACT","BUMP_MECH","ACT_MECH", ...
            "LEFT_RIGHT","FRONT_REAR","RACK_ROLL","ROLL_CORNERS","LOADS_SAME", ...
            "LOADS_GLOBAL","GLOBAL_MECH","GLOBAL_BUMP","REGISTERED","SINGLE","EMPTY"}
        PublicAPI = {"VALIDATE","EVALUATE","ASSESSMENT","COMPARISON","READINESS","TABLE","PLOT"}
        Reproducer = {"BUMP","STATIC_LOADS"}
        Attack = {"SOURCE_AND_CANDIDATE_IDS","CORNER_AND_NESTED_ID","NESTED_ID_AND_NOMINAL", ...
            "REF_GEOMETRY_AND_STATUS","REF_VEHICLE_AND_STATUS","CANONICAL_EVIDENCE_MISSING"}
    end
    methods (TestClassSetup)
        function nativeFixtures(t)
            oldPath = path; t.addTeardown(@() path(oldPath));
            addpath(fullfile(fileparts(fileparts(mfilename("fullpath"))),"examples"));
            t.Fixtures = designAuditFixture();
        end
    end
    methods (Test)
        function mandatoryDifferentBumpGeometriesWithoutRegistry(t)
            f = t.Fixtures; c = candidate({f.bumpA;f.bumpB}); spec = bumpSpecification(f);
            t.verifyNotEqual(fsd.model.geometryIdentity(f.bumpA.model),fsd.model.geometryIdentity(f.bumpB.model));
            t.verifyError(@() fsd.analysis.validateDesignCandidate(c),"fsd:analysis:InvalidDesignCandidate");
            t.verifyError(@() fsd.analysis.evaluateDesignCandidate(spec,c),"fsd:analysis:InvalidDesignCandidate");
        end
        function mandatoryDifferentVehiclesWithoutRegistry(t)
            f = t.Fixtures; c = candidate({f.loadsA;f.loadsB});
            sources = {f.loadsA;f.loadsB}; values = [250,500];
            for i = 1:2
                t.verifyEqual(sources{i}.result.cornerLoads_N(1),values(i),"AbsTol",1e-12);
            end
            spec = loadSpecification(f);
            t.verifyError(@() fsd.analysis.evaluateDesignCandidate(spec,c),"fsd:analysis:InvalidDesignCandidate");
        end
        function allRelevantInvalidAssociationsBothOrders(t,InvalidPair)
            f = t.Fixtures; extra = struct();
            switch InvalidPair
                case "BUMP_BUMP", sources = {f.bumpA;f.bumpB};
                case "BUMP_ACT", sources = {f.bumpA;f.actB};
                case "BUMP_MECH", sources = {f.bumpA;f.mechB};
                case "ACT_MECH", sources = {f.actA;f.mechB};
                case "RACK_LEFT", sources = {f.rack;f.bumpA};
                case "ROLL_LEFT", sources = {f.roll;f.bumpA};
                case {"RACK_RIGHT","ROLL_RIGHT"}
                    other = bump(fsd.geometry.reflectDoubleWishboneGeometry(f.bumpA.model),"OTHER_RIGHT");
                    first = f.rack; if InvalidPair == "ROLL_RIGHT", first = f.roll; end
                    sources = {first;other};
                case "LOADS_LOADS", sources = {f.loadsA;f.loadsB};
                case "LOADS_GLOBAL", sources = {f.loadsA;f.global};
                case "GLOBAL_BUMP", sources = {f.global;f.bumpB};
                case "GLOBAL_MECH", sources = {f.global;f.mechA}; % same corner/geometry, different spring
                case "GEOMETRY_REF"
                    sources = {f.bumpA;f.bumpB}; extra.geometries = {f.bumpA.model};
                case "VEHICLE_REF"
                    sources = {f.loadsA;f.loadsB}; extra.vehicle = f.loadsA.model;
                case "SINGLE_GEOMETRY_REF"
                    sources = {f.bumpA}; extra.geometries = {f.bumpB.model};
                case "SINGLE_VEHICLE_REF"
                    sources = {f.loadsA}; extra.vehicle = f.loadsB.model;
                case "LOAD_CASE"
                    s = f.loadsA; s.id = "OTHER_CASE";
                    lc = fsd.model.createVehicleLoadCase(s.model, ...
                        struct("mode","CROSSWEIGHT_SPECIFIED","crossweight",.6,"sourceKind","KNOWN"));
                    s.result = fsd.analysis.analyzeStaticVehicleLoads(s.model,lc);
                    sources = {f.loadsA;s};
                case "ACTUATION_CONFIGURATION"
                    [g,act] = actuationFixture("XZ_PLANE");
                    b = fsd.kinematics.solveBumpSweep(g,[-.01;0;.01],"m");
                    sw = fsd.kinematics.solveActuationSweep(act,b);
                    s = struct("id","XZ_ACT","type","ACTUATION","model",act,"sweep",sw, ...
                        "result",fsd.analysis.analyzeActuationSweep(act,sw));
                    sources = {f.actA;s};
                case "MECHANICAL_CONFIGURATION"
                    s = f.mechA; s.id = "OTHER_SPRING";
                    [~,act,~,md,u] = springDamperFixture(); md.spring.rate = 40000;
                    s.model = fsd.model.createSpringDamperModel(act,md,u); s.auxiliary = [];
                    s.result = fsd.analysis.analyzePrescribedSpringDamperPath(s.model,[-.01;0;.01],[-.005;0;.005],0, ...
                        struct("length","m","velocity","m/s"));
                    sources = {f.mechA;s};
                case "GLOBAL_ROAD"
                    s = f.global; m = s.model; o = m.options; o.roadHeight_m = .001;
                    s.model = fsd.model.createGlobalStaticSystem(m.vehicle,m.loadCase,m.sources,m.tires,o);
                    s.id = "OTHER_ROAD";
                    s.result = fsd.analysis.solveGlobalStaticEquilibrium(s.model,zeros(7,1),s.result.solverOptions);
                    sources = {f.global;s};
            end
            for order = 1:2
                if order == 2, sources = flipud(sources); end
                c = candidate(sources,extra);
                t.verifyTrue(fsd.model.validateDesignCandidate(c)); % structural != full coherence
                t.verifyError(@() fsd.analysis.validateDesignCandidate(c),"fsd:analysis:InvalidDesignCandidate");
            end
        end
        function legitimateAssociationsRemainAccepted(t,ValidPair)
            f = t.Fixtures; extra = struct();
            switch ValidPair
                case "SAME_BUMP", other = f.bumpA; other.id = "SECOND_BUMP"; sources = {f.bumpA;other};
                case "DIFFERENT_SWEEPS", sources = {f.bumpA;bump(f.bumpA.model,"SHORT_BUMP")};
                case "BUMP_ACT", sources = {f.bumpA;f.actA};
                case "BUMP_MECH", sources = {f.bumpA;f.mechA};
                case "ACT_MECH", sources = {f.actA;f.mechA};
                case "LEFT_RIGHT", sources = {f.axleLeft;f.axleRight};
                case "FRONT_REAR", sources = {f.bumpA;f.rear};
                case "RACK_ROLL", sources = {f.rack;f.roll};
                case "ROLL_CORNERS", sources = {f.roll;f.axleLeft;f.axleRight};
                case "LOADS_SAME", other = f.loadsA; other.id = "SECOND_LOADS"; sources = {f.loadsA;other};
                case "LOADS_GLOBAL", sources = {f.globalLoads;f.global};
                case "GLOBAL_MECH", sources = {f.globalMech;f.global};
                case "GLOBAL_BUMP", sources = {f.globalBump;f.global};
                case "REGISTERED"
                    sources = {f.bumpA;f.actA;f.mechA;f.loadsA};
                    extra.geometries = {f.bumpA.model}; extra.vehicle = f.loadsA.model;
                case "SINGLE", sources = {f.mechA};
                case "EMPTY", sources = {};
            end
            c = candidate(sources,extra); t.verifyTrue(fsd.analysis.validateDesignCandidate(c));
            spec = fsd.model.createDesignSpecification(struct("id","PRELIMINARY_SPEC"));
            a = fsd.analysis.evaluateDesignCandidate(spec,c);
            t.verifyTrue(fsd.analysis.validateDesignAssessment(a,spec,c));
        end
        function noPublicFullValidationRouteBypassesCoherence(t,PublicAPI,Reproducer)
            f = t.Fixtures; c = candidate({f.bumpA;f.bumpB}); spec = bumpSpecification(f);
            if Reproducer == "STATIC_LOADS", c = candidate({f.loadsA;f.loadsB}); spec = loadSpecification(f); end
            legacy = designAuditTestCall("LEGACY_ASSESSMENT",spec,c);
            t.verifyEqual(legacy.hardFeasibility,"SATISFIES_SAMPLED_HARD_REQUIREMENTS");
            switch PublicAPI
                case "VALIDATE", call = @() fsd.analysis.validateDesignCandidate(c);
                case "EVALUATE", call = @() fsd.analysis.evaluateDesignCandidate(spec,c);
                case "ASSESSMENT", call = @() fsd.analysis.validateDesignAssessment(legacy,spec,c);
                case "COMPARISON", call = @() fsd.analysis.compareDesignCandidates(spec,{f.example.candidates{1};c});
                case "READINESS", call = @() fsd.analysis.designReadiness(spec,c);
                case "TABLE", call = @() fsd.analysis.designAssessmentTable(legacy,spec,c);
                case "PLOT", call = @() fsd.analysis.plotDesignTargetEvaluation(spec,c);
            end
            t.verifyError(call,"fsd:analysis:InvalidDesignCandidate");
        end
        function coordinatedPayloadAttacksDoNotCertifyHard(t,Attack)
            f = t.Fixtures; c = candidate({f.bumpA;f.bumpB}); spec = bumpSpecification(f);
            legacy = designAuditTestCall("LEGACY_ASSESSMENT",spec,c);
            switch Attack
                case "SOURCE_AND_CANDIDATE_IDS"
                    for i = 1:2
                        c.definitionSI.sources{i}.id = "RENAMED_"+i;
                        c.identity.definitionSI.sources{i}.id = "RENAMED_"+i;
                    end
                case "CORNER_AND_NESTED_ID"
                    c.definitionSI.sources{2}.model.cornerId = "FR";
                    c.identity.definitionSI.sources{2}.modelIdentity.cornerId = "FR";
                case "NESTED_ID_AND_NOMINAL"
                    c = candidate({f.bumpA;f.actB},struct("geometries",{{f.bumpA.model}}));
                    c.definitionSI.sources{2}.model.cornerGeometryIdentity = fsd.model.geometryIdentity(f.bumpA.model);
                    c.definitionSI.sources{2}.model.identity.cornerGeometryIdentity = fsd.model.geometryIdentity(f.bumpA.model);
                    c.identity.definitionSI.sources{2}.modelIdentity = c.definitionSI.sources{2}.model.identity;
                case "REF_GEOMETRY_AND_STATUS"
                    c = candidate({f.bumpA;f.bumpB},struct("geometries",{{f.bumpB.model}}));
                case "REF_VEHICLE_AND_STATUS"
                    c = candidate({f.loadsA;f.loadsB},struct("vehicle",f.loadsB.model));
                case "CANONICAL_EVIDENCE_MISSING"
                    c = candidate({f.bumpA;f.actA});
                    c.definitionSI.sources{2}.model = rmfield(c.definitionSI.sources{2}.model,"cornerGeometryIdentity");
            end
            legacy.candidateIdentity = c.identity; legacy.hardFeasibility = "SATISFIES_SAMPLED_HARD_REQUIREMENTS";
            for i = 1:numel(legacy.targetAssessments), legacy.targetAssessments{i}.status = "SAMPLED_PASS"; end
            expected = "fsd:analysis:InvalidDesignCandidate";
            if Attack == "NESTED_ID_AND_NOMINAL", expected = "fsd:kinematics:ActuationIdentityMismatch"; end
            t.verifyError(@() fsd.analysis.validateDesignAssessment(legacy,spec,c),expected);
        end
        function missingEvidenceHasExplicitDiagnosticAndNativeCause(t)
            f = t.Fixtures; c = candidate({f.actA});
            c.definitionSI.sources{1}.model = rmfield(c.definitionSI.sources{1}.model,"cornerGeometryIdentity");
            try
                fsd.analysis.validateDesignCandidate(c); t.assertFail("Missing evidence accepted.");
            catch cause
                t.verifyEqual(cause.identifier,'fsd:analysis:InvalidDesignCandidate');
                t.verifySubstring(cause.message,'INVALID_CANONICAL_EVIDENCE');
                t.verifyNotEmpty(cause.cause);
            end
        end
        function frontAndRearAxleAssociationsAreIndependent(t)
            rear = translationAxleFixture("REAR");
            sw = fsd.kinematics.solveAxleRollSweep(rear,[-.01;0;.01],0,"rad","m");
            roll = struct("id","REAR_ROLL","type","ROLL","model",rear,"sweep",sw, ...
                "result",fsd.analysis.analyzeAxleRollSweep(rear,sw));
            c = candidate({t.Fixtures.roll;roll;t.Fixtures.rear});
            t.verifyTrue(fsd.analysis.validateDesignCandidate(c));
        end
        function changingCgOrGravityIsNotApproximateCompatibility(t)
            f = t.Fixtures; [~,d,u] = vehicleFixture();
            for field = ["cg","gravity"]
                changed = d;
                if field == "cg", changed.cg = d.cg+[0,0,.001]; else, changed.gravity_mps2 = 9.81; end
                v = fsd.model.createVehicleParameters(changed,u);
                lc = fsd.model.createVehicleLoadCase(v,struct("mode","CROSSWEIGHT_SPECIFIED","crossweight",.5,"sourceKind","KNOWN"));
                source = struct("id","CHANGED_VEHICLE","type","STATIC_LOADS","model",v, ...
                    "result",fsd.analysis.analyzeStaticVehicleLoads(v,lc));
                c = candidate({f.loadsA;source});
                t.verifyError(@() fsd.analysis.validateDesignCandidate(c),"fsd:analysis:InvalidDesignCandidate");
            end
        end
        function distinctDesignsTwoAndThreeComparisonRemainsLegal(t)
            f = t.Fixtures; third = candidate({bump(f.bumpA.model,f.bumpA.id)},struct("id","THIRD_PARTIAL"));
            for candidates = {f.example.candidates,[f.example.candidates;{third}]}
                r = fsd.analysis.compareDesignCandidates(f.example.specification,candidates{1});
                t.verifyEqual(r.selectionPolicy,"NO_AUTOMATIC_WINNER");
                t.verifyNumElements(r.assessments,numel(candidates{1}));
            end
            r = fsd.analysis.evaluateDesignCandidate(f.example.specification,third);
            t.verifyEqual(r.targetAssessments{3}.status,"NOT_EVALUATED");
        end
    end
end

function spec = loadSpecification(f)
sources = {f.loadsA;f.loadsB}; targets = cell(2,1); values = [250,500];
for i = 1:2
    targets{i} = designTargetFixture("POINT_TARGET","CORNER_LOAD", ...
        struct("id","LOAD_"+i,"sourceId",sources{i}.id,"sourceType","STATIC_LOADS", ...
        "independentVariable","NONE","x",[],"value",values(i),"tolerance",1e-9,"strength","HARD"));
end
spec = fsd.model.createDesignSpecification(struct("id","LOAD_REPRODUCER", ...
    "targets",fsd.model.createSuspensionDesignTargets(targets)));
end

function source = bump(geometry,id)
sw = fsd.kinematics.solveBumpSweep(geometry,[-.01;0;.01],"m");
source = struct("id",id,"type","BUMP","model",geometry,"sweep",sw, ...
    "result",fsd.analysis.analyzeBumpSweep(geometry,sw));
end

function c = candidate(sources,extra)
if nargin < 2, extra = struct(); end
d = struct("id","AUDIT_CANDIDATE","sources",{sources});
for name = string(fieldnames(extra))', d.(name) = extra.(name); end
c = fsd.model.createDesignCandidate(d);
end

function spec = bumpSpecification(f)
sources = {f.bumpA;f.bumpB}; targets = cell(2,1); values = [0,-.02];
for i = 1:2
    targets{i} = designTargetFixture("POINT_TARGET","CAMBER", ...
        struct("id","CAMBER_"+i,"sourceId",sources{i}.id,"sourceType","BUMP", ...
        "x",0,"value",values(i),"tolerance",1e-9,"strength","HARD"));
end
spec = fsd.model.createDesignSpecification(struct("id","BUMP_REPRODUCER", ...
    "targets",fsd.model.createSuspensionDesignTargets(targets)));
end
