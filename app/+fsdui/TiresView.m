classdef TiresView < handle
    %TIRESVIEW Minimal native editor/study/evidence UI; no engineering equations.
    properties(SetAccess=private)
        UI=struct()
    end
    properties(Access=private)
        Controller
        Invoke
        Draft
        Tire=[]
        Dirty=false
        DirtyParts=strings(0,1)
        StudyReadiness=[]
        DrawnScenario="NONE"
        DrawnProject=[]
        Records={}
    end
    methods
        function obj=TiresView(tab,controller,invoke,draft)
            obj.Controller=controller; obj.Invoke=invoke; obj.Draft=draft;
            g=uigridlayout(tab,[4,1]); g.RowHeight={75,32,32,'1x'};
            obj.UI.Status=uitextarea(g,'Editable','off');
            obj.UI.Resource=uidropdown(g,'Items',{'NEW'},'ValueChangedFcn',@(~,~)obj.pick());
            obj.UI.Page=uidropdown(g,'Items',{'Definition','Study','Results'},'ValueChangedFcn',@(~,~)obj.page());
            holder=uigridlayout(g,[1,1]); holder.Padding=0;
            for name=["Definition","Study","Results"]
                obj.UI.(name)=uipanel(holder); obj.UI.(name).Layout.Row=1; obj.UI.(name).Layout.Column=1;
            end
            obj.definition(); obj.study(); obj.results(); obj.page();
            obj.setRows(fsdui.tireConfiguration('ROWS',[]));
        end
        function updateStatus(obj)
            if isempty(obj.Controller), return; end
            c=obj.Controller; text=[c.Status;"Calculated curves are models, never experimental measurements."];
            if obj.Dirty, text(end+1)="Unapplied tire/study/assignment draft; apply before saving or executing."; end
            if ~isempty(obj.StudyReadiness), text=[text;"Study readiness: "+obj.StudyReadiness.status;obj.StudyReadiness.missing;obj.StudyReadiness.diagnostics]; end
            if ~isempty(c.LastError), text=[text;fsdui.errorText(c.LastError)];
            elseif isstruct(c.LastValue)&&isfield(c.LastValue,'missing')
                text=[text;"Readiness: "+c.LastValue.status;c.LastValue.missing;c.LastValue.diagnostics];
            end
            obj.UI.Status.Value=cellstr(text);
            ready=~isempty(obj.StudyReadiness)&&obj.StudyReadiness.status=="READY";
            obj.UI.Run.Enable=~c.Busy&&~obj.Dirty&&ready;
        end
        function refresh(obj)
            if isempty(obj.Controller), return; end
            obj.updateStatus(); p=obj.Controller.Project;
            if isequaln(obj.DrawnProject,p), return; end
            tires={}; if isfield(p.definition.resources,'tires'), tires=p.definition.resources.tires; end
            labels=["NEW",string(cellfun(@(t)obj.key(t),tires,'UniformOutput',false))'];
            old=string(obj.UI.Resource.Value); obj.UI.Resource.Items=cellstr(labels);
            if obj.Controller.LastAction=="TIRE_CONFIG"&&isstruct(obj.Controller.LastValue)&&isfield(obj.Controller.LastValue,'kind')&&obj.Controller.LastValue.kind=="TireDefinition"
                old=obj.key(obj.Controller.LastValue);
            end
            if ismember(old,labels), obj.UI.Resource.Value=char(old); end
            if ~ismember("DEFINITION",obj.DirtyParts)
                obj.Tire=[];
                for k=1:numel(tires), if string(obj.UI.Resource.Value)==obj.key(tires{k}), obj.Tire=tires{k}; end, end
                obj.fillDefinition();
            end
            if ~ismember("ASSIGNMENT",obj.DirtyParts), obj.fillAssignments(p); end
            ss=p.definition.scenarios; ss=ss(cellfun(@(s)s.definition.engine=="TIRE_CHARACTERIZATION",ss));
            labels=cellfun(@(s)char(s.definition.id),ss,'UniformOutput',false); if isempty(labels), labels={'NONE'}; end
            obj.picker(obj.UI.Scenario,labels);
            if obj.Controller.LastAction=="TIRE_STUDY_CONFIG"&&isstruct(obj.Controller.LastValue)&&isfield(obj.Controller.LastValue,'scenarioId')&& ...
                    ismember(obj.Controller.LastValue.scenarioId,string(labels))
                obj.UI.Scenario.Value=char(obj.Controller.LastValue.scenarioId);
            end
            if ~ismember("STUDY",obj.DirtyParts)&&ismember(obj.Controller.LastAction,["LOAD","TIRE_STUDY_CONFIG"]), obj.loadStudy(); end
            obj.StudyReadiness=[];
            if ~strcmp(obj.UI.Scenario.Value,'NONE'), obj.StudyReadiness=fsd.project.designReadiness(p,string(obj.UI.Scenario.Value)); end
            rs=p.definition.results; obj.Records=rs(cellfun(@(r)r.engine=="TIRE_CHARACTERIZATION",rs));
            labels=[{'NONE'},cellfun(@(r)char(r.id),obj.Records,'UniformOutput',false)'];
            obj.picker(obj.UI.Primary,labels); obj.picker(obj.UI.Reference,labels);
            if obj.Controller.LastAction=="TIRE_RUN"&&isstruct(obj.Controller.LastValue)&&isfield(obj.Controller.LastValue,'id')
                obj.UI.Primary.Value=char(obj.Controller.LastValue.id);
            elseif obj.Controller.LastAction=="LOAD"&&~isempty(obj.Records)
                obj.UI.Primary.Value=char(obj.Records{end}.id);
            end
            obj.render(); obj.updateStatus(); obj.DrawnProject=p;
            obj.DrawnScenario=string(obj.UI.Scenario.Value);
        end
        function committed(obj,action)
            switch string(action)
                case "TIRE_CONFIG", part="DEFINITION";
                case "TIRE_ASSIGN", part="ASSIGNMENT";
                case "TIRE_STUDY_CONFIG", part="STUDY";
            end
            obj.DirtyParts=setdiff(obj.DirtyParts,part); obj.Dirty=~isempty(obj.DirtyParts); obj.DrawnProject=[];
        end
        function value=hasDraft(obj)
            value=obj.Dirty;
        end
        function prepareAction(obj,action)
            if string(action)=="TIRE_RUN"
                assert(~obj.Dirty,'fsd:ui:UnappliedDraft','Apply tire, assignments and study drafts before running.');
            elseif ismember(string(action),["TIRE_ASSIGN","TIRE_STUDY_CONFIG"])
                assert(~ismember("DEFINITION",obj.DirtyParts),'fsd:ui:UnappliedDraft','Apply the tire definition before selecting its revision.');
            end
        end
        function resetDrafts(obj)
            obj.Dirty=false; obj.DirtyParts=strings(0,1); obj.Tire=[]; obj.DrawnProject=[]; obj.StudyReadiness=[];
            obj.UI.Resource.Value='NEW'; obj.UI.States.Data(:,2)=repmat({''},4,1);
        end
        function release(obj)
            obj.Controller=[]; obj.Invoke=[]; obj.Draft=[]; obj.Records={}; obj.Tire=[]; obj.UI=struct(); obj.DrawnProject=[];
        end
        function applyDefinition(obj)
            try
                r=struct('id',obj.UI.Id.Value,'name',obj.UI.Name.Value,'level',obj.UI.Level.Value, ...
                    'family',obj.UI.Family.Value,'evidence',obj.UI.Evidence.Value,'note',obj.UI.Note.Value, ...
                    'parameters',{obj.UI.Parameters.Data},'domain',{obj.UI.Domain.Data},'laws',{obj.UI.Laws.Data});
                d=fsdui.tireConfiguration('DEFINITION',r,obj.Tire);
                obj.Invoke('TIRE_CONFIG',struct('definition',d));
                if isempty(obj.Controller.LastError)&&isstruct(obj.Controller.LastValue)&&isfield(obj.Controller.LastValue,'kind')&& ...
                        obj.Controller.LastValue.kind=="TireDefinition"
                    t=obj.Controller.LastValue; obj.UI.Resource.Value=char(obj.key(t)); obj.DrawnProject=[]; obj.refresh();
                end
            catch cause
                obj.UI.Status.Value=cellstr(fsdui.errorText(cause));
            end
        end
        function applyAssignments(obj)
            try
                rows=obj.UI.Assignments.Data; assignments={};
                for k=1:4
                    text=string(rows{k,2}); if strlength(text)==0, continue; end
                    bits=split(text,'@'); assert(numel(bits)==2,'fsd:ui:TireInput','Use ID@revision from the resource selector.');
                    assignments{end+1,1}=struct('cornerId',string(rows{k,1}),'tireId',bits(1),'tireRevision',str2double(bits(2))); %#ok<AGROW>
                end
                obj.Invoke('TIRE_ASSIGN',struct('assignments',{assignments}));
            catch cause
                obj.UI.Status.Value=cellstr(fsdui.errorText(cause));
            end
        end
        function applyStudy(obj)
            try
                assert(~isempty(obj.Tire),'fsd:ui:TireInput','Select a registered tire revision.');
                rows=obj.UI.States.Data;
                s=struct('Fz_N',fsdui.numberList(rows{1,2}), ...
                    'alpha_rad',fsdui.numberList(rows{2,2})*pi/180,'kappa',fsdui.numberList(rows{3,2}), ...
                    'gamma_rad',fsdui.numberList(rows{4,2})*pi/180);
                channels=split(string(obj.UI.Channels.Value),'+');
                q=struct('channels',channels,'domainPolicy',string(obj.UI.Policy.Value));
                d=struct('id',string(obj.UI.StudyId.Value),'engine',"TIRE_CHARACTERIZATION", ...
                    'scope',fsd.model.designScope('VEHICLE','VEHICLE'), ...
                    'inputs',struct('tireId',obj.Tire.definition.id,'tireRevision',obj.Tire.definition.revision), ...
                    'plan',struct('states',s,'request',q));
                obj.Invoke('TIRE_STUDY_CONFIG',struct('definition',d));
                if isempty(obj.Controller.LastError)&&ismember(char(d.id),obj.UI.Scenario.Items), obj.UI.Scenario.Value=char(d.id); end
            catch cause
                obj.UI.Status.Value=cellstr(fsdui.errorText(cause));
            end
        end
        function run(obj)
            obj.Invoke('TIRE_RUN',struct('scenarioId',string(obj.UI.Scenario.Value),'resultId',obj.Controller.nextResultId()));
        end
    end
    methods(Access=private)
        function definition(obj)
            g=uigridlayout(obj.UI.Definition,[11,2]); g.Scrollable='on';
            g.ColumnWidth={'1x','1x'}; g.RowHeight={32,32,32,32,32,32,36,400,145,190,40};
            uilabel(g,'Text','Tire ID'); obj.UI.Id=obj.edit(g);
            uilabel(g,'Text','Name'); obj.UI.Name=obj.edit(g);
            uilabel(g,'Text','Information level'); obj.UI.Level=obj.drop(g,{'GEOMETRY_ONLY','GENERIC','CUSTOM'});
            uilabel(g,'Text','Native force family'); obj.UI.Family=obj.drop(g,{'NONE','DUGOFF_REDUCED_1'});
            uilabel(g,'Text','Declared evidence quality'); obj.UI.Evidence=obj.drop(g,{'USER_DECLARED','ASSUMPTION_BASED','CALIBRATED','VALIDATED'});
            uilabel(g,'Text','Evidence reference / note'); obj.UI.Note=obj.edit(g);
            obj.UI.Apply=uibutton(g,'Text','Apply tire revision','ButtonPushedFcn',@(~,~)obj.applyDefinition());
            obj.UI.Example=uibutton(g,'Text','Load explicit synthetic draft','ButtonPushedFcn',@(~,~)obj.example());
            obj.UI.Parameters=uitable(g,'ColumnName',{'Parameter','Value','Unit','Source kind','Source note'}, ...
                'ColumnEditable',[false,true,false,true,true],'CellEditCallback',@(~,~)obj.edited()); obj.UI.Parameters.Layout.Column=[1,2];
            obj.UI.Domain=uitable(g,'ColumnName',{'Declared domain','Minimum','Maximum'},'ColumnEditable',[false,true,true], ...
                'CellEditCallback',@(~,~)obj.edited()); obj.UI.Domain.Layout.Column=[1,2];
            obj.UI.Laws=uitable(g,'ColumnName',{'Law','Choice'},'ColumnEditable',[false,true], ...
                'CellEditCallback',@(~,~)obj.edited()); obj.UI.Laws.Layout.Column=[1,2];
            label=uilabel(g,'Text','Laws: capacity REFERENCE_ONLY/CONSTANT_MU/POWER; stiffness REFERENCE_ONLY/CONSTANT/POWER; camber NEGLECTED/LINEAR_CONSTANT or QUADRATIC.');
            label.WordWrap='on'; label.Layout.Column=[1,2];
        end
        function study(obj)
            g=uigridlayout(obj.UI.Study,[9,2]); g.Scrollable='on'; g.RowHeight={30,150,36,30,30,30,150,36,65};
            label=uilabel(g,'Text','Assignments use exact ID@revision; blank means unassigned.'); label.Layout.Column=[1,2];
            obj.UI.Assignments=uitable(g,'ColumnName',{'Corner','Tire ID@revision'},'ColumnEditable',[false,true], ...
                'CellEditCallback',@(~,~)obj.edited("ASSIGNMENT")); obj.UI.Assignments.Layout.Column=[1,2];
            obj.UI.ApplyAssignments=uibutton(g,'Text','Apply corner assignments','ButtonPushedFcn',@(~,~)obj.applyAssignments());
            obj.UI.Scenario=uidropdown(g,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.loadStudy());
            uilabel(g,'Text','Study ID'); obj.UI.StudyId=obj.edit(g); obj.UI.StudyId.Value='UI_TIRE_STUDY';
            obj.UI.StudyId.ValueChangedFcn=@(~,~)obj.edited("STUDY");
            uilabel(g,'Text','Requested channels'); obj.UI.Channels=obj.drop(g,{'Fx+Fy','Fx','Fy','Mz'});
            obj.UI.Channels.ValueChangedFcn=@(~,~)obj.edited("STUDY");
            uilabel(g,'Text','Domain policy'); obj.UI.Policy=obj.drop(g,{'MARK','REJECT'});
            obj.UI.Policy.ValueChangedFcn=@(~,~)obj.edited("STUDY");
            obj.UI.States=uitable(g,'Data',{'Fz [N]','';'alpha [deg]','';'kappa','';'gamma [deg]',''}, ...
                'ColumnName',{'Channel','Explicit samples (matching length or scalar)'},'ColumnEditable',[false,true], ...
                'CellEditCallback',@(~,~)obj.edited("STUDY")); obj.UI.States.Layout.Column=[1,2];
            obj.UI.ApplyStudy=uibutton(g,'Text','Apply study and check readiness','ButtonPushedFcn',@(~,~)obj.applyStudy());
            obj.UI.Run=uibutton(g,'Text','Run tire study','ButtonPushedFcn',@(~,~)obj.run());
            label=uilabel(g,'Text','No Cartesian expansion or invented inputs. For global equilibrium select LIBRARY_ASSIGNMENTS on Global static.');
            label.WordWrap='on'; label.Layout.Column=[1,2];
        end
        function results(obj)
            g=uigridlayout(obj.UI.Results,[6,1]); g.Scrollable='on'; g.RowHeight={32,32,90,280,200,100};
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            obj.UI.Primary=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Reference=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.X=uidropdown(g,'Items',{'alpha [deg]','kappa','Fz [N]','gamma [deg]'},'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Summary=uitextarea(g,'Editable','off'); obj.UI.Axes=uiaxes(g);
            obj.UI.Values=uitable(g,'ColumnName',{'Fz N','alpha deg','kappa','gamma deg','Fx N','Fy N','Fx status','Fy status','Mz status'});
            obj.UI.Details=uitextarea(g,'Editable','off');
        end
        function edit=edit(obj,g)
            edit=uieditfield(g,'text','ValueChangedFcn',@(~,~)obj.edited());
        end
        function drop=drop(obj,g,items)
            drop=uidropdown(g,'Items',items,'ValueChangedFcn',@(~,~)obj.edited());
        end
        function edited(obj,part)
            if nargin<2, part="DEFINITION"; end
            obj.DirtyParts=union(obj.DirtyParts,part); obj.Dirty=true; obj.Draft(); obj.updateStatus();
        end
        function pick(obj)
            if obj.Dirty
                key='NEW'; if ~isempty(obj.Tire)&&ismember(obj.key(obj.Tire),string(obj.UI.Resource.Items)), key=char(obj.key(obj.Tire)); end
                obj.UI.Resource.Value=key; obj.UI.Status.Value={'Apply drafts before selecting another tire revision.'}; return;
            end
            obj.DrawnProject=[]; obj.refresh();
        end
        function fillDefinition(obj)
            rows=fsdui.tireConfiguration('ROWS',obj.Tire); obj.setRows(rows);
            if isempty(obj.Tire)
                obj.UI.Id.Value=''; obj.UI.Name.Value=''; obj.UI.Level.Value='GEOMETRY_ONLY'; obj.UI.Family.Value='NONE';
                obj.UI.Evidence.Value='USER_DECLARED'; obj.UI.Note.Value='';
            else
                d=obj.Tire.definition; obj.UI.Id.Value=char(d.id); obj.UI.Name.Value=char(d.name);
                obj.UI.Level.Value=char(d.level); obj.UI.Family.Value=char(d.force.family);
                obj.UI.Evidence.Value=char(d.evidence); obj.UI.Note.Value=char(d.note);
            end
        end
        function setRows(obj,r)
            obj.UI.Parameters.Data=r.parameters; obj.UI.Domain.Data=r.domain; obj.UI.Laws.Data=r.laws;
        end
        function fillAssignments(obj,p)
            rows=[cellstr(["FL";"FR";"RL";"RR"]),repmat({''},4,1)];
            if isfield(p.definition.resources,'tireAssignments')
                for a=p.definition.resources.tireAssignments'
                    i=string(rows(:,1))==a{1}.cornerId; rows{i,2}=char(a{1}.tireId+"@"+string(a{1}.tireRevision));
                end
            end
            obj.UI.Assignments.Data=rows;
        end
        function loadStudy(obj)
            if ismember("STUDY",obj.DirtyParts)
                if ismember(obj.DrawnScenario,string(obj.UI.Scenario.Items)), obj.UI.Scenario.Value=char(obj.DrawnScenario); end
                obj.UI.Status.Value={'Apply study draft before loading another study.'}; return;
            end
            ss=obj.Controller.Project.definition.scenarios;
            for k=1:numel(ss)
                d=ss{k}.definition;
                if d.id~=string(obj.UI.Scenario.Value), continue; end
                key="";
                if all(isfield(d.inputs,["tireId","tireRevision"]))
                    key=string(d.inputs.tireId)+"@"+string(d.inputs.tireRevision);
                end
                if ~ismember("DEFINITION",obj.DirtyParts)&&ismember(key,string(obj.UI.Resource.Items))
                    obj.UI.Resource.Value=char(key); obj.Tire=fsd.project.findTire(obj.Controller.Project,d.inputs.tireId,d.inputs.tireRevision); obj.fillDefinition();
                end
                obj.UI.StudyId.Value=char(d.id); keys=["Fz_N","alpha_rad","kappa","gamma_rad"]; factors=[1,180/pi,1,180/pi];
                for j=1:4
                    obj.UI.States.Data{j,2}='';
                    if isfield(d.plan,'states')&&isstruct(d.plan.states)&&isscalar(d.plan.states)&&isfield(d.plan.states,keys(j))
                        v=d.plan.states.(keys(j));
                        if isnumeric(v)&&isreal(v)
                            obj.UI.States.Data{j,2}=char(join(compose('%.17g',double(v(:)')*factors(j)),' '));
                        end
                    end
                end
                % Defaults are presentation only; never rewrite the loaded plan.
                q=struct(); if isfield(d.plan,'request'), q=d.plan.request; end
                try
                    q=fsd.tire.normalizeRequest(q); channelText=char(join(q.channels,'+'));
                    if ~ismember(channelText,obj.UI.Channels.Items), obj.UI.Channels.Items{end+1}=channelText; end
                    obj.UI.Channels.Value=channelText; obj.UI.Policy.Value=char(q.domainPolicy);
                catch cause
                    if ~startsWith(string(cause.identifier),'fsd:tire:'), rethrow(cause); end
                    % Canonical readiness below exposes the invalid declaration.
                end
                obj.StudyReadiness=fsd.project.designReadiness(obj.Controller.Project,d.id);
                obj.DrawnScenario=d.id; obj.updateStatus();
            end
        end
        function example(obj)
            root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=path; cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'examples'));
            d=tireCharacterizationInputs; t=fsd.tire.create(d); obj.Tire=t; obj.fillDefinition(); obj.edited();
        end
        function page(obj)
            for name=["Definition","Study","Results"], obj.UI.(name).Visible=strcmp(obj.UI.Page.Value,name); end
        end
        function render(obj)
            cla(obj.UI.Axes); obj.UI.Values.Data=cell(0,9); obj.UI.Details.Value={''}; obj.UI.Summary.Value={'No stored tire response selected.'};
            r=obj.record(obj.UI.Primary.Value); if isempty(r), return; end
            v=r.nativePayload; s=v.states; i=cellfun(@(x)x.id==r.id,obj.Controller.Project.definition.results);
            compatibility=obj.Controller.Compatibility{i}.status;
            obj.UI.Summary.Value=cellstr(["MODEL CURVE — "+v.family+" | declared "+v.evidence+" | assumptions "+v.assumptionBased; ...
                "Result "+r.id+" revision "+r.projectRevision+" | "+compatibility; ...
                "Tire "+r.prepared.tire.definition.id+"@"+r.prepared.tire.definition.revision]);
            obj.UI.Values.Data=[num2cell([s.Fz_N,s.alpha_rad*180/pi,s.kappa,s.gamma_rad*180/pi,v.Fx_N,v.Fy_N]), ...
                cellstr(v.status+" / "+v.quality)];
            labels=["alpha [deg]","kappa","Fz [N]","gamma [deg]"]; keys=["alpha_rad","kappa","Fz_N","gamma_rad"]; factors=[180/pi,1,1,180/pi];
            j=labels==string(obj.UI.X.Value); x=s.(keys(j))*factors(j);
            plot(obj.UI.Axes,x,v.Fx_N,'DisplayName',r.id+" Fx"); hold(obj.UI.Axes,'on');
            plot(obj.UI.Axes,x,v.Fy_N,'DisplayName',r.id+" Fy");
            ref=obj.record(obj.UI.Reference.Value);
            if ~isempty(ref)
                if isequaln(ref.nativePayload.states,v.states)&&isequaln(ref.nativePayload.request,v.request)
                    plot(obj.UI.Axes,x,ref.nativePayload.Fx_N,'--','DisplayName',ref.id+" Fx");
                    plot(obj.UI.Axes,x,ref.nativePayload.Fy_N,'--','DisplayName',ref.id+" Fy");
                    all=obj.Controller.Project.definition.results; match=cellfun(@(x)x.id==ref.id,all);
                    referenceStatus=obj.Controller.Compatibility{match}.status;
                    obj.UI.Summary.Value=[obj.UI.Summary.Value;cellstr("Reference "+ref.id+" revision "+ref.projectRevision+" | "+referenceStatus)];
                else, obj.UI.Summary.Value=[obj.UI.Summary.Value;{'Reference conditions differ; no overlay or equivalence implied.'}];
                end
            end
            hold(obj.UI.Axes,'off'); xlabel(obj.UI.Axes,labels(j)); ylabel(obj.UI.Axes,'Force [N]');
            legend(obj.UI.Axes,'show','Interpreter','none','Location','best');
            obj.UI.Details.Value=cellstr([unique(v.diagnostics(strlength(v.diagnostics)>0));"Sources: "+string(jsonencode(v.provenance))]);
        end
        function r=record(obj,id)
            r=[]; for k=1:numel(obj.Records), if obj.Records{k}.id==string(id), r=obj.Records{k}; return; end, end
        end
    end
    methods(Static,Access=private)
        function text=key(t)
            text=t.definition.id+"@"+string(t.definition.revision);
        end
        function picker(control,labels)
            old=control.Value; control.Items=labels; if ismember(string(old),string(labels)), control.Value=old; end
        end
    end
end
