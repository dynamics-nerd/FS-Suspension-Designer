classdef TestEngineeringResultIntegrity < matlab.unittest.TestCase
    properties
        Project
        Result
    end
    properties (TestParameter)
        Attack={"MASS","CG","UNIT","CORNER","SEED","ARCHITECTURE","SCENARIO","PLAN", ...
            "OPTIONS","IDENTITY","REVISION","PROJECT_ID","ASSESSMENT","ANALYSIS","POSE","PREPARED","EXTRA","TIMING","PAYLOAD_TIME"}
        FileAttack={"HEADER","VERSION","PROJECT","REVISION","CONCEPT","SCENARIO","RESULT","OBJECT"}
    end
    methods (TestClassSetup)
        function setup(t)
            old=path; t.addTeardown(@()path(old)); root=fileparts(fileparts(mfilename('fullpath')));
            addpath(fullfile(root,'src'),fullfile(root,'examples'));
            t.Project=projectWorkflowFixture('BUMP'); t.Result=fsd.project.runEngineeringScenario(t.Project,'SCENARIO','BASE');
        end
    end
    methods (Test)
        function rejectsManipulatedEvidence(t,Attack)
            r=t.Result;
            switch Attack
                case {"MASS","CG"}
                    id="VEHICLE_MASS"; if Attack=="CG", id="CG_Z"; end
                    ps=r.projectAtExecution.definition.concept.definitionSI.parameters;
                    index=cellfun(@(q)q.id==id,ps);
                    r.projectAtExecution.definition.concept.definitionSI.parameters{index}.parameter.definitionSI.value=99;
                case "UNIT", r.projectAtExecution.definition.concept.definitionSI.parameters{1}.parameter.definitionSI.unit="mm";
                case "CORNER", r.nativePayload.sweep.geometryIdentity.cornerId="FR";
                case "SEED", r.projectAtExecution.definition.resources.geometries{1}.hardpoints.xyz_m(1,3)=9;
                case "ARCHITECTURE", r.projectAtExecution.definition.concept.definitionSI.architectures.frontSuspension="OTHER";
                case "SCENARIO", r.scenarioAtExecution.definition.id="OTHER";
                case "PLAN", r.scenarioAtExecution.definition.plan.travel_m=0;
                case "OPTIONS", r.prepared.plan.solverOptions.MaxIterations=1;
                case "IDENTITY", r.identity.context.engine="OTHER";
                case "REVISION", r.projectRevision=2;
                case "PROJECT_ID", r.projectId="OTHER";
                case "ASSESSMENT", r.assessment=struct('compositeScore',0);
                case "ANALYSIS", r.nativePayload.analysis.camber_rad(1)=1;
                case "POSE", r.nativePayload.sweep.results(1).uprightPose.translation_m(3)=1;
                case "PREPARED", r.prepared.context.resources=struct();
                case "EXTRA", r.unrequested=1;
                case "TIMING", r.elapsedTime_s=NaN;
                case "PAYLOAD_TIME", r.nativePayload.analysis.analysisElapsedTime_s=NaN;
            end
            t.verifyError(@()fsd.project.validateEngineeringResult(r),'fsd:project:InvalidEngineeringResult');
        end
        function matRoundTripAndOverwritePolicy(t)
            p=fsd.project.attachEngineeringResult(t.Project,t.Result); file=string(tempname)+".mat";
            t.addTeardown(@()removeTestFile(file)); fsd.project.saveEngineeringProject(p,file);
            loaded=fsd.project.loadEngineeringProject(file); t.verifyEqual(loaded,p);
            t.verifyError(@()fsd.project.saveEngineeringProject(p,file),'fsd:project:InvalidInput');
            fsd.project.saveEngineeringProject(p,file,true);
            t.verifyEqual(fsd.project.resultCompatibility(loaded.definition.results{1},loaded).status,"CURRENT_EXECUTION");
        end
        function matRejectsManipulation(t,FileAttack)
            p=fsd.project.attachEngineeringResult(t.Project,t.Result);
            envelope=struct('kind',"FsdEngineeringProjectFile",'schemaVersion',"0.16.0",'project',p);
            switch FileAttack
                case "HEADER", envelope.kind="SynthesisResult";
                case "VERSION", envelope.schemaVersion="0.1.0";
                case "PROJECT", envelope.project.identity.projectId="OTHER";
                case "REVISION", envelope.project.definition.revision=0;
                case "CONCEPT", envelope.project.definition.concept.definitionSI.massConvention="INCLUDES_DRIVER";
                case "SCENARIO", envelope.project.definition.scenarios{1}.definition.plan.travel_m=0;
                case "RESULT", envelope.project.definition.results{1}.projectRevision=3;
                case "OBJECT", envelope.project.definition.name=@sin;
            end
            file=string(tempname)+".mat"; t.addTeardown(@()removeTestFile(file)); save(file,'envelope');
            t.verifyTrue(rejected(@()fsd.project.loadEngineeringProject(file)));
        end
        function staleHistoryMayBeSavedButNeverRelabelled(t)
            p=fsd.project.attachEngineeringResult(t.Project,t.Result); d=p.definition.scenarios{1}.definition;
            d.plan.travel_m=[-.005;0;.005]; revised=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{fsd.project.createEngineeringScenario(d)}}));
            t.verifyEqual(revised.definition.results{1},t.Result);
            file=string(tempname)+".mat"; t.addTeardown(@()removeTestFile(file)); fsd.project.saveEngineeringProject(revised,file);
            loaded=fsd.project.loadEngineeringProject(file);
            t.verifyEqual(fsd.project.resultCompatibility(loaded.definition.results{1},loaded).status,"STALE");
            t.verifyError(@()fsd.project.attachEngineeringResult(revised,t.Result),'fsd:project:InvalidInput');
        end
        function wrongProjectAndMissingScenario(t)
            d=t.Project.definition; c=d.concept.definitionSI; c.id="OTHER"; d.concept=fsd.project.createVehicleConcept(c);
            p=fsd.project.createEngineeringProject(d);
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,p).status,"INCOMPATIBLE");
            t.verifyError(@()fsd.project.attachEngineeringResult(p,t.Result),'fsd:project:InvalidInput');
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{{}}));
            t.verifyEqual(fsd.project.resultCompatibility(t.Result,p).status,"INCOMPATIBLE");
        end
        function consumersHaveNoForwardSolves(t)
            file=string(tempname)+".mat"; t.addTeardown(@()removeTestFile(file));
            p=fsd.project.attachEngineeringResult(t.Project,t.Result); profile clear; profile on;
            fsd.project.validateEngineeringResult(t.Result); fsd.project.validateEngineeringProject(p);
            fsd.project.resultCompatibility(t.Result,p); fsd.project.saveEngineeringProject(p,file); fsd.project.loadEngineeringProject(file);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["fsolve","fzero","solveBump","solveActuation","solveRack","solveAxleRoll"])));
        end
        function targetEvaluationUsesActualDeclaredEvidence(t)
            [s,~]=synthesisFixture(); native=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1));
            candidate=native.search.records{1}.candidate;
            scenario=fsd.project.createEngineeringScenario(struct('id',"TARGETS",'engine',"TARGET_EVALUATION", ...
                'scope',fsd.model.designScope('CORNER','FL'),'specification',s.specification,'inputs',struct('candidate',candidate)));
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{{scenario}}));
            t.verifyEqual(fsd.project.designReadiness(p,'TARGETS').status,"READY");
            r=fsd.project.runEngineeringScenario(p,'TARGETS','ASSESSMENT');
            expected=fsd.analysis.evaluateDesignCandidate(s.specification,candidate);
            t.verifyEqual(r.assessment.compositeScore,expected.compositeScore,'AbsTol',1e-12);
            t.verifyEqual(r.assessment.targetAssessments,expected.targetAssessments);
            r.assessment.compositeScore=99; t.verifyError(@()fsd.project.validateEngineeringResult(r),'fsd:project:InvalidEngineeringResult');
        end
        function missingSourceAndUnsupportedTargets(t)
            [space,~]=actuationSynthesisFixture(); spec=space.specification; candidate=fsd.model.createDesignCandidate( ...
                struct('id',"NO_SOURCES",'geometries',{{space.seed}},'sources',{{}}));
            scenario=fsd.project.createEngineeringScenario(struct('id',"MISSING_SOURCE",'engine',"TARGET_EVALUATION", ...
                'scope',fsd.model.designScope('CORNER','FL'),'specification',spec,'inputs',struct('candidate',candidate)));
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{{scenario}}));
            readiness=fsd.project.designReadiness(p,'MISSING_SOURCE');
            t.verifyEqual(readiness.status,"BLOCKED_BY_DEPENDENCY"); t.verifyTrue(any(readiness.missing=="SOURCE:ACT:ACTUATION"));
            s=t.Project.definition.scenarios{1}.definition; s.specification=spec;
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{{fsd.project.createEngineeringScenario(s)}}));
            t.verifyEqual(fsd.project.designReadiness(p,'SCENARIO').status,"UNSUPPORTED");
            requests=fsd.project.specificationSources(spec);
            t.verifyTrue(any(cellfun(@(q)q.metricId=="TANGENT_WHEEL_RATE" && q.sourceType=="MECHANICAL",requests)));
        end
        function targetSourceWrongCornerIsBlocked(t)
            [s,~]=synthesisFixture(); native=fsd.synthesis.runInverseSearch(s,struct('maxEvaluations',1));
            d=s.specification.definitionSI; d.parameters={}; d.constraints={};
            ts=d.targets.definitionSI.targets; q=ts{1}.definitionSI; q.scope=fsd.model.designScope('CORNER','FR');
            d.targets=fsd.model.createSuspensionDesignTargets({fsd.model.createDesignTarget(q,'rad','m')});
            scenario=fsd.project.createEngineeringScenario(struct('id',"WRONG_SCOPE",'engine',"TARGET_EVALUATION", ...
                'scope',fsd.model.designScope('AXLE','FRONT'),'specification',fsd.model.createDesignSpecification(d), ...
                'inputs',struct('candidate',native.search.records{1}.candidate)));
            p=fsd.project.reviseEngineeringProject(t.Project,struct('scenarios',{{scenario}}));
            r=fsd.project.designReadiness(p,'WRONG_SCOPE'); t.verifyEqual(r.status,"BLOCKED_BY_DEPENDENCY");
            t.verifyTrue(any(startsWith(r.missing,"SOURCE_SCOPE_OR_CONDITION:")));
        end
        function sourceAliasCannotCrossPhysicalFamilies(t)
            p=projectWorkflowFixture('ACTUATION_SYNTHESIS'); s=p.definition.scenarios{1}.definition;
            d=s.specification.definitionSI; ts=d.targets.definitionSI.targets; q=ts{4}.definitionSI;
            q.sourceId="ACT"; ts{4}=fsd.model.createDesignTarget(q,'N/m','m');
            d.targets=fsd.model.createSuspensionDesignTargets(ts); s.specification=fsd.model.createDesignSpecification(d);
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{{fsd.project.createEngineeringScenario(s)}}));
            r=fsd.project.designReadiness(p,'SCENARIO'); t.verifyEqual(r.status,"INVALID_INPUT");
            t.verifyTrue(any(r.diagnostics=="SOURCE_ALIAS_CROSSES_FAMILIES:ACT"));
        end
        function fourCornersAreOptionalAndExplicit(t)
            front=axleSynthesisFixture(false,'FRONT'); rear=axleSynthesisFixture(false,'REAR');
            resources=struct('geometries',{{front.seedAxle.leftGeometry;front.seedAxle.rightGeometry; ...
                rear.seedAxle.leftGeometry;rear.seedAxle.rightGeometry}});
            p=fsd.project.reviseEngineeringProject(t.Project,struct('resources',resources));
            t.verifyEqual(numel(p.definition.resources.geometries),4); t.verifyTrue(fsd.project.validateEngineeringProject(p));
        end
    end
end

function removeTestFile(file)
% Exact generated test file only; no recursive removal.
if isfile(file), delete(file); end
end

function yes = rejected(callback)
yes=false;
try
    callback();
catch cause
    yes=startsWith(string(cause.identifier),'fsd:');
end
end
