classdef TestGuidedDesignWorkflow < matlab.unittest.TestCase
    properties
        Root
        BuiltProject
        SearchProject
        SearchResult
    end
    methods (TestClassSetup)
        function knownCase(t)
            t.Root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(t.Root,'src'),fullfile(t.Root,'app'),fullfile(t.Root,'examples'));
            c=fsdui.Controller(); t.addTeardown(@()c.close());
            c.run('DEMO',struct(),false);
            c.run('BUILD',struct('scope',"FRONT",'resultId',c.nextResultId()),false);
            t.BuiltProject=c.Project;
            c.run('REFERENCE_TARGETS',struct(),false);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',c.nextResultId()),false);
            t.SearchProject=c.Project; t.SearchResult=c.LastValue;
        end
    end
    methods (Test)
        function nativeBenchmarkUnchanged(t)
            r=t.SearchResult.nativePayload;
            t.verifyEqual(r.search.evaluationCount,7); t.verifyEqual(r.statistics.physicalBumpSweeps,7);
            t.verifyEqual(r.search.records{1}.score,.101722096447,'AbsTol',1e-12);
            t.verifyEqual(r.search.records{r.selectedIndex}.score,0);
        end
        function noHiddenBumpDuringConstruction(t)
            rs=t.BuiltProject.definition.results;
            t.verifyEqual(numel(rs),1); t.verifyEqual(rs{1}.engine,"PARAMETRIC_SEED");
            t.verifyEmpty(rs{1}.nativePayload.bumpCheck);
            t.verifyEqual(rs{1}.nativePayload.seed.sampledStatus,"NOT_CHECKED");
        end
        function targetsAndVariablesRoundTrip(t)
            r=t.SearchResult; spec=r.scenarioAtExecution.definition.specification.definitionSI;
            definition=fsdui.searchDefinition("FL",fsdui.specRows(spec,'targets'), ...
                fsdui.specRows(spec,'parameters'),fsdui.specRows(spec,'constraints'), ...
                r.prepared.plan.travel_m,r.prepared.plan.solverOptions,r.scenarioAtExecution.definition.options);
            t.verifyEqual(definition.specification.definitionSI.targets,spec.targets);
            t.verifyEqual(definition.specification.definitionSI.parameters,spec.parameters);
            % Preserve native fields not exposed as editable table columns.
            previous=r.scenarioAtExecution.definition;
            previous.name="Native scenario name"; previous.description="Native scenario provenance retained";
            spec.metadata=struct('auditMarker',"UI_ROUND_TRIP");
            target=spec.targets.definitionSI.targets{1}.definitionSI;
            target.metadata=struct('auditMarker',"TARGET_METADATA"); target.transform="ABS";
            ts=spec.targets.definitionSI.targets; ts{1}=fsd.model.createDesignTarget(target,'rad','m');
            spec.targets=fsd.model.createSuspensionDesignTargets(ts);
            spec.targets.metadata=struct('auditMarker',"COLLECTION_METADATA");
            fsd.model.validateSuspensionDesignTargets(spec.targets);
            p=spec.parameters{1}.definitionSI; p.description="Preserved native description";
            p.metadata=struct('auditMarker',"PARAMETER_METADATA");
            spec.parameters{1}=fsd.model.createDesignParameter(p,'m');
            native=steeringSynthesisFixture();
            fixed=native.specification.definitionSI.constraints{1};
            box=fsd.model.createDesignConstraint(struct('id',"XYZ_ORDER_ORACLE", ...
                'scope',fsd.model.designScope('HARDPOINT','FL_UBJ','FL'), ...
                'type',"AXIS_ALIGNED_BOX",'strength',"HARD",'bounds',[1 2;3 4;5 6], ...
                'metadata',struct('auditMarker',"CONSTRAINT_METADATA"), ...
                'sourceNote',"Software-only XYZ serialization oracle in m, not a vehicle packaging region"),'m');
            spec.constraints={fixed;box};
            previous.specification=fsd.model.createDesignSpecification(spec);
            definition=fsdui.searchDefinition("FL",fsdui.specRows(spec,'targets'), ...
                fsdui.specRows(spec,'parameters'),fsdui.specRows(spec,'constraints'), ...
                r.prepared.plan.travel_m,r.prepared.plan.solverOptions,previous.options,previous);
            t.verifyEqual(definition.specification,previous.specification);
            t.verifyEqual(definition.targetOrigins,previous.targetOrigins);
            t.verifyEqual(definition.name,previous.name); t.verifyEqual(definition.description,previous.description);
            t.verifyEqual(definition.symmetryLinks,previous.symmetryLinks);
            t.verifyEqual(definition.conceptDependencies,previous.conceptDependencies);
            unsupported=previous; unsupported.plan.roll=struct('softwareTest',true);
            t.verifyError(@()fsdui.searchDefinition("FL",fsdui.specRows(spec,'targets'), ...
                fsdui.specRows(spec,'parameters'),fsdui.specRows(spec,'constraints'), ...
                r.prepared.plan.travel_m,r.prepared.plan.solverOptions,previous.options,unsupported), ...
                'fsd:ui:UnsupportedEditor');
            rows=fsdui.specRows(spec,'parameters'); rows{1,5}='RANGE'; rows{1,6}=''; rows{1,9}='NOT_PROVIDED';
            unknown=fsdui.searchDefinition("FL",fsdui.specRows(spec,'targets'),rows, ...
                fsdui.specRows(spec,'constraints'),r.prepared.plan.travel_m,r.prepared.plan.solverOptions,previous.options);
            t.verifyEmpty(unknown.specification.definitionSI.parameters{1}.definitionSI.value);
            t.verifyEqual(unknown.specification.definitionSI.parameters{1}.definitionSI.sourceKind,"UNSPECIFIED");
        end
        function saveLoadUsesNativeEnvelope(t)
            c=fsdui.Controller(t.SearchProject); t.addTeardown(@()c.close());
            file=string(tempname)+".mat"; t.addTeardown(@()removeFile(file));
            c.run('SAVE',struct('file',file,'overwrite',false),false);
            loaded=fsd.project.loadEngineeringProject(file);
            t.verifyEqual(loaded,t.SearchProject); stored=load(file);
            % Nonempty histories use the bounded native0.19 envelope. Check
            % its complete inventory, not the legacy single-variable layout;
            % the exact logical-project assertion above remains mandatory.
            count=numel(t.SearchProject.definition.results);
            names=compose("FSD_RESULT_%06d",(1:count)');
            t.verifyEqual(sort(string(fieldnames(stored))),sort(["envelope";names]));
            t.verifyEqual(stored.envelope.kind,'FsdEngineeringProjectStorage');
            t.verifyEqual(stored.envelope.schemaVersion,'0.19.0');
            t.verifyEqual(stored.envelope.encoding,'FSD_VALUE_GRAPH_V1');
            t.verifyEqual(string(stored.envelope.resultNames(:)),names);
            t.verifyEqual(stored.envelope.resultShape,[count 1]);
            t.verifyFalse(c.Dirty); t.verifyFalse(c.Busy);
        end
        function saveRefusesImplicitOverwrite(t)
            c=fsdui.Controller(t.BuiltProject); t.addTeardown(@()c.close());
            file=string(tempname)+".mat"; t.addTeardown(@()removeFile(file));
            c.run('SAVE',struct('file',file,'overwrite',false),false);
            t.verifyError(@()c.run('SAVE',struct('file',file,'overwrite',false),false),'fsd:ui:Overwrite');
        end
        function adoptionIsExplicitAndPreservesHistory(t)
            c=fsdui.Controller(t.SearchProject); t.addTeardown(@()c.close());
            original=c.Project.definition.results; r=t.SearchResult;
            c.run('ADOPT',struct('resultId',r.id,'index',r.nativePayload.selectedIndex),false);
            t.verifyEqual(c.Project.definition.results,original);
            report=fsd.project.resultCompatibility(r,c.Project); t.verifyEqual(report.status,"STALE");
            t.verifyNotEqual(c.Project.identity,t.SearchProject.identity);
        end
        function adoptionRejectsOutOfRange(t)
            c=fsdui.Controller(t.SearchProject); t.addTeardown(@()c.close());
            t.verifyError(@()c.run('ADOPT',struct('resultId',t.SearchResult.id,'index',999),false),'fsd:ui:InvalidSelection');
            t.verifyEqual(c.Project,t.SearchProject); t.verifyFalse(c.Busy);
        end
        function nativeBumpAndFailuresAreRetained(t)
            c=fsdui.Controller(t.BuiltProject); t.addTeardown(@()c.close());
            plan=struct('travel_m',[-.01;0;.01;.4]);
            c.run('BUMP',struct('scope',"FL",'plan',plan,'resultId',c.nextResultId()),false);
            r=c.LastValue{1}; s=r.nativePayload.sweep; a=r.nativePayload.analysis;
            t.verifyEqual(s.converged,[true;true;true;false]); t.verifyTrue(isnan(a.camber_rad(4)));
            g=r.prepared.resources.geometries{1}; independent=fsd.kinematics.solveBumpSweep(g,plan.travel_m,'m');
            t.verifyEqual(s.camber_rad,independent.camber_rad,'AbsTol',1e-12);
        end
        function v018ResultsAndHistoricalSoftwareRemainValid(t)
            t.verifyEqual(t.SearchResult.fsdVersion,"0.21.0");
            t.verifyTrue(fsd.project.validateEngineeringResult(t.SearchResult));
            old=t.SearchResult; old.fsdVersion="0.17.0";
            t.verifyTrue(fsd.project.validateEngineeringResult(old));
            old.fsdVersion="0.18.0";
            t.verifyTrue(fsd.project.validateEngineeringResult(old));
        end
        function readinessDoesNotAppendEvidence(t)
            c=fsdui.Controller(t.BuiltProject); t.addTeardown(@()c.close()); before=c.Project;
            c.run('READINESS',struct('scenarioId',"UI_BUILD_FRONT"),false);
            t.verifyEqual(c.LastValue.status,"READY"); t.verifyEqual(c.Project,before);
        end
        function axleSynthesisDelegatesOneJointSearch(t)
            c=fsdui.Controller(t.BuiltProject); t.addTeardown(@()c.close());
            r=t.SearchResult; spec=r.scenarioAtExecution.definition.specification.definitionSI;
            d=fsdui.searchDefinition("FRONT",fsdui.specRows(spec,'targets'),fsdui.specRows(spec,'parameters'), ...
                fsdui.specRows(spec,'constraints'),r.prepared.plan.travel_m,r.prepared.plan.solverOptions,r.scenarioAtExecution.definition.options);
            c.run('SPECIFICATION',struct('definition',d),false); t.verifyEqual(c.LastValue.status,"READY");
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FRONT",'resultId',c.nextResultId()),false);
            actual=c.LastValue.nativePayload;
            t.verifyEqual(actual.search.evaluationCount,7);
            t.verifyEqual(actual.statistics.leftBumpSweeps,7); t.verifyEqual(actual.statistics.rightBumpSweeps,7);
            t.verifyEqual(actual.search.records{actual.selectedIndex}.score,0);
            % FR is intentionally fixed: only FL variables/targets were declared.
            t.verifyEqual(actual.search.records{actual.selectedIndex}.axle.rightGeometry, ...
                actual.problem.seedAxle.rightGeometry);
        end
    end
end
function removeFile(file)
if isfile(file), delete(file); end
end
