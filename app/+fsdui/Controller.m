classdef Controller < handle
    %CONTROLLER UI session, immutable project snapshots and one guarded operation.
    properties (SetAccess=private)
        Project = []
        Epoch = 0
        Busy = false
        Status = "Ready — no project"
        LastValue = []
        LastError = []
        LastElapsed_s = 0
        LastAction = ""
        Compatibility = {}
        File = ""
        Dirty = false
        Future = []
        Operation = []
        Pool = []
        OwnPool = false
        TransportStage = ""
    end
    properties
        Changed = []
    end
    properties (Access=private)
        Sequence = 0
        CancelRequested = false
        Completing = false
        TransportInput = []
    end
    methods
        function obj=Controller(project)
            if nargin>0
                obj.Compatibility=fsd.project.resultCompatibilities(project); obj.Project=project;
            else
                obj.run("NEW",struct('id',"UNTITLED"),false);
            end
        end
        function enableWorker(obj)
            obj.requireIdle();
            if ~license('test','Distrib_Computing_Toolbox')
                error('fsd:ui:NoParallelLicense','Parallel Computing Toolbox is unavailable; choose explicit synchronous mode.');
            end
            obj.Status="Starting process worker (startup can take several seconds)"; obj.emitChange(); drawnow;
            pool=gcp('nocreate');
            if isempty(pool), pool=parpool('Processes',1); obj.OwnPool=true; end
            if isa(pool,'parallel.ThreadPool')
                error('fsd:ui:ThreadPool','An existing thread pool is not certified for this workflow; choose synchronous mode or a process pool.');
            end
            assert(isa(pool,'parallel.ProcessPool'),'fsd:ui:RemotePool', ...
                'Only a local process pool is supported. The existing cluster pool is retained; choose synchronous mode.');
            obj.Pool=pool; obj.Status="Process worker ready; native search remains sequential"; obj.emitChange();
        end
        function id=nextResultId(obj)
            obj.Sequence=obj.Sequence+1; id="UI_RESULT_"+string(obj.Sequence);
            existing=string(cellfun(@(r)r.id,obj.Project.definition.results,'UniformOutput',false));
            while any(startsWith(existing,id))
                obj.Sequence=obj.Sequence+1; id="UI_RESULT_"+string(obj.Sequence);
            end
        end
        function invalidate(obj)
            % Even unapplied presentation edits invalidate an in-flight response.
            obj.Epoch=obj.Epoch+1; obj.Dirty=true;
        end
        function run(obj,action,args,asynchronous)
            obj.requireIdle(); action=string(action);
            if nargin<4, asynchronous=~isempty(obj.Pool) && isvalid(obj.Pool); end
            if action=="SAVE"
                target=string(args.file); folder=fileparts(target);
                if strlength(folder)==0, folder=string(pwd); target=fullfile(folder,target); end
                assert(endsWith(lower(target),'.mat') && isfolder(folder),'fsd:ui:InvalidFile','Choose an existing folder and .mat filename.');
                assert(~isfile(target) || args.overwrite,'fsd:ui:Overwrite','Explicit overwrite confirmation required.');
                args.file=target; args.temporaryFile=string(tempname(folder))+".mat";
                args.originalStamp=fsdui.fileStamp(target);
            elseif action=="LOAD"
                args.sourceStamp=fsdui.fileStamp(args.file);
            end
            obj.Sequence=obj.Sequence+1;
            request=struct('operationId',obj.Sequence,'epoch',obj.Epoch,'action',action, ...
                'project',obj.Project,'arguments',args);
            obj.Operation=request; obj.CancelRequested=false; obj.Busy=true;
            obj.LastError=[]; obj.Status=action+" running — no percentage available"; obj.emitChange();
            try
                transport=fsdui.workerRequest(request);
                if asynchronous
                    assert(~isempty(obj.Pool) && isvalid(obj.Pool),'fsd:ui:NoWorker','Start a process worker first.');
                    % Defer pure conversion to poll, yielding UI callbacks in
                    % bounded traversal quanta. Do not start a second runtime
                    % on backgroundPool merely to serialize one operation.
                    obj.TransportStage="ENCODING";
                    obj.TransportInput=transport;
                else
                    response=fsdui.perform(transport); obj.accept(response);
                end
            catch cause
                obj.fail(cause);
                if ~asynchronous, rethrow(cause); end
            end
        end
        function poll(obj)
            if obj.Completing || ~obj.Busy || strlength(obj.TransportStage)==0, return; end
            if obj.TransportStage=="EXECUTING" && ...
                    (isempty(obj.Future) || string(obj.Future.State)~="finished"), return; end
            % fetchOutputs/UI rendering may dispatch MATLAB timer callbacks.
            % Exactly one poll owns completion, including all yielding operations.
            obj.Completing=true; completionGuard=onCleanup(@()obj.releaseCompletion());
            try
                if obj.CancelRequested
                    obj.cleanupSave(); obj.Status="Operation cancelled; no result applied";
                    obj.finish(); return;
                end
                switch obj.TransportStage
                    case "ENCODING"
                        payload=fsd.project.encodeStorageGraph(obj.TransportInput,@()obj.yieldConversion());
                        obj.TransportInput=[];
                        obj.TransportStage="EXECUTING";
                        obj.Future=parfeval(obj.Pool,@fsdui.performEncoded,1,payload);
                        obj.Status=obj.Operation.action+" executing on process worker"; obj.emitChange();
                    case "EXECUTING"
                        payload=fetchOutputs(obj.Future);
                        obj.Future=[];
                        obj.TransportStage="DECODING";
                        obj.TransportInput=payload;
                        obj.Status=obj.Operation.action+" decoding immutable response"; obj.emitChange();
                    case "DECODING"
                        response=fsd.project.decodeStorageGraph(obj.TransportInput,@()obj.yieldConversion());
                        obj.TransportInput=[]; obj.accept(response);
                    otherwise
                        error('fsd:ui:TransportStage','Unexpected asynchronous transport stage.');
                end
            catch cause
                if obj.CancelRequested && strcmp(cause.identifier,'fsd:ui:ConversionCancelled')
                    obj.cleanupSave(); obj.Status="Operation cancelled; no result applied"; obj.finish();
                else
                    obj.fail(cause);
                end
            end
        end
        function cancel(obj)
            if obj.Busy
                obj.CancelRequested=true;
                if ~isempty(obj.Future), cancel(obj.Future); end
                obj.Status="Cancellation requested — waiting for worker completion"; obj.emitChange();
            end
        end
        function accept(obj,response)
            % Public to permit deterministic stale-response tests without sleeps.
            assert(obj.Busy && ~isempty(obj.Operation),'fsd:ui:OperationMismatch', ...
                'No pending operation may receive this response.');
            validateEnvelope(response);
            assert(obj.Busy && response.operationId==obj.Operation.operationId, ...
                'fsd:ui:OperationMismatch','Response does not belong to the active operation.');
            assert(response.action==obj.Operation.action && response.epoch==obj.Operation.epoch, ...
                'fsd:ui:OperationMismatch','Response action/epoch differs from its immutable operation.');
            action=string(obj.Operation.action); expected=fsdui.workerRequest(obj.Operation);
            assert(string(response.ledgerPolicy)==expected.ledgerPolicy, ...
                'fsd:ui:InvalidResponse','Response history policy does not match the requested action.');
            if response.epoch~=obj.Epoch || ~isequaln(obj.Project,obj.Operation.project)
                obj.cleanupSave(); obj.Status="STALE response discarded; current project retained";
                obj.finish(); return;
            end
            if obj.CancelRequested
                obj.cleanupSave(); obj.Status="Operation cancelled; no result applied"; obj.finish(); return;
            end
            % Prepare every validated value locally. No session mutation until
            % the complete protocol/payload and the post-validation epoch pass.
            switch string(response.ledgerPolicy)
                case "APPEND"
                    validateResultValue(response,action);
                    fsd.project.validateEngineeringProject(response.project);
                    fsdui.validateOperationResponse(expected,response);
                    [response.project,response.compatibility]=fsd.project.mergeEngineeringProjectHistory(response.project,obj.Operation.project);
                case "REPLACE"
                    assert(isempty(response.value),'fsd:ui:InvalidResponse','Replacement must not return an unrelated result payload.');
                    reports=fsd.project.resultCompatibilities(response.project);
                    assert(isequaln(response.compatibility(:),reports(:)), ...
                        'fsd:ui:InvalidResponse','Replacement compatibility does not match its canonical project.');
                    response.compatibility=reports;
                    if action=="NEW"
                        assert(string(response.project.id)==string(obj.Operation.arguments.id), ...
                            'fsd:ui:InvalidResponse','NEW returned another project identity.');
                    end
                    fsdui.validateOperationResponse(expected,response);
                case "UNCHANGED"
                    assert(isempty(response.project) && isempty(response.compatibility), ...
                        'fsd:ui:InvalidResponse','Read-only response must not replace project/history.');
                    response.project=obj.Project;
                    if action=="VALIDATE"
                        assert(isequal(response.value,true),'fsd:ui:InvalidResponse','Invalid validation result.');
                    elseif action=="COMPATIBILITY"
                        assert(isequaln(response.value,obj.Compatibility), ...
                            'fsd:ui:InvalidResponse','Read-only compatibility payload differs from the current ledger.');
                    else
                        assert(isempty(response.value),'fsd:ui:InvalidResponse','SAVE must not return a result payload.');
                    end
                    unchanged=response; unchanged.project=[];
                    fsdui.validateOperationResponse(expected,unchanged);
            end
            if response.epoch~=obj.Epoch || ~isequaln(obj.Project,obj.Operation.project)
                obj.cleanupSave(); obj.Status="STALE response discarded; current project retained";
                obj.finish(); return;
            end
            if obj.CancelRequested
                obj.cleanupSave(); obj.Status="Operation cancelled; no result applied"; obj.finish(); return;
            end
            if action=="SAVE"
                a=obj.Operation.arguments;
                assert(isequaln(fsdui.fileStamp(a.file),a.originalStamp), ...
                    'fsd:ui:FileChanged','Destination changed during save; original file retained.');
                if a.overwrite, [ok,message]=movefile(a.temporaryFile,a.file,'f');
                else, [ok,message]=movefile(a.temporaryFile,a.file); end
                assert(ok,'fsd:ui:SaveCommit','%s',message); obj.File=a.file; obj.Dirty=false;
            else
                if ~isequaln(response.project,obj.Project)
                    obj.Project=response.project; obj.Epoch=obj.Epoch+1; obj.Dirty=true;
                    obj.Compatibility=response.compatibility;
                end
                if action=="LOAD", obj.File=obj.Operation.arguments.file; obj.Dirty=false; end
                if ismember(action,["NEW","DEMO"]), obj.File=""; obj.Dirty=true; end
            end
            if action=="COMPATIBILITY", obj.Compatibility=response.value; end
            obj.LastValue=response.value; obj.LastElapsed_s=response.elapsed_s; obj.LastAction=action;
            obj.Status=action+" complete ("+compose('%.3f',response.elapsed_s)+" s)";
            obj.finish();
        end
        function close(obj)
            assert(~obj.Busy,'fsd:ui:Busy','Wait for completion/cancellation before closing.');
            if obj.OwnPool && ~isempty(obj.Pool) && isvalid(obj.Pool)
                queue=obj.Pool.FevalQueue;
                if isempty(queue.RunningFutures) && isempty(queue.QueuedFutures)
                    delete(obj.Pool);
                else
                    % Another app/user may have borrowed this global MATLAB pool.
                    % Relinquish it rather than abort work not owned by this session.
                    obj.Status="Process pool retained: other queued/running work still uses it";
                end
            end
            obj.Pool=[]; obj.OwnPool=false;
        end
    end
    methods (Access=private)
        function yieldConversion(obj)
            % Dispatch navigation/edits/cancellation, never a second poll or
            % writer: Completing/Busy guards cover this whole conversion.
            drawnow limitrate;
            assert(~obj.CancelRequested,'fsd:ui:ConversionCancelled','Conversion cancelled.');
        end
        function releaseCompletion(obj)
            obj.Completing=false;
        end
        function requireIdle(obj)
            assert(~obj.Busy,'fsd:ui:Busy','Only one operation may own the project or MAT destination at a time.');
        end
        function cleanupSave(obj)
            if ~isempty(obj.Operation) && obj.Operation.action=="SAVE"
                file=obj.Operation.arguments.temporaryFile;
                if isfile(file), delete(file); end % Only this operation's exact temporary file.
            end
        end
        function fail(obj,cause)
            obj.cleanupSave(); obj.LastError=cause; obj.Status=string(cause.identifier)+": "+string(cause.message);
            obj.finish();
        end
        function finish(obj)
            obj.Busy=false; obj.Future=[]; obj.Operation=[]; obj.TransportInput=[];
            obj.TransportStage=""; obj.emitChange();
        end
        function emitChange(obj)
            if ~isempty(obj.Changed), obj.Changed(); end
        end
    end
