classdef TestGuidedOperationSemantics < matlab.unittest.TestCase
    % Owner intent versus genuine, independently canonical alternative evidence.
    properties
        Project
        Bump
        Arguments
        Owner
        Built
        Search
        SearchResult
    end
    properties (TestParameter)
        packagingSwap={'mode','parent','definition','geometry','revision', ...
            'provenance','resultId','engine','combined'}
        bumpSwap={'grid','options','scenario','resultId','geometry','corner'}
        synthesisSwap={'options','targets','parameters','provenance'}
        configuration={'VEHICLE','DECISIONS','SPECIFICATION','PACKAGING_DEFINITION', ...
            'PACKAGING_DEMO','READINESS','BUILD','SYNTHESIS','REFERENCE_TARGETS','ADOPT','PACKAGING_COMPARE'}
        transport={false,true}
    end
    methods (TestClassSetup)
        function canonicalInputs(t)
            root=fileparts(fileparts(mfilename('fullpath'))); old=path;
            t.addTeardown(@()path(old)); addpath(fullfile(root,'src'),fullfile(root,'app'),fullfile(root,'examples'));
            [t.Project,t.Bump]=packagingHistoryFixture(2);
            t.Arguments=struct('cornerId',"FL",'packagingId',"SOFTWARE_CASE", ...
                'parentId',"BUMP_EVIDENCE",'selection',"REGISTRY",'index',1, ...
                'mode',"NOMINAL",'resultId',"FOURTH");
            t.assumeTrue(logical(license('test','Distrib_Computing_Toolbox')));
            t.Owner=fsdui.Controller(); t.Owner.enableWorker(); t.addTeardown(@()cleanup(t.Owner));
            c=fsdui.Controller(); t.addTeardown(@()cleanup(c));
            c.run('DEMO',struct(),false);
            c.run('BUILD',struct('scope',"FRONT",'resultId',"SEED"),false); t.Built=c.Project;
            c.run('REFERENCE_TARGETS',struct(),false);
            c.run('SYNTHESIS',struct('scenarioId',"UI_SEARCH_FL",'resultId',"SEARCH"),false);
            t.Search=c.Project; t.SearchResult=c.LastValue;
        end
    end
    methods (Test)
        function genuineBumpPackagingCannotSatisfyNominal(t,transport)
            c=start(t,t.Project,'PACKAGING_RUN',t.Arguments);
            request=fsdui.workerRequest(c.Operation); request.arguments.mode="BUMP";
            response=execute(request,transport,c.Pool); verifyCanonical(t,response);
            t.verifyEqual(response.value{1}.engine,"PACKAGING");
            t.verifyEqual(response.value{1}.prepared.plan.mode,"BUMP");
            rejectAndRoundTrip(t,c,response);
        end
        function genuineNativeBumpCannotSatisfyPackaging(t)
            c=start(t,t.Project,'PACKAGING_RUN',t.Arguments);
            response=nativeBumpResponse(c.Operation,t.Bump);
            verifyCanonical(t,response); t.verifyEqual(response.value{1}.engine,"BUMP");
            rejectAndRoundTrip(t,c,response);
        end
        function genuineNominalCannotSatisfySampledPackaging(t,transport)
            args=t.Arguments; args.mode="BUMP";
            c=start(t,t.Project,'PACKAGING_RUN',args);
            request=fsdui.workerRequest(c.Operation); request.arguments.mode="NOMINAL";
            response=execute(request,transport,c.Pool); verifyCanonical(t,response);
            rejectAndRoundTrip(t,c,response);
        end
        function canonicalPackagingAlternativesAreBound(t,packagingSwap)
            args=t.Arguments;
            if ismember(string(packagingSwap),["geometry","combined"]), args.parentId=""; end
            c=start(t,t.Project,'PACKAGING_RUN',args);
            request=fsdui.workerRequest(c.Operation);
            switch packagingSwap
                case 'mode', request.arguments.mode="BUMP";
                case 'parent', request.arguments.parentId="";
                case 'definition'
                    resources=request.project.definition.resources;
                    d=resources.packaging{1}.definitionSI; d.id="OTHER_DEFINITION";
                    resources.packaging{end+1}=fsd.packaging.createDefinition(d);
                    request.project=fsd.project.reviseEngineeringProject(request.project,struct('resources',resources));
                    request.arguments.packagingId="OTHER_DEFINITION";
                case 'geometry', request.project=changedGeometry(request.project);
                case 'revision'
                    request.project=fsd.project.reviseEngineeringProject(request.project,struct('name',"Another revision"));
                case 'provenance'
                    request.project=fsd.project.reviseEngineeringProject(request.project,struct('description',"Other provenance"));
                case 'resultId', request.arguments.resultId="FOURTH_OTHER";
                case 'engine'
                    response=nativeBumpResponse(c.Operation,t.Bump);
                case 'combined'
                    request.arguments.resultId="OTHER";
                    request.project=changedGeometry(request.project);
            end
            if ~strcmp(packagingSwap,'engine'), response=fsdui.perform(request); end
            verifyCanonical(t,response); rejectAndRoundTrip(t,c,response);
        end
        function canonicalBumpAlternativesAreBound(t,bumpSwap)
            args=struct('scope',"FL",'plan',struct('travel_m',[0;.04]),'resultId',"BUMP_NEW");
            c=start(t,t.Project,'BUMP',args); request=fsdui.workerRequest(c.Operation);
            switch bumpSwap
                case 'grid', request.arguments.plan.travel_m=[0;.02;.04];
                case 'options', request.arguments.plan.solverOptions=struct('MaxIterations',125);
                case 'resultId', request.arguments.resultId="BUMP_OTHER";
                case 'geometry', request.project=changedGeometry(request.project);
                case 'corner'
                    axle=translationAxleFixture(); resources=request.project.definition.resources;
                    resources.geometries{end+1}=axle.rightGeometry;
                    request.project=fsd.project.reviseEngineeringProject(request.project,struct('resources',resources));
                    request.arguments.scope="FR";
                case 'scenario'
                    d=t.Bump.scenarioAtExecution.definition; d.id="OTHER_BUMP_SCENARIO";
                    p=fsdui.upsertScenario(request.project,fsd.project.createEngineeringScenario(d));
                    [r,p]=fsd.project.runEngineeringScenario(p,d.id,"BUMP_NEW_FL");
                    response=struct('operationId',request.operationId,'epoch',request.epoch, ...
                        'action',request.action,'project',p,'value',{{r}},'compatibility',{{}},'elapsed_s',0);
                    response=fsdui.workerResponse(response,request);
            end
            if ~strcmp(bumpSwap,'scenario'), response=fsdui.perform(request); end
            verifyCanonical(t,response); rejectAndRoundTrip(t,c,response);
        end
        function everyConfigurationOutcomeIsBound(t,configuration)
            p=t.Search; action=string(configuration);
            switch action
                case 'VEHICLE'
                    a=struct('definition',p.definition.concept.definitionSI);
                case 'DECISIONS'
                    a=struct('definition',t.Built.definition.resources.seedBindings{1}.construction.definition.definitionSI);
                case 'SPECIFICATION'
                    a=struct('definition',t.SearchResult.scenarioAtExecution.definition);
                case 'PACKAGING_DEFINITION'
                    p=t.Project; a=struct('definition',p.definition.resources.packaging{1});
                case 'PACKAGING_DEMO', p=t.Project; a=struct('cornerId',"FL");
                case 'READINESS', a=struct('scenarioId',"UI_SEARCH_FL");
                case 'BUILD', a=struct('scope',"FRONT",'resultId',"OTHER_SEED");
                case 'SYNTHESIS', a=struct('scenarioId',"UI_SEARCH_FL",'resultId',"OTHER_SEARCH");
                case 'REFERENCE_TARGETS', a=struct();
                case 'ADOPT', a=struct('resultId',"SEARCH",'index',t.SearchResult.nativePayload.selectedIndex);
                case 'PACKAGING_COMPARE'
                    demo=requestFor(p,'PACKAGING_DEMO',struct('cornerId',"FL"));
                    demo=fsdui.perform(demo); p=demo.project;
                    a=struct('cornerId',"FL",'packagingId',"DEMO_PACKAGING",'parentId',"SEARCH", ...
                        'selection',"CANDIDATE",'index',t.SearchResult.nativePayload.selectedIndex, ...
                        'mode',"BUMP",'resultId',"COMPARISON");
            end
            c=start(t,p,action,a); request=fsdui.workerRequest(c.Operation);
            % A genuine alternative owner configuration, not a broken fingerprint.
            request.project=fsd.project.reviseEngineeringProject(request.project, ...
                struct('description',"Canonical but not the pending operation snapshot"));
            response=fsdui.perform(request); verifyCanonical(t,response);
            rejectAndRoundTrip(t,c,response);
        end
        function synthesisDeclarationsAreBound(t,synthesisSwap)
            args=struct('scenarioId',"UI_SEARCH_FL",'resultId',"NEW_SEARCH");
            c=start(t,t.Search,'SYNTHESIS',args); request=fsdui.workerRequest(c.Operation);
            d=t.SearchResult.scenarioAtExecution.definition;
            switch synthesisSwap
                case 'options', d.options.maxIterations=d.options.maxIterations+1;
                case 'provenance', d.targetOrigins{1}.note="Other declared origin";
                case 'targets'
                    spec=d.specification.definitionSI; targets=spec.targets.definitionSI.targets;
                    td=targets{1}.definitionSI; td.sourceNote="Other software target declaration";
                    targets{1}=fsd.model.createDesignTarget(td,'rad','m');
                    spec.targets=fsd.model.createSuspensionDesignTargets(targets);
                    d.specification=fsd.model.createDesignSpecification(spec);
                case 'parameters'
                    spec=d.specification.definitionSI; pd=spec.parameters{1}.definitionSI;
                    pd.sourceNote="Other declared software parameter";
                    spec.parameters{1}=fsd.model.createDesignParameter(pd,'m');
                    d.specification=fsd.model.createDesignSpecification(spec);
            end
            request.project=fsdui.upsertScenario(request.project,fsd.project.createEngineeringScenario(d));
            response=fsdui.perform(request); verifyCanonical(t,response); rejectAndRoundTrip(t,c,response);
        end
        function validAppendAndNativeBumpUseBothTransports(t,transport)
            c=fsdui.Controller(t.Project); c.enableWorker(); t.addTeardown(@()cleanup(c));
            for mode=["NOMINAL","BUMP"]
                a=t.Arguments; a.mode=mode; a.resultId="VALID_"+mode;
                c.run('PACKAGING_RUN',a,transport); waitFor(c); t.assertEmpty(c.LastError);
                t.verifyEqual(c.LastValue{1}.prepared.plan.mode,mode);
            end
            c.run('BUMP',struct('scope',"FL",'plan',struct('travel_m',[0;.04]), ...
                'resultId',"VALID_BUMP"),transport); waitFor(c); t.assertEmpty(c.LastError);
            t.verifyNumElements(c.Project.definition.results,6);
            roundTrip(t,c,c.Project,transport);
        end
        function validFrontBumpPreservesPerCornerTransitions(t,transport)
            c=fsdui.Controller(t.Built); c.enableWorker(); t.addTeardown(@()cleanup(c));
            args=struct('scope',"FRONT",'plan',struct('travel_m',[-.01;0;.01]),'resultId',"PAIR");
            c.run('BUMP',args,transport); waitFor(c); t.assertEmpty(c.LastError);
            t.assertNumElements(c.LastValue,2); t.verifyNumElements(c.Project.definition.results,3);
            t.verifyEqual(c.LastValue{1}.id,"PAIR_FL"); t.verifyEqual(c.LastValue{2}.id,"PAIR_FR");
            roundTrip(t,c,c.Project,transport);
        end
        function receiptDoesNotRunForwardSolvers(t)
            c=start(t,t.Project,'PACKAGING_RUN',t.Arguments);
            response=fsdui.perform(fsdui.workerRequest(c.Operation));
            profile clear; profile on; guard=onCleanup(@()profile('off'));
            c.accept(response); profile off; information=profile('info');
            names=string({information.FunctionTable.FunctionName});
            t.verifyFalse(any(contains(names,["solveBumpSweep","executeScenarioCore", ...
                "solveBumpState","synthesizeCorner","synthesizeAxle"])));
            t.verifyNumElements(c.Project.definition.results,4);
        end
        function replacementsAndReadonlyOutcomesAreBound(t)
            c=start(t,t.Project,'NEW',struct('id',"SAME_ID"));
            response=fsdui.perform(fsdui.workerRequest(c.Operation));
            response.project=fsd.project.reviseEngineeringProject(response.project,struct('name',"Unexpected content"));
            rejectAndRoundTrip(t,c,response);
            c=start(t,t.Project,'DEMO',struct());
            response=fsdui.perform(fsdui.workerRequest(c.Operation));
            response.project=fsd.project.reviseEngineeringProject(response.project,struct('description',"Other demo"));
            rejectAndRoundTrip(t,c,response);
            for action=["VALIDATE","COMPATIBILITY"]
                c=start(t,t.Project,action,struct());
                response=fsdui.perform(fsdui.workerRequest(c.Operation));
                if action=="VALIDATE", response.value=false; else, response.value={}; end
                rejectAndRoundTrip(t,c,response,'fsd:ui:InvalidResponse');
            end
        end
        function loadAndSaveBindActualMatContent(t)
            f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            first=string(fullfile(f.Folder,'first.mat')); second=string(fullfile(f.Folder,'second.mat'));
            fsd.project.saveEngineeringProject(t.Project,first,false);
            other=fsd.project.reviseEngineeringProject(t.Project,struct('description',"Other MAT content"));
            fsd.project.saveEngineeringProject(other,second,false);
            c=start(t,t.Project,'LOAD',struct('file',first));
            request=fsdui.workerRequest(c.Operation); request.arguments.file=second;
            response=fsdui.perform(request); rejectAndRoundTrip(t,c,response);
            c=start(t,t.Project,'SAVE',struct('file',string(fullfile(f.Folder,'destination.mat')),'overwrite',false));
            request=fsdui.workerRequest(c.Operation); response=fsdui.perform(request);
            delete(request.arguments.temporaryFile); % Only this test's exact private temporary MAT.
            fsd.project.saveEngineeringProject(other,request.arguments.temporaryFile,false);
            rejectAndRoundTrip(t,c,response);
            t.verifyFalse(isfile(request.arguments.file));
        end
        function legitimateTimingAndIdentifierRepresentationAreNotRecomputed(t)
            c=start(t,t.Project,'PACKAGING_RUN',t.Arguments);
            response=fsdui.perform(fsdui.workerRequest(c.Operation));
            r=response.value{1}; r.id=char(r.id); r.identity.id=r.id;
            r.elapsedTime_s=r.elapsedTime_s+1; response.elapsed_s=response.elapsed_s+2;
            response.value={r}; response.project.definition.results={r};
            c.accept(response); t.verifyClass(c.LastValue{1}.id,'char');
            t.verifyEqual(c.LastValue{1},r); roundTrip(t,c,c.Project,false);
        end
        function referenceEvidenceMustMatchRequestedGrid(t)
            c=start(t,t.Built,'REFERENCE_TARGETS',struct());
            response=fsdui.perform(fsdui.workerRequest(c.Operation));
            identity=response.referenceSweep.geometryIdentity;
            g=fsd.model.createDoubleWishboneGeometry(identity.cornerId,identity.hardpointIds, ...
                identity.hardpointXyz_m,'m',identity.wheelAxis);
            response.referenceSweep=fsd.kinematics.solveBumpSweep(g,[0;.01],'m');
            t.assertTrue(fsd.kinematics.validateBumpSweepResult(response.referenceSweep));
            rejectAndRoundTrip(t,c,response);
        end
        function nativeBumpWorkerHeaderCannotBeRelabelled(t)
            c=start(t,t.Project,'PACKAGING_RUN',t.Arguments);
            request=fsdui.workerRequest(c.Operation); request.action="BUMP";
            request.arguments=struct('scope',"FL",'plan',struct('travel_m',[0;.04]),'resultId',"FOURTH");
            response=execute(request,true,c.Pool); response.action="PACKAGING_RUN";
            verifyCanonical(t,response); rejectAndRoundTrip(t,c,response);
        end
    end
