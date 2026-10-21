classdef TestGuidedPackagingBinding < matlab.unittest.TestCase
    % Genuine alternate selections/parents with unchanged outer operation IDs.
    properties
        Project
        Parent
        Owner
    end
    methods (TestClassSetup)
        function nativeAlternatives(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            t.assumeTrue(logical(license('test','Distrib_Computing_Toolbox')));
            t.Owner=fsdui.Controller(); t.Owner.enableWorker(); t.addTeardown(@()cleanup(t.Owner));
            c=fsdui.Controller(); t.addTeardown(@()cleanup(c));
            c.run('DEMO',struct(),false);
            c.run('BUILD',struct('scope',"FRONT",'resultId',"SEED"),false);
            c.run('REFERENCE_TARGETS',struct(),false);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',"SEARCH"),false);
            t.Parent=c.LastValue; c.run('PACKAGING_DEMO',struct('cornerId',"FL"),false);
            p=c.Project;
            for j=1:2
                grid=[-.01;0;.01]/j; % Explicit software sample domains, in m.
                s=fsd.project.createEngineeringScenario(struct('id',"SOURCE_"+j,'engine',"BUMP", ...
                    'scope',fsd.model.designScope('CORNER','FL'),'plan',struct('travel_m',grid)));
                p=fsdui.upsertScenario(p,s);
                [~,p]=fsd.project.runEngineeringScenario(p,s.definition.id,"PARENT_"+j);
            end
            t.Project=p;
        end
    end
    methods (Test)
        function comparisonCannotSubstituteAnotherStoredCandidate(t)
            a=argumentsFor(t.Parent.id,"CANDIDATE",t.Parent.nativePayload.selectedIndex);
            t.assertNotEqual(a.index,1,'Known case must select a non-seed candidate.');
            check(t,'PACKAGING_COMPARE',a,'index',1);
        end
        function physicallyEqualSeedCannotRelabelCandidateSelection(t)
            a=argumentsFor(t.Parent.id,"SEED",1);
            check(t,'PACKAGING_RUN',a,'selection',"CANDIDATE");
        end
        function sampledPackagingCannotSubstituteAnotherParentGrid(t)
            a=argumentsFor("PARENT_1","REGISTRY",1);
            check(t,'PACKAGING_RUN',a,'parentId',"PARENT_2");
        end
    end
end
function a=argumentsFor(parent,selection,index)
a=struct('cornerId',"FL",'packagingId',"DEMO_PACKAGING",'parentId',parent, ...
    'selection',selection,'index',index,'mode',"BUMP",'resultId',"BOUND");
end
function check(t,action,args,field,value)
c=fsdui.Controller(t.Project); c.enableWorker(); t.addTeardown(@()cleanup(c));
c.run(action,args,true); request=c.Operation;
request.arguments.(field)=value; request=fsdui.workerRequest(request);
response=fsdui.perform(request);
t.assertTrue(fsd.project.validateEngineeringProject(response.project));
for r=response.project.definition.results', t.assertTrue(fsd.project.validateEngineeringResult(r{1})); end
before=session(c); t.verifyError(@()c.accept(response),'fsd:ui:SemanticMismatch');
t.verifyTrue(isequaln(session(c),before),'Complete public session and canonical history must remain unchanged.');
expected=c.Project; c.cancel(); c.poll();
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=string(fullfile(f.Folder,'selection-integrity.mat'));
c.run('SAVE',struct('file',file,'overwrite',false),false);
c.run('LOAD',struct('file',file),false); t.verifyEqual(c.Project,expected);
end
function s=session(c)
s=struct(); names=properties(c);
for j=1:numel(names), s.(names{j})=c.(names{j}); end
end
function cleanup(c)
c.Changed=[];
if c.Busy
    c.cancel(); started=tic;
    while c.Busy && toc(started)<300, c.poll(); pause(.02); end
end
assert(~c.Busy,'fsd:ui:TestTimeout','Test cleanup exceeded its software wait budget.'); c.close();
end
