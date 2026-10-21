classdef TestProjectOperationIntegrity < matlab.unittest.TestCase
    properties
        Project
        Bump
    end
    methods (TestClassSetup)
        function nativeHistory(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'));
            [t.Project,t.Bump]=packagingHistoryFixture(4);
        end
    end
    methods (Test)
        function sharedExecutionAndAppendMatchesTheStandaloneContracts(t)
            untouched=t.Project; original=untouched;
            % The existing validator accepts scalar text IDs as char or string;
            % sort keys may normalize, but historical field classes must not.
            original.definition.results{end}.id=char(original.definition.results{end}.id);
            original.definition.results{end}.identity.id=original.definition.results{end}.id;
            t.verifyTrue(fsd.project.validateEngineeringProject(original));
            [r,combined]=fsd.project.runEngineeringScenario(original,"PACK","SHARED_OPERATION");
            expected=fsd.project.attachEngineeringResult(original,r);
            t.verifyEqual(combined,expected); t.verifyTrue(fsd.project.validateEngineeringProject(combined));
            t.verifyEqual(t.Project,untouched);
            bad=original; bad.identity.projectId="TAMPERED";
            t.verifyError(@()executeAndAppend(bad,"PACK","MUST_REJECT"),'fsd:project:InvalidInput');
        end
        function sharedExecutionRejectsDuplicateBeforeExecutingPhysics(t)
            existing=t.Project.definition.results{1}.id;
            profile clear; profile on; guard=onCleanup(@()profile('off'));
            t.verifyError(@()executeAndAppend(t.Project,"PACK",existing),'fsd:project:InvalidInput');
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            t.verifyFalse(any(endsWith(names,'executeScenarioCore')));
        end
        function uncachedLargeRecordUsesLosslessBoundedFallback(t)
            % Software-only33MiB payload, just beyond the32MiB I/O buffer.
            % It has no engineering meaning and is not a capacity benchmark.
            d=t.Project.definition; d.results=cell(0,1); d.derivations=cell(0,1);
            p=fsd.project.createEngineeringProject(d);
            inputs=struct('softwareOnlyPadding',zeros(1,33*1024^2,'uint8'));
            s=fsd.project.createEngineeringScenario(struct('id',"IO_BUFFER_FIXTURE", ...
                'engine',"EXPLICITLY_UNSUPPORTED",'scope',fsd.model.designScope('CORNER','FL'),'inputs',inputs));
            p=fsd.project.reviseEngineeringProject(p,struct('scenarios',{[p.definition.scenarios;{s}]}));
            r=fsd.project.runEngineeringScenario(p,"PACK","UNCACHED_RECORD");
            p=fsd.project.attachEngineeringResult(p,r);
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'uncached-record.mat');
            profile clear; profile on; guard=onCleanup(@()profile('off'));
            fsd.project.saveEngineeringProject(p,file,false);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            functions=info.FunctionTable(endsWith(names,'encodeStorageGraph'));
            t.verifyEqual(sum([functions.NumCalls]),3,'Header once; uncached record in preflight and write.');
            t.verifyEqual(fsd.project.loadEngineeringProject(file),p);
        end
        function smallStorageGraphsAreEncodedOncePerRecord(t)
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=fullfile(folder.Folder,'bounded-buffer.mat');
            profile clear; profile on; guard=onCleanup(@()profile('off'));
            fsd.project.saveEngineeringProject(t.Project,file,false);
            profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
            functions=info.FunctionTable(endsWith(names,'encodeStorageGraph'));
            t.verifyEqual(sum([functions.NumCalls]),numel(t.Project.definition.results)+1);
            t.verifyEqual(fsd.project.loadEngineeringProject(file),t.Project);
        end
        function synchronousNotificationCannotPollAnUnscheduledConversion(t)
            c=fsdui.Controller(); cleanup=onCleanup(@()closeController(c));
            c.Changed=@()c.poll();
            c.run('NEW',struct('id',"SYNC_POLL_GUARD"),false);
            t.verifyFalse(c.Busy); t.verifyEmpty(c.LastError);
            t.verifyEqual(c.Project.id,"SYNC_POLL_GUARD");
        end
        function bulkUsesCanonicalClassificationWithoutRepeatedNativeValidation(t)
            p=t.Project; before=p; profile clear; profile on; cleanup=onCleanup(@()profile('off'));
            actual=fsd.project.resultCompatibilities(p); profile off; info=profile('info');
            f=info.FunctionTable; names=string({f.FunctionName});
            count=sum([f(endsWith(names,'validateResultCore')).NumCalls]);
            t.verifyGreaterThan(count,0);
            t.verifyEqual(count,numel(p.definition.results));
            sources=sum([f(endsWith(names,'validateSourceCore')).NumCalls]);
            t.verifyGreaterThanOrEqual(sources,1);
            expected=cellfun(@(r)fsd.project.resultCompatibility(r,p),p.definition.results,'UniformOutput',false);
            t.verifyEqual(actual,expected); t.verifyEqual(p,before);
            revised=fsd.project.reviseEngineeringProject(p,struct('description',"Independent presentation"));
            reports=fsd.project.resultCompatibilities(revised);
            t.verifyTrue(all(cellfun(@(r)r.status=="REUSABLE_DEPENDENCIES",reports)));
        end
        function sameIdsAndRevisionsDoNotAuthorizeTamperedValues(t)
            p=t.Project; p.identity.resources=struct();
            t.verifyError(@()fsd.project.resultCompatibilities(p),'fsd:project:InvalidInput');
            p=t.Project; index=find(cellfun(@(r)r.engine=="PACKAGING",p.definition.results),1);
            p.definition.results{index}.nativePayload.checks{3}.status="CLEAR_SAMPLED";
            t.verifyError(@()fsd.project.resultCompatibilities(p),'fsd:project:InvalidEngineeringResult');
            p=t.Project; p.definition.results{index}.prepared.context=struct();
            t.verifyError(@()fsd.project.resultCompatibilities(p),'fsd:project:InvalidEngineeringResult');
            % A successful earlier call never authorizes a changed later input.
            t.verifyTrue(fsd.project.validateEngineeringProject(t.Project));
            p=t.Project; p.definition.results{index}.elapsedTime_s=-1;
            t.verifyError(@()fsd.project.validateEngineeringProject(p),'fsd:project:InvalidEngineeringResult');
        end
        function workerPayloadIsIndependentOfUnrelatedHistory(t)
            a=struct('cornerId',"FL",'packagingId',"SOFTWARE_CASE",'parentId',"", ...
                'selection',"REGISTRY",'index',1,'mode',"NOMINAL",'resultId',"NEW_PACK");
            full=struct('operationId',1,'epoch',0,'action',"PACKAGING_RUN",'project',t.Project,'arguments',a);
            thin=fsdui.workerRequest(full); t.verifyEmpty(thin.project.definition.results);
            older=full; older.project.definition.results=older.project.definition.results(1);
            t.verifyEqual(fsdui.workerRequest(older),thin);
            a.parentId=t.Bump.id; full.arguments=a; thin=fsdui.workerRequest(full);
            t.verifyNumElements(thin.project.definition.results,1);
            t.verifyEqual(thin.project.definition.results{1},t.Bump);
            t.verifyEqual(full.project,t.Project);
        end
        function mergePreservesEveryOriginalRecordAndRejectsCollisions(t)
            original=t.Project;
            original.definition.results{end}.id=char(original.definition.results{end}.id);
            original.definition.results{end}.identity.id=original.definition.results{end}.id;
            t.verifyTrue(fsd.project.validateEngineeringProject(original));
            updated=original; updated.definition.results=cell(0,1);
            r=fsd.project.runEngineeringScenario(updated,"PACK","NEW_PACK");
            updated=fsd.project.attachEngineeringResult(updated,r);
            [merged,reports]=fsd.project.mergeEngineeringProjectHistory(updated,original);
            t.verifyNumElements(merged.definition.results,numel(original.definition.results)+1);
            for record=original.definition.results'
                same=cellfun(@(x)string(x.id)==string(record{1}.id),merged.definition.results);
                t.verifyEqual(merged.definition.results{same},record{1});
            end
            t.verifyEqual(reports,fsd.project.resultCompatibilities(merged));
            t.verifyError(@()fsd.project.mergeEngineeringProjectHistory(original,original),'fsd:project:InvalidInput');
        end
        function readonlyResponsesCannotReturnMutatedProjects(t)
            request=struct('action',"VALIDATE",'project',t.Project,'arguments',struct());
            request=fsdui.workerRequest(request); response=struct('project',t.Project);
            small=fsdui.workerResponse(response,request); t.verifyEmpty(small.project);
            response.project.definition.description="Unexpected worker mutation";
            t.verifyError(@()fsdui.workerResponse(response,request),'fsd:ui:HistoryMutation');
        end
        function groupedPlainPredicateStillRejectsExecutableMetadata(t)
            values={single([NaN Inf]),uint64(intmax('uint64')),sparse(eye(2)), ...
                logical([1 0]),char([945 946]),["text",missing],complex(1,0),cell(0,3)};
            d=struct('id',"FUTURE",'engine',"EXPLICITLY_UNSUPPORTED", ...
                'scope',fsd.model.designScope('CORNER','FL'),'inputs',struct('values',{values}));
            scenario=fsd.project.createEngineeringScenario(d);
            t.verifyEqual(scenario.definition.inputs.values,values);
            d.inputs.values{end+1}=struct('nested',{{struct('callback',@sin)}});
            t.verifyError(@()fsd.project.createEngineeringScenario(d),'fsd:project:InvalidInput');
            d.inputs=struct('opaque',containers.Map('a',1));
            t.verifyError(@()fsd.project.createEngineeringScenario(d),'fsd:project:InvalidInput');
        end
    end
end
function closeController(value)
value.Changed=[]; value.close();
end
function executeAndAppend(project,scenario,id)
[~,~]=fsd.project.runEngineeringScenario(project,scenario,id);
end