end

function validateEnvelope(r)
fields=["operationId";"epoch";"action";"project";"value";"compatibility";"elapsed_s";"ledgerPolicy"];
if isstruct(r) && isscalar(r) && isfield(r,'action') && scalarText(r.action) && ...
        string(r.action)=="REFERENCE_TARGETS"
    fields(end+1)="referenceSweep";
end
assert(isstruct(r) && isscalar(r) && isequal(sort(string(fieldnames(r))),sort(fields)), ...
    'fsd:ui:InvalidResponse','Worker response has missing or unknown protocol fields.');
assert(integerScalar(r.operationId,1) && integerScalar(r.epoch,0) && ...
    scalarText(r.action) && scalarText(r.ledgerPolicy) && ...
    ismember(string(r.action),["NEW","DEMO","LOAD","SAVE","VALIDATE","COMPATIBILITY", ...
    "VEHICLE","DECISIONS","READINESS","BUILD","BUMP","SPECIFICATION","SYNTHESIS", ...
    "REFERENCE_TARGETS","ADOPT","ACTUATION_CONFIG","ACTUATION_RUN","ACTUATION_ADOPT","GLOBAL_CONFIG","GLOBAL_RUN", ...
    "PACKAGING_DEFINITION","PACKAGING_DEMO","PACKAGING_RUN","PACKAGING_COMPARE"]) && ...
    ismember(string(r.ledgerPolicy),["APPEND","REPLACE","UNCHANGED"]) && ...
    isnumeric(r.elapsed_s) && isreal(r.elapsed_s) && isscalar(r.elapsed_s) && ...
    isfinite(r.elapsed_s) && r.elapsed_s>=0 && iscell(r.compatibility) && ...
    (isvector(r.compatibility) || isempty(r.compatibility)), ...
    'fsd:ui:InvalidResponse','Malformed worker response metadata or history policy.');
