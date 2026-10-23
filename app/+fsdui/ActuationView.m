classdef ActuationView < handle
    %ACTUATIONVIEW Minimal native workflow; all physics belongs to fsd APIs.
    properties(SetAccess=private)
        UI=struct()
        Axes
        CurveAxes
    end
    properties(Access=private)
        Controller
        Invoke
        Draft
        Tab
        Figure
        Corner="NONE"
        ConfigDirty=false
        SearchDirty=false
        PlanDirty=false
        PendingKind=""
        DrawnProject=[]
        RenderKey=[]
        Definition=[]
        SolverOptions=struct()
    end
    methods
        function obj=ActuationView(tab,controller,invoke,draft)
            obj.Tab=tab; obj.Figure=ancestor(tab,'figure'); obj.Controller=controller;
            obj.Invoke=invoke; obj.Draft=draft;
            root=uigridlayout(tab,[4,1]); root.RowHeight={34,48,30,'1x'};
            bar=obj.bar(root,{75,90,'1x'});
            uilabel(bar,'Text','Corner'); obj.UI.Scope=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.pickCorner());
            obj.UI.GeometryStatus=uilabel(bar,'Text','Select registered geometry; no dimensions are inferred.');
            obj.UI.Status=uitextarea(root,'Editable','off');
            obj.UI.Pages=uidropdown(root,'Items',{'Configuration','Analysis','Synthesis','Evidence'}, ...
                'ValueChangedFcn',@(~,~)obj.showPage());
            holder=uigridlayout(root,[1,1]); holder.Padding=0;
            for name=["Configuration","Analysis","Synthesis","Evidence"]
                panel=uipanel(holder,'Title',name); panel.Layout.Row=1; panel.Layout.Column=1;
                obj.UI.(name+"Panel")=panel;
            end
            obj.configurationPage(); obj.analysisPage(); obj.synthesisPage(); obj.evidencePage();
            obj.showPage();
        end
        function updateStatus(obj)
            if isempty(obj.Controller), return; end
            c=obj.Controller;
            states=["applied","unapplied"];
            obj.UI.Status.Value=cellstr([c.Status;"Configuration "+states(1+obj.ConfigDirty)+ ...
                " | analysis plan "+states(1+obj.PlanDirty)+" | synthesis "+states(1+obj.SearchDirty)]);
            if ~isempty(c.LastError)
                obj.UI.Status.Value=cellstr([string(obj.UI.Status.Value); ...
                    string(c.LastError.identifier)+": "+string(c.LastError.message)]);
            elseif isstruct(c.LastValue) && isfield(c.LastValue,'status') && isfield(c.LastValue,'missing')
                obj.UI.Status.Value=cellstr([string(obj.UI.Status.Value);"Readiness: "+c.LastValue.status; ...
                    c.LastValue.missing;c.LastValue.diagnostics]);
            end
        end
        function refresh(obj)
            if isempty(obj.Controller), return; end
            obj.updateStatus(); p=obj.Controller.Project;
            if ~isequaln(p,obj.DrawnProject)
                gs=p.definition.resources.geometries;
                ids=cellfun(@(g)char(g.cornerId),gs,'UniformOutput',false); if isempty(ids), ids={'NONE'}; end
                selected=obj.Corner; obj.UI.Scope.Items=ids;
                if ismember(selected,string(ids)), obj.UI.Scope.Value=char(selected); end
                obj.Corner=string(obj.UI.Scope.Value);
                restore=isempty(obj.DrawnProject) || selected~=obj.Corner || obj.DrawnProject.id~=p.id;
                if ~obj.ConfigDirty, obj.loadConfiguration(); end
                if ~obj.SearchDirty, obj.loadSearch(restore); end
                if ~obj.PlanDirty && isempty(obj.Definition) && restore, obj.loadAnalysisPlan(); end
                records=p.definition.results;
                keep=cellfun(@(r)ismember(r.engine,["ACTUATION","MECHANICAL","ACTUATION_SYNTHESIS"]) && ...
                    r.scenarioAtExecution.definition.scope.id==obj.Corner,records);
                ids=cellfun(@(r)char(r.id),records(keep),'UniformOutput',false); if isempty(ids), ids={'NONE'}; end
                previous=string(obj.UI.ResultPicker.Value); obj.UI.ResultPicker.Items=ids;
                if ismember(previous,string(ids)), obj.UI.ResultPicker.Value=char(previous); end
                r=obj.Controller.LastValue;
                if isstruct(r) && isfield(r,'id') && ismember(string(r.id),string(ids))
                    obj.UI.ResultPicker.Value=char(r.id);
                end
                obj.DrawnProject=p; obj.RenderKey=[];
            end
            obj.render();
        end
        function prepareAction(obj,action,args)
            action=string(action);
            if action=="ACTUATION_CONFIG"
                obj.PendingKind="CONFIG";
            elseif action=="SPECIFICATION"
                assert(~obj.ConfigDirty,'fsd:ui:UnappliedDraft','Apply actuation configuration before preparing a scenario.');
                if args.definition.engine=="ACTUATION_SYNTHESIS", obj.PendingKind="SEARCH";
                else
                    assert(~obj.SearchDirty,'fsd:ui:UnappliedDraft','Apply synthesis edits before preparing an analysis.');
                    obj.PendingKind="PLAN";
                end
            elseif action=="ACTUATION_RUN"
                assert(~obj.ConfigDirty && ~obj.SearchDirty,'fsd:ui:UnappliedDraft', ...
                    'Apply configuration and synthesis drafts before analysis.'); obj.PendingKind="PLAN";
            else
                assert(~obj.hasDraft(),'fsd:ui:UnappliedDraft','Apply Actuation drafts before this operation.');
                obj.PendingKind="";
            end
        end
        function committed(obj)
            switch obj.PendingKind
                case "CONFIG", obj.ConfigDirty=false;
                case "PLAN", obj.PlanDirty=false;
                case "SEARCH", obj.SearchDirty=false; obj.PlanDirty=false;
            end
            obj.PendingKind="";
        end
        function yes=hasDraft(obj)
            yes=obj.ConfigDirty || obj.SearchDirty || obj.PlanDirty;
        end
        function resetDrafts(obj)
            obj.ConfigDirty=false; obj.SearchDirty=false; obj.PlanDirty=false; obj.Definition=[];
            obj.DrawnProject=[];
            obj.SolverOptions=struct(); obj.UI.Travel.Value=''; obj.UI.Velocity.Value=''; obj.UI.Composite.Value=false;
        end
        function applyConfiguration(obj)
            try
                args=fsdui.actuationConfiguration(obj.Corner,obj.UI.Architecture.Value,obj.UI.Body.Value, ...
                    obj.UI.Mode.Value,obj.UI.Points.Data,obj.UI.Mechanical.Value,obj.UI.Law.Value, ...
                    obj.UI.Mechanics.Data,obj.UI.Compression.Data,obj.UI.Rebound.Data);
                resources=obj.Controller.Project.definition.resources;
                for name=["actuations","mechanicals"]
                    values=resources.(name); selected=cellfun(@(x)x.cornerId==obj.Corner,values);
                    if nnz(selected)==1
                        metadata=values{selected}.metadata;
                        if name=="actuations"
                            metadata.parameterProvenance=args.definition.metadata.parameterProvenance;
                            args.definition.metadata=metadata;
                        elseif ~isempty(args.mechanicalDefinition)
                            metadata.parameterProvenance=args.mechanicalDefinition.metadata.parameterProvenance;
                            args.mechanicalDefinition.metadata=metadata;
                        end
                    end
                end
                obj.Invoke('ACTUATION_CONFIG',args);
            catch cause
                obj.fail(cause);
            end
        end
        function runAnalysis(obj,readiness)
            try
                engine=string(obj.UI.Engine.Value); plan=obj.plan(engine=="MECHANICAL");
                if readiness
                    definition=struct('id',"UI_"+engine+"_"+obj.Corner,'engine',engine, ...
                        'scope',fsd.model.designScope('CORNER',obj.Corner),'plan',plan);
                    obj.Invoke('SPECIFICATION',struct('definition',definition));
                else
                    obj.Invoke('ACTUATION_RUN',struct('cornerId',obj.Corner,'engine',engine, ...
                        'plan',plan,'resultId',obj.Controller.nextResultId()));
                end
            catch cause
                obj.fail(cause);
            end
        end
        function applySearch(obj)
            try
                resources=obj.Controller.Project.definition.resources;
                mechanical=any(cellfun(@(m)m.cornerId==obj.Corner,resources.mechanicals));
                options=struct();
                if ~isempty(obj.Definition), options=obj.Definition.options; end
                rows=obj.UI.Options.Data;
                for j=1:size(rows,1)
                    v=fsdui.numberList(rows{j,2});
                    if ~isempty(v)
                        assert(isscalar(v),'fsd:ui:ActuationInput','Search options require scalars.');
                        options.(rows{j,1})=v;
                    elseif isfield(options,rows{j,1}), options=rmfield(options,rows{j,1});
                    end
                end
                d=fsdui.actuationSearchDefinition(obj.Corner,obj.UI.Targets.Data,obj.UI.Variables.Data, ...
                    obj.UI.Constraints.Data,obj.plan(mechanical),options,obj.UI.Composite.Value,obj.Definition);
                obj.Invoke('SPECIFICATION',struct('definition',d));
            catch cause
                obj.fail(cause);
            end
        end
        function runSearch(obj)
            obj.Invoke('SYNTHESIS',struct('scenarioId',"UI_ACT_SEARCH_"+obj.Corner,'resultId',obj.Controller.nextResultId()));
        end
        function adopt(obj)
            r=obj.selectedResult();
            if isempty(r), return; end
            answer=uiconfirm(obj.Figure,'Adopt this eligible candidate actuation and its exact coilover? Suspension stays fixed; all historical results remain stored.', ...
                'Adopt actuation','Options',{'Cancel','Adopt'},'DefaultOption',1,'CancelOption',1);
            if string(answer)=="Adopt"
                obj.Invoke('ACTUATION_ADOPT',struct('resultId',string(r.id),'index',obj.UI.Candidate.Value));
            end
        end
        function release(obj)
            obj.Controller=[]; obj.Invoke=[]; obj.Draft=[]; obj.DrawnProject=[]; obj.Definition=[];
            obj.UI=struct(); obj.Axes=[]; obj.CurveAxes=[]; obj.Tab=[]; obj.Figure=[]; obj.RenderKey=[];
        end
    end
    methods(Access=private)
        function configurationPage(obj)
            g=uigridlayout(obj.UI.ConfigurationPanel,[7,1]); g.RowHeight={32,32,170,32,190,130,42}; g.Scrollable='on';
            b=obj.bar(g,{'1x','1x','1x'});
            obj.UI.Architecture=uidropdown(b,'Items',{'UNSELECTED','PUSHROD','PULLROD'},'ValueChangedFcn',@(~,~)obj.mark('CONFIG'));
            obj.UI.Body=uidropdown(b,'Items',{'UNSELECTED','UPRIGHT','UCA','LCA'},'ValueChangedFcn',@(~,~)obj.mark('CONFIG'));
            obj.UI.Mode=uidropdown(b,'Items',{'UNSELECTED','YZ_PLANE','XZ_PLANE','CUSTOM'},'ValueChangedFcn',@(~,~)obj.mark('CONFIG'));
            obj.UI.Apply=uibutton(g,'Text','Apply actuation + optional coilover','ButtonPushedFcn',@(~,~)obj.applyConfiguration());
            obj.UI.Points=uitable(g,'ColumnName',{'Point','X','Y','Z','Unit','Source kind','Source note'}, ...
                'ColumnEditable',[false true true true false true true],'CellEditCallback',@(~,~)obj.mark('CONFIG'));
            obj.UI.Points.ColumnWidth={185,90,90,90,60,120,360};
            b=obj.bar(g,{240,'1x'});
            obj.UI.Mechanical=uicheckbox(b,'Text','Explicit COILOVER enabled','Value',false,'ValueChangedFcn',@(~,~)obj.mark('CONFIG'));
            obj.UI.Law=uidropdown(b,'Items',{'UNSELECTED','LINEAR_ASYMMETRIC','TABULATED_FORCE_VELOCITY'},'ValueChangedFcn',@(~,~)obj.mark('CONFIG'));
            obj.UI.Mechanics=uitable(g,'ColumnName',{'Parameter','Value','Unit','Source kind','Source note'}, ...
                'ColumnEditable',[false true false true true],'CellEditCallback',@(~,~)obj.mark('CONFIG'));
            obj.UI.Mechanics.ColumnWidth={215,110,100,130,400};
            b=uigridlayout(g,[1,2]);
            obj.UI.Compression=uitable(b,'ColumnName',{'Compression speed [mm/s]','Force [N]'}, ...
                'ColumnEditable',true,'CellEditCallback',@(~,~)obj.mark('CONFIG'));
            obj.UI.Rebound=uitable(b,'ColumnName',{'Rebound speed [mm/s]','Force [N]'}, ...
                'ColumnEditable',true,'CellEditCallback',@(~,~)obj.mark('CONFIG'));
            obj.UI.Compression.Tooltip='For tabulated damping, declare compression source in COMPRESSION_COEFFICIENT source columns; coefficient value is unused.';
            obj.UI.Rebound.Tooltip='For tabulated damping, declare rebound source in REBOUND_COEFFICIENT source columns; coefficient value is unused.';
            b=obj.bar(g,{'1x','1x','1x','1x'});
            uibutton(b,'Text','Add compression row','ButtonPushedFcn',@(~,~)obj.addCurve('Compression'));
            uibutton(b,'Text','Add rebound row','ButtonPushedFcn',@(~,~)obj.addCurve('Rebound'));
            uibutton(b,'Text','Remove compression row','ButtonPushedFcn',@(~,~)obj.removeCurve('Compression'));
            uibutton(b,'Text','Remove rebound row','ButtonPushedFcn',@(~,~)obj.removeCurve('Rebound'));
        end
        function analysisPage(obj)
            g=uigridlayout(obj.UI.AnalysisPanel,[5,2]); g.RowHeight={30,34,34,34,'1x'};
            uilabel(g,'Text','Wheel travel [mm], explicit ordered samples');
            obj.UI.Travel=uieditfield(g,'text','Value','','ValueChangedFcn',@(~,~)obj.mark('PLAN'));
            uilabel(g,'Text','Prescribed velocity [mm/s]; scalar or per sample');
            obj.UI.Velocity=uieditfield(g,'text','Value','','ValueChangedFcn',@(~,~)obj.mark('PLAN'));
            obj.UI.Engine=uidropdown(g,'Items',{'ACTUATION','MECHANICAL'},'ValueChangedFcn',@(~,~)obj.mark('PLAN'));
            obj.UI.Readiness=uibutton(g,'Text','Check / apply analysis plan','ButtonPushedFcn',@(~,~)obj.runAnalysis(true));
            obj.UI.Run=uibutton(g,'Text','Run selected analysis','ButtonPushedFcn',@(~,~)obj.runAnalysis(false));
            uilabel(g,'Text','Results and validity are stored under Evidence.');
            text=uitextarea(g,'Editable','off','Value',{'No grid, velocity, physical dimensions or limits are invented.'; ...
                'Zero velocity must be entered explicitly for prescribed rest.'; ...
                'MR is signed dc/dz; wheel rate includes the geometric term when evaluable.'; ...
                'Search uses this same explicit travel/velocity plan.'}); text.Layout.Column=[1 2];
        end
        function synthesisPage(obj)
            g=uigridlayout(obj.UI.SynthesisPanel,[8,1]); g.RowHeight={32,150,32,130,32,120,150,34}; g.Scrollable='on';
            b=obj.bar(g,{'1x','1x','1x'});
            uibutton(b,'Text','Add target','ButtonPushedFcn',@(~,~)obj.addRow('Targets'));
            uibutton(b,'Text','Remove selected target','ButtonPushedFcn',@(~,~)obj.removeRow('Targets'));
            obj.UI.Composite=uicheckbox(b,'Text','Explicit composite SOFT score','Value',false,'ValueChangedFcn',@(~,~)obj.mark('SEARCH'));
            obj.UI.Targets=uitable(g,'ColumnName',{'ID','Metric','Family','Source ID','Type','HARD / SOFT','x [mm]', ...
                'Value','Tolerance','Lower','Upper','Scale','Weight','Value unit','Source note','Scale justification'}, ...
                'ColumnEditable',true,'CellEditCallback',@(~,~)obj.mark('SEARCH'));
            b=obj.bar(g,{'1x','1x'});
            uibutton(b,'Text','Add coordinate declaration','ButtonPushedFcn',@(~,~)obj.addRow('Variables'));
            uibutton(b,'Text','Remove selected declaration','ButtonPushedFcn',@(~,~)obj.removeRow('Variables'));
            obj.UI.Variables=uitable(g,'ColumnName',{'ID','Point / mechanical source ID','Axis / native binding','FIXED / RANGE / FREE','Value', ...
                'Bounds','Tolerance','Availability','Source kind','Source note','Unit'}, ...
                'ColumnEditable',true,'CellEditCallback',@(~,~)obj.mark('SEARCH'));
            b=obj.bar(g,{'1x','1x'});
            uibutton(b,'Text','Add nominal constraint','ButtonPushedFcn',@(~,~)obj.addRow('Constraints'));
            uibutton(b,'Text','Remove selected constraint','ButtonPushedFcn',@(~,~)obj.removeRow('Constraints'));
            obj.UI.Constraints=uitable(g,'ColumnName',{'ID','Point ID','Type','Strength','XYZ [mm]', ...
                'Xmin Xmax Ymin Ymax Zmin Zmax [mm]','Tolerance [mm]','Source note','Corner'}, ...
                'ColumnEditable',true,'CellEditCallback',@(~,~)obj.mark('SEARCH'));
            obj.UI.Options=uitable(g,'ColumnName',{'Native search control','Value (blank uses native default)'}, ...
                'ColumnEditable',[false true],'CellEditCallback',@(~,~)obj.mark('SEARCH'));
            b=obj.bar(g,{'1x','1x'});
            obj.UI.ApplySearch=uibutton(b,'Text','Apply synthesis / show readiness','ButtonPushedFcn',@(~,~)obj.applySearch());
            obj.UI.Search=uibutton(b,'Text','Run fixed-suspension synthesis','ButtonPushedFcn',@(~,~)obj.runSearch());
        end
        function evidencePage(obj)
            g=uigridlayout(obj.UI.EvidencePanel,[5,2]); g.RowHeight={34,125,180,270,100}; g.Scrollable='on';
            b=obj.bar(g,{'1x',80,80,'1x',150}); b.Layout.Column=[1 2];
            obj.UI.ResultPicker=uidropdown(b,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Candidate=uispinner(b,'Limits',[1 Inf],'Value',1,'Step',1,'Tooltip','Stored candidate index', ...
                'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Sample=uispinner(b,'Limits',[1 Inf],'Value',1,'Step',1,'Tooltip','Stored motion sample index', ...
                'ValueChangedFcn',@(~,~)obj.render());
            keys={'COMPRESSION_MM','LENGTH_MM','ROCKER_DEG','MOTION_RATIO','INSTALLATION_RATIO', ...
                'SPRING_N','SPRING_WHEEL_N','DAMPER_N','DAMPER_WHEEL_N','RATE_N_MM','ELASTIC_N_MM','GEOMETRIC_N_MM'};
            labels={'Damper compression [mm]','Damper length [mm]','Rocker angle [deg]','Signed motion ratio [1]', ...
                'Installation ratio [1]','Spring axial force [N]','Spring wheel resistance [N]', ...
                'Damper axial resistance [N]','Damper wheel resistance [N]','Total wheel rate [N/mm]', ...
                'Elastic wheel rate [N/mm]','Geometric wheel rate [N/mm]'};
            obj.UI.Metric=uidropdown(b,'Items',labels,'ItemsData',keys,'Value','COMPRESSION_MM', ...
                'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Adopt=uibutton(b,'Text','Adopt candidate','ButtonPushedFcn',@(~,~)obj.adopt());
            obj.UI.Candidates=uitable(g,'ColumnName',{'Candidate','Eligible','Score','HARD','Classification','Reason'});
            obj.UI.Candidates.Layout.Column=[1 2];
            obj.UI.Rows=uitable(g,'ColumnName',{'Sample','Travel [mm]','Length [mm]','Compression [mm]','Rocker [deg]', ...
                'Signed MR','Spring axial [N]','Spring wheel [N]','Damper axial [N]','Total rate [N/mm]', ...
                'Actuation','MR validity','Mechanical validity / limits','Failure'}); obj.UI.Rows.Layout.Column=[1 2];
            obj.UI.Rows.ColumnWidth={65,105,105,140,115,100,130,140,140,160,140,230,600,300};
            obj.Axes=uiaxes(g); obj.CurveAxes=uiaxes(g);
            axtoolbar(obj.Axes,{'rotate','pan','zoomin','zoomout','restoreview','datacursor'});
            obj.UI.Diagnostics=uitextarea(g,'Editable','off'); obj.UI.Diagnostics.Layout.Column=[1 2];
        end
        function pickCorner(obj)
            if obj.hasDraft()
                obj.UI.Scope.Value=char(obj.Corner); obj.fail(MException('fsd:ui:UnappliedDraft','Apply drafts before selecting another corner.')); return;
            end
            obj.Corner=string(obj.UI.Scope.Value); obj.UI.Travel.Value=''; obj.UI.Velocity.Value='';
            obj.UI.Composite.Value=false; obj.SolverOptions=struct(); obj.DrawnProject=[]; obj.refresh();
        end
        function showPage(obj)
            for name=["Configuration","Analysis","Synthesis","Evidence"]
                obj.UI.(name+"Panel").Visible=matlab.lang.OnOffSwitchState(name==string(obj.UI.Pages.Value));
            end
            obj.render();
        end
        function loadConfiguration(obj)
            resources=obj.Controller.Project.definition.resources; a=[]; m=[];
            for value=resources.actuations', if value{1}.cornerId==obj.Corner, a=value{1}; end, end
            for value=resources.mechanicals', if value{1}.cornerId==obj.Corner, m=value{1}; end, end
            [p,rows,c,r]=fsdui.actuationRows(a,m);
            obj.UI.Points.Data=p; obj.UI.Mechanics.Data=rows; obj.UI.Compression.Data=c; obj.UI.Rebound.Data=r;
            obj.UI.Mechanical.Value=~isempty(m);
            if ~isempty(a)
                obj.UI.Architecture.Value=char(a.actuationType); obj.UI.Body.Value=char(a.suspensionAttachment.body);
                obj.UI.Mode.Value=char(a.rocker.orientationMode);
            else
                obj.UI.Architecture.Value='UNSELECTED'; obj.UI.Body.Value='UNSELECTED'; obj.UI.Mode.Value='UNSELECTED';
            end
            if ~isempty(m), obj.UI.Law.Value=char(m.damper.modelType); else, obj.UI.Law.Value='UNSELECTED'; end
            registered=any(cellfun(@(g)g.cornerId==obj.Corner,resources.geometries));
            states=["MISSING","REGISTERED"];
            obj.UI.GeometryStatus.Text=char(obj.Corner+" | geometry "+states(1+registered)+ ...
                " | actuation "+states(1+~isempty(a))+" | coilover "+states(1+~isempty(m))+ ...
                " | revision "+obj.Controller.Project.definition.revision);
        end
        function loadSearch(obj,restore)
            previous=obj.Definition; obj.Definition=[]; scenarios=obj.Controller.Project.definition.scenarios;
            for s=scenarios'
                if s{1}.definition.id=="UI_ACT_SEARCH_"+obj.Corner, obj.Definition=s{1}.definition; break; end
            end
            [t,p,c]=fsdui.actuationSearchRows(obj.Definition);
            obj.UI.Targets.Data=t; obj.UI.Variables.Data=p; obj.UI.Constraints.Data=c;
            names={'maxEvaluations';'maxIterations';'initialStep';'minimumStep';'stepReduction';'stopAtScore';'scoreImprovement'};
            options=[names,repmat({''},numel(names),1)];
            if ~isempty(obj.Definition)
                obj.UI.Composite.Value=obj.Definition.specification.definitionSI.compositeScore;
                for j=1:numel(names)
                    if isfield(obj.Definition.options,names{j}), options{j,2}=obj.Definition.options.(names{j}); end
                end
                if ~obj.PlanDirty && (restore || ~isequaln(previous,obj.Definition))
                    obj.UI.Travel.Value=n(1000*obj.Definition.plan.travel_m);
                    obj.SolverOptions=struct();
                    if isfield(obj.Definition.plan,'solverOptions'), obj.SolverOptions=obj.Definition.plan.solverOptions; end
                    if isfield(obj.Definition.plan,'wheelVelocity_m_per_s'), obj.UI.Velocity.Value=n(1000*obj.Definition.plan.wheelVelocity_m_per_s); end
                end
            end
            obj.UI.Options.Data=options;
        end
        function loadAnalysisPlan(obj)
            % Recover declared plans, never infer a grid/velocity from results.
            obj.UI.Travel.Value=''; obj.UI.Velocity.Value=''; obj.SolverOptions=struct();
            scenarios=obj.Controller.Project.definition.scenarios; chosen=[];
            for s=scenarios'
                d=s{1}.definition;
                if ismember(d.engine,["ACTUATION","MECHANICAL"]) && ...
                        d.id=="UI_"+d.engine+"_"+obj.Corner
                    chosen=d;
                    if d.engine==string(obj.UI.Engine.Value), break; end
                end
            end
            if isempty(chosen), return; end
            obj.UI.Engine.Value=char(chosen.engine);
            obj.UI.Travel.Value=n(1000*chosen.plan.travel_m); obj.UI.Velocity.Value='';
            obj.SolverOptions=struct();
            if isfield(chosen.plan,'solverOptions'), obj.SolverOptions=chosen.plan.solverOptions; end
            if isfield(chosen.plan,'wheelVelocity_m_per_s')
                obj.UI.Velocity.Value=n(1000*chosen.plan.wheelVelocity_m_per_s);
            end
        end
        function plan=plan(obj,mechanical)
            plan=fsdui.actuationPlan(obj.UI.Travel.Value,obj.UI.Velocity.Value,mechanical);
            plan.solverOptions=obj.SolverOptions;
        end
        function r=selectedResult(obj)
            r=[]; values=obj.Controller.Project.definition.results;
            for value=values', if string(value{1}.id)==string(obj.UI.ResultPicker.Value), r=value{1}; return; end, end
        end
        function render(obj)
            if isempty(obj.Controller) || obj.Controller.Busy || ~isgraphics(obj.Tab), return; end
            parent=obj.Tab.Parent;
            if parent.SelectedTab~=obj.Tab || string(obj.UI.Pages.Value)~="Evidence", return; end
            r=obj.selectedResult();
            if isempty(r)
                cla(obj.Axes); cla(obj.CurveAxes); obj.UI.Rows.Data=cell(0,14); obj.UI.Candidates.Data=cell(0,6);
                obj.RenderKey=[];
                obj.UI.Adopt.Enable='off'; obj.UI.Diagnostics.Value={'No stored actuation/mechanical result for this corner.'}; return;
            end
            key={r.id,r.identity,obj.UI.Candidate.Value,obj.UI.Sample.Value,obj.UI.Metric.Value,obj.Controller.Epoch};
            if isequaln(key,obj.RenderKey), return; end
            try
                index=1; comparison=1;
                obj.UI.Candidates.Data=cell(0,6);
                if r.engine=="ACTUATION_SYNTHESIS"
                    index=obj.UI.Candidate.Value; comparison=unique([1,index]); records=r.nativePayload.search.records;
                    rows=cell(numel(records),6);
                    for j=1:numel(records)
                        q=records{j}; rows(j,:)={j,q.eligible,q.score,char(q.hardFeasibility),char(q.classification),char(q.reason)};
                    end
                    obj.UI.Candidates.Data=rows;
                end
                e=fsdui.actuationEvidence(r,index); obj.UI.Rows.Data=e.rows;
                report=fsd.project.resultCompatibility(r,obj.Controller.Project);
                obj.UI.Diagnostics.Value=cellstr(["Result "+r.id+" | "+report.status+" | executed revision "+r.projectRevision; ...
                    report.diagnostics;e.diagnostics]);
                canAdopt=r.engine=="ACTUATION_SYNTHESIS" && ...
                    ismember(report.status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"]);
                if canAdopt, canAdopt=r.nativePayload.search.records{index}.eligible; end
                obj.UI.Adopt.Enable=matlab.lang.OnOffSwitchState(canAdopt);
                ax=obj.CurveAxes; cla(ax); hold(ax,'on');
                for j=comparison
                    curve=fsdui.actuationEvidence(r,j);
                    if ~isempty(curve.travel_mm)
                        plot(ax,curve.travel_mm,curve.values.(string(obj.UI.Metric.Value)),'o-', ...
                            'DisplayName',"Stored E"+j);
                    end
                end
                hold(ax,'off'); grid(ax,'on'); xlabel(ax,'Achieved wheel travel [mm]');
                label=string(obj.UI.Metric.Items); keyValues=string(obj.UI.Metric.ItemsData);
                ylabel(ax,label(keyValues==string(obj.UI.Metric.Value))); title(ax,'Stored seed / selected candidate; NaN gaps preserved');
                if ~isempty(ax.Children), legend(ax,'Location','best','Interpreter','none'); end
                ax=obj.Axes; cla(ax); sample=obj.UI.Sample.Value;
                if ~isempty(e.sweep) && sample<=numel(e.sweep.results) && sample==fix(sample) && e.sweep.results(sample).converged
                    h=fsd.kinematics.plotBumpResult(e.geometry,e.sweep.results(sample).sourceResult,ax);
                    set(h.static.labels,'Visible','off');
                    fsd.kinematics.plotActuationResult(e.actuation,e.sweep.results(sample),ax);
                    obj.scaleAxes(ax); title(ax,"Stored sample "+sample+" | "+report.status,'Interpreter','none');
                else
                    title(ax,'Selected stored pose unavailable; no replacement pose inferred');
                end
                obj.RenderKey=key; obj.updateStatus();
            catch cause
                cla(obj.Axes); cla(obj.CurveAxes); obj.UI.Rows.Data=cell(0,14); obj.UI.Adopt.Enable='off';
                obj.RenderKey=[];
                obj.UI.Diagnostics.Value=cellstr("Selection unavailable: "+string(cause.identifier)+": "+string(cause.message));
                obj.fail(cause);
            end
        end
        function scaleAxes(~,ax)
            for type=["line","scatter"]
                handles=findall(ax,'Type',type);
                for h=handles'
                    h.XData=1000*h.XData; h.YData=1000*h.YData; h.ZData=1000*h.ZData;
                end
            end
            xlabel(ax,'X [mm]'); ylabel(ax,'Y [mm]'); zlabel(ax,'Z [mm]'); axis(ax,'equal');
        end
        function mark(obj,kind)
            switch string(kind)
                case "CONFIG", obj.ConfigDirty=true;
                case "PLAN", obj.PlanDirty=true;
                case "SEARCH", obj.SearchDirty=true;
            end
            obj.Draft(); obj.updateStatus();
        end
        function addCurve(obj,name)
            rows=obj.UI.(name).Data; rows(end+1,:)={'',''}; obj.UI.(name).Data=rows; obj.mark('CONFIG');
        end
        function removeCurve(obj,name)
            table=obj.UI.(name); selected=table.Selection;
            if ~isempty(selected)
                rows=table.Data; rows(unique(selected(:,1)),:)=[]; table.Selection=[]; table.Data=rows; obj.mark('CONFIG');
            end
        end
        function addRow(obj,name)
            rows=obj.UI.(name).Data; id=string(size(rows,1)+1);
            switch name
                case 'Targets', row={char("TARGET_"+id),'MOTION_RATIO','ACTUATION',char("ACT_"+obj.Corner),'POINT_TARGET','SOFT','','','','','','','','1','',''};
                case 'Variables', row={char("VARIABLE_"+id),char(obj.Corner+"_DAMPER_CHASSIS"),'Y','FREE','','','','UNSPECIFIED','UNSPECIFIED','','mm'};
                case 'Constraints', row={char("CONSTRAINT_"+id),'','HARDPOINT_FIXED','HARD','','','','',char(obj.Corner)};
            end
            rows(end+1,:)=row; obj.UI.(name).Data=rows; obj.mark('SEARCH');
        end
        function removeRow(obj,name)
            table=obj.UI.(name); selected=table.Selection;
            if ~isempty(selected)
                rows=table.Data; rows(unique(selected(:,1)),:)=[]; table.Selection=[]; table.Data=rows; obj.mark('SEARCH');
            end
        end
        function fail(obj,cause)
            obj.UI.Status.Value=cellstr(string(cause.identifier)+": "+string(cause.message));
        end
        function b=bar(~,parent,widths)
            b=uigridlayout(parent,[1,numel(widths)]); b.ColumnWidth=widths; b.Padding=0;
        end
    end
end
function text=n(v)
text=char(strjoin(compose('%.17g',v(:)),' '));
end
