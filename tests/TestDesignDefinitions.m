classdef TestDesignDefinitions < matlab.unittest.TestCase
    properties (TestParameter)
        Role = {"KNOWN","FIXED","RANGE","FREE","TARGET","DERIVED","ASSUMED","RULE"}
        Missing = {"NOT_PROVIDED","NOT_APPLICABLE","PENDING_CALCULATION","INVALID"}
        Corner = {"FL","FR","RL","RR"}
        UnitCase = { {"LENGTH","mm",250,.25,"m"}, {"ANGLE","deg",90,pi/2,"rad"}, ...
            {"FORCE","N",200,200,"N"}, {"STIFFNESS","N/mm",30,30000,"N/m"}, ...
            {"DAMPING","N/(mm/s)",1.5,1500,"N*s/m"}, {"MASS","kg",200,200,"kg"}, ...
            {"TIME","s",2,2,"s"}, {"FRACTION","%",50,.5,"1"}, {"RATIO","1",-.5,-.5,"1"} }
        BadParameter = {"INVERTED_BOUNDS","NONFINITE","ASSUMED_AS_KNOWN","DERIVED_NO_REFERENCE","BAD_ID","BAD_SCOPE","UNKNOWN_ZERO"}
        BadTarget = {"NEGATIVE_TOLERANCE","ZERO_SCALE","NO_SCALE_NOTE","NONMONOTONIC","DUPLICATE","NONFINITE", ...
            "UNKNOWN_METRIC","WRONG_UNIT","WRONG_SCOPE","MISSING_HARD_VALUE","MATRIX_VALUES","MISSING_TOLERANCE"}
    end
    methods (Test)
        function parameterRoles(t,Role)
            d = basicParameter(); d.type = Role;
            if Role == "RANGE", d.bounds = [1,2]; end
            if Role == "RULE"
                d.ruleReference = struct("organizer","TEST_ONLY","version","ILLUSTRATIVE", ...
                    "ruleId","NOT_A_REAL_RULE","quantity","LENGTH","source","Test fixture", ...
                    "status","UNVERIFIED","applicability","Fixture only, no regulatory claim");
            end
            p = fsd.model.createDesignParameter(d,"m");
            t.verifyTrue(fsd.model.validateDesignParameter(p)); t.verifyEmpty(p.definitionSI.value);
        end
        function unknownAvailabilityIsNotZero(t,Missing)
            d = basicParameter(); d.availability = Missing;
            p = fsd.model.createDesignParameter(d,"m");
            t.verifyEmpty(p.definitionSI.value); t.verifyEqual(p.definitionSI.availability,Missing);
        end
        function allCornerScopes(t,Corner)
            s = fsd.model.designScope("CORNER",Corner); t.verifyEqual(s.id,Corner);
            hp = fsd.model.designScope("HARDPOINT",Corner+"_UBJ",Corner);
            t.verifyEqual(hp.cornerId,Corner);
        end
        function equivalentBoundaryUnits(t,UnitCase)
            c = UnitCase; [value,unit] = fsd.model.convertDesignUnits(c{3},c{1},c{2});
            t.verifyEqual(value,c{4},"AbsTol",1e-12); t.verifyEqual(unit,c{5});
        end
        function preliminarySpecificationAndClosedSpace(t)
            p = fsd.model.createDesignParameter(basicParameter(),"m");
            s = fsd.model.createDesignSpecification(struct("id","PRELIMINARY","parameters",{{p}}));
            c = fsd.model.createDesignCandidate(struct("id","NO_GEOMETRY_YET"));
            a = fsd.analysis.evaluateDesignCandidate(s,c);
            t.verifyEqual(a.readiness.unknownParameters,"CG_X:NOT_PROVIDED");
            t.verifyFalse(a.readiness.allRequirementsEvaluated);
            t.verifyError(@() fsd.model.designVariableSpace(s,true),"fsd:model:IncompleteDesignSpace");
            d = basicParameter(); d.scope = fsd.model.designScope("HARDPOINT","FL_UBJ","FL");
            d.binding = "HARDPOINT_X"; d.bounds = [-.1,.1];
            p = fsd.model.createDesignParameter(d,"m");
            s = fsd.model.createDesignSpecification(struct("id","BOUNDED","parameters",{{p}}));
            space = fsd.model.designVariableSpace(s,true);
            t.verifyEqual(space.status,"CLOSED_DECLARED_SPACE"); t.verifyFalse(space.optimizerImplemented);
        end
        function invalidParameters(t,BadParameter)
            d = basicParameter();
            switch BadParameter
                case "INVERTED_BOUNDS", d.bounds = [2,1];
                case "NONFINITE", d.value = Inf;
                case "ASSUMED_AS_KNOWN", d.type = "ASSUMED"; d.value = 1; d.availability = "KNOWN"; d.sourceKind = "KNOWN"; d.sourceNote = "Test";
                case "DERIVED_NO_REFERENCE", d.type = "DERIVED"; d.value = 1; d.availability = "DERIVED"; d.sourceKind = "DERIVED"; d.sourceNote = "Test";
                case "BAD_ID", d.id = "ambiguous id";
                case "BAD_SCOPE", d.scope.id = "FL";
                case "UNKNOWN_ZERO", d.value = 0;
            end
            t.verifyError(@() fsd.model.createDesignParameter(d,"m"),"fsd:model:InvalidDesignDefinition");
        end
        function invalidTargets(t,BadTarget)
            [~,d] = designTargetFixture("CURVE_TARGET","CAMBER",struct("sourceType","BUMP", ...
                "x",[-.01;0;.01],"value",0,"tolerance",.001)); unit = "rad";
            switch BadTarget
                case "NEGATIVE_TOLERANCE", d.tolerance = -.001;
                case "ZERO_SCALE", d.normalizationScale = 0; d.normalizationNote = "Test";
                case "NO_SCALE_NOTE", d.normalizationScale = .01;
                case "NONMONOTONIC", d.x = [-.01;.01;0];
                case "DUPLICATE", d.x = [-.01;0;0];
                case "NONFINITE", d.value = [0;NaN;0];
                case "UNKNOWN_METRIC", d.metricId = "INVENTED_GRIP";
                case "WRONG_UNIT", unit = "m";
                case "WRONG_SCOPE", d.scope = fsd.model.designScope("AXLE","FRONT");
                case "MISSING_HARD_VALUE", d.strength = "HARD"; d.value = [];
                case "MATRIX_VALUES", d.value = zeros(2);
                case "MISSING_TOLERANCE", d = rmfield(d,"tolerance");
            end
            t.verifyError(@() fsd.model.createDesignTarget(d,unit,"m"),"fsd:model:InvalidDesignDefinition");
        end
        function metadataAndPhysicalIdentity(t)
            d = basicParameter(); p = fsd.model.createDesignParameter(d,"m");
            d.metadata = struct("displayName","Human label","eventPriority","BALANCED");
            other = fsd.model.createDesignParameter(d,"m"); t.verifyEqual(other.identity,p.identity);
            d.bounds = [-.1,.1]; changed = fsd.model.createDesignParameter(d,"m");
            t.verifyNotEqual(changed.identity,p.identity);
            q = p; q.definitionSI.type = "FIXED";
            t.verifyError(@() fsd.model.validateDesignParameter(q),"fsd:model:InvalidDesignDefinition");
        end
        function ruleMustIdentifyConcreteUnverifiedSource(t)
            d = basicParameter(); d.type = "RULE";
            t.verifyError(@() fsd.model.createDesignParameter(d,"m"),"fsd:model:InvalidDesignDefinition");
        end
        function equivalentAngleTargetsAndPresentation(t)
            [~,d] = designTargetFixture("CURVE_TARGET","CAMBER",struct("sourceType","BUMP", ...
                "x",[-10;10],"value",-2,"tolerance",.1));
            a = fsd.model.createDesignTarget(d,"deg","mm");
            d.x = [-.01;.01]; d.value = -2*pi/180; d.tolerance = .1*pi/180;
            b = fsd.model.createDesignTarget(d,"rad","m");
            t.verifyEqual(a.identity,b.identity);
            d.metadata = struct("displayName","Camber human label");
            b = fsd.model.createDesignTarget(d,"rad","m"); t.verifyEqual(a.identity,b.identity);
            d.tolerance = 2*d.tolerance; b = fsd.model.createDesignTarget(d,"rad","m");
            t.verifyNotEqual(a.identity,b.identity);
        end
        function knownIsNotFixed(t)
            d = basicParameter(); d.type = "KNOWN"; d.value = 2; d.availability = "KNOWN";
            d.sourceKind = "KNOWN"; d.sourceNote = "Supplied datum"; d.binding = "VEHICLE_WHEELBASE";
            p = fsd.model.createDesignParameter(d,"m");
            s = fsd.model.createDesignSpecification(struct("id","KNOWN_ONLY","parameters",{{p}}));
            a = fsd.analysis.evaluateDesignCandidate(s,fsd.model.createDesignCandidate(struct("id","EMPTY")));
            t.verifyEmpty(a.parameterAssessments); t.verifyEqual(a.hardFeasibility,"NO_HARD_REQUIREMENTS");
        end
        function fixedNeedsExplicitComparisonTolerance(t)
            d = basicParameter(); d.type = "FIXED"; d.value = 2; d.availability = "KNOWN";
            d.sourceKind = "KNOWN"; d.sourceNote = "Test"; d.binding = "VEHICLE_WHEELBASE";
            t.verifyError(@() fsd.model.createDesignParameter(d,"m"),"fsd:model:InvalidDesignDefinition");
        end
        function duplicateAndIncompleteScoreRejected(t)
            target = designTargetFixture("POINT_TARGET","DAMPER_COMPRESSION",struct("value",0,"tolerance",0));
            t.verifyError(@() fsd.model.createSuspensionDesignTargets({target;target}),"fsd:model:InvalidDesignDefinition");
            t.verifyError(@() designSpecificationFixture(target,true),"fsd:model:InvalidDesignDefinition");
        end
        function matRoundTrip(t)
            target = designTargetFixture("CURVE_TARGET","MOTION_RATIO",struct("x",[-.01;0;.01],"value",.5,"tolerance",.01));
            specification = designSpecificationFixture(target); candidate = designEvaluationFixture();
            assessment = fsd.analysis.evaluateDesignCandidate(specification,candidate);
            file = string(tempname)+".mat"; cleanup = onCleanup(@() delete(file));
            save(file,"specification","candidate","assessment"); loaded = load(file);
            t.verifyEqual(loaded.specification,specification); t.verifyEqual(loaded.candidate,candidate);
            t.verifyEqual(loaded.assessment,assessment);
            t.verifyTrue(fsd.analysis.validateDesignAssessment(loaded.assessment,loaded.specification,loaded.candidate));
        end
    end
end

function d = basicParameter()
d = struct("id","CG_X","quantity","LENGTH","scope",fsd.model.designScope("VEHICLE","VEHICLE"),"type","FREE");
end