end
function c=start(t,p,action,args)
c=fsdui.Controller(p); c.enableWorker(); t.addTeardown(@()cleanup(c));
c.run(action,args,true); t.assertTrue(c.Busy); t.assertEqual(c.TransportStage,"ENCODING");
end
function response=nativeBumpResponse(operation,bump)
request=fsdui.workerRequest(operation);
p=fsdui.upsertScenario(request.project,bump.scenarioAtExecution);
[r,p]=fsd.project.runEngineeringScenario(p,bump.scenarioAtExecution.definition.id,"FOURTH_1");
response=struct('operationId',request.operationId,'epoch',request.epoch,'action',request.action, ...
    'project',p,'value',{{r}},'compatibility',{{}},'elapsed_s',0);
response=fsdui.workerResponse(response,request);
end
function request=requestFor(p,action,args)
request=struct('operationId',1,'epoch',0,'action',action,'project',p,'arguments',args);
end
function response=execute(request,asynchronous,pool)
if asynchronous
    future=parfeval(pool,@fsdui.performEncoded,1,fsd.project.encodeStorageGraph(request));
    response=fsd.project.decodeStorageGraph(fetchOutputs(future));
else
    response=fsdui.perform(request);
end
end
function p=changedGeometry(p)
resources=p.definition.resources; g=resources.geometries{1};
xyz=g.hardpoints.xyz_m; xyz(:,1)=xyz(:,1)+.001; % Rigid translation: canonical software case in m.
provenance=struct('sourceKind',g.hardpoints.sourceKind,'sourceNote',g.hardpoints.sourceNote);
g=fsd.model.createDoubleWishboneGeometry(g.cornerId,g.hardpoints.ids,xyz,'m',g.wheel.wheelAxis,provenance);
resources.geometries{1}=g;
p=fsd.project.reviseEngineeringProject(p,struct('resources',resources));
end
function verifyCanonical(t,response)
t.assertTrue(fsd.project.validateEngineeringProject(response.project));
for r=response.project.definition.results', t.assertTrue(fsd.project.validateEngineeringResult(r{1})); end
end
function rejectAndRoundTrip(t,c,response,expectedIdentifier)
if nargin<4, expectedIdentifier='fsd:ui:SemanticMismatch'; end
before=session(c); rejected=false; identifier="";
try
    c.accept(response);
