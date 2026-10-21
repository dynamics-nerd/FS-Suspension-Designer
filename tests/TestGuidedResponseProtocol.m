classdef TestGuidedResponseProtocol < matlab.unittest.TestCase
    % Real canonical records; deterministic hostile responses at public accept.
    properties
        Project
        Response
        Arguments
        Owner
    end
    properties (TestParameter)
        representation={'char','string','mixed'}
        asynchronous={false,true}
        badAppend={'missingPolicy','unknownPolicy','replacePolicy','unchangedPolicy', ...
            'vectorPolicy','operation','action','epoch','missingValue','badTimer', ...
            'invalidHistory','foreignProject','identity','duplicate','valueMismatch'}
        badReplace={'missingPolicy','appendPolicy','unknownPolicy','invalidProject', ...
            'wrongIdentity','invalidHistory','badCompatibility','unexpectedValue'}
    end
    methods (TestClassSetup)
        function canonicalCase(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'));
            [t.Project,~]=packagingHistoryFixture(2); % Exactly three original records.
            t.Arguments=struct('cornerId',"FL",'packagingId',"SOFTWARE_CASE",'parentId',"", ...
                'selection',"REGISTRY",'index',1,'mode',"NOMINAL",'resultId',"FOURTH");
            request=struct('operationId',1,'epoch',0,'action',"PACKAGING_RUN", ...
                'project',t.Project,'arguments',t.Arguments);
            t.Response=fsdui.perform(fsdui.workerRequest(request));
            t.assertNumElements(t.Response.project.definition.results,1);
            t.assumeTrue(logical(license('test','Distrib_Computing_Toolbox')));
            t.Owner=fsdui.Controller(); t.Owner.enableWorker();
            t.addTeardown(@()cleanup(t.Owner));
        end
    end
    methods (Test)
        function identifiersSurviveAppendAndMat(t,representation,asynchronous)
            p=withIds(t.Project,representation); t.assertTrue(fsd.project.validateEngineeringProject(p));
            c=fsdui.Controller(p); c.enableWorker(); t.addTeardown(@()cleanup(c));
            a=t.Arguments; a.parentId=char("BUMP_EVIDENCE"); a.mode="BUMP";
            c.run('PACKAGING_RUN',a,asynchronous); waitFor(c); t.assertEmpty(c.LastError);
            t.assertNumElements(c.Project.definition.results,4); verifyOriginals(t,p,c.Project);
            expected=c.Project;
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=string(fullfile(folder.Folder,'ids.mat'));
            c.run('SAVE',struct('file',file,'overwrite',false),asynchronous); waitFor(c);
            t.assertEmpty(c.LastError); c.run('LOAD',struct('file',file),asynchronous); waitFor(c);
            t.assertEmpty(c.LastError); t.verifyEqual(c.Project,expected); verifyOriginals(t,p,c.Project);
        end
        function charResponseUsesScalarKeysWithoutRewritingIdentity(t)
            p=withIds(t.Project,'char'); full=t.Response;
            full.project.definition.results=[p.definition.results;full.project.definition.results];
            request=struct('ledgerPolicy',"APPEND",'project',p);
            delta=fsdui.workerResponse(full,request);
            t.verifyEqual(delta.project.definition.results,t.Response.project.definition.results);
            t.verifyClass(p.definition.results{1}.id,'char');
            t.verifyClass(p.definition.results{1}.identity.id,'char');
            % A prefix/character vector is not an equivalent result identity.
            full.project.definition.results{1}.id='BUMP_EVIDENC';
            t.verifyError(@()fsdui.workerResponse(full,request),'fsd:ui:HistoryMutation');
        end
        function validAppendPreservesThreeAndAddsFourth(t)
            c=start(t,'PACKAGING_RUN',t.Arguments); r=forOperation(t.Response,c);
            c.accept(r); t.verifyFalse(c.Busy); t.verifyNumElements(c.Project.definition.results,4);
            verifyOriginals(t,t.Project,c.Project);
        end
        function malformedAppendNeverMutatesSession(t,badAppend)
            c=start(t,'PACKAGING_RUN',t.Arguments); r=forOperation(t.Response,c);
            switch badAppend
                case 'missingPolicy', r=rmfield(r,'ledgerPolicy');
                case 'unknownPolicy', r.ledgerPolicy="UNKNOWN";
                case 'replacePolicy', r.ledgerPolicy="REPLACE";
                case 'unchangedPolicy', r.ledgerPolicy="UNCHANGED";
                case 'vectorPolicy', r.ledgerPolicy=["APPEND","REPLACE"];
                case 'operation', r.operationId=r.operationId+1;
                case 'action', r.action="LOAD";
                case 'epoch', r.epoch=r.epoch+1;
                case 'missingValue', r=rmfield(r,'value');
                case 'badTimer', r.elapsed_s=NaN;
                case 'invalidHistory', r.project.definition.results={42};
                case 'foreignProject', r.project.id="ANOTHER_PROJECT";
                case 'identity', r.project.definition.results{1}.identity.id="ANOTHER_RESULT";
                case 'duplicate'
                    r.project.definition.results{end+1}=t.Project.definition.results{1};
                    r.value{end+1}=t.Project.definition.results{1};
                case 'valueMismatch', r.value{1}.id="DIFFERENT_RESULT";
            end
            before=session(c); rejected=false;
            try
                c.accept(r);
            catch
                rejected=true;
            end
            t.verifyTrue(rejected,'Malformed response must be rejected, not partially applied.');
            t.verifyTrue(isequaln(session(c),before),'All canonical/session fields must remain intact.');
            t.verifyNumElements(c.Project.definition.results,3); verifyOriginals(t,t.Project,c.Project);
        end
        function missingPolicyRejectsWithoutMatLoss(t)
            c=start(t,'PACKAGING_RUN',t.Arguments); r=forOperation(t.Response,c);
            r=rmfield(r,'ledgerPolicy'); original=c.Project;
            t.verifyError(@()c.accept(r),'fsd:ui:InvalidResponse');
            t.verifyTrue(isequaln(c.Project,original)); t.verifyNumElements(c.Project.definition.results,3);
            c.cancel(); c.poll();
            folder=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            file=string(fullfile(folder.Folder,'no-history-loss.mat'));
            c.run('SAVE',struct('file',file,'overwrite',false),false);
            c.run('LOAD',struct('file',file),false);
            t.verifyEqual(c.Project,original); verifyOriginals(t,original,c.Project);
        end
        function malformedReplaceNeverMutatesSession(t,badReplace)
            c=start(t,'NEW',struct('id',"REPLACEMENT"));
            r=fsdui.perform(fsdui.workerRequest(c.Operation));
            switch badReplace
                case 'missingPolicy', r=rmfield(r,'ledgerPolicy');
                case 'appendPolicy', r.ledgerPolicy="APPEND";
                case 'unknownPolicy', r.ledgerPolicy="UNKNOWN";
                case 'invalidProject', r.project=struct();
                case 'wrongIdentity'
                    concept=fsd.project.createVehicleConcept(struct('id',"DIFFERENT_PROJECT"));
                    r.project=fsd.project.createEngineeringProject(struct('concept',concept));
                case 'invalidHistory', r.project.definition.results={struct('id',"INVALID")};
                case 'badCompatibility', r.compatibility={struct('status',"CURRENT_EXECUTION")};
                case 'unexpectedValue', r.value=t.Response.value;
            end
            before=session(c); rejected=false;
            try
                c.accept(r);
            catch
                rejected=true;
            end
            t.verifyTrue(rejected); t.verifyTrue(isequaln(session(c),before));
        end
        function validReplacementAndReadonlyProtocol(t)
            c=start(t,'NEW',struct('id',"REPLACEMENT"));
            c.accept(fsdui.perform(fsdui.workerRequest(c.Operation)));
            t.verifyEqual(c.Project.id,"REPLACEMENT"); t.verifyEmpty(c.Project.definition.results);
            c.run('VALIDATE',struct(),false); t.verifyEmpty(c.LastError);
            c.run('COMPATIBILITY',struct(),false); t.verifyEmpty(c.LastError);
        end
        function staleAndCancelledResponsesDoNotApply(t)
            c=start(t,'PACKAGING_RUN',t.Arguments); r=forOperation(t.Response,c); original=c.Project;
            c.invalidate(); c.accept(r); t.verifyEqual(c.Project,original);
            t.verifyTrue(startsWith(c.Status,'STALE'));
            c.run('PACKAGING_RUN',t.Arguments,true); r=forOperation(t.Response,c);
            c.cancel(); c.accept(r); t.verifyEqual(c.Project,original);
            t.verifyTrue(contains(c.Status,'cancelled')); t.verifyFalse(c.Busy);
        end
    end
end
function c=start(t,action,args)
c=fsdui.Controller(t.Project); c.enableWorker(); t.addTeardown(@()cleanup(c));
c.run(action,args,true); % Pause before conversion/dispatch for deterministic injection.
end
function r=forOperation(r,c)
r.operationId=c.Operation.operationId; r.epoch=c.Operation.epoch;
end
function p=withIds(p,representation)
for j=1:numel(p.definition.results)
    if strcmp(representation,'char') || (strcmp(representation,'mixed') && mod(j,2)==1)
        p.definition.results{j}.id=char(p.definition.results{j}.id);
        p.definition.results{j}.identity.id=p.definition.results{j}.id;
    end
end
end
function verifyOriginals(t,original,actual)
for j=1:numel(original.definition.results)
    r=original.definition.results{j};
    match=cellfun(@(x)string(x.id)==string(r.id),actual.definition.results);
    t.assertEqual(nnz(match),1); t.verifyEqual(actual.definition.results{match},r);
end
end
function s=session(c)
s=struct('project',c.Project,'epoch',c.Epoch,'compatibility',{c.Compatibility}, ...
    'file',c.File,'dirty',c.Dirty,'busy',c.Busy,'value',{c.LastValue}, ...
    'action',c.LastAction,'elapsed',c.LastElapsed_s,'status',c.Status);
end
function waitFor(c)
started=tic; while c.Busy && toc(started)<240, c.poll(); pause(.02); end
assert(~c.Busy,'fsd:ui:TestTimeout','Operation exceeded its software test wait budget.');
end
function cleanup(c)
c.Changed=[]; if c.Busy, c.cancel(); waitFor(c); end; c.close();
end
