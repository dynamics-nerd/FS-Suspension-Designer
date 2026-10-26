classdef ArbView < handle
    %ARBVIEW Native declarations/studies/history; engineering stays in fsd APIs.
    properties(SetAccess=private)
        UI=struct()
    end
    properties(Access=private)
        Controller
        Invoke
        Draft
        Bar=[]
        DirtyParts=strings(0,1)
        DrawnProject=[]
        DrawnScenario="NONE"
        Readiness=[]
        Records={}
        LoadedStudy=[]
        LoadedStudyRows=struct()
    end
    methods
        function obj=ArbView(tab,controller,invoke,draft)
            obj.Controller=controller; obj.Invoke=invoke; obj.Draft=draft;
            g=uigridlayout(tab,[4,1]); g.RowHeight={85,32,32,'1x'};
            obj.UI.Status=uitextarea(g,'Editable','off');
            obj.UI.Resource=uidropdown(g,'Items',{'NEW'},'ValueChangedFcn',@(~,~)obj.pick());
            obj.UI.Page=uidropdown(g,'Items',{'Definition','Parameters','Study','Packaging','Results'},'ValueChangedFcn',@(~,~)obj.page());
            holder=uigridlayout(g,[1,1]); holder.Padding=0;
            for name=["Definition","ParametersPage","Study","Packaging","Results"]
                obj.UI.(name)=uipanel(holder); obj.UI.(name).Layout.Row=1; obj.UI.(name).Layout.Column=1;
            end
            obj.definition(); obj.study(); obj.packaging(); obj.results(); obj.page(); obj.fillDefinition();
        end
        function updateStatus(obj)
            if isempty(obj.Controller), return; end
            c=obj.Controller; text=[c.Status;"Preliminary elastic model; calculated curves are not measured FS data."];
            if obj.hasDraft(), text(end+1)="Unapplied ARB draft: "+join(obj.DirtyParts,', ')+". Apply before Save/Run."; end
            if ~isempty(obj.Readiness), text=[text;"Study readiness: "+obj.Readiness.status;obj.Readiness.missing;obj.Readiness.diagnostics]; end
            if ~isempty(c.LastError), text=[text;fsdui.errorText(c.LastError)]; end
            obj.UI.Status.Value=cellstr(text);
            obj.UI.Run.Enable=~c.Busy&&~obj.hasDraft()&&~isempty(obj.Readiness)&&obj.Readiness.status=="READY";
        end
        function refresh(obj)
            if isempty(obj.Controller), return; end
            obj.updateStatus(); p=obj.Controller.Project;
            if isequaln(obj.DrawnProject,p), return; end
            bars={}; if isfield(p.definition.resources,'antiRollBars'), bars=p.definition.resources.antiRollBars; end
            labels=["NEW",string(cellfun(@(b)obj.key(b),bars,'UniformOutput',false))'];
            previous=string(obj.UI.Resource.Value); obj.UI.Resource.Items=cellstr(labels);
            if obj.Controller.LastAction=="ARB_CONFIG"&&isstruct(obj.Controller.LastValue)&& ...
                    isfield(obj.Controller.LastValue,'kind')&&obj.Controller.LastValue.kind=="AntiRollBar"
                previous=obj.key(obj.Controller.LastValue);
            end
            if ismember(previous,labels), obj.UI.Resource.Value=char(previous); end
            if ~ismember("DEFINITION",obj.DirtyParts)
                obj.Bar=[];
                for k=1:numel(bars), if obj.key(bars{k})==string(obj.UI.Resource.Value), obj.Bar=bars{k}; end, end
                obj.fillDefinition();
            end
            if ~ismember("ASSIGNMENT",obj.DirtyParts), obj.fillAssignments(p); end
            ss=p.definition.scenarios; ss=ss(cellfun(@(s)startsWith(s.definition.engine,'ARB_'),ss));
            labels=cellfun(@(s)char(s.definition.id),ss,'UniformOutput',false); if isempty(labels), labels={'NONE'}; end
            obj.picker(obj.UI.Scenario,labels);
            if obj.Controller.LastAction=="ARB_STUDY_CONFIG"&&isstruct(obj.Controller.LastValue)&& ...
                    isfield(obj.Controller.LastValue,'scenarioId')&&ismember(obj.Controller.LastValue.scenarioId,string(labels))
                obj.UI.Scenario.Value=char(obj.Controller.LastValue.scenarioId);
            end
            if ~ismember("STUDY",obj.DirtyParts)&&ismember(obj.Controller.LastAction,["LOAD","ARB_STUDY_CONFIG"]), obj.loadStudy(); end
            obj.Readiness=[];
            if string(obj.UI.Scenario.Value)~="NONE", obj.Readiness=fsd.project.designReadiness(p,string(obj.UI.Scenario.Value)); end
            obj.Records=p.definition.results(cellfun(@(r)startsWith(r.engine,'ARB_'),p.definition.results));
            labels=[{'NONE'},cellfun(@(r)char(r.id),obj.Records,'UniformOutput',false)'];
            obj.picker(obj.UI.Primary,labels); obj.picker(obj.UI.Reference,labels);
            if obj.Controller.LastAction=="ARB_RUN"&&isstruct(obj.Controller.LastValue)&&isfield(obj.Controller.LastValue,'id')
                obj.UI.Primary.Value=char(obj.Controller.LastValue.id);
            elseif obj.Controller.LastAction=="LOAD"&&~isempty(obj.Records), obj.UI.Primary.Value=char(obj.Records{end}.id);
            end
            obj.render(); obj.updateStatus(); obj.DrawnProject=p; obj.DrawnScenario=string(obj.UI.Scenario.Value);
        end
        function committed(obj,action)
            part="STUDY";
            if string(action)=="ARB_CONFIG", part="DEFINITION";
            elseif string(action)=="ARB_ASSIGN", part="ASSIGNMENT"; end
            obj.DirtyParts=setdiff(obj.DirtyParts,part); obj.DrawnProject=[];
        end
        function value=hasDraft(obj)
            value=~isempty(obj.DirtyParts);
        end
        function prepareAction(obj,action)
            if string(action)=="ARB_RUN", assert(~obj.hasDraft(),'fsd:ui:UnappliedDraft','Apply all ARB drafts before running.');
            elseif ismember(string(action),["ARB_ASSIGN","ARB_STUDY_CONFIG"])
                assert(~ismember("DEFINITION",obj.DirtyParts),'fsd:ui:UnappliedDraft','Apply the ARB revision before selecting it.');
            end
        end
        function resetDrafts(obj)
            obj.DirtyParts=strings(0,1); obj.Bar=[]; obj.Readiness=[]; obj.DrawnProject=[];
            obj.UI.Resource.Value='NEW'; obj.blankStudy();
        end
        function release(obj)
            obj.Controller=[]; obj.Invoke=[]; obj.Draft=[]; obj.Bar=[]; obj.DrawnProject=[]; obj.Records={}; obj.UI=struct();
            obj.LoadedStudy=[]; obj.LoadedStudyRows=struct();
        end
        function applyDefinition(obj)
            try
                r=struct();
                names=["Id","Name","Axle","Representation","ReferenceMode","StiffnessMode","StiffnessScope","Section","Adjustment","Note"];
                keys=["id","name","axleId","representation","referenceMode","stiffnessMode","stiffnessScope","section","adjustmentId","note"];
                for k=1:numel(names), r.(keys(k))=obj.UI.(names(k)).Value; end
                r.drivers=[string(obj.UI.LeftDriver.Value);string(obj.UI.RightDriver.Value)];
                r.parameters=obj.UI.Parameters.Data; r.referenceFrame=[];
                if ~isempty(obj.Bar), r.referenceFrame=obj.Bar.definition.referenceFrame; end
                if isempty(r.referenceFrame)&&string(r.representation)=="COAXIAL_TORSION"
                    ids=["FL","FR"]; if string(r.axleId)=="REAR", ids=["RL","RR"]; end
                    gs=obj.Controller.Project.definition.resources.geometries; match=cellfun(@(g)g.cornerId==ids(1),gs);
                    if any(match), r.referenceFrame=gs{match}.referenceFrame; end
                end
                d=fsdui.arbConfiguration('DEFINITION',r,obj.Bar); obj.Invoke('ARB_CONFIG',struct('definition',d));
            catch cause
                obj.error(cause);
            end
        end
        function applyAssignments(obj)
            try
                rows=obj.UI.Assignments.Data; entries={};
                for k=1:2
                    text=string(rows{k,2}); if strlength(text)==0, continue; end
                    bits=split(text,'@'); assert(numel(bits)==2,'fsd:ui:ArbInput','Use exact ID@revision.');
                    entries{end+1,1}=struct('axleId',string(rows{k,1}),'arbId',bits(1),'arbRevision',str2double(bits(2))); %#ok<AGROW>
                end
                obj.Invoke('ARB_ASSIGN',struct('assignments',{entries}));
            catch cause
                obj.error(cause);
            end
        end
        function applyStudy(obj)
            try
                assert(~isempty(obj.Bar)&&obj.Bar.definition.axleId~="UNSELECTED",'fsd:ui:ArbInput','Select a registered ARB with declared axle.');
                engine=string(obj.UI.Engine.Value);
                fresh=isempty(obj.LoadedStudy)||engine~=obj.LoadedStudy.engine;
                plan=struct();
                if ~fresh, plan=obj.LoadedStudy.plan; end
                if engine=="ARB_SIZING"
                    plan=obj.sizingPlan(plan,fresh);
                else
                    motion=string(obj.UI.Motion.Value);
                    if fresh||obj.studyChanged('Motion'), plan.motion=motion; end
                    if motion=="PRESCRIBED"
                        if fresh||obj.studyChanged('Wheels')
                            if any(strlength(strtrim(string(obj.UI.Wheels.Data(:,2))))>0)
                                plan.wheelTravel_m=obj.wheelSamples(plan,fresh);
                            elseif isfield(plan,'wheelTravel_m'), plan.wheelTravel_m=[];
                            end
                        end
                    else
                        if fresh||obj.studyChanged('Roll',1), plan.rollAngles_rad=fsdui.numberList(obj.UI.Roll.Data{1,2})*pi/180; end
                        if fresh||obj.studyChanged('Roll',2)
                            heave=[]; if strlength(string(obj.UI.Roll.Data{2,2}))>0, heave=obj.scalar(obj.UI.Roll.Data{2,2})/1000; end
                            plan.axleHeave_m=heave;
                        end
                    end
                    if obj.Bar.definition.representation=="COAXIAL_TORSION"
                        for side=1:2
                            if ~fresh&&~obj.studyChanged('DriverPaths',side), continue; end
                            if ~isfield(plan,'driverTravel_m'), plan.driverTravel_m={[],[]}; end
                            plan.driverTravel_m{side}=fsdui.numberList(obj.UI.DriverPaths.Data{side,2})/1000;
                        end
                    end
                    if obj.UI.PackEnabled.Value
                        if fresh||~isfield(plan,'packaging')||any(cellfun(@(n)obj.studyChanged(n),{'Components','Obstacles','Pairs','PackNote'}))
                            plan.packaging=obj.packagingPlan(plan,fresh);
                        end
                    elseif isfield(plan,'packaging')&&(fresh||obj.studyChanged('PackEnabled'))
                        plan=rmfield(plan,'packaging');
                    end
                end
                d=struct('id',string(obj.UI.StudyId.Value),'engine',engine, ...
                    'scope',fsd.model.designScope('AXLE',obj.Bar.definition.axleId), ...
                    'inputs',struct('arbId',obj.Bar.definition.id,'arbRevision',obj.Bar.definition.revision),'plan',plan);
                if ~isempty(obj.LoadedStudy)
                    original=obj.LoadedStudy; original.id=d.id; original.engine=d.engine;
                    if obj.studyChanged('Resource'), original.scope=d.scope; original.inputs=d.inputs; end
                    original.plan=d.plan;
                    if fresh, original.options=struct(); end
                    d=original;
                end
                obj.Invoke('ARB_STUDY_CONFIG',struct('definition',d));
            catch cause
                obj.error(cause);
            end
        end
        function run(obj)
            obj.Invoke('ARB_RUN',struct('scenarioId',string(obj.UI.Scenario.Value),'resultId',obj.Controller.nextResultId()));
        end
    end
    methods(Access=private)
        function plan=sizingPlan(obj,plan,fresh)
            % An unchanged presentation must not rewrite canonical input data.
            values=obj.UI.Target.Data;
            if ~fresh&&~obj.studyChanged('Target'), return; end
            if ~isfield(plan,'target'), plan.target=struct(); end
            keys=["stiffness_Nm_per_rad","sourceKind","sourceNote"];
            for k=1:3
                if ~fresh&&~obj.studyChanged('Target',k), continue; end
                if k==1
                    value=[];
                    if strlength(string(values{k,2}))>0, value=obj.scalar(values{k,2})/(pi/180); end
                else
                    value=string(values{k,2});
                end
                plan.target.(keys(k))=value;
            end
        end
        function rows=studyRows(obj)
            rows=struct();
            for name=["Resource","Motion","PackEnabled","PackNote"]
                rows.(name)=obj.UI.(name).Value;
            end
            for name=["Wheels","DriverPaths","Roll","Target","Components","Obstacles","Pairs"]
                rows.(name)=obj.UI.(name).Data;
            end
        end
        function changed=studyChanged(obj,name,row)
            now=obj.studyRows();
            changed=~isfield(obj.LoadedStudyRows,name);
            if changed, return; end
            before=obj.LoadedStudyRows.(name); after=now.(name);
            if nargin==3, before=before(row,2); after=after(row,2); end
            changed=~isequaln(before,after);
        end
        function samples=wheelSamples(obj,plan,fresh)
            paths=cell(1,2);
            for side=1:2
                if ~fresh&&~obj.studyChanged('Wheels',side)&&isfield(plan,'wheelTravel_m')&&~isempty(plan.wheelTravel_m)
                    paths{side}=double(plan.wheelTravel_m(:,side));
                else
                    paths{side}=fsdui.numberList(obj.UI.Wheels.Data{side,2})/1000;
                end
            end
            n=max(cellfun(@numel,paths));
            for side=1:2
                assert(~isempty(paths{side})&&(isscalar(paths{side})||numel(paths{side})==n), ...
                    'fsd:ui:ArbInput','Supply matching left/right lists or a scalar expansion, never a grid.');
                if isscalar(paths{side}), paths{side}=repmat(paths{side},n,1); end
            end
            samples=[paths{1}(:),paths{2}(:)];
        end
        function value=packagingPlan(obj,plan,fresh)
            input=struct('components',{obj.UI.Components.Data},'obstacles',{obj.UI.Obstacles.Data}, ...
                'pairs',{obj.UI.Pairs.Data},'note',obj.UI.PackNote.Value);
            if fresh||~isfield(plan,'packaging')
                value=fsdui.arbPackagingConfiguration('DEFINITION',input,obj.Bar); return;
            end
            d=plan.packaging.definition;
            if any(cellfun(@(n)obj.studyChanged(n),{'Components','Obstacles','Pairs'}))
                parsed=fsdui.arbPackagingConfiguration('DEFINITION',input,obj.Bar);
                for name=["components","obstacles","pairs"]
                    control=char(upper(extractBefore(name,2))+extractAfter(name,1));
                    if obj.studyChanged(control)
                        d.(name)=obj.packingRows(name,control,d.(name),parsed.definition.(name));
                    end
                end
            end
            if obj.studyChanged('PackNote'), d.provenance=string(obj.UI.PackNote.Value); end
            value=fsd.packaging.createAntiRollBarDefinition(d);
        end
        function entries=packingRows(obj,name,control,original,parsed)
            before=obj.LoadedStudyRows.(control); after=obj.UI.(control).Data;
            entries=parsed;
            active=find(any(strlength(string(after))>0,2));
            for k=1:numel(parsed)
                row=active(k);
                if row>numel(original)||row>size(before,1), continue; end
                if isequaln(before(row,:),after(row,:)), entries{k}=original{row}; continue; end
                if name=="obstacles"
                    d=original{row}.definitionSI; changed=parsed{k}.definitionSI;
                    for col=1:6
                        if isequaln(before{row,col},after{row,col}), continue; end
                        switch col
                            case 1, d.id=changed.id;
                            case 2, d.shape=changed.shape;
                            case 3, d.transform(1:3,4)=changed.transform(1:3,4);
                            case 4, d.dimensions=changed.dimensions;
                            case 5, d.transform(1:3,1:3)=changed.transform(1:3,1:3);
                            case 6, d.provenance=changed.provenance;
                        end
                    end
                    entries{k}=fsd.packaging.createVolume(d,'m');
                else
                    keys=["id","shape","firstPoint","secondPoint","radius_m","source"];
                    if name=="pairs", keys=["id","first","second","requiredClearance_m"]; end
                    d=original{row};
                    for col=1:numel(keys)
                        if ~isequaln(before{row,col},after{row,col}), d.(keys(col))=parsed{k}.(keys(col)); end
                    end
                    entries{k}=d;
                end
            end
        end
        function definition(obj)
            g=uigridlayout(obj.UI.Definition,[14,2]); g.Scrollable='on'; g.ColumnWidth={230,'1x'};
            g.RowHeight=[repmat({32},1,12),{38,55}];
            labels={'ARB ID','Name','Axle','Representation','Free reference','Stiffness route','Stiffness port scope', ...
                'Circular section','Left driver','Right driver','Adjustment / variant ID','Provenance / note'};
            names=["Id","Name","Axle","Representation","ReferenceMode","StiffnessMode","StiffnessScope", ...
                "Section","LeftDriver","RightDriver","Adjustment","Note"];
            choices={[],[],{'UNSELECTED','FRONT','REAR'},{'EQUIVALENT_LINEAR','COAXIAL_TORSION'}, ...
                {'UNKNOWN','ZERO_AT_INSTALLATION','DECLARED_FREE'},{'UNKNOWN','KNOWN','CIRCULAR_SHAFT'}, ...
                {'UNKNOWN','SHAFT_ONLY','EFFECTIVE_PORTS'},{'UNKNOWN','SOLID','TUBULAR'}, ...
                {'UNSELECTED','ROCKER','UPRIGHT','UCA','LCA'},{'UNSELECTED','ROCKER','UPRIGHT','UCA','LCA'},[],[]};
            for k=1:numel(names)
                uilabel(g,'Text',labels{k});
                if isempty(choices{k}), control=uieditfield(g,'text');
                else, control=uidropdown(g,'Items',choices{k}); end
                control.ValueChangedFcn=@(~,~)obj.edited("DEFINITION"); obj.UI.(names(k))=control;
            end
            obj.UI.Apply=uibutton(g,'Text','Apply ARB revision','ButtonPushedFcn',@(~,~)obj.applyDefinition());
            obj.UI.Example=uibutton(g,'Text','Load explicit synthetic draft','ButtonPushedFcn',@(~,~)obj.example());
            obj.UI.Frame=uitextarea(g,'Editable','off'); obj.UI.Frame.Layout.Column=[1,2];
            pg=uigridlayout(obj.UI.ParametersPage,[3,1]); pg.RowHeight={45,'1x',36};
            label=uilabel(pg,'Text','Explicit engineering values and provenance. Blank values remain unknown. Arrays use rows separated by semicolons. Geometry uses the shared vehicle frame shown on Definition.'); label.WordWrap='on';
            obj.UI.Parameters=uitable(pg,'ColumnName',{'SI parameter / shape in contract','Engineering value (rows with ;)','Unit','Source kind','Source note'}, ...
                'ColumnEditable',[false,true,false,true,true],'ColumnWidth',{250,200,65,100,'1x'}, ...
                'CellEditCallback',@(~,~)obj.edited("DEFINITION"));
            obj.UI.ApplyParameters=uibutton(pg,'Text','Apply ARB revision (definition and parameters)','ButtonPushedFcn',@(~,~)obj.applyDefinition());
        end
        function study(obj)
            g=uigridlayout(obj.UI.Study,[11,1]); g.Scrollable='on'; g.RowHeight={36,36,36,32,115,115,115,135,100,36,65};
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            obj.UI.ApplyStudy=uibutton(bar,'Text','Apply study and check readiness','ButtonPushedFcn',@(~,~)obj.applyStudy());
            obj.UI.Run=uibutton(bar,'Text','Run selected ARB study','ButtonPushedFcn',@(~,~)obj.run());
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            obj.UI.Scenario=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.loadStudy());
            obj.UI.Engine=uidropdown(bar,'Items',{'ARB_MECHANICAL','ARB_KINEMATICS','ARB_SIZING'},'ValueChangedFcn',@(~,~)obj.edited("STUDY"));
            bar=uigridlayout(g,[1,2]); bar.Padding=0; uilabel(bar,'Text','Study ID');
            obj.UI.StudyId=uieditfield(bar,'text','Value','UI_ARB_STUDY','ValueChangedFcn',@(~,~)obj.edited("STUDY"));
            obj.UI.Motion=uidropdown(g,'Items',{'PRESCRIBED','ROLL'},'ValueChangedFcn',@(~,~)obj.edited("STUDY"));
            obj.UI.Wheels=obj.table(g,{'Requested wheel coordinate','Explicit samples / scalar expansion'},[false,true],"STUDY");
            obj.UI.DriverPaths=obj.table(g,{'Driver path','Strictly ordered explicit samples'},[false,true],"STUDY");
            obj.UI.Roll=obj.table(g,{'Native ROLL request','Explicit value/list'},[false,true],"STUDY");
            obj.UI.Target=obj.table(g,{'Circular shaft sizing target','Value / source'},[false,true],"STUDY");
            obj.UI.Assignments=obj.table(g,{'Axle','Selected ARB ID@revision'},[false,true],"ASSIGNMENT");
            obj.UI.ApplyAssignments=uibutton(g,'Text','Apply axle assignments (enable consumed axles on Global static)', ...
                'ButtonPushedFcn',@(~,~)obj.applyAssignments());
            label=uilabel(g,'Text','Nominal arm points define installation; ZERO_AT_INSTALLATION is an explicit unloaded condition. Sizing uses declared G/length/section and a user target. No optimal FS target is inferred.'); label.WordWrap='on';
            obj.blankStudy();
        end
        function packaging(obj)
            g=uigridlayout(obj.UI.Packaging,[9,1]); g.Scrollable='on'; g.RowHeight={32,32,220,36,200,36,150,36,65};
            obj.UI.PackEnabled=uicheckbox(g,'Text','Include sampled packaging in this study (geometric ARB only)', ...
                'ValueChangedFcn',@(~,~)obj.edited("STUDY"));
            obj.UI.PackNote=uieditfield(g,'text','Placeholder','Explicit material/check provenance', ...
                'ValueChangedFcn',@(~,~)obj.edited("STUDY"));
            obj.UI.Components=obj.table(g,{'ID','Shape','First point','Second point','Radius mm','Source note'},true(1,6),"STUDY");
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            uibutton(bar,'Text','Add component row','ButtonPushedFcn',@(~,~)obj.row("Components",true));
            uibutton(bar,'Text','Remove last component row','ButtonPushedFcn',@(~,~)obj.row("Components",false));
            obj.UI.Obstacles=obj.table(g,{'ID','Shape','Centre mm','Dimensions mm','Rotation rows (optional sphere/AABB)','Source note'},true(1,6),"STUDY");
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            obj.UI.AddObstacle=uibutton(bar,'Text','Add obstacle row','ButtonPushedFcn',@(~,~)obj.row("Obstacles",true));
            uibutton(bar,'Text','Remove last obstacle row','ButtonPushedFcn',@(~,~)obj.row("Obstacles",false));
            obj.UI.Pairs=obj.table(g,{'Check ID','First volume','Second volume','Required clearance mm'},true(1,4),"STUDY");
            bar=uigridlayout(g,[1,2]); bar.Padding=0;
            obj.UI.AddPair=uibutton(bar,'Text','Add selected pair','ButtonPushedFcn',@(~,~)obj.row("Pairs",true));
            uibutton(bar,'Text','Remove last pair','ButtonPushedFcn',@(~,~)obj.row("Pairs",false));
            label=uilabel(g,'Text','Known endpoints do not supply material radii. Enter occupied simplified geometry and selected pairs. Blank dimensions/clearance remain unknown. CLEAR_SAMPLED covers selected checks only; no continuous collision or strength certificate.'); label.WordWrap='on';
            obj.fillPacking([]);
        end
        function results(obj)
            g=uigridlayout(obj.UI.Results,[8,1]); g.Scrollable='on'; g.RowHeight={32,100,240,270,240,260,150,120};
            bar=uigridlayout(g,[1,3]); bar.Padding=0;
            obj.UI.Primary=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Reference=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Quantity=uidropdown(bar,'Items',{'FORCES','DEFORMATION','ARM_ANGLES','TWIST','TORQUE','ENERGY','TANGENT','LINK_FORCES'}, ...
                'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.Summary=uitextarea(g,'Editable','off'); obj.UI.Values=uitable(g);
            obj.UI.CurvePanel=uipanel(g); plotGrid=uigridlayout(obj.UI.CurvePanel,[1,1]); plotGrid.Padding=0;
            obj.UI.Axes=uiaxes(plotGrid);
            obj.UI.GeometryPanel=uipanel(g); geometryGrid=uigridlayout(obj.UI.GeometryPanel,[1,1]); geometryGrid.Padding=0;
            obj.UI.GeometryAxes=uiaxes(geometryGrid);
            modal=uigridlayout(g,[5,2]); modal.RowHeight={32,85,32,32,65}; modal.Scrollable='on';
            obj.UI.ModalUnit=uidropdown(modal,'Items',{'mm','deg'});
            obj.UI.LinearPath=uicheckbox(modal,'Text','Declared linear path (zero curvature)');
            obj.UI.ModalPath=uitable(modal,'Data',{'first derivative','','';'second derivative','',''}, ...
                'ColumnName',{'mm/mm or mm/deg; curvature mm/unit^2','Left','Right'},'ColumnEditable',[false,true,true]);
            obj.UI.ModalPath.Layout.Column=[1,2];
            obj.UI.ModalSample=uieditfield(modal,'numeric','Value',1,'Tooltip','Stored sample index for diagnostics and tangent', ...
                'ValueChangedFcn',@(~,~)obj.render());
            obj.UI.ModalReference=uieditfield(modal,'numeric','Value',1,'Tooltip','Stored reference sample index for secant');
            obj.UI.ModalIncrement=uieditfield(modal,'text','Placeholder','Explicit secant increment [selected mm/deg]');
            obj.UI.ModalRun=uibutton(modal,'Text','Evaluate declared modal path','ButtonPushedFcn',@(~,~)obj.modal());
            obj.UI.ModalOutput=uitextarea(modal,'Editable','off'); obj.UI.ModalOutput.Layout.Column=[1,2];
            obj.UI.PackResults=uitable(g,'ColumnName',{'Sample','Pair','Status','Distance mm','Required mm'});
            obj.UI.Details=uitextarea(g,'Editable','off');
        end
        function control=table(obj,parent,columns,editable,part)
            control=uitable(parent,'ColumnName',columns,'ColumnEditable',editable,'CellEditCallback',@(~,~)obj.edited(part));
        end
        function edited(obj,part)
            obj.DirtyParts=union(obj.DirtyParts,string(part)); obj.Draft(); obj.updateStatus();
        end
        function row(obj,name,add)
            data=obj.UI.(name).Data;
            if add, data(end+1,:)=repmat({''},1,numel(obj.UI.(name).ColumnName));
            elseif ~isempty(data), data(end,:)=[]; end
            obj.UI.(name).Data=data; obj.edited("STUDY");
        end
        function page(obj)
            for name=["Definition","Study","Packaging","Results"], obj.UI.(name).Visible=strcmp(obj.UI.Page.Value,name); end
            obj.UI.ParametersPage.Visible=strcmp(obj.UI.Page.Value,'Parameters');
        end
        function pick(obj)
            if obj.hasDraft()
                key='NEW'; if ~isempty(obj.Bar)&&ismember(obj.key(obj.Bar),string(obj.UI.Resource.Items)), key=char(obj.key(obj.Bar)); end
                obj.UI.Resource.Value=key; obj.UI.Status.Value={'Apply drafts before choosing another ARB revision.'}; return;
            end
            obj.DrawnProject=[]; obj.refresh();
        end
        function fillDefinition(obj)
            obj.UI.Parameters.Data=fsdui.arbConfiguration('ROWS',obj.Bar);
            names=["Id","Name","Axle","Representation","ReferenceMode","StiffnessMode","StiffnessScope","Section","Adjustment","Note"];
            keys=["id","name","axleId","representation","referenceMode","stiffnessMode","stiffnessScope","section","adjustmentId","note"];
            if isempty(obj.Bar)
                values=["","","UNSELECTED","EQUIVALENT_LINEAR","UNKNOWN","UNKNOWN","UNKNOWN","UNKNOWN","",""];
                for k=1:numel(names), obj.UI.(names(k)).Value=char(values(k)); end
                obj.UI.LeftDriver.Value='UNSELECTED'; obj.UI.RightDriver.Value='UNSELECTED'; obj.UI.Frame.Value={'No geometric parent frame declared.'};
            else
                d=obj.Bar.definition;
                for k=1:numel(names), obj.UI.(names(k)).Value=char(d.(keys(k))); end
                obj.UI.LeftDriver.Value=char(d.drivers(1)); obj.UI.RightDriver.Value=char(d.drivers(2));
                obj.UI.Frame.Value={char("Geometric coordinate frame: "+string(jsonencode(d.referenceFrame)))};
            end
        end
        function example(obj)
            try
                old=path; cleanup=onCleanup(@()path(old)); root=fileparts(fileparts(fileparts(mfilename('fullpath')))); addpath(fullfile(root,'examples'));
                if strcmp(obj.UI.Representation.Value,'COAXIAL_TORSION')
                    assert(ismember(string(obj.UI.Axle.Value),["FRONT","REAR"]),'fsd:ui:ArbInput','Select an axle before loading this explicit synthetic draft.');
                    assert(~strcmp(obj.UI.LeftDriver.Value,'UNSELECTED'),'fsd:ui:ArbInput','Select a native driver body before loading this explicit synthetic draft.');
                    d=geometricAntiRollBarInputs(obj.Controller.Project,string(obj.UI.Axle.Value),string(obj.UI.LeftDriver.Value));
                else
                    d=antiRollBarInputs('EQUIVALENT_LINEAR',string(obj.UI.Axle.Value));
                end
                obj.Bar=fsd.model.createAntiRollBar(d); obj.fillDefinition(); obj.edited("DEFINITION");
            catch cause
                obj.error(cause);
            end
        end
        function fillAssignments(obj,p)
            rows={'FRONT','';'REAR',''};
            if isfield(p.definition.resources,'arbAssignments')
                for a=p.definition.resources.arbAssignments'
                    index=string(rows(:,1))==a{1}.axleId; rows{index,2}=char(a{1}.arbId+"@"+a{1}.arbRevision);
                end
            end
            obj.UI.Assignments.Data=rows;
        end
        function blankStudy(obj)
            obj.LoadedStudy=[]; obj.LoadedStudyRows=struct();
            obj.UI.Wheels.Data={'Left wheel [mm]','';'Right wheel [mm]',''};
            obj.UI.DriverPaths.Data={'Left native driver path [mm]','';'Right native driver path [mm]',''};
            obj.UI.Roll.Data={'Body roll [deg]','';'Axle heave [mm]',''};
            obj.UI.Target.Data={'Target SHAFT stiffness [N*m/deg]','';'Target source kind','';'Target source note',''};
            obj.UI.Motion.Value='PRESCRIBED';
        end
        function loadStudy(obj)
            if ismember("STUDY",obj.DirtyParts)
                if ismember(obj.DrawnScenario,string(obj.UI.Scenario.Items)), obj.UI.Scenario.Value=char(obj.DrawnScenario); end
                obj.UI.Status.Value={'Apply the study draft before selecting another.'}; return;
            end
            scenarios=obj.Controller.Project.definition.scenarios;
            for k=1:numel(scenarios)
                d=scenarios{k}.definition; if d.id~=string(obj.UI.Scenario.Value), continue; end
                obj.blankStudy(); obj.fillPacking([]); obj.UI.PackEnabled.Value=false;
                obj.UI.StudyId.Value=char(d.id); obj.UI.Engine.Value=char(d.engine);
                if all(isfield(d.inputs,{'arbId','arbRevision'}))
                    key=d.inputs.arbId+"@"+d.inputs.arbRevision;
                    if ~ismember("DEFINITION",obj.DirtyParts)&&ismember(key,string(obj.UI.Resource.Items))
                        obj.UI.Resource.Value=char(key); obj.Bar=fsd.project.findAntiRollBar(obj.Controller.Project,d.inputs.arbId,d.inputs.arbRevision); obj.fillDefinition();
                    end
                end
                p=d.plan;
                if isfield(p,'motion'), obj.UI.Motion.Value=char(p.motion); end
                if isfield(p,'wheelTravel_m')&&isnumeric(p.wheelTravel_m)&&size(p.wheelTravel_m,2)==2
                    for side=1:2, obj.UI.Wheels.Data{side,2}=obj.listText(double(p.wheelTravel_m(:,side))*1000); end
                end
                if isfield(p,'driverTravel_m')&&iscell(p.driverTravel_m)&&numel(p.driverTravel_m)==2
                    for side=1:2, obj.UI.DriverPaths.Data{side,2}=obj.listText(double(p.driverTravel_m{side})*1000); end
                end
                if isfield(p,'rollAngles_rad'), obj.UI.Roll.Data{1,2}=obj.listText(double(p.rollAngles_rad)*180/pi); end
                if isfield(p,'axleHeave_m'), obj.UI.Roll.Data{2,2}=obj.listText(double(p.axleHeave_m)*1000); end
                if isfield(p,'target')&&isstruct(p.target)
                    target=p.target;
                    if isfield(target,'stiffness_Nm_per_rad'), obj.UI.Target.Data{1,2}=obj.listText(double(target.stiffness_Nm_per_rad)*(pi/180)); end
                    if isfield(target,'sourceKind'), obj.UI.Target.Data{2,2}=char(target.sourceKind); end
                    if isfield(target,'sourceNote'), obj.UI.Target.Data{3,2}=char(target.sourceNote); end
                end
                if isfield(p,'packaging'), obj.fillPacking(p.packaging); obj.UI.PackEnabled.Value=true; end
                obj.LoadedStudy=d; obj.LoadedStudyRows=obj.studyRows();
                obj.Readiness=fsd.project.designReadiness(obj.Controller.Project,d.id); obj.DrawnScenario=d.id; obj.updateStatus();
            end
        end
        function fillPacking(obj,input)
            if ~isfield(obj.UI,'Components'), return; end
            r=fsdui.arbPackagingConfiguration('ROWS',input,[]);
            obj.UI.Components.Data=r.components; obj.UI.Obstacles.Data=r.obstacles; obj.UI.Pairs.Data=r.pairs; obj.UI.PackNote.Value=r.note;
        end
        function render(obj)
            cla(obj.UI.Axes); cla(obj.UI.GeometryAxes); obj.UI.Values.Data={}; obj.UI.PackResults.Data=cell(0,5);
            obj.UI.Summary.Value={'No ARB evidence selected.'}; obj.UI.Details.Value={''}; obj.UI.ModalOutput.Value={''};
            r=obj.record(obj.UI.Primary.Value); if isempty(r), return; end
            index=cellfun(@(v)v.id==r.id,obj.Controller.Project.definition.results); status=obj.Controller.Compatibility{index}.status;
            obj.UI.Summary.Value=cellstr(["MODEL — "+r.engine+" | result "+r.id+" | revision "+r.projectRevision+" | "+status; ...
                "ARB "+r.prepared.bar.definition.id+"@"+r.prepared.bar.definition.revision+" | "+r.prepared.bar.definition.representation; ...
                "Adjustment "+r.prepared.bar.definition.adjustmentId+" | free reference "+r.prepared.bar.definition.referenceMode; ...
                "Stiffness route / scope: "+r.prepared.bar.definition.stiffnessMode+" / "+r.prepared.bar.definition.stiffnessScope; ...
                "Internal forces are not tire normal loads. Tangents require available bilateral curvature."]);
            if r.prepared.bar.definition.representation=="EQUIVALENT_LINEAR"
                obj.UI.Summary.Value{4}=char("Equivalent coordinate stiffness: "+r.prepared.bar.definition.parameters.linearStiffness_N_per_m/1000+ ...
                    " N/mm | weights "+string(mat2str(r.prepared.bar.definition.parameters.weights')));
            elseif isfield(r.nativePayload,'study')&&~isempty(r.nativePayload.study.prepared.stiffness)
                stiffness=r.nativePayload.study.prepared.stiffness;
                obj.UI.Summary.Value{4}=char("Constitutive port stiffness: "+stiffness.kTheta_Nm_per_rad*pi/180+ ...
                    " N*m/deg | "+stiffness.status+" / "+stiffness.scope);
            end
            if r.engine=="ARB_SIZING"
                s=r.nativePayload.sizing; obj.UI.Values.ColumnName={'Outer diameter mm','Inner diameter mm','Active length mm','G GPa','Target shaft N*m/deg'};
                obj.UI.Values.Data=num2cell([s.outerDiameter_m*1000,s.innerDiameter_m*1000,s.effectiveLength_m*1000,s.G_Pa/1e9,s.target_Nm_per_rad*pi/180]);
                obj.UI.Details.Value=cellstr([s.assumption;"Target source: "+string(jsonencode(r.nativePayload.target))]); return;
            end
            s=r.nativePayload.study; rows=cell(numel(s.responses),14);
            for k=1:numel(s.responses)
                v=s.responses{k}; angles=nan(2,1); deformation=NaN; psi=NaN; torque=NaN; energy=NaN; force=nan(2,1); K=nan(2);
                if isfield(v,'angles_rad'), angles=v.angles_rad; end
                if isfield(v,'armAngles_rad'), angles=v.armAngles_rad; psi=v.twist_rad; torque=v.torque_Nm; energy=v.energy_J; force=v.resistance_N; K=v.tangent_N_per_m; end
                if isfield(v,'deformation_m'), deformation=v.deformation_m; end
                rowStatus=v.status; if isfield(v,'tangentStatus'), rowStatus=rowStatus+" / K: "+v.tangentStatus; end
                rows(k,:)=[num2cell([v.wheelTravel_m'*1000,angles'*180/pi,deformation*1000,psi*180/pi,torque,energy,force',K(1,1)/1000,K(1,2)/1000,K(2,2)/1000]),{char(rowStatus)}];
            end
            obj.UI.Values.ColumnName={'zL mm','zR mm','alphaL deg','alphaR deg','Equivalent deflection mm','twist deg','Torque Nm','Energy J', ...
                'Resistance L N','Resistance R N','KLL N/mm','KLR N/mm','KRR N/mm','Availability / tangent'};
            obj.UI.Values.Data=rows; obj.plotStudy(s,r.id,'-'); ref=obj.record(obj.UI.Reference.Value);
            if ~isempty(ref)&&isfield(ref.nativePayload,'study')
                other=ref.nativePayload.study;
                if other.kind==s.kind&&isequaln(other.requestedWheelTravel_m,s.requestedWheelTravel_m)
                    obj.plotStudy(other,ref.id,'--'); obj.UI.Summary.Value=[obj.UI.Summary.Value;cellstr("Reference "+ref.id+" | ARB "+ ...
                        ref.prepared.bar.definition.id+"@"+ref.prepared.bar.definition.revision+" | adjustment "+ ...
                        ref.prepared.bar.definition.adjustmentId+" retains its own model/hypotheses.")];
                else
                    obj.UI.Summary.Value=[obj.UI.Summary.Value;{'Reference motion/analysis differs; no overlay.'}];
                end
            end
            hold(obj.UI.Axes,'off'); xlabel(obj.UI.Axes,'Left wheel travel [mm]'); legend(obj.UI.Axes,'show','Interpreter','none','Location','best');
            valid=find(cellfun(@(v)v.available,s.responses),1);
            if ~isempty(valid)&&r.prepared.bar.definition.representation=="COAXIAL_TORSION"
                points=fsd.geometry.antiRollBarPoints(r.prepared.bar,s.responses{valid}); xyz=points.xyz_m*1000;
                edges=[1,2;1,3;2,4;3,5;4,6]; hold(obj.UI.GeometryAxes,'on');
                for k=1:size(edges,1), line=xyz(edges(k,:),:); plot3(obj.UI.GeometryAxes,line(:,1),line(:,2),line(:,3),'-o'); end
                hold(obj.UI.GeometryAxes,'off'); axis(obj.UI.GeometryAxes,'equal'); grid(obj.UI.GeometryAxes,'on'); view(obj.UI.GeometryAxes,3);
                xlabel(obj.UI.GeometryAxes,'X rear [mm]'); ylabel(obj.UI.GeometryAxes,'Y right [mm]'); zlabel(obj.UI.GeometryAxes,'Z up [mm]');
                title(obj.UI.GeometryAxes,'Stored geometric centre lines; material radii are separate');
            end
            details=["Source / parameter provenance: "+string(jsonencode(r.prepared.bar.definition.provenance)); ...
                "Declared parameters/domains (SI): "+string(jsonencode(r.prepared.bar.definition.parameters)); ...
                "Stored motion/path/packaging request (SI): "+string(jsonencode(r.prepared.plan)); ...
                "Coordinates and hypotheses belong to the stored execution, not a new solve."];
            index=obj.UI.ModalSample.Value;
            if index>=1&&fix(index)==index&&index<=numel(s.responses)
                sample=s.responses{index}; ends={};
                if isfield(sample,'closureEnds'), ends=sample.closureEnds;
                elseif isfield(sample,'ends'), ends=sample.ends; end
                details=["Diagnostic sample "+index+" | "+sample.status;details];
                for side=1:numel(ends)
                    e=ends{side}; if isempty(e), continue; end
                    details=["Side "+side+" | "+e.status+" | closure residual "+e.closureResidual_m*1000+ ...
                        " mm | conditioning "+e.conditioning+" | branch "+e.branchSign;details]; %#ok<AGROW> Two ends only.
                end
            else
                details=["Diagnostic sample index is outside the stored path.";details];
            end
            if ~isempty(r.nativePayload.packaging)
                packing=r.nativePayload.packaging; checks=packing.checks; data=cell(numel(checks),5);
                for k=1:numel(checks), c=checks{k}; margin=NaN; if ~isempty(c.requiredClearance_m), margin=c.requiredClearance_m*1000; end
                    data(k,:)={c.sampleIndex,char(c.pairId),char(c.status),c.distance_m*1000,margin}; end
                obj.UI.PackResults.Data=data; details=[details;"Packaging: "+packing.status;packing.limitation;"Coverage: "+string(jsonencode(packing.coverage))];
            else
                details=[details;"No packaging check requested; no clearance result inferred."];
            end
            obj.UI.Details.Value=cellstr(details);
        end
        function plotStudy(obj,s,id,style)
            x=s.requestedWheelTravel_m(:,1)*1000; y=nan(numel(x),2); labels=["L","R"];
            if s.kind=="AntiRollBarKinematicSweep"
                for k=1:numel(x), y(k,:)=s.responses{k}.angles_rad'*180/pi; end
                unit='Arm angle [deg]';
            else
                quantity=string(obj.UI.Quantity.Value);
                switch quantity
                    case "FORCES", field='resistance_N'; unit='Generalized resistance [N]'; factor=1;
                    case "DEFORMATION", field='deformation_m'; unit='Equivalent coupling deflection [mm]'; factor=1000;
                    case "ARM_ANGLES", field='armAngles_rad'; unit='Arm angle [deg]'; factor=180/pi;
                    case "TWIST", field='twist_rad'; unit='Relative shaft twist [deg]'; factor=180/pi;
                    case "TORQUE", field='torque_Nm'; unit='Constitutive port torque [Nm]'; factor=1;
                    case "ENERGY", field='energy_J'; unit='Coupled energy [J]'; factor=1;
                    case "LINK_FORCES", field='linkForces_N'; unit='Signed axial link force [N]'; factor=1;
                    case "TANGENT", field='tangent_N_per_m'; unit='Coupled tangent [N/mm]'; factor=.001;
                end
                first=s.responses{1}.(field); n=numel(first); if quantity=="TANGENT", n=3; labels=["LL","LR","RR"]; end
                y=nan(numel(x),n); if n==1, labels=quantity; end
                for k=1:numel(x)
                    v=s.responses{k}.(field); if quantity=="TANGENT", v=[v(1,1),v(1,2),v(2,2)]; end
                    y(k,:)=v(:)'*factor;
                end
            end
            hold(obj.UI.Axes,'on');
            for k=1:size(y,2), plot(obj.UI.Axes,x,y(:,k),style,'Marker','.','DisplayName',id+" "+labels(k)); end
            ylabel(obj.UI.Axes,unit);
        end
        function modal(obj)
            try
                record=obj.record(obj.UI.Primary.Value);
                assert(~isempty(record)&&record.engine=="ARB_MECHANICAL",'fsd:ui:ArbInput','Select stored mechanical evidence.');
                values=record.nativePayload.study.responses; index=obj.UI.ModalSample.Value; reference=obj.UI.ModalReference.Value;
                assert(index>=1&&fix(index)==index&&index<=numel(values)&&reference>=1&&fix(reference)==reference&&reference<=numel(values), ...
                    'fsd:ui:ArbInput','Select existing integer sample indices.');
                table=obj.UI.ModalPath.Data; a=[obj.scalar(table{1,2});obj.scalar(table{1,3})];
                if obj.UI.LinearPath.Value, b=[0;0]; else, b=[obj.scalar(table{2,2});obj.scalar(table{2,3})]; end
                delta=[]; if strlength(string(obj.UI.ModalIncrement.Value))>0, delta=obj.scalar(obj.UI.ModalIncrement.Value); end
                coordinate="m"; outputFactor=.001; label="N/mm";
                if strcmp(obj.UI.ModalUnit.Value,'deg')
                    a=a/1000/(pi/180); b=b/1000/(pi/180)^2; delta=delta*pi/180;
                    coordinate="rad"; outputFactor=pi/180; label="N*m/deg";
                else
                    b=b*1000; delta=delta/1000;
                end
                r=fsd.analysis.antiRollBarModalResponse(values{index},a,b,delta,coordinate);
                text=["Tangent: "+r.tangentStiffness*outputFactor+" "+label+" | "+r.tangentStatus; ...
                    "Declared path first/second (SI): "+string(mat2str(a'))+" / "+string(mat2str(b'))];
                if ~isempty(delta)&&obj.UI.LinearPath.Value
                    sec=fsd.analysis.antiRollBarSecantResponse(values{reference},values{index},a,delta,coordinate);
                    text(end+1)="Incremental secant: "+sec.stiffness*outputFactor+" "+label+" | "+sec.status;
                else
                    text(end+1)="Secant requires an explicit linear path, matching reference and increment.";
                end
                obj.UI.ModalOutput.Value=cellstr(text);
            catch cause
                obj.UI.ModalOutput.Value=cellstr(fsdui.errorText(cause));
            end
        end
        function r=record(obj,id)
            r=[]; for k=1:numel(obj.Records), if obj.Records{k}.id==string(id), r=obj.Records{k}; return; end, end
        end
        function error(obj,cause)
            obj.UI.Status.Value=cellstr(fsdui.errorText(cause));
        end
    end
    methods(Static,Access=private)
        function key=key(bar)
            key=bar.definition.id+"@"+string(bar.definition.revision);
        end
        function picker(control,labels)
            old=string(control.Value); control.Items=labels; if ismember(old,string(labels)), control.Value=char(old); end
        end
        function text=listText(values)
            text=char(join(compose('%.17g',double(values(:)')),' '));
        end
        function value=scalar(input)
            values=fsdui.numberList(input); assert(isscalar(values),'fsd:ui:ArbInput','One explicit numeric value required.'); value=values;
        end
    end
end