catch cause
    rejected=true; identifier=string(cause.identifier);
end
t.assertTrue(rejected,'Canonical evidence for another operation must not be applied.');
t.verifyEqual(identifier,string(expectedIdentifier));
t.verifyTrue(isequaln(session(c),before),'Every canonical/session field must remain unchanged.');
original=c.Project; c.cancel(); c.poll(); roundTrip(t,c,original,false);
end
function s=session(c)
names=["Project","Epoch","Compatibility","File","Dirty","Busy","LastValue", ...
    "LastAction","LastElapsed_s","Status","LastError","Operation","TransportStage","Future"];
s=struct(); for name=names, s.(name)=c.(name); end
end
function roundTrip(t,c,expected,asynchronous)
f=t.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
file=string(fullfile(f.Folder,'semantic-integrity.mat'));
c.run('SAVE',struct('file',file,'overwrite',false),asynchronous); waitFor(c); t.assertEmpty(c.LastError);
c.run('LOAD',struct('file',file),asynchronous); waitFor(c); t.assertEmpty(c.LastError);
t.verifyEqual(c.Project,expected);
end
function waitFor(c)
started=tic; while c.Busy && toc(started)<300, c.poll(); pause(.02); end
assert(~c.Busy,'fsd:ui:TestTimeout','Operation exceeded its software test wait budget.');
end
function cleanup(c)
c.Changed=[]; if c.Busy, c.cancel(); waitFor(c); end; c.close();
end
