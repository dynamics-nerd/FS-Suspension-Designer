classdef View < handle
    %VIEW Native MATLAB controls; callbacks adapt data and delegate to Controller.
    properties (SetAccess=private)
        Figure
        Controller
        UI = struct()
        Tabs
        GeometryAxes
        CurveAxes
        ResultAxes
        ResultCurveAxes
        Packaging
        Actuation
        GlobalStatic
        Tires
    end
    properties (Access=private)
        PollTimer
        DrawnProject = []
        DrawnCompatibility = {}
        GeometryPlotPending = true
        AnalysisPlotPending = true
        ResultPlotPending = true
        SeedRows
        Definition
        ActiveGroup = "Wheel / References"
        ActiveSide = "FL"
        DrawnSearchScope = "FL"
        DraftPages = strings(0,1)
        PendingCommit = ""
        PendingActuation = false
        Closing = false
    end
    methods
        function obj=View(fig)
            obj.Figure=fig; obj.Controller=fsdui.Controller();
            screen=get(groot,'ScreenSize');
            fig.Name='FS Suspension Designer | v0.22.0';
            fig.Position=[40 40 min(1280,screen(3)-80) min(820,screen(4)-100)];
            theme(fig,'light'); % Explicit local theme; never change the user's MATLAB preference.
            fig.Color=[.96 .97 .98]; fig.CloseRequestFcn=@(~,~)obj.close();
            fig.DeleteFcn=@(~,~)obj.figureDeleted();
            obj.build(); obj.Tabs.SelectionChangedFcn=@(~,~)obj.drawSelectedTab();
            obj.Controller.Changed=@()obj.refresh(); obj.refresh();
            obj.PollTimer=timer('ExecutionMode','fixedSpacing','Period',.3, ...
                'BusyMode','drop','TimerFcn',@(~,~)obj.Controller.poll());
            start(obj.PollTimer);
        end
        function invoke(obj,action,args)
            if obj.Closing || isempty(obj.Controller), return; end
            try
                if nargin<3, args=struct(); end
                action=string(action); allowed=strings(0,1);
                switch action
                    case "VEHICLE", allowed="Vehicle";
                    case "DECISIONS", allowed="Geometry";
                    case "SPECIFICATION", allowed=["Targets";"Synthesis";"Analysis"];
                    case "BUMP", allowed="Analysis";
                    case {"PACKAGING_DEFINITION","PACKAGING_DEMO"}, allowed="Packaging";
                    case {"ACTUATION_CONFIG","ACTUATION_RUN","ACTUATION_ADOPT"}, allowed="Actuation";
                    case "GLOBAL_CONFIG", allowed="Global static";
                    case {"TIRE_CONFIG","TIRE_ASSIGN","TIRE_STUDY_CONFIG","TIRE_RUN"}
                        allowed="Tires"; obj.Tires.prepareAction(action);
                    case {"NEW","LOAD","DEMO"}, allowed=obj.DraftPages;
                end
                actuationAction=startsWith(action,'ACTUATION_') || ...
                    (action=="SPECIFICATION" && ismember(string(args.definition.engine),["ACTUATION","MECHANICAL","ACTUATION_SYNTHESIS"])) || ...
                    (ismember(action,["SYNTHESIS","READINESS"]) && startsWith(string(args.scenarioId),'UI_ACT_SEARCH_'));
                if actuationAction
                    allowed="Actuation"; obj.Actuation.prepareAction(action,args);
                end
                if ~isempty(setdiff(obj.DraftPages,allowed))
                    error('fsd:ui:UnappliedDraft','Apply drafts on %s before running this action; this prevents silent data loss.',strjoin(setdiff(obj.DraftPages,allowed),', '));
                end
                async=obj.UI.Async.Value;
                if async && (isempty(obj.Controller.Pool) || ~isvalid(obj.Controller.Pool))
                    answer=uiconfirm(obj.Figure,'No process worker is available. Choose explicitly how to execute this operation.', ...
                        'Execution mode','Options',{'Cancel','Start worker','Run synchronously'},'DefaultOption',1,'CancelOption',1);
                    if string(answer)=="Cancel", return;
                    elseif string(answer)=="Start worker", obj.Controller.enableWorker();
                    else, async=false; obj.UI.Async.Value=false;
                    end
                end
                assert(~obj.Controller.Busy,'fsd:ui:Busy','Wait for the current operation before starting another.');
                obj.PendingCommit=action; obj.PendingActuation=actuationAction; obj.Controller.run(action,args,async);
            catch cause, obj.showError(cause);
            end
        end
        function refresh(obj)
            if isempty(obj.Controller), return; end
            if obj.Closing || ~isgraphics(obj.Figure)
                if ~obj.Controller.Busy, obj.shutdown(); end
                return;
            end
            c=obj.Controller; obj.UI.Status.Text=char(c.Status);
            obj.Actuation.updateStatus();
            obj.GlobalStatic.updateStatus();
            obj.UI.Cancel.Enable=matlab.lang.OnOffSwitchState(c.Busy);
            if c.Busy, return; end
            if strlength(obj.PendingCommit)>0 && startsWith(c.Status,obj.PendingCommit+" complete")
                if obj.PendingActuation
                    obj.Actuation.committed();
                    if ~obj.Actuation.hasDraft(), obj.DraftPages=setdiff(obj.DraftPages,"Actuation"); end
                else
                switch obj.PendingCommit
                    case {"TIRE_CONFIG","TIRE_ASSIGN","TIRE_STUDY_CONFIG"}
                        obj.Tires.committed(obj.PendingCommit);
                        if ~obj.Tires.hasDraft(), obj.DraftPages=setdiff(obj.DraftPages,"Tires"); end
                    case "VEHICLE", obj.DraftPages=setdiff(obj.DraftPages,"Vehicle");
                    case "DECISIONS", obj.DraftPages=setdiff(obj.DraftPages,"Geometry");
                    case "SPECIFICATION", obj.DraftPages=setdiff(obj.DraftPages,["Targets";"Synthesis";"Analysis"]);
                    case "BUMP", obj.DraftPages=setdiff(obj.DraftPages,"Analysis");
                    case {"PACKAGING_DEFINITION","PACKAGING_DEMO"}
                        obj.DraftPages=setdiff(obj.DraftPages,"Packaging"); obj.Packaging.committed();
                    case "GLOBAL_CONFIG", obj.DraftPages=setdiff(obj.DraftPages,"Global static"); obj.GlobalStatic.committed();
                    case {"NEW","LOAD","DEMO"}, obj.DraftPages=strings(0,1); obj.Actuation.resetDrafts(); obj.GlobalStatic.resetDrafts(); obj.Tires.resetDrafts();
                end
                end
                obj.PendingCommit="";
            end
            p=c.Project;
            obj.UI.Summary.Value={char("Project "+p.id+" | revision "+p.definition.revision+" | software "+fsd.version()); ...
                char("File: "+c.File); char("Unsaved configuration/results: "+string(c.Dirty)); ...
                'Readiness ≠ nominal validity ≠ sampled feasibility. No manufacturing certification.'; ...
                'Edits are drafts until Apply. Blank numeric inputs mean unknown, not zero.'; ...
                'Only open trusted MAT files. Save uses the native project envelope.'};
            projectChanged=~isequaln(p,obj.DrawnProject);
            compatibilityChanged=~isequaln(c.Compatibility,obj.DrawnCompatibility);
            if projectChanged
                obj.fillVehicle(); obj.loadDecisions();
                updatePlan=ismember(c.LastAction,["REFERENCE_TARGETS","SPECIFICATION","LOAD","DEMO","NEW"]);
                obj.fillSearch(updatePlan); obj.fillResults();
                obj.DrawnProject=p; obj.drawGeometry();
            end
            if ~isempty(c.LastError)
                obj.UI.Diagnostics.Value=cellstr(string(c.LastError.identifier)+": "+string(c.LastError.message));
                obj.UI.SearchDiagnostics.Value=obj.UI.Diagnostics.Value;
            elseif isstruct(c.LastValue) && isfield(c.LastValue,'status')
                obj.UI.Diagnostics.Value=cellstr(string(jsonencode(c.LastValue)));
                obj.UI.SearchDiagnostics.Value=obj.UI.Diagnostics.Value;
            elseif isstruct(c.LastValue) && isfield(c.LastValue,'engine') && c.LastValue.engine=="PARAMETRIC_SEED"
                s=c.LastValue.nativePayload.seed;
                obj.UI.Diagnostics.Value=cellstr(["Nominal: "+s.nominalStatus;"BUMP: "+s.sampledStatus; ...
                    "Consistency: "+string(jsonencode(s.consistency));s.diagnostics]);
            end
            if c.LastAction=="COMPATIBILITY" && iscell(c.LastValue)
                rows=obj.UI.Ledger.Data;
                for k=1:min(numel(c.LastValue),size(rows,1)), rows{k,5}=char(c.LastValue{k}.status); end
                obj.UI.Ledger.Data=rows;
            end
            if projectChanged || compatibilityChanged
                obj.drawAnalysis(); obj.DrawnCompatibility=c.Compatibility;
            end
            obj.Packaging.refresh();
            obj.Actuation.refresh();
            obj.GlobalStatic.refresh();
            obj.Tires.refresh();
        end
        function close(obj)
            if obj.Closing || isempty(obj.Controller), return; end
            if obj.Controller.Busy
                uialert(obj.Figure,'An operation still owns its resources. Request cancellation and wait for completion before closing.', ...
                    'Operation active','Icon','warning'); return;
            end
            if obj.Controller.Dirty
                answer=uiconfirm(obj.Figure,'Close without saving current changes?','Unsaved project', ...
                    'Options',{'Keep open','Close without saving'},'DefaultOption',1,'CancelOption',1);
                if string(answer)~="Close without saving", return; end
            end
            figure=obj.Figure; obj.shutdown(); delete(figure);
        end
        function shutdown(obj)
            % Explicit idle-only shutdown also used by automated UI tests.
            if isempty(obj.Controller), return; end
            assert(~obj.Controller.Busy,'fsd:ui:Busy','Wait for worker completion before shutdown.');
            obj.Closing=true;
            if isgraphics(obj.Figure), obj.Figure.Visible='off'; end
            if ~isempty(obj.PollTimer) && isvalid(obj.PollTimer), stop(obj.PollTimer); delete(obj.PollTimer); end
            obj.PollTimer=[];
            obj.Controller.Changed=[]; obj.Controller.close();
            if isfield(obj.UI,'Sample') && isgraphics(obj.UI.Sample), obj.UI.Sample.UserData=[]; end
            if ~isempty(obj.Packaging) && isvalid(obj.Packaging), obj.Packaging.release(); end
            if ~isempty(obj.Actuation) && isvalid(obj.Actuation), obj.Actuation.release(); end
            if ~isempty(obj.GlobalStatic) && isvalid(obj.GlobalStatic), obj.GlobalStatic.release(); end
            if ~isempty(obj.Tires) && isvalid(obj.Tires), obj.Tires.release(); end
            obj.DrawnProject=[]; obj.DrawnCompatibility={}; obj.Definition=[]; obj.SeedRows=[];
            obj.Controller=[]; obj.UI=struct(); obj.Tabs=[];
            obj.GeometryAxes=[]; obj.CurveAxes=[]; obj.ResultAxes=[]; obj.ResultCurveAxes=[];
            obj.Figure=[];
        end
    end
    methods (Access=private)
        function figureDeleted(obj)
            obj.Closing=true;
            obj.Figure=[];
            if isempty(obj.Controller), return; end
            if obj.Controller.Busy
                obj.Controller.cancel(); % Timer retains ownership until completion.
            else
                obj.shutdown();
            end
        end
        function build(obj)
            root=uigridlayout(obj.Figure,[4 1]); root.RowHeight={64,34,'1x',60}; root.Padding=[16 12 16 12];
            header=uigridlayout(root,[1 2]); header.ColumnWidth={'1x',350};
            uilabel(header,'Text','FS  /  SUSPENSION DESIGNER','FontSize',23,'FontWeight','bold','FontColor',[.08 .17 .25]);
            uilabel(header,'Text','v0.22  •  TIRE MODELS FOUNDATION','HorizontalAlignment','right','FontColor',[.22 .34 .42]);
            bar=uigridlayout(root,[1 2]); bar.ColumnWidth={'1x',170}; bar.Padding=0;
            obj.UI.Status=uilabel(bar,'Text','Ready','FontWeight','bold');
            obj.UI.Cancel=uibutton(bar,'Text','Request cancellation','ButtonPushedFcn',@(~,~)obj.Controller.cancel());
            obj.Tabs=uitabgroup(root);
            names=["Project","Vehicle","Geometry","Analysis","Targets","Synthesis","Results","Packaging","Actuation","GlobalStatic","Tires"];
            for name=names, obj.UI.(name+"Tab")=uitab(obj.Tabs,'Title',name); end
            obj.UI.GlobalStaticTab.Title='Global static';
            footer=uitextarea(root,'Editable','off','Value', ...
                {'EXPERIMENTAL ENGINEERING SOFTWARE — not suitable for manufacturing a real suspension.'; ...
                'SI internally • +X rearward / +Y rightward / +Z upward • illustrative inputs are ASSUMED, never recommended FS values.'});
            footer.BackgroundColor=[.99 .95 .87];
            footer.FontColor=[.18 .20 .22];
            obj.projectPage(); obj.vehiclePage(); obj.geometryPage(); obj.analysisPage();
            obj.targetsPage(); obj.synthesisPage(); obj.resultsPage();
            obj.Packaging=fsdui.PackagingView(obj.UI.PackagingTab,obj.Controller,@(action,args)obj.invoke(action,args),@()obj.draft());
            obj.Actuation=fsdui.ActuationView(obj.UI.ActuationTab,obj.Controller,@(action,args)obj.invoke(action,args),@()obj.draft());
            obj.GlobalStatic=fsdui.GlobalStaticView(obj.UI.GlobalStaticTab,obj.Controller,@(action,args)obj.invoke(action,args),@()obj.draft());
            obj.Tires=fsdui.TiresView(obj.UI.TiresTab,obj.Controller,@(action,args)obj.invoke(action,args),@()obj.draft());
        end
        function projectPage(obj)
            g=uigridlayout(obj.UI.ProjectTab,[6 1]); g.RowHeight={38,38,38,130,'1x',40};
            bar=obj.bar(g,{'1x',180,180,180});
            obj.UI.ProjectId=uieditfield(bar,'text','Value','MY_PROJECT','Tooltip','Canonical ID: uppercase letters, digits and underscore.');
            uibutton(bar,'Text','New empty project','ButtonPushedFcn',@(~,~)obj.newProject());
            uibutton(bar,'Text','Illustrative inputs','ButtonPushedFcn',@(~,~)obj.demo());
            uibutton(bar,'Text','Open trusted MAT…','ButtonPushedFcn',@(~,~)obj.openFile());
            bar=obj.bar(g,{180,180,180,'1x'});
            uibutton(bar,'Text','Save','ButtonPushedFcn',@(~,~)obj.saveFile(false));
            uibutton(bar,'Text','Save as…','ButtonPushedFcn',@(~,~)obj.saveFile(true));
            uibutton(bar,'Text','Validate project','ButtonPushedFcn',@(~,~)obj.invoke('VALIDATE'));
            obj.UI.Async=uicheckbox(bar,'Text','Asynchronous execution (process worker)','Value',true);
            bar=obj.bar(g,{220,'1x'});
            uibutton(bar,'Text','Start / reuse process worker','ButtonPushedFcn',@(~,~)obj.startWorker());
            uilabel(bar,'Text','One snapshot operation at a time. Search stays deterministic; no parfor acceleration.');
            obj.UI.Summary=uitextarea(g,'Editable','off');
            uitextarea(g,'Editable','off','Value',{'WORKFLOW'; ...
                '1  Declare vehicle data and provenance. No geometry is invented from mass.'; ...
                '2  Apply the 28 decisions per corner, or an explicitly symmetric FRONT pair.'; ...
                '3  Check readiness, then Build and adopt. Inspect hardpoints and 3D.'; ...
                '4  Set an explicit BUMP grid and run it. Inspect convergence and gaps.'; ...
                '5  Declare HARD/SOFT targets and bounded variables. Apply search configuration.'; ...
                '6  Run native synthesis, compare stored candidates, explicitly adopt if appropriate.'; ...
                '7  Save and reopen the native MAT project, including its original result ledger.'; ...
                'The illustrative path requires explicit clicks for generation, reference BUMP and synthesis.'});
            uilabel(g,'Text','No automatic optimal targets, CAD clearance, rule certification, dynamic tire model or Adams export.');
        end
        function vehiclePage(obj)
            g=uigridlayout(obj.UI.VehicleTab,[3 1]); g.RowHeight={38,'1x',46};
            bar=obj.bar(g,{180,160,180,180,'1x'});
            uilabel(bar,'Text','Mass inclusion convention');
            obj.UI.MassConvention=uidropdown(bar,'Items',{'UNSPECIFIED','INCLUDES_DRIVER','EXCLUDES_DRIVER'},'ValueChangedFcn',@(~,~)obj.draft());
            obj.UI.FrontArchitecture=uidropdown(bar,'Items',{'UNSELECTED','DOUBLE_WISHBONE'},'ValueChangedFcn',@(~,~)obj.draft());
            obj.UI.RearArchitecture=uidropdown(bar,'Items',{'UNSELECTED','DOUBLE_WISHBONE'},'ValueChangedFcn',@(~,~)obj.draft());
            uibutton(bar,'Text','Apply vehicle','ButtonPushedFcn',@(~,~)obj.applyVehicle());
            obj.UI.VehicleTable=uitable(g,'ColumnName',obj.parameterColumns(),'ColumnEditable',[false true true false true true true true true true true], ...
                'CellEditCallback',@(~,~)obj.draft(),'ColumnWidth',{210,95,120,55,95,110,95,250,130,160,300});
            uilabel(g,'Text','RULE / TARGET are not physical inputs. No range midpoint. Extra JSON holds ruleReference / derivationReference; provenance is preserved.');
        end
        function geometryPage(obj)
            g=uigridlayout(obj.UI.GeometryTab,[5 2]); g.RowHeight={36,36,'1x',110,150}; g.ColumnWidth={'1.2x','1x'};
            bar=obj.bar(g,{80,100,120,140,'1x'}); bar.Layout.Column=[1 2];
            uilabel(bar,'Text','Build scope'); obj.UI.Scope=uidropdown(bar,'Items',{'FRONT','FL','FR','RL','RR'},'ValueChangedFcn',@(~,~)obj.changeScope());
            obj.UI.Symmetry=uidropdown(bar,'Items',{'NONE','MIRROR_FL'},'ValueChangedFcn',@(~,~)obj.draft());
            obj.UI.Side=uidropdown(bar,'Items',{'FL','FR'},'ValueChangedFcn',@(~,~)obj.changeSide());
            uilabel(bar,'Text','FRONT NONE = two independent sets; MIRROR_FL = explicit reflection.');
            bar=obj.bar(g,{180,120,180,'1x'}); bar.Layout.Column=[1 2];
            obj.UI.Group=uidropdown(bar,'Items',{'Wheel / References','Upright','UCA','LCA','Tie Rod'},'ValueChangedFcn',@(~,~)obj.changeGroup());
            uibutton(bar,'Text','Apply decisions','ButtonPushedFcn',@(~,~)obj.applyDecisions());
            uibutton(bar,'Text','Check input readiness','ButtonPushedFcn',@(~,~)obj.checkReadiness());
            obj.UI.Build=uibutton(bar,'Text','Build and adopt geometry','ButtonPushedFcn',@(~,~)obj.buildGeometry());
            obj.UI.DecisionTable=uitable(g,'ColumnName',obj.parameterColumns(),'ColumnEditable',[false true true false true true true true false false true], ...
                'CellEditCallback',@(~,~)obj.seedDraft(),'ColumnWidth',{190,90,100,50,80,110,95,230,80,90,250});
            obj.GeometryAxes=uiaxes(g); obj.GeometryAxes.Layout.Row=[3 4]; obj.GeometryAxes.Layout.Column=2;
            obj.UI.Diagnostics=uitextarea(g,'Editable','off'); obj.UI.Diagnostics.Layout.Row=4; obj.UI.Diagnostics.Layout.Column=1;
            obj.UI.Hardpoints=uitable(g,'ColumnName',{'Corner / Point','X rear [m]','Y right [m]','Z up [m]'},'ColumnWidth',{'auto',100,100,100});
            obj.UI.Hardpoints.Layout.Row=5; obj.UI.Hardpoints.Layout.Column=[1 2];
            axtoolbar(obj.GeometryAxes,{'rotate','pan','zoomin','zoomout','restoreview','datacursor'});
        end
        function analysisPage(obj)
            g=uigridlayout(obj.UI.AnalysisTab,[5 2]); g.RowHeight={36,38,64,'1x',100}; g.RowSpacing=6;
            bar=obj.bar(g,{120,'1x',150,140,140}); bar.Layout.Column=[1 2];
            uilabel(bar,'Text','BUMP samples [m]'); obj.UI.Travel=uieditfield(bar,'text','Value','','Placeholder','Explicit samples, e.g. -0.01 0 0.01','ValueChangedFcn',@(~,~)obj.draft());
            obj.UI.AnalysisCorner=uidropdown(bar,'Items',{'FRONT','FL','FR','RL','RR'},'ValueChangedFcn',@(~,~)obj.drawAnalysis());
            obj.UI.RunBump=uibutton(bar,'Text','Run BUMP','ButtonPushedFcn',@(~,~)obj.runBump());
            uibutton(bar,'Text','Refresh stored curves','ButtonPushedFcn',@(~,~)obj.drawAnalysis());
            bar=obj.bar(g,{170,'1x',170}); bar.Layout.Column=[1 2];
            uilabel(bar,'Text','Native solver options JSON'); obj.UI.Solver=uieditfield(bar,'text','Value','{}','ValueChangedFcn',@(~,~)obj.draft());
            obj.UI.Metric=uidropdown(bar,'Items',{'camber_rad','toe_rad','bumpSteer_rad','caster_rad','kingpinInclination_rad'},'ValueChangedFcn',@(~,~)obj.drawAnalysis());
            obj.UI.CurveEvidence=uitextarea(g,'Editable','off'); obj.UI.CurveEvidence.Layout.Row=3; obj.UI.CurveEvidence.Layout.Column=1;
            obj.UI.StateEvidence=uitextarea(g,'Editable','off'); obj.UI.StateEvidence.Layout.Row=3; obj.UI.StateEvidence.Layout.Column=2;
            obj.CurveAxes=uiaxes(g); obj.CurveAxes.Layout.Row=4; obj.CurveAxes.Layout.Column=1;
            obj.UI.StatePanel=uipanel(g,'Title','Stored converged sample — check status above'); obj.UI.StatePanel.Layout.Row=4; obj.UI.StatePanel.Layout.Column=2;
            sg=uigridlayout(obj.UI.StatePanel,[2 1]); sg.RowHeight={28,'1x'}; sg.Padding=[6 6 6 6]; sg.RowSpacing=4;
            obj.UI.Sample=uidropdown(sg,'Items',{'No samples'},'ValueChangedFcn',@(~,~)obj.drawState());
            obj.UI.StateAxes=uiaxes(sg);
            obj.UI.AnalysisTable=uitable(g,'ColumnName',{'Result','Corner','Sample','Travel [m]','Converged','Native status','Reliable','rcond'});
            obj.UI.AnalysisTable.Layout.Row=5; obj.UI.AnalysisTable.Layout.Column=[1 2];
        end
        function targetsPage(obj)
            g=uigridlayout(obj.UI.TargetsTab,[4 1]); g.RowHeight={40,60,'1x',90};
            bar=obj.bar(g,{180,180,'1x'});
            uibutton(bar,'Text','Add target row','ButtonPushedFcn',@(~,~)obj.addTarget());
            uibutton(bar,'Text','Remove selected rows','ButtonPushedFcn',@(~,~)obj.removeRows('Targets'));
            uilabel(bar,'Text','BUMP metrics supported by native corner / axle synthesis; RACK remains disabled without a steering workflow.');
            bar=obj.bar(g,{300,'1x'});
            uibutton(bar,'Text','Load illustrative reference targets (NEW BUMP)','ButtonPushedFcn',@(~,~)obj.referenceTargets());
            uilabel(bar,'Text','Explicit software fixture: native reference geometry, not automatic optimal targets.');
            obj.UI.Targets=uitable(g,'ColumnName',{'ID','Metric','Source ID','Corner','Type','Strength','x [m]','Value [rad]','Tolerance [rad]', ...
                'Lower [rad]','Upper [rad]','Scale [rad]','Weight','Source note','Scale justification'}, ...
                'ColumnEditable',true(1,15),'Data',cell(0,15),'CellEditCallback',@(~,~)obj.draft(),'ColumnWidth',repmat({130},1,15));
            uitextarea(g,'Editable','off','Value',{'Native catalog: CAMBER / TOE / BUMP_STEER / CASTER / KPI. Positive toe-in; negative top-in camber.'; ...
                'CURVE_TARGET needs x, value, tolerance; CURVE_BAND needs x, lower, upper. POINT_TARGET / VALUE_BAND / bounds require one x.'; ...
                'No MATLAB expressions. Enter numbers separated by spaces. Weights, normalization and provenance are explicit.'; ...
                'Targets, variables and constraints are committed together with Apply search configuration on Synthesis.'});
        end
        function synthesisPage(obj)
            g=uigridlayout(obj.UI.SynthesisTab,[8 1]); g.RowHeight={38,34,130,34,110,40,40,'1x'}; g.Scrollable='on';
            bar=obj.bar(g,{110,140,220,180,'1x'});
            uilabel(bar,'Text','Search scope'); obj.UI.SearchScope=uidropdown(bar,'Items',{'FL','FR','RL','RR','FRONT'},'ValueChangedFcn',@(~,~)obj.changeSearchScope());
            uibutton(bar,'Text','Apply search configuration','ButtonPushedFcn',@(~,~)obj.applySearch());
            obj.UI.RunSearch=uibutton(bar,'Text','Run native synthesis','ButtonPushedFcn',@(~,~)obj.runSearch());
            uibutton(bar,'Text','Check search readiness','ButtonPushedFcn',@(~,~)obj.searchReadiness());
            bar=obj.bar(g,{180,180,'1x'}); uibutton(bar,'Text','Add variable / FIXED','ButtonPushedFcn',@(~,~)obj.addVariable());
            uibutton(bar,'Text','Remove selected variables','ButtonPushedFcn',@(~,~)obj.removeRows('Variables'));
            uilabel(bar,'Text','Native authorized UCA / LCA chassis coordinates; explicit absolute SI bounds.');
            obj.UI.Variables=uitable(g,'ColumnName',{'ID','Corner','Hardpoint ID','X/Y/Z','Role','Initial [m]','Bounds [m]','FIXED tolerance [m]','Provenance','Note'}, ...
                'ColumnEditable',true(1,10),'Data',cell(0,10),'CellEditCallback',@(~,~)obj.draft());
            bar=obj.bar(g,{180,180,'1x'}); uibutton(bar,'Text','Add nominal constraint','ButtonPushedFcn',@(~,~)obj.addConstraint());
            uibutton(bar,'Text','Remove selected constraints','ButtonPushedFcn',@(~,~)obj.removeRows('Constraints'));
            uilabel(bar,'Text','A nominal box is not CAD clearance or collision checking.');
            obj.UI.Constraints=uitable(g,'ColumnName',{'ID','Corner','Hardpoint ID','Type','Strength','Position XYZ [m]','Box Xmin Xmax Ymin Ymax Zmin Zmax [m]','Tolerance [m]','Note'}, ...
                'ColumnEditable',true(1,9),'Data',cell(0,9),'CellEditCallback',@(~,~)obj.draft());
            bar=obj.bar(g,{190,'1x'}); uilabel(bar,'Text','Native search options JSON');
            obj.UI.SearchOptions=uieditfield(bar,'text','Value','{}','ValueChangedFcn',@(~,~)obj.draft());
            uilabel(g,'Text','Budget: maxEvaluations / maxIterations. Numerical defaults remain those of the audited controller; supplied options are validated natively.');
            obj.UI.SearchDiagnostics=uitextarea(g,'Editable','off','Value',{'No search configured. Inputs and targets must be explicit.'});
        end
        function resultsPage(obj)
            g=uigridlayout(obj.UI.ResultsTab,[6 2]); g.RowHeight={40,'0.6x',40,'0.9x','1.7x',70};
            bar=obj.bar(g,{180,180,180,'1x'}); bar.Layout.Column=[1 2];
            uibutton(bar,'Text','Check compatibility / STALE','ButtonPushedFcn',@(~,~)obj.invoke('COMPATIBILITY'));
            obj.UI.ResultPicker=uidropdown(bar,'Items',{'No synthesis'},'ValueChangedFcn',@(~,~)obj.drawResults());
            obj.UI.ResultMetric=uidropdown(bar,'Items',{'camber_rad','toe_rad','bumpSteer_rad','caster_rad','kingpinInclination_rad'},'ValueChangedFcn',@(~,~)obj.drawResults());
            uilabel(bar,'Text','Historic snapshots are never rewritten; selection/adoption is explicit.');
            obj.UI.Ledger=uitable(g,'ColumnName',{'Result ID','Engine','Revision','Elapsed [s]','Compatibility'},'ColumnWidth',{'auto','auto',80,100,180});
            obj.UI.Ledger.Layout.Column=[1 2];
            bar=obj.bar(g,{160,180,180,'1x'}); bar.Layout.Column=[1 2];
            obj.UI.Candidate=uieditfield(bar,'numeric','Value',1,'Limits',[1 Inf],'RoundFractionalValues','on','ValueChangedFcn',@(~,~)obj.drawResults());
            uibutton(bar,'Text','Inspect / compare with seed','ButtonPushedFcn',@(~,~)obj.drawResults());
            uibutton(bar,'Text','Adopt eligible candidate','ButtonPushedFcn',@(~,~)obj.adopt());
            uibutton(bar,'Text','Restore 3D view','ButtonPushedFcn',@(~,~)view(obj.ResultAxes,3));
            obj.UI.Candidates=uitable(g,'ColumnName',{'Index','Score','HARD','Eligible','Classification','Reason'});
            obj.UI.Candidates.Layout.Column=[1 2];
            obj.ResultCurveAxes=uiaxes(g);
            obj.ResultAxes=uiaxes(g); axtoolbar(obj.ResultAxes,{'rotate','pan','zoomin','zoomout','restoreview','datacursor'});
            obj.UI.ResultDetails=uitextarea(g,'Editable','off'); obj.UI.ResultDetails.Layout.Column=[1 2];
        end
        function fillVehicle(obj)
            d=obj.Controller.Project.definition.concept.definitionSI;
            obj.UI.VehicleTable.Data=fsdui.parameterRows(fsd.project.conceptParameterCatalog(),d.parameters,true);
            obj.UI.MassConvention.Value=d.massConvention;
            for side=["Front","Rear"]
                value=d.architectures.(lower(side)+"Suspension"); control=obj.UI.(side+"Architecture");
                control.Items=unique([string(control.Items),value],'stable'); control.Value=value;
            end
        end
        function applyVehicle(obj)
            try
                d=obj.Controller.Project.definition.concept.definitionSI;
                d.parameters=fsdui.parametersFromRows(obj.UI.VehicleTable.Data,d.parameters,"",true);
                d.massConvention=string(obj.UI.MassConvention.Value);
                d.architectures.frontSuspension=string(obj.UI.FrontArchitecture.Value);
                d.architectures.rearSuspension=string(obj.UI.RearArchitecture.Value);
                obj.invoke('VEHICLE',struct('definition',d));
            catch cause
                obj.showError(cause);
            end
        end
        function loadDecisions(obj)
            obj.Definition=fsdui.seedDefinition(obj.Controller.Project,string(obj.UI.Scope.Value));
            d=obj.Definition.definitionSI; obj.UI.Symmetry.Value=d.symmetry;
            if d.cornerId=="FRONT" && d.symmetry=="MIRROR_FL", obj.UI.Side.Value='FL'; end
            side=string(obj.UI.Scope.Value); if side=="FRONT", side=string(obj.UI.Side.Value); end
            obj.ActiveSide=side; obj.SeedRows=fsdui.parameterRows(fsd.construction.seedParameterCatalog(),obj.sideParameters(d,side),false);
            obj.showGroup();
        end
        function showGroup(obj)
            c=fsd.construction.seedParameterCatalog(); ids=string({c.id});
            switch obj.ActiveGroup
                case "Wheel / References", keep=1:4;
                case "Upright", keep=5:13;
                case "UCA", keep=find(startsWith(ids,'UCA_'));
                case "LCA", keep=find(startsWith(ids,'LCA_'));
                otherwise, keep=find(startsWith(ids,'TIE_IN_'));
            end
            obj.UI.DecisionTable.UserData=keep; obj.UI.DecisionTable.Data=obj.SeedRows(keep,:);
        end
        function seedDraft(obj)
            obj.SeedRows(obj.UI.DecisionTable.UserData,:)=obj.UI.DecisionTable.Data; obj.draft();
        end
        function changeGroup(obj)
            obj.SeedRows(obj.UI.DecisionTable.UserData,:)=obj.UI.DecisionTable.Data;
            obj.ActiveGroup=string(obj.UI.Group.Value); obj.showGroup();
        end
        function changeScope(obj)
            if ismember("Geometry",obj.DraftPages)
                obj.UI.Scope.Value=obj.Definition.definitionSI.cornerId;
                obj.showError(MException('fsd:ui:UnappliedDraft','Apply geometry decisions before changing scope.')); return;
            end
            obj.loadDecisions(); obj.drawGeometry();
        end
        function changeSearchScope(obj)
            if any(ismember(obj.DraftPages,["Targets","Synthesis","Analysis"]))
                obj.UI.SearchScope.Value=obj.DrawnSearchScope;
                obj.showError(MException('fsd:ui:UnappliedDraft','Apply search drafts before changing scope.')); return;
            end
            obj.fillSearch();
        end
        function changeSide(obj)
            try
                if string(obj.UI.Scope.Value)~="FRONT" || string(obj.UI.Symmetry.Value)=="MIRROR_FL"
                    obj.UI.Side.Value='FL'; return;
                end
                obj.captureDecisions(); obj.ActiveSide=string(obj.UI.Side.Value);
                obj.SeedRows=fsdui.parameterRows(fsd.construction.seedParameterCatalog(),obj.sideParameters(obj.Definition.definitionSI,obj.ActiveSide),false);
                obj.showGroup();
            catch cause
                obj.showError(cause);
            end
        end
        function captureDecisions(obj)
            obj.SeedRows(obj.UI.DecisionTable.UserData,:)=obj.UI.DecisionTable.Data;
            d=obj.Definition.definitionSI; side=obj.ActiveSide;
            ps=fsdui.parametersFromRows(obj.SeedRows,obj.sideParameters(d,side),side,false);
            if d.cornerId=="FRONT" && side=="FR", d.rightParameters=ps; else, d.parameters=ps; end
            d.symmetry=string(obj.UI.Symmetry.Value);
            if d.cornerId~="FRONT", d.symmetry="NONE"; end
            if d.symmetry=="MIRROR_FL", d.rightParameters={}; end
            obj.Definition=fsd.construction.createParametricSeedDefinition(d);
        end
        function applyDecisions(obj)
            try
                obj.captureDecisions(); obj.invoke('DECISIONS',struct('definition',obj.Definition.definitionSI));
            catch cause
                obj.showError(cause);
            end
        end
        function checkReadiness(obj)
            obj.invoke('READINESS',struct('scenarioId',"UI_BUILD_"+string(obj.UI.Scope.Value)));
        end
        function buildGeometry(obj)
            obj.invoke('BUILD',struct('scope',string(obj.UI.Scope.Value),'resultId',obj.Controller.nextResultId()));
        end
        function runBump(obj)
            try
                plan=obj.plan(); obj.invoke('BUMP',struct('scope',string(obj.UI.AnalysisCorner.Value),'plan',plan,'resultId',obj.Controller.nextResultId()));
            catch cause
                obj.showError(cause);
            end
        end
        function plan=plan(obj)
            plan=struct('travel_m',fsdui.numberList(obj.UI.Travel.Value),'solverOptions',jsondecode(obj.UI.Solver.Value));
            assert(~isempty(plan.travel_m),'fsd:ui:MissingPlan','Declare BUMP samples in metres.');
        end
        function fillSearch(obj,updatePlan)
            if nargin<2, updatePlan=true; end
            obj.DrawnSearchScope=string(obj.UI.SearchScope.Value);
            p=obj.Controller.Project; id="UI_SEARCH_"+string(obj.UI.SearchScope.Value); ss=p.definition.scenarios;
            obj.UI.Targets.Data=cell(0,15); obj.UI.Variables.Data=cell(0,10); obj.UI.Constraints.Data=cell(0,9);
            obj.UI.SearchOptions.Value='{}';
            if updatePlan, obj.UI.Travel.Value=''; obj.UI.Solver.Value='{}'; end
            for j=1:numel(ss)
                if ss{j}.definition.id~=id, continue; end
                d=ss{j}.definition; spec=d.specification.definitionSI;
                obj.UI.Targets.Data=fsdui.specRows(spec,'targets'); obj.UI.Variables.Data=fsdui.specRows(spec,'parameters');
                obj.UI.Constraints.Data=fsdui.specRows(spec,'constraints'); obj.UI.SearchOptions.Value=jsonencode(d.options);
                plan=d.plan; if isfield(plan,'leftBump'), plan=plan.leftBump; end
                if updatePlan
                    obj.UI.Travel.Value=obj.numbers(plan.travel_m);
                    if isfield(plan,'solverOptions'), obj.UI.Solver.Value=jsonencode(plan.solverOptions); end
                end
                obj.UI.SearchDiagnostics.Value={char("Stored scenario: "+id);char("Engine: "+d.engine)};
            end
        end
        function applySearch(obj)
            try
                plan=obj.plan(); definition=fsdui.searchDefinition(string(obj.UI.SearchScope.Value),obj.UI.Targets.Data, ...
                    obj.UI.Variables.Data,obj.UI.Constraints.Data,plan.travel_m,plan.solverOptions,jsondecode(obj.UI.SearchOptions.Value),obj.existingSearch());
                obj.invoke('SPECIFICATION',struct('definition',definition));
            catch cause
                obj.showError(cause);
            end
        end
        function runSearch(obj)
            obj.invoke('SYNTHESIS',struct('scenarioId',"UI_SEARCH_"+string(obj.UI.SearchScope.Value),'resultId',obj.Controller.nextResultId()));
        end
        function existing=existingSearch(obj)
            existing=[]; scenarios=obj.Controller.Project.definition.scenarios;
            id="UI_SEARCH_"+string(obj.UI.SearchScope.Value);
            for k=1:numel(scenarios)
                if scenarios{k}.definition.id==id, existing=scenarios{k}.definition; return; end
            end
        end
        function searchReadiness(obj)
            obj.invoke('READINESS',struct('scenarioId',"UI_SEARCH_"+string(obj.UI.SearchScope.Value)));
        end
        function referenceTargets(obj)
            answer=uiconfirm(obj.Figure,'Execute a NEW native reference BUMP and load the explicit v0.17 software benchmark? This is not a recommended FS setup.', ...
                'Illustrative reference','Options',{'Cancel','Execute reference'},'DefaultOption',1,'CancelOption',1);
            if string(answer)=="Execute reference", obj.UI.SearchScope.Value='FL'; obj.invoke('REFERENCE_TARGETS'); end
        end
        function addTarget(obj)
            rows=obj.UI.Targets.Data; rows(end+1,:)={char("TARGET_"+string(size(rows,1)+1)),'','','FL','CURVE_TARGET','SOFT','','','','','','','','',''};
            obj.UI.Targets.Data=rows; obj.draft();
        end
        function addVariable(obj)
            rows=obj.UI.Variables.Data; rows(end+1,:)={char("VARIABLE_"+string(size(rows,1)+1)),'FL','','Z','FREE','','','','ASSUMED',''};
            obj.UI.Variables.Data=rows; obj.draft();
        end
        function addConstraint(obj)
            rows=obj.UI.Constraints.Data; rows(end+1,:)={char("CONSTRAINT_"+string(size(rows,1)+1)),'FL','','AXIS_ALIGNED_BOX','HARD','','','',''};
            obj.UI.Constraints.Data=rows; obj.draft();
        end
        function removeRows(obj,name)
            control=obj.UI.(name); selection=control.Selection;
            if isempty(selection), return; end
            rows=unique(selection(:,1)); data=control.Data; data(rows,:)=[]; control.Data=data; obj.draft();
        end
        function fillResults(obj)
            rs=obj.Controller.Project.definition.results; rows=cell(numel(rs),5); ids=strings(0,1);
            for j=1:numel(rs)
                r=rs{j}; rows(j,:)={char(r.id),char(r.engine),r.projectRevision,r.elapsedTime_s,'NOT_CHECKED'};
                if numel(obj.Controller.Compatibility)==numel(rs)
                    rows{j,5}=char(obj.Controller.Compatibility{j}.status);
                end
                if ismember(r.engine,["CORNER_SYNTHESIS","AXLE_SYNTHESIS"]), ids(end+1)=r.id; end %#ok<AGROW>
            end
            obj.UI.Ledger.Data=rows;
            if isempty(ids), ids="No synthesis"; end
            previous=string(obj.UI.ResultPicker.Value); obj.UI.ResultPicker.Items=ids; nativeSelection=false;
            c=obj.Controller;
            if c.LastAction=="SYNTHESIS" && isstruct(c.LastValue) && isfield(c.LastValue,'id') && ismember(c.LastValue.id,ids)
                obj.UI.ResultPicker.Value=c.LastValue.id; nativeSelection=true;
            elseif ismember(previous,ids)
                obj.UI.ResultPicker.Value=previous;
            else
                obj.UI.ResultPicker.Value=ids(end); nativeSelection=true;
            end
            if nativeSelection
                for j=1:numel(rs)
                    if rs{j}.id~=string(obj.UI.ResultPicker.Value), continue; end
                    index=rs{j}.nativePayload.selectedIndex;
                    if isscalar(index) && isfinite(index) && index>=1, obj.UI.Candidate.Value=index;
                    else, obj.UI.Candidate.Value=1; end % Inspect row 1; do not invent native eligibility/selection.
                end
            end
            obj.drawResults();
        end
        function drawGeometry(obj)
            gs=obj.Controller.Project.definition.resources.geometries; ax=obj.GeometryAxes; cla(ax); hold(ax,'on');
            rows=cell(0,4); scope=string(obj.UI.Scope.Value);
            visible=obj.Tabs.SelectedTab==obj.UI.GeometryTab;
            for j=1:numel(gs)
                g=gs{j};
                if scope=="FRONT" && ~ismember(g.cornerId,["FL","FR"]), continue; end
                if scope~="FRONT" && g.cornerId~=scope, continue; end
                if visible, fsdui.drawGeometry(g,ax); end
                rows=[rows;[cellstr(g.hardpoints.ids),num2cell(g.hardpoints.xyz_m)]]; %#ok<AGROW>
            end
            hold(ax,'off'); obj.UI.Hardpoints.Data=rows; view(ax,3); title(ax,scope+" geometry [m] — data tips identify points");
            obj.GeometryPlotPending=~visible;
        end
        function drawAnalysis(obj)
            rs=obj.Controller.Project.definition.results; rows=cell(0,8); samples="No samples";
            evidence={}; lastEvidence=[];
            ax=obj.CurveAxes; cla(ax); hold(ax,'on'); selected=string(obj.UI.AnalysisCorner.Value); last=[];
            visible=obj.Tabs.SelectedTab==obj.UI.AnalysisTab;
            for j=1:numel(rs)
                r=rs{j}; if r.engine~="BUMP", continue; end
                corner=r.scenarioAtExecution.definition.scope.id;
                if selected~="FRONT" && corner~=selected, continue; end
                if selected=="FRONT" && ~ismember(corner,["FL","FR"]), continue; end
                display=fsdui.bumpDisplay(r); a=display.analysis;
                info=obj.evidenceFor(r,j); evidence{end+1,1}=info; %#ok<AGROW> Stored display records only.
                if visible
                    metric=string(obj.UI.Metric.Value); plot(ax,a.requestedWheelTravel_m,a.(metric),'o-','DisplayName',r.id+" "+corner+" ["+info.status+"] rev "+info.executedRevision);
                end
                rows=[rows;display.rows]; %#ok<AGROW> Presentation rows, no physical loop.
                % Prefer applicable stored poses, then latest execution revision;
                % revision orders evidence, but NEVER determines compatibility.
                if isempty(lastEvidence) || (info.applicable && ~lastEvidence.applicable) || ...
                        (info.applicable==lastEvidence.applicable && r.projectRevision>=last.projectRevision)
                    last=r; lastEvidence=info;
                end
            end
            hold(ax,'off'); xlabel(ax,'Requested wheel travel [m]'); ylabel(ax,strrep(obj.UI.Metric.Value,'_',' ')); grid(ax,'on');
            if visible && ~isempty(rows), legend(ax,'Location','best','Interpreter','none'); end
            obj.UI.AnalysisTable.Data=rows;
            obj.UI.CurveEvidence.UserData=evidence;
            if isempty(evidence)
                obj.UI.CurveEvidence.Value={'No stored BUMP evidence for this scope.'};
                title(ax,'No stored BUMP evidence');
            else
                stale=any(cellfun(@(e)~e.applicable,evidence));
                heading="Stored curves — dependencies applicable; convergence is original";
                chartTitle="Stored curves — dependencies applicable";
                if stale
                    heading="STALE / incompatible history is NOT current geometry evidence; check each source status";
                    chartTitle="STALE historical curves — not current evidence";
                    if any(cellfun(@(e)e.applicable,evidence)), chartTitle="Mixed: STALE history + applicable stored curves"; end
                end
                obj.UI.CurveEvidence.Value=cellstr([heading; ...
                    "Current project "+obj.Controller.Project.id+" rev "+obj.Controller.Project.definition.revision; ...
                    string(cellfun(@(e)e.summary+" | "+e.detail(4),evidence,'UniformOutput',false))]);
                title(ax,chartTitle,'Interpreter','none');
            end
            if ~isempty(last)
                good=find(last.nativePayload.sweep.converged); samples=compose('%d',good);
                if isempty(samples), samples="No samples"; end
            end
            obj.UI.StateEvidence.UserData=lastEvidence;
            obj.UI.Sample.UserData=last; obj.UI.Sample.Items=samples; obj.UI.Sample.Value=samples(1); obj.drawState();
            obj.AnalysisPlotPending=~visible;
        end
        function drawState(obj)
            ax=obj.UI.StateAxes; cla(ax); r=obj.UI.Sample.UserData;
            if isempty(r)
                obj.UI.StateEvidence.Value={'No stored BUMP pose for this scope.'}; title(ax,'No converged stored sample'); return;
            end
            info=obj.UI.StateEvidence.UserData; obj.UI.StateEvidence.Value=cellstr(info.detail);
            if obj.Tabs.SelectedTab~=obj.UI.AnalysisTab, return; end
            if string(obj.UI.Sample.Value)=="No samples", title(ax,'No converged stored sample — '+info.status,'Interpreter','none'); return; end
            index=str2double(obj.UI.Sample.Value); g=r.prepared.resources.geometries{1};
            handles=fsd.kinematics.plotBumpResult(g,r.nativePayload.sweep.results(index),ax);
            set(handles.static.labels,'Visible','off');
            caption=string(ax.Title.String);
            title(ax,"["+info.status+"] "+strjoin(caption(:)," "),'Interpreter','none','FontSize',10);
        end
        function info=evidenceFor(obj,result,index)
            reports=obj.Controller.Compatibility;
            if numel(reports)==numel(obj.Controller.Project.definition.results)
                info=fsdui.bumpEvidence(result,obj.Controller.Project,reports{index});
            else
                info=fsdui.bumpEvidence(result,obj.Controller.Project);
            end
        end
        function drawResults(obj)
            rs=obj.Controller.Project.definition.results; id=string(obj.UI.ResultPicker.Value); r=[];
            for j=1:numel(rs), if rs{j}.id==id, r=rs{j}; break; end, end
            if isempty(r)
                obj.UI.Candidates.Data=cell(0,6); cla(obj.ResultAxes); cla(obj.ResultCurveAxes);
                obj.ResultPlotPending=false;
                obj.UI.ResultDetails.Value={'No stored synthesis in the current project.'}; return;
            end
            p=r.nativePayload; rows=cell(numel(p.search.records),6);
            for j=1:size(rows,1)
                e=p.search.records{j}; rows(j,:)={j,e.score,char(e.hardFeasibility),e.eligible,char(e.classification),char(e.reason)};
            end
            obj.UI.Candidates.Data=rows; index=obj.UI.Candidate.Value;
            if index>numel(p.search.records)
                cla(obj.ResultAxes); cla(obj.ResultCurveAxes);
                obj.ResultPlotPending=false;
                obj.UI.ResultDetails.Value={'Candidate index is outside this stored history.'}; return;
            end
            obj.UI.ResultDetails.Value={char("Original revision "+r.projectRevision+" | selected index "+p.selectedIndex); ...
                char("Stop reason: "+p.search.stopReason); char("Inspected index "+index+" | score "+p.search.records{index}.score+" | HARD "+p.search.records{index}.hardFeasibility); ...
                'Geometries are overlaid from stored evidence. No new forward solves on redraw. Check compatibility before adoption.'};
            if obj.Tabs.SelectedTab~=obj.UI.ResultsTab
                cla(obj.ResultAxes); cla(obj.ResultCurveAxes); obj.ResultPlotPending=true; return;
            end
            ax=obj.ResultAxes; cla(ax); hold(ax,'on');
            e=p.search.records{index};
            if r.engine=="CORNER_SYNTHESIS"
                fsdui.drawGeometry(p.problem.seed,ax,"SEED");
                if ~isempty(e.geometry), fsdui.drawGeometry(e.geometry,ax); end
            else
                fsdui.drawGeometry(p.problem.seedAxle.leftGeometry,ax,"SEED"); fsdui.drawGeometry(p.problem.seedAxle.rightGeometry,ax,"SEED");
                if ~isempty(e.axle), fsdui.drawGeometry(e.axle.leftGeometry,ax); fsdui.drawGeometry(e.axle.rightGeometry,ax); end
            end
            hold(ax,'off'); title(ax,'Seed: grey dashed / candidate: colored'); view(ax,3);
            curves=obj.ResultCurveAxes; cla(curves); hold(curves,'on');
            selectedRecords=unique([1 index]);
            for k=selectedRecords
                record=p.search.records{k};
                if isempty(record.candidate), continue; end
                sources=record.candidate.definitionSI.sources;
                for q=1:numel(sources)
                    source=sources{q}; if source.type~="BUMP", continue; end
                    a=source.result;
                    plot(curves,a.requestedWheelTravel_m,a.(string(obj.UI.ResultMetric.Value)),'o-','DisplayName',"E"+k+" "+source.id);
                end
            end
            hold(curves,'off'); grid(curves,'on'); xlabel(curves,'Wheel travel [m]'); ylabel(curves,strrep(obj.UI.ResultMetric.Value,'_',' '));
            title(curves,'Stored seed / candidate curves; NaN gaps retained');
            if ~isempty(curves.Children), legend(curves,'Interpreter','none','Location','best'); end
            obj.ResultPlotPending=false;
        end
        function drawSelectedTab(obj)
            if obj.Closing || isempty(obj.Controller), return; end
            % Render stored data on demand; hidden pages must not allocate
            % fresh graphics on every immutable project/history update.
            if obj.Tabs.SelectedTab==obj.UI.GeometryTab && obj.GeometryPlotPending, obj.drawGeometry();
            elseif obj.Tabs.SelectedTab==obj.UI.AnalysisTab && obj.AnalysisPlotPending, obj.drawAnalysis();
            elseif obj.Tabs.SelectedTab==obj.UI.ResultsTab && obj.ResultPlotPending, obj.drawResults();
            elseif obj.Tabs.SelectedTab==obj.UI.ActuationTab, obj.Actuation.refresh();
            elseif obj.Tabs.SelectedTab==obj.UI.GlobalStaticTab, obj.GlobalStatic.refresh();
            elseif obj.Tabs.SelectedTab==obj.UI.TiresTab, obj.Tires.refresh();
            end
        end
        function adopt(obj)
            answer=uiconfirm(obj.Figure,'Explicitly replace registered geometry with this eligible candidate? Historical results remain unchanged.', ...
                'Adopt candidate','Options',{'Cancel','Adopt'},'DefaultOption',1,'CancelOption',1);
            if string(answer)=="Adopt", obj.invoke('ADOPT',struct('resultId',string(obj.UI.ResultPicker.Value),'index',obj.UI.Candidate.Value)); end
        end
        function draft(obj)
            obj.DraftPages=unique([obj.DraftPages;string(obj.Tabs.SelectedTab.Title)]);
            obj.Controller.invalidate(); obj.UI.Status.Text='Unapplied draft — use Apply on its page before running or saving';
        end
        function startWorker(obj)
            try
                obj.Controller.enableWorker(); obj.UI.Async.Value=true;
            catch cause
                obj.showError(cause);
            end
        end
        function newProject(obj)
            if obj.confirmReplace(), obj.invoke('NEW',struct('id',string(obj.UI.ProjectId.Value))); end
        end
        function demo(obj)
            if obj.confirmReplace(), obj.UI.Scope.Value='FRONT'; obj.invoke('DEMO'); end
        end
        function yes=confirmReplace(obj)
            yes=true;
            if obj.Controller.Dirty
                answer=uiconfirm(obj.Figure,'Replace the current unsaved session?','Replace project', ...
                    'Options',{'Cancel','Replace'},'DefaultOption',1,'CancelOption',1); yes=string(answer)=="Replace";
            end
        end
        function openFile(obj)
            if ~obj.confirmReplace(), return; end
            [file,folder]=uigetfile('*.mat','Open trusted native project');
            if isequal(file,0), return; end
            obj.invoke('LOAD',struct('file',string(fullfile(folder,file))));
        end
        function saveFile(obj,saveAs)
            file=obj.Controller.File;
            if saveAs || strlength(file)==0
                [name,folder]=uiputfile('*.mat','Save native project'); if isequal(name,0), return; end
                file=string(fullfile(folder,name));
            end
            overwrite=false;
            if isfile(file)
                answer=uiconfirm(obj.Figure,'Replace this MAT file with the current committed project?','Confirm overwrite', ...
                    'Options',{'Cancel','Replace'},'DefaultOption',1,'CancelOption',1);
                if string(answer)~="Replace", return; end
                overwrite=true;
            end
            obj.invoke('SAVE',struct('file',file,'overwrite',overwrite));
        end
        function showError(obj,cause)
            obj.UI.Status.Text=char(string(cause.identifier)+": "+string(cause.message));
            obj.UI.Diagnostics.Value=cellstr(fsdui.errorText(cause));
            obj.UI.SearchDiagnostics.Value=obj.UI.Diagnostics.Value;
            uialert(obj.Figure,cause.message,'Operation not completed','Icon','error');
        end
    end
    methods (Static,Access=private)
        function bar=bar(parent,widths)
            bar=uigridlayout(parent,[1 numel(widths)]); bar.ColumnWidth=widths; bar.Padding=0;
        end
        function cols=parameterColumns()
            cols={'ID','Value','Bounds','Unit','Role','Availability','Source kind','Source note','Confirmation','Reference','Extra JSON'};
        end
        function ps=sideParameters(d,side)
            ps=d.parameters; if d.cornerId=="FRONT" && side=="FR", ps=d.rightParameters; end
        end
        function s=numbers(values)
            s=char(strjoin(compose('%.17g',values),' '));
        end
    end
end