end

function valid=integerScalar(value,minimum)
valid=isnumeric(value) && isreal(value) && isscalar(value) && isfinite(value) && ...
    value>=minimum && fix(value)==value;
end

function valid=scalarText(value)
valid=(isstring(value) && isscalar(value) && ~ismissing(value)) || ...
    (ischar(value) && isrow(value) && ~isempty(value));
end

function validateResultValue(r,action)
p=r.project;
assert(isstruct(p) && isscalar(p) && isfield(p,'definition') && ...
    isstruct(p.definition) && isscalar(p.definition) && isfield(p.definition,'results') && ...
    iscell(p.definition.results) && (isvector(p.definition.results) || isempty(p.definition.results)) && ...
    isempty(r.compatibility),'fsd:ui:InvalidResponse','Invalid APPEND project/history payload.');
records=p.definition.results;
assert(all(cellfun(@(x)isstruct(x) && isscalar(x) && isfield(x,'id') && scalarText(x.id),records)), ...
    'fsd:ui:InvalidResponse','Invalid APPEND result entries.');
if ismember(action,["BUILD","SYNTHESIS","ACTUATION_RUN","GLOBAL_RUN"])
    values={r.value};
elseif ismember(action,["BUMP","PACKAGING_RUN","PACKAGING_COMPARE"])
    assert(iscell(r.value) && isvector(r.value),'fsd:ui:InvalidResponse','Result batch must be a cell vector.');
    values=r.value;
else
    assert(isempty(records),'fsd:ui:InvalidResponse','Configuration-only action returned unexpected result records.');
    return;
end
assert(numel(values)==numel(records) && ~isempty(values), ...
    'fsd:ui:InvalidResponse','Result payload and APPEND ledger differ.');
ids=cellfun(@(x)string(x.id),records);
used=false(size(ids));
for j=1:numel(values)
    v=values{j};
    assert(isstruct(v) && isscalar(v) && isfield(v,'id') && scalarText(v.id), ...
        'fsd:ui:InvalidResponse','Invalid result value.');
    match=ids==string(v.id);
    assert(nnz(match)==1 && ~any(used(match)) && isequaln(records{match},v), ...
        'fsd:ui:InvalidResponse','Result value does not match an exact unique APPEND record.');
    used=used | match;
end
end
