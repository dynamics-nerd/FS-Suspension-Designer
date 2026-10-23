classdef GlobalStaticView < handle
    %GLOBALSTATICVIEW Native input/evidence controls; no engineering calculations.
    properties(SetAccess=private)
        UI=struct()
    end
    properties(Access=private)
        Controller
        Invoke
        Draft
        Dirty=false
        Scenario=[]
        DrawnProject=[]
        Records={}
        Readiness=[]
    end
    methods
        function obj=GlobalStaticView(tab,controller,invoke,draft)
            obj.Controller=controller; obj.Invoke=invoke; obj.Draft=draft;
            root=uigridlayout(tab,[4,1]); root.RowHeight={65,30,30,'1x'};
            obj.UI.Status=uitextarea(root,'Editable','off');
            obj.UI.Scenario=uidropdown(root,'Items',{'NEW'},'ValueChangedFcn',@(~,~)obj.pickScenario());
            obj.UI.Pages=uidropdown(root,'Items',{'Configuration','Results'},'ValueChangedFcn',@(~,~)obj.page());
            holder=uigridlayout(root,[1,1]); holder.Padding=0;
            obj.UI.Configuration=uipanel(holder); obj.UI.Configuration.Layout.Row=1; obj.UI.Configuration.Layout.Column=1;
            obj.UI.Results=uipanel(holder); obj.UI.Results.Layout.Row=1; obj.UI.Results.Layout.Column=1;
            obj.configuration(); obj.results(); obj.page();
        end
        function updateStatus(obj)
            if isempty(obj.Controller), return; end
            c=obj.Controller; text=[c.Status;"Vehicle masses/CG: Vehicle tab; independent corners: Geometry and Actuation tabs."];
            if obj.Dirty, text(end+1)="Unapplied global configuration; apply before running or saving."; end
            if ~isempty(obj.Readiness)
                text=[text;"Global readiness: "+obj.Readiness.status;obj.Readiness.missing;obj.Readiness.diagnostics];
            end
            if ~isempty(c.LastError), text=[text;fsdui.errorText(c.LastError)];
            elseif isstruct(c.LastValue) && isfield(c.LastValue,'missing')
                text=[text;"Readiness: "+c.LastValue.status;c.LastValue.missing;c.LastValue.diagnostics];
            end
            obj.UI.Status.Value=cellstr(text);
            ready=~isempty(obj.Readiness) && obj.Readiness.status=="READY";
            obj.UI.Run.Enable=~c.Busy && ~obj.Dirty && ready; obj.UI.Apply.Enable=~c.Busy;
        end
        function refresh(obj)
            if isempty(obj.Controller), return; end
            obj.updateStatus(); p=obj.Controller.Project;
            if isequaln(obj.DrawnProject,p), return; end
            ss=p.definition.scenarios; ss=ss(cellfun(@(s)s.definition.engine=="GLOBAL_STATIC",ss));
            labels=cellfun(@(s)char(s.definition.id),ss,'UniformOutput',false); if isempty(labels), labels={'NEW'}; end
            obj.setPicker(obj.UI.Scenario,labels);
            match=cellfun(@(s)s.definition.id==string(obj.UI.Scenario.Value),ss);
            if ~obj.Dirty
                obj.Scenario=[]; if any(match), obj.Scenario=ss{match}; end
                rows=fsdui.globalStaticConfiguration('ROWS',obj.Scenario); obj.setRows(rows);
            end
            obj.Readiness=[];
            if any(match), obj.Readiness=fsd.project.designReadiness(p,ss{match}.definition.id); end
            rows=cell(4,4); ids=["FL","FR","RL","RR"];
            for k=1:4
                rows{k,1}=char(ids(k));
                for j=1:3
                    names=["geometries","actuations","mechanicals"]; rs=p.definition.resources.(names(j));
                    present=any(cellfun(@(r)r.cornerId==ids(k),rs));
                    status="MISSING — configure "+names(j); if present, status="REGISTERED"; end
                    rows{k,j+1}=char(status);
                end
            end
            obj.UI.Resources.Data=rows;
            rs=p.definition.results; obj.Records=rs(cellfun(@(r)r.engine=="GLOBAL_STATIC",rs));
            labels=cellfun(@(r)char(string(r.id)),obj.Records,'UniformOutput',false); if isempty(labels), labels={'NONE'}; end
            obj.setPicker(obj.UI.Primary,labels); obj.setPicker(obj.UI.Reference,labels);
            obj.selectResult();
            obj.updateStatus();
            % Commit only a complete render; a failed refresh remains retryable.
            obj.DrawnProject=p;
        end
        function committed(obj)
            obj.Dirty=false; obj.DrawnProject=[];
        end
        function resetDrafts(obj)
            obj.Dirty=false; obj.Scenario=[]; obj.DrawnProject=[]; obj.Readiness=[];
        end
        function release(obj)
            obj.Controller=[]; obj.Invoke=[]; obj.Draft=[]; obj.Records={}; obj.Scenario=[]; obj.DrawnProject=[]; obj.Readiness=[]; obj.UI=struct();
        end
        function apply(obj)
            try
                d=fsdui.globalStaticConfiguration('DEFINITION',obj.getRows(),obj.Scenario);
                obj.Invoke('GLOBAL_CONFIG',struct('definition',d));
            catch cause
                obj.UI.Status.Value=cellstr(fsdui.errorText(cause));
            end
        end
        function run(obj)
            assert(~isempty(obj.Scenario),'fsd:ui:GlobalInput','Apply a global scenario first.');
            obj.Invoke('GLOBAL_RUN',struct('scenarioId',obj.Scenario.definition.id,'resultId',obj.Controller.nextResultId()));
        end
    end
    methods(Access=private)
        function pickScenario(obj)
            if obj.Dirty
                value='NEW'; if ~isempty(obj.Scenario), value=char(obj.Scenario.definition.id); end
                obj.UI.Scenario.Value=value; obj.UI.Status.Value={'Apply the current global draft before selecting another scenario.'}; return;
            end
            obj.DrawnProject=[]; obj.refresh();
        end
        function configuration(obj)
            g=uigridlayout(obj.UI.Configuration,[21,1]); g.Scrollable='on';
            g.RowHeight={36,28,125,30,165,30,135,30,285,30,220,30,220,36,30,130,30,130,36,40,250};
            bar=uigridlayout(g,[1,3]); bar.ColumnWidth={200,200,'1x'}; bar.Padding=0;
            obj.UI.Apply=uibutton(bar,'Text','Apply and check readiness','ButtonPushedFcn',@(~,~)obj.apply());
            obj.UI.Run=uibutton(bar,'Text','Run global equilibrium','ButtonPushedFcn',@(~,~)obj.run());
            uilabel(bar,'Text','Paths are generated explicitly in this run; static velocity is zero.');
            uilabel(g,'Text','Registered corner resources (native identity validation occurs at readiness)');
            obj.UI.Resources=uitable(g,'ColumnName',{'Corner','Geometry','Actuation','Coilover'});
            uilabel(g,'Text','Vertical tires — linear unilateral law only');
            obj.UI.tires=obj.table(g,{'Corner','Stiffness [N/mm]','Unloaded radius [mm]','Source kind','Source note'},[false,true,true,true,true]);
            uilabel(g,'Text','Independent body-relative bump samples [mm], at rest; at least three per path');
            obj.UI.paths=obj.table(g,{'Corner','Travel samples [mm]'},[false,true]);
            uilabel(g,'Text','Explicit vehicle and model declarations (no physical defaults)');
            obj.UI.controls=obj.table(g,{'Declaration','Value'},[false,true]);
            uilabel(g,'Text','Solver search box and coordinate scales — numerical bounds are not mechanical stops');
            obj.UI.coordinates=obj.table(g,{'Coordinate / unit','Lower bound','Upper bound','Scale'},[false,true,true,true]);
            uilabel(g,'Text','Initial guesses — rows h, pitch, roll, zFL, zFR, zRL, zRR; mm / degrees');
            obj.UI.guesses=obj.table(g,{'Seed 1'},true);
            bar=uigridlayout(g,[1,3]); bar.Padding=0;
            obj.UI.AddSeed=uibutton(bar,'Text','Add empty seed','ButtonPushedFcn',@(~,~)obj.addSeed());
            uibutton(bar,'Text','Remove last seed','ButtonPushedFcn',@(~,~)obj.removeSeed());
            uilabel(bar,'Text','No uniqueness beyond supplied seeds.');
            uilabel(g,'Text','Explicit contacts [mm], consumed only with EXPLICIT contact policy');
            obj.UI.contacts=obj.table(g,{'Corner','X [mm]','Y [mm]','Z [mm]'},[false,true,true,true]);
            uilabel(g,'Text','Optional chassis ride-height reference points, body frame [mm]');
            obj.UI.heights=obj.table(g,{'ID','X [mm]','Y [mm]','Z [mm]'},true(1,4));
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            uibutton(bar,'Text','Add empty height reference','ButtonPushedFcn',@(~,~)obj.heightRow(true));
            uibutton(bar,'Text','Remove last reference','ButtonPushedFcn',@(~,~)obj.heightRow(false));
            uilabel(g,'Text','Mandatory numerical budgets below; optional algorithm settings may be blank (native defaults).');
            % Settings use their exact native SI names; engineering display is explicit.
            obj.UI.options=obj.table(g,{'Native solver setting / SI unit','Value'},[false,true]);
            obj.UI.options.Layout.Row=21;
        end
        function results(obj)
            g=uigridlayout(obj.UI.Results,[10,1]); g.Scrollable='on'; g.RowHeight={36,36,110,200,190,95,125,180,200,180};
            bar=uigridlayout(g,[1,4]); bar.ColumnWidth={110,'1x',110,'1x'}; bar.Padding=0;
            uilabel(bar,'Text','Stored result'); obj.UI.Primary=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.selectResult());
            uilabel(bar,'Text','Compare with'); obj.UI.Reference=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.render());
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            uilabel(bar,'Text','Inspect stored alternative (NONE publishes no selected pose)');
            obj.UI.Alternative=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Summary=uitextarea(g,'Editable','off');
            obj.UI.Pose=uitable(g,'ColumnName',{'Magnitude','Value','Unit'});
            obj.UI.Corners=uitable(g,'ColumnName',{'Corner','Travel mm','WC X mm','WC Y mm','WC Z mm','Compression mm', ...
                'Damper length mm','Signed MR','Spring axial N','Spring generalized body-z N','Tire normal world-Z N', ...
                'Tire compression mm','Loaded radius mm','Gap mm','Contact','Path','Limits'});
            obj.UI.Heights=uitable(g,'ColumnName',{'Reference','Height mm'});
            obj.UI.Attempts=uitable(g,'ColumnName',{'Attempt','Converged/admissible','Status','Stability','rcond'});
            obj.UI.Comparison=uitable(g,'ColumnName',{'Corner','Primary N','Reference selected N','Difference N'});
            obj.UI.PoseComparison=uitable(g,'ColumnName',{'Magnitude','Primary','Reference selected','Difference','Unit'});
            obj.UI.Details=uitextarea(g,'Editable','off');
        end
        function table=table(obj,parent,columns,editable)
            table=uitable(parent,'ColumnName',columns,'ColumnEditable',editable,'CellEditCallback',@(~,~)obj.edited());
        end
        function edited(obj)
            obj.Dirty=true; obj.Draft(); obj.updateStatus();
        end
        function r=getRows(obj)
            r=struct();
            for name=["controls","tires","paths","coordinates","guesses","options","contacts","heights"]
                r.(name)=obj.UI.(name).Data;
            end
        end
        function setRows(obj,r)
            for name=string(fieldnames(r))', obj.UI.(name).Data=r.(name); end
            obj.seedHeaders();
        end
        function seedHeaders(obj)
            n=size(obj.UI.guesses.Data,2); obj.UI.guesses.ColumnName=cellstr("Seed "+(1:n)); obj.UI.guesses.ColumnEditable=true(1,n);
        end
        function addSeed(obj)
            obj.UI.guesses.Data(:,end+1)=repmat({''},7,1); obj.seedHeaders(); obj.edited();
        end
        function removeSeed(obj)
            if size(obj.UI.guesses.Data,2)>1, obj.UI.guesses.Data(:,end)=[]; obj.seedHeaders(); obj.edited(); end
        end
        function heightRow(obj,add)
            if add
                obj.UI.heights.Data(end+1,:)=repmat({''},1,4);
            elseif ~isempty(obj.UI.heights.Data)
                obj.UI.heights.Data(end,:)=[];
            end
            obj.edited();
        end
        function page(obj)
            obj.UI.Configuration.Visible=strcmp(obj.UI.Pages.Value,'Configuration'); obj.UI.Results.Visible=strcmp(obj.UI.Pages.Value,'Results');
        end
        function selectResult(obj)
            r=obj.findRecord(obj.UI.Primary.Value); labels="NONE";
            if ~isempty(r), labels=[labels,string(1:numel(r.nativePayload.equilibrium.alternatives))]; end
            obj.UI.Alternative.Items=cellstr(labels); obj.UI.Alternative.Value='NONE';
            if ~isempty(r) && isfinite(r.nativePayload.equilibrium.selectedIndex)
                obj.UI.Alternative.Value=char(string(r.nativePayload.equilibrium.selectedIndex));
            end
            obj.render();
        end
        function r=findRecord(obj,id)
            r=[]; for k=1:numel(obj.Records), if string(obj.Records{k}.id)==string(id), r=obj.Records{k}; return; end, end
        end
        function status=compatibility(obj,r)
            status="UNKNOWN"; all=obj.Controller.Project.definition.results;
            i=find(cellfun(@(x)string(x.id)==string(r.id),all));
            if isscalar(i) && numel(obj.Controller.Compatibility)>=i, status=obj.Controller.Compatibility{i}.status; end
        end
        function render(obj)
            for name=["Pose","Corners","Heights","Attempts","Comparison","PoseComparison"], obj.UI.(name).Data=cell(0,numel(obj.UI.(name).ColumnName)); end
            obj.UI.Summary.Value={'No stored global result selected.'}; obj.UI.Details.Value={''};
            r=obj.findRecord(obj.UI.Primary.Value); if isempty(r), return; end
            e=fsdui.globalStaticEvidence(r,str2double(obj.UI.Alternative.Value));
            obj.UI.Summary.Value=cellstr(["Project "+r.projectId+" revision "+r.projectRevision+" | "+obj.compatibility(r); ...
                "Scenario "+r.scenarioAtExecution.definition.id+" | software "+r.fsdVersion+ ...
                " | physical system schema "+r.nativePayload.system.schemaVersion;e.summary]);
            obj.UI.Pose.Data=e.pose; obj.UI.Corners.Data=e.corners; obj.UI.Heights.Data=e.heights;
            obj.UI.Attempts.Data=e.attempts; obj.UI.Details.Value=cellstr([e.details;"Attempts diagnostics: "+string(jsonencode(r.nativePayload.equilibrium.attempts))]);
            ref=obj.findRecord(obj.UI.Reference.Value);
            if isempty(ref) || isempty(e.corners) || ~isfinite(ref.nativePayload.equilibrium.selectedIndex), return; end
            other=fsdui.globalStaticEvidence(ref,ref.nativePayload.equilibrium.selectedIndex);
            rows=[e.corners(:,1),e.corners(:,11),other.corners(:,11), ...
                num2cell(cell2mat(e.corners(:,11))-cell2mat(other.corners(:,11)))];
            obj.UI.Comparison.Data=rows;
            obj.UI.PoseComparison.Data=[e.pose(:,1:2),other.pose(:,2), ...
                num2cell(cell2mat(e.pose(:,2))-cell2mat(other.pose(:,2))),e.pose(:,3)];
            obj.UI.Summary.Value=cellstr([string(obj.UI.Summary.Value);"Comparison reference: "+string(ref.id)+ ...
                " revision "+ref.projectRevision+" | "+obj.compatibility(ref)+" | selected alternative "+ref.nativePayload.equilibrium.selectedIndex; ...
                "Equal normal loads do not imply equal pose or configuration."]);
        end
    end
    methods(Static,Access=private)
        function setPicker(control,labels)
            old=control.Value; control.Items=labels; if ismember(string(old),string(labels)), control.Value=old; end
        end
    end
end
