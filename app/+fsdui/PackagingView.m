classdef PackagingView < handle
    %PACKAGINGVIEW Explicit presentation/drafts; engineering stays in fsd APIs.
    properties (SetAccess=private)
        UI=struct()
        Axes
    end
    properties (Access=private)
        Controller
        Invoke
        Draft
        Figure
        DrawnProject=[]
        Definition=[]
        Result=[]
        Reports={}
        VisibleChecks=[]
        SelectedCheck=NaN
        SelectionKey=[]
        SelectedEditorRow=[]
        Dirty=false
    end
    methods
        function obj=PackagingView(tab,controller,invoke,draft)
            obj.Controller=controller; obj.Invoke=invoke; obj.Draft=draft; obj.Figure=ancestor(tab,'figure');
            g=uigridlayout(tab,[7 2]); g.ColumnWidth={'1x','1x'};
            g.RowHeight={34,30,138,34,34,250,70}; g.RowSpacing=5; g.Scrollable='on';
            bar=obj.bar(g,{70,90,100,'1x',140,185}); bar.Layout.Column=[1 2];
            uilabel(bar,'Text','Corner'); obj.UI.Scope=uidropdown(bar,'Items',{'FL','FR','RL','RR'});
            uilabel(bar,'Text','Definition ID'); obj.UI.DefinitionId=uieditfield(bar,'text','Value','PACKAGING', ...
                'ValueChangedFcn',@(~,~)obj.markDraft());
            obj.UI.Apply=uibutton(bar,'Text','Apply definitions','ButtonPushedFcn',@(~,~)obj.apply());
            obj.UI.Demo=uibutton(bar,'Text','Illustrative solids (explicit)', 'ButtonPushedFcn',@(~,~)obj.demo());
            bar=obj.bar(g,{130,130,130,160,110,'1x'}); bar.Layout.Column=[1 2];
            uibutton(bar,'Text','Add volume','ButtonPushedFcn',@(~,~)obj.addRow('Volumes'));
            uibutton(bar,'Text','Add pair','ButtonPushedFcn',@(~,~)obj.addRow('Pairs'));
            uibutton(bar,'Text','Add point region','ButtonPushedFcn',@(~,~)obj.addRow('Regions'));
            uibutton(bar,'Text','Remove selected row','ButtonPushedFcn',@(~,~)obj.removeRow());
            obj.UI.EditorSelector=uidropdown(bar,'Items',{'Volumes','Pairs','Regions'}, ...
                'ValueChangedFcn',@(~,~)obj.showEditor(obj.UI.EditorSelector.Value));
            obj.UI.DefinitionPicker=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.pickDefinition());
            editors=uipanel(g,'Title','Explicit SI declarations'); editors.Layout.Column=[1 2];
            inner=uigridlayout(editors,[1 1]); inner.Padding=0;
            for name=["Volumes","Pairs","Regions"]
                table=uitable(inner,'ColumnEditable',true,'CellEditCallback',@(~,~)obj.markDraft(), ...
                    'CellSelectionCallback',@(~,event)obj.selectEditor(name,event)); obj.UI.(name)=table;
                table.Layout.Row=1; table.Layout.Column=1;
            end
            obj.UI.Volumes.ColumnName={'ID','Component ID','Type','OCCUPIED / FREE_REGION','Shape', ...
                'Dimensions [m]: radius / D:diameter; length; XYZ','Translation [m]','R columns (9)','Binding','Corner','Point IDs', ...
                'Source','Fidelity','Source revision','Provenance'};
            obj.UI.Volumes.ColumnWidth={130,160,110,170,100,210,170,180,100,75,270,260,220,100,350};
            obj.UI.Volumes.ColumnEditable=true(1,15);
            obj.UI.Pairs.ColumnName={'ID','First volume','Second volume','Required clearance [m]','Exact-pair exception JSON (optional)'};
            obj.UI.Pairs.ColumnWidth={140,170,170,160,650};
            obj.UI.Pairs.ColumnEditable=true(1,5);
            obj.UI.Regions.ColumnName={'ID','Corner','Point ID','FIXED / INSIDE / OUTSIDE','Volume ID','Target XYZ [m]', ...
                'FIXED tolerance [m]','Region clearance [m]','Source','Provenance'};
            obj.UI.Regions.ColumnWidth={140,75,230,190,170,180,150,150,260,350};
            obj.UI.Regions.ColumnEditable=true(1,10);
            bar=obj.bar(g,{100,'1x',110,150,75,75}); bar.Layout.Column=[1 2];
            uilabel(bar,'Text','Stored parent'); obj.UI.Parent=uidropdown(bar,'Items',{'NONE'});
            uilabel(bar,'Text','Geometry source'); obj.UI.Selection=uidropdown(bar,'Items',{'REGISTRY','SEED','CANDIDATE'});
            uilabel(bar,'Text','Index'); obj.UI.Candidate=uispinner(bar,'Limits',[1 Inf],'Value',1,'Step',1);
            bar=obj.bar(g,{115,145,180,'1x',95,80}); bar.Layout.Column=[1 2];
            obj.UI.Nominal=uibutton(bar,'Text','Run nominal','ButtonPushedFcn',@(~,~)obj.run('NOMINAL',false));
            obj.UI.Bump=uibutton(bar,'Text','Check stored BUMP','ButtonPushedFcn',@(~,~)obj.run('BUMP',false));
            obj.UI.Compare=uibutton(bar,'Text','Compare seed + index','ButtonPushedFcn',@(~,~)obj.run('BUMP',true));
            obj.UI.ResultPicker=uidropdown(bar,'Items',{'NONE'},'ValueChangedFcn',@(~,~)obj.showPickedResult());
            obj.UI.Sample=uidropdown(bar,'Items',{'1'},'ValueChangedFcn',@(~,~)obj.sampleChanged());
            obj.UI.Filter=uidropdown(bar,'Items',{'ALL','ISSUES','CLEAR'},'ValueChangedFcn',@(~,~)obj.filterChanged());
            panels=uipanel(g,'Title','Stored evidence');
            p=uigridlayout(panels,[2 1]); p.RowHeight={28,'1x'}; p.Padding=0;
            obj.UI.EvidenceSelector=uidropdown(p,'Items',{'Pair checks','Point regions','History / compare'}, ...
                'ValueChangedFcn',@(~,~)obj.showEvidence());
            obj.UI.Checks=uitable(p,'ColumnName',{'Sample','Pair','Status','Distance [m]','Margin [m]','First component','Second component','Diagnostic'}, ...
                'CellSelectionCallback',@(~,event)obj.selectCheck(event));
            obj.UI.RegionChecks=uitable(p,'ColumnName',{'Sample','Region','Point','Status','Margin [m]','Diagnostic'});
            obj.UI.Comparison=uitable(p,'ColumnName',{'Result','Source','Index','Original score','Packaging','Coverage complete','Minimum observed [m]','Compatibility'}, ...
                'CellSelectionCallback',@(~,event)obj.selectComparison(event));
            for name=["Checks","RegionChecks","Comparison"]
                obj.UI.(name).Layout.Row=2; obj.UI.(name).Layout.Column=1;
            end
            obj.Axes=uiaxes(g); axtoolbar(obj.Axes,{'rotate','pan','zoomin','zoomout','restoreview','datacursor'});
            obj.UI.Status=uitextarea(g,'Editable','off','Value',{'No packaging evidence. Dimensions/margins are explicit; no manufacturing approval.'});
            obj.UI.Status.Layout.Column=[1 2];
            obj.showEditor('Volumes'); obj.showEvidence();
            obj.clearTables();
        end
        function refresh(obj)
            p=obj.Controller.Project; obj.Reports=obj.Controller.Compatibility;
            if ~isequaln(p,obj.DrawnProject)
                obj.committed(); % Main View prevents unrelated operations from discarding drafts.
                definitions={}; if isfield(p.definition.resources,'packaging'), definitions=p.definition.resources.packaging; end
                ids=cellfun(@(d)char(d.definitionSI.id),definitions,'UniformOutput',false);
                if isempty(ids), ids={'NONE'}; end
                chosen=string(obj.UI.DefinitionPicker.Value); obj.UI.DefinitionPicker.Items=ids;
                if ismember(chosen,string(ids)), obj.UI.DefinitionPicker.Value=char(chosen); end
                if startsWith(obj.Controller.LastAction,'PACKAGING_') && isstruct(obj.Controller.LastValue) && ...
                        isfield(obj.Controller.LastValue,'kind') && obj.Controller.LastValue.kind=="PackagingDefinition"
                    obj.UI.DefinitionPicker.Value=char(obj.Controller.LastValue.definitionSI.id);
                end
                obj.loadPickedDefinition();
                rs=p.definition.results;
                parents=rs(cellfun(@(r)ismember(r.engine,["BUMP","CORNER_SYNTHESIS","AXLE_SYNTHESIS"]),rs));
                parentIds=[{'NONE'};cellfun(@(r)char(r.id),parents,'UniformOutput',false)];
                chosen=string(obj.UI.Parent.Value); obj.UI.Parent.Items=parentIds;
                if ismember(chosen,string(parentIds)), obj.UI.Parent.Value=char(chosen); end
                packaging=rs(cellfun(@(r)r.engine=="PACKAGING",rs));
                ids=cellfun(@(r)char(r.id),packaging,'UniformOutput',false); if isempty(ids), ids={'NONE'}; end
                chosen=string(obj.UI.ResultPicker.Value); obj.UI.ResultPicker.Items=ids;
                if ismember(chosen,string(ids)), obj.UI.ResultPicker.Value=char(chosen); end
                if iscell(obj.Controller.LastValue) && ~isempty(obj.Controller.LastValue) && ...
                        startsWith(obj.Controller.LastAction,'PACKAGING_')
                    latest=obj.Controller.LastValue{end};
                    if isstruct(latest) && isfield(latest,'engine') && latest.engine=="PACKAGING"
                        obj.UI.ResultPicker.Value=char(latest.id);
                    end
                end
                obj.fillComparison(packaging); obj.showPickedResult(); obj.DrawnProject=p;
            elseif ~isempty(obj.Result)
                obj.showStatus();
            end
        end
        function release(obj)
            % Break the Packaging callbacks -> main View ownership cycle and
            % drop closed-view data even if a test/caller retains the View.
            obj.Controller=[]; obj.Invoke=[]; obj.Draft=[];
            obj.DrawnProject=[]; obj.Definition=[]; obj.Result=[]; obj.Reports={};
            obj.VisibleChecks=[]; obj.SelectionKey=[]; obj.SelectedEditorRow=[];
            obj.UI=struct(); obj.Axes=[]; obj.Figure=[];
        end
        function apply(obj)
            try
                gs=obj.Controller.Project.definition.resources.geometries;
                found=cellfun(@(g)g.cornerId==string(obj.UI.Scope.Value),gs);
                assert(nnz(found)==1,'fsd:ui:MissingGeometry','Build the selected corner first; no frame is invented.');
                definition=fsdui.packagingFromRows(obj.UI.DefinitionId.Value,obj.UI.Volumes.Data,obj.UI.Pairs.Data, ...
                    obj.UI.Regions.Data,gs{found}.referenceFrame,obj.Definition);
                obj.Invoke('PACKAGING_DEFINITION',struct('definition',definition));
            catch cause, obj.fail(cause);
            end
        end
        function committed(obj)
            % A successful identical Apply may leave Project unchanged.
            obj.Dirty=false; obj.UI.Apply.Text='Apply definitions';
        end
        function run(obj,mode,compare)
            try
                parent=string(obj.UI.Parent.Value); if parent=="NONE", parent=""; end
                action="PACKAGING_RUN"; if compare, action="PACKAGING_COMPARE"; end
                args=struct('cornerId',string(obj.UI.Scope.Value),'packagingId',string(obj.UI.DefinitionId.Value), ...
                    'parentId',parent,'selection',string(obj.UI.Selection.Value),'index',obj.UI.Candidate.Value, ...
                    'mode',string(mode),'resultId',obj.Controller.nextResultId());
                obj.Invoke(action,args);
            catch cause, obj.fail(cause);
            end
        end
    end
    methods (Access=private)
        function demo(obj)
            answer=uiconfirm(obj.Figure,'Replace/add DEMO_PACKAGING with explicit synthetic4mm radii,12mm offset,2mm margin and100mm region? These are software inputs, not FS recommendations.', ...
                'Illustrative solids','Options',{'Cancel','Load explicit fixture'},'DefaultOption',1,'CancelOption',1);
            if string(answer)=="Load explicit fixture", obj.Invoke('PACKAGING_DEMO',struct('cornerId',string(obj.UI.Scope.Value))); end
        end
        function clearTables(obj)
            obj.UI.Volumes.Data=cell(0,15); obj.UI.Pairs.Data=cell(0,5); obj.UI.Regions.Data=cell(0,10);
            obj.UI.Checks.Data=cell(0,8); obj.UI.RegionChecks.Data=cell(0,6); obj.UI.Comparison.Data=cell(0,8);
        end
        function loadPickedDefinition(obj)
            obj.Definition=[]; p=obj.Controller.Project;
            if isfield(p.definition.resources,'packaging')
                for d=p.definition.resources.packaging'
                    if d{1}.definitionSI.id==string(obj.UI.DefinitionPicker.Value), obj.Definition=d{1}; break; end
                end
            end
            if ~isempty(obj.Definition), obj.UI.DefinitionId.Value=char(obj.Definition.definitionSI.id);
            else, obj.UI.DefinitionId.Value='PACKAGING'; end
            [volumes,pairs,regions]=fsdui.packagingRows(obj.Definition);
            obj.UI.Volumes.Data=volumes; obj.UI.Pairs.Data=pairs; obj.UI.Regions.Data=regions;
        end
        function addRow(obj,name)
            count=size(obj.UI.(name).Data,1)+1;
            switch name
                case 'Volumes'
                    row={char("VOLUME_"+count),char("COMPONENT_"+count),'OTHER','OCCUPIED','','','','','','','','','','',''};
                case 'Pairs', row={char("PAIR_"+count),'','','',''};
                case 'Regions', row={char("REGION_"+count),'','','','','','','','',''};
            end
            obj.UI.(name).Data=[obj.UI.(name).Data;row]; obj.markDraft();
            obj.showEditor(name);
        end
        function selectEditor(obj,name,event)
            obj.SelectedEditorRow=[];
            if ~isempty(event.Indices), obj.SelectedEditorRow=struct('name',name,'index',event.Indices(1,1)); end
        end
        function removeRow(obj)
            if isempty(obj.SelectedEditorRow), return; end
            row=obj.SelectedEditorRow; data=obj.UI.(row.name).Data;
            if row.index<=size(data,1), data(row.index,:)=[]; obj.UI.(row.name).Data=data; obj.markDraft(); end
            obj.SelectedEditorRow=[];
        end
        function showPickedResult(obj)
            previous=obj.Result;
            obj.Result=[]; rs=obj.Controller.Project.definition.results;
            for r=rs'
                if r{1}.id==string(obj.UI.ResultPicker.Value) && r{1}.engine=="PACKAGING", obj.Result=r{1}; break; end
            end
            obj.UI.Comparison.Selection=[];
            if isempty(obj.Result)
                obj.SelectionKey=[]; obj.SelectedCheck=NaN; obj.VisibleChecks=[];
                obj.UI.Checks.Selection=[]; obj.UI.Sample.Items={'1'}; obj.UI.Sample.Value='1';
                obj.UI.Checks.Data=cell(0,8); obj.UI.RegionChecks.Data=cell(0,6); cla(obj.Axes);
                obj.Axes.UserData=[];
                title(obj.Axes,'No packaging evidence','Interpreter','none');
                obj.UI.Status.UserData=[];
                obj.UI.Status.Value={'No stored packaging evidence. No implicit BUMP or physical dimensions.'}; return;
            end
            historyRow=find(obj.UI.Comparison.UserData==obj.Result.id,1);
            if ~isempty(historyRow), obj.UI.Comparison.Selection=[historyRow 5]; end
            native=obj.Result.nativePayload;
            sample=string(obj.UI.Sample.Value);
            obj.UI.Sample.Items=cellstr(compose('%d',(1:numel(native.states))'));
            if ~isempty(previous) && isequaln(previous,obj.Result) && ismember(sample,string(obj.UI.Sample.Items))
                obj.UI.Sample.Value=char(sample);
            else
                obj.SelectionKey=[]; obj.SelectedCheck=NaN; obj.UI.Sample.Value='1';
                if isfinite(native.worstCheckIndex), obj.setCheck(native.worstCheckIndex); end
            end
            obj.fillChecks(); obj.showStatus(); obj.draw();
        end
        function fillChecks(obj)
            if isempty(obj.Result), return; end
            checks=obj.Result.nativePayload.checks; rows=cell(0,8); indices=zeros(0,1);
            for j=1:numel(checks)
                c=checks{j}; filter=string(obj.UI.Filter.Value);
                if (filter=="ISSUES" && c.status=="CLEAR_SAMPLED") || (filter=="CLEAR" && c.status~="CLEAR_SAMPLED"), continue; end
                rows(end+1,:)={c.sampleIndex,char(c.pairId),char(c.status),c.distance_m,c.margin_m, ...
                    char(c.firstComponent),char(c.secondComponent),char(c.diagnostic)}; %#ok<AGROW> Visible presentation rows only.
                indices(end+1,1)=j; %#ok<AGROW> One mapping per displayed check.
            end
            % Native Selection indices describe the OLD visible rows. Never
            % retain them while replacing Data (an equal cell may emit no event).
            obj.UI.Checks.Selection=[];
            obj.VisibleChecks=indices; obj.UI.Checks.Data=rows;
            obj.reconcileSelection(true);
            regions=obj.Result.nativePayload.regions; rows=cell(numel(regions),6);
            for j=1:numel(regions)
                r=regions{j}; rows(j,:)={r.sampleIndex,char(r.regionId),char(r.pointId),char(r.status),r.margin_m,char(r.diagnostic)};
            end
            obj.UI.RegionChecks.Data=rows;
        end
        function selectCheck(obj,event)
            if isempty(event.Indices) || isempty(obj.Result), return; end
            row=event.Indices(1,1);
            if row>numel(obj.VisibleChecks), return; end
            obj.setCheck(obj.VisibleChecks(row)); obj.showStatus(); obj.draw();
        end
        function sampleChanged(obj)
            obj.SelectionKey=[]; obj.SelectedCheck=NaN;
            obj.reconcileSelection(false); obj.showStatus(); obj.draw();
        end
        function filterChanged(obj)
            obj.fillChecks();
            if ~isempty(obj.Result), obj.showStatus(); obj.draw(); end
        end
        function setCheck(obj,index)
            check=obj.Result.nativePayload.checks{index};
            obj.SelectionKey=struct('projectId',obj.Result.projectId,'resultId',obj.Result.id, ...
                'revision',obj.Result.projectRevision,'pairId',check.pairId,'sampleIndex',check.sampleIndex);
            obj.SelectedCheck=index; obj.UI.Sample.Value=char(string(check.sampleIndex));
        end
        function reconcileSelection(obj,chooseVisibleFallback)
            obj.SelectedCheck=NaN; obj.UI.Checks.Selection=[];
            if isempty(obj.Result), obj.SelectionKey=[]; return; end
            checks=obj.Result.nativePayload.checks; key=obj.SelectionKey;
            for row=1:numel(obj.VisibleChecks)
                index=obj.VisibleChecks(row); check=checks{index};
                same=~isempty(key) && key.projectId==obj.Result.projectId && key.resultId==obj.Result.id && ...
                    key.revision==obj.Result.projectRevision && key.pairId==check.pairId && key.sampleIndex==check.sampleIndex;
                if same || (isempty(key) && ~chooseVisibleFallback && check.sampleIndex==str2double(obj.UI.Sample.Value))
                    obj.setCheck(index); obj.UI.Checks.Selection=[row 3]; return;
                end
            end
            obj.SelectionKey=[];
            if chooseVisibleFallback && ~isempty(obj.VisibleChecks)
                obj.setCheck(obj.VisibleChecks(1)); obj.UI.Checks.Selection=[1 3];
            end
        end
        function draw(obj)
            if isempty(obj.Result), return; end
            fsd.packaging.plotResult(obj.Result.nativePayload,obj.Axes,str2double(obj.UI.Sample.Value),obj.SelectedCheck);
            status=obj.compatibility(obj.Result.id);
            lines=string(obj.Axes.Title.String);
            title(obj.Axes,["["+status+"]";lines(:)],'Interpreter','none','FontSize',10);
        end
        function status=compatibility(obj,id)
            rs=obj.Controller.Project.definition.results; status="INCOMPATIBLE";
            for j=1:numel(rs)
                if rs{j}.id~=id, continue; end
                if numel(obj.Reports)==numel(rs), report=obj.Reports{j};
                else, report=fsd.project.resultCompatibility(rs{j},obj.Controller.Project); end
                status=report.status; return;
            end
        end
        function showStatus(obj)
            r=obj.Result; n=r.nativePayload; current=obj.Controller.Project;
            status=obj.compatibility(r.id); warning="Stored evidence; only declared solids/pairs/samples checked.";
            if ~ismember(status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"]), warning="HISTORICAL ONLY / STALE: NOT current geometry/packaging evidence."; end
            obj.UI.Status.Value=cellstr(["["+status+"] "+r.id+" | "+n.status+" | execution rev "+r.projectRevision+" / current rev "+current.definition.revision; ...
                warning;"Coverage complete="+n.coverage.complete+"; resolved "+n.coverage.resolvedSamples+"/"+n.coverage.requestedSamples+ ...
                "; minimum OBSERVED distance="+n.minimumObservedDistance_m+" m. Not manufacturing/continuous approval."]);
            obj.UI.Status.UserData=struct('compatibility',status,'resultId',r.id,'nativeStatus',n.status);
            if isfinite(obj.SelectedCheck)
                check=n.checks{obj.SelectedCheck};
                obj.UI.Status.Value=[obj.UI.Status.Value;cellstr("Selected: "+r.id+" | "+check.pairId+ ...
                    " | sample "+check.sampleIndex+" | "+check.status+" | "+check.diagnostic)];
                obj.UI.Status.UserData.selection=obj.SelectionKey;
                obj.UI.Status.UserData.pairStatus=check.status;
            end
        end
        function fillComparison(obj,records)
            rows=cell(numel(records),8); ids=strings(numel(records),1);
            for j=1:numel(records)
                r=records{j}; inputs=r.scenarioAtExecution.definition.inputs; score=NaN; index=NaN;
                if ~isempty(inputs.candidateIndex)
                    index=inputs.candidateIndex; score=inputs.parent.nativePayload.search.records{index}.score;
                end
                n=r.nativePayload; ids(j)=r.id;
                rows(j,:)={char(r.id),char(inputs.selection),index,score,char(n.status),n.coverage.complete, ...
                    n.minimumObservedDistance_m,char(obj.compatibility(r.id))};
            end
            obj.UI.Comparison.Selection=[]; obj.UI.Comparison.Data=rows; obj.UI.Comparison.UserData=ids;
        end
        function selectComparison(obj,event)
            if isempty(event.Indices), return; end
            ids=obj.UI.Comparison.UserData; obj.UI.ResultPicker.Value=char(ids(event.Indices(1,1))); obj.showPickedResult();
        end
        function fail(obj,cause)
            obj.UI.Status.Value=cellstr(fsdui.errorText(cause));
            uialert(obj.Figure,cause.message,'Packaging operation not completed','Icon','error');
        end
        function markDraft(obj)
            obj.Dirty=true; obj.UI.Apply.Text='Apply definitions *'; obj.Draft();
        end
        function showEditor(obj,name)
            obj.UI.EditorSelector.Value=char(name);
            obj.SelectedEditorRow=[];
            for item=["Volumes","Pairs","Regions"]
                obj.UI.(item).Visible=matlab.lang.OnOffSwitchState(item==string(name));
            end
        end
        function showEvidence(obj)
            names=["Checks","RegionChecks","Comparison"];
            labels=["Pair checks","Point regions","History / compare"];
            for j=1:numel(names)
                obj.UI.(names(j)).Visible=matlab.lang.OnOffSwitchState(labels(j)==string(obj.UI.EvidenceSelector.Value));
            end
        end
        function pickDefinition(obj)
            if obj.Dirty
                if isempty(obj.Definition), obj.UI.DefinitionPicker.Value='NONE';
                else, obj.UI.DefinitionPicker.Value=char(obj.Definition.definitionSI.id); end
                obj.fail(MException('fsd:ui:UnappliedDraft','Apply the packaging draft before selecting another definition.')); return;
            end
            obj.loadPickedDefinition();
        end
    end
    methods (Static,Access=private)
        function bar=bar(parent,widths)
            bar=uigridlayout(parent,[1 numel(widths)]); bar.ColumnWidth=widths; bar.Padding=0;
        end
    end
end
