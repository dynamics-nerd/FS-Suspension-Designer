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
    end
    properties
        Changed = []
    end
    properties (Access=private)
        Sequence = 0
        CancelRequested = false
        Completing = false
    end
    methods
        function obj=Controller(project)
            if nargin>0
                fsd.project.validateEngineeringProject(project); obj.Project=project;
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
            end
            obj.Sequence=obj.Sequence+1;
            request=struct('operationId',obj.Sequence,'epoch',obj.Epoch,'action',action, ...
                'project',obj.Project,'arguments',args);
            obj.Operation=request; obj.CancelRequested=false; obj.Busy=true;
            obj.LastError=[]; obj.Status=action+" running — no percentage available"; obj.emitChange();
            try
                if asynchronous
                    assert(~isempty(obj.Pool) && isvalid(obj.Pool),'fsd:ui:NoWorker','Start a process worker first.');
                    obj.Future=parfeval(obj.Pool,@fsdui.perform,1,request);
                else
                    response=fsdui.perform(request); obj.accept(response);
                end
            catch cause
                obj.fail(cause);
                if ~asynchronous, rethrow(cause); end
            end
        end
        function poll(obj)
            if obj.Completing || ~obj.Busy || isempty(obj.Future) || string(obj.Future.State)~="finished", return; end
            % fetchOutputs/UI rendering may dispatch MATLAB timer callbacks.
            % Exactly one poll owns completion, including all yielding operations.
            obj.Completing=true; completionGuard=onCleanup(@()obj.releaseCompletion());
            try
                if obj.CancelRequested
                    obj.cleanupSave(); obj.Status="Operation cancelled; no result applied";
                    obj.finish(); return;
                end
                response=fetchOutputs(obj.Future); obj.accept(response);
            catch cause, obj.fail(cause);
            end
        end
        function cancel(obj)
            if obj.Busy && ~isempty(obj.Future)
                obj.CancelRequested=true; cancel(obj.Future);
                obj.Status="Cancellation requested — waiting for worker completion"; obj.emitChange();
            end
        end
        function accept(obj,response)
            % Public to permit deterministic stale-response tests without sleeps.
            assert(obj.Busy && response.operationId==obj.Operation.operationId, ...
                'fsd:ui:OperationMismatch','Response does not belong to the active operation.');
            if response.epoch~=obj.Epoch || ~isequaln(obj.Project,obj.Operation.project)
                obj.cleanupSave(); obj.Status="STALE response discarded; current project retained";
                obj.finish(); return;
            end
            action=response.action;
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
            obj.Busy=false; obj.Future=[]; obj.Operation=[]; obj.emitChange();
        end
        function emitChange(obj)
            if ~isempty(obj.Changed), obj.Changed(); end
        end
    end
end
