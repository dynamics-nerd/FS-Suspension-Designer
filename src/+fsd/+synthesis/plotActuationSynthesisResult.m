function figures = plotActuationSynthesisResult(result,indices)
%PLOTACTUATIONSYNTHESISRESULT Validated stored evidence, no physical solves.
fsd.synthesis.validateActuationSynthesisResult(result); records=result.search.records;
if nargin<2
    indices=1; if isfinite(result.selectedIndex), indices=unique([1;result.selectedIndex],'stable'); end
    indices=indices(cellfun(@(e)~isempty(e.candidate),records(indices)));
end
requireSynthesis(isnumeric(indices) && isreal(indices) && (isvector(indices) || isempty(indices)) && ...
    all(isfinite(indices) & indices==fix(indices) & indices>=1 & indices<=numel(records)) && ...
    numel(unique(indices))==numel(indices),'Unique recorded indices required.');
requireSynthesis(all(cellfun(@(e)~isempty(e.candidate),records(indices))),'Builder failures have no representable candidate.');
x=(1:numel(records))'; figures=gobjects(0,1);
f=frame('Actuation synthesis trace'); layout=tiledlayout(f,2,2,'TileSpacing','loose','Padding','loose');
ax=nexttile(layout); plot(ax,x,cellfun(@(e)e.score,records),'o-'); grid(ax,'on');
xlabel(ax,'Unique evaluation ID'); ylabel(ax,'SOFT score [1]'); title(ax,'Eligible scores; unavailable values remain NaN');
ax=nexttile(layout); values=cell2mat(cellfun(@(e)e.u',records,'UniformOutput',false));
if ~isempty(values)
    plot(ax,x,values,'o-'); legend(ax,cellfun(@(v)v.id,result.problem.variables),'Interpreter','none','Location','eastoutside');
end
grid(ax,'on'); xlabel(ax,'Unique evaluation ID'); ylabel(ax,'Independent u [1]');
ax=nexttile(layout); eligible=cellfun(@(e)e.eligible,records);
plot(ax,x,cumsum(eligible),'o-',x,cumsum(~eligible),'x-'); grid(ax,'on');
legend(ax,{'Sampled eligible','Rejected / incomplete'},'Location','eastoutside');
xlabel(ax,'Unique evaluation ID'); ylabel(ax,'Count'); title(ax,result.search.stopReason,'Interpreter','none');
ax=nexttile(layout); history=result.search.history;
plot(ax,1:numel(history),cellfun(@(h)h.step,history),'o-'); grid(ax,'on');
xlabel(ax,'Attempt ID including cache'); ylabel(ax,'Poll step [1]'); title(ax,'Local bounded search, not global optimality');
f.UserData=result; figures(end+1,1)=f;
f=frame('Actuation synthesis diagnostics'); layout=tiledlayout(f,2,1,'Padding','loose'); ax=nexttile(layout);
labels=cellfun(@(e)e.classification,records); kinds=unique(labels,'stable'); [~,status]=ismember(labels,kinds);
plot(ax,x,status,'o','LineStyle','none'); yticks(ax,1:numel(kinds)); yticklabels(ax,kinds); ax.TickLabelInterpreter='none';
xlabel(ax,'Unique evaluation ID'); ylabel(ax,'State'); grid(ax,'on'); ax=nexttile(layout); axis(ax,'off');
selection="NO_AUTOMATIC_WINNER";
if isfinite(result.selectedIndex), selection="Selected explored evaluation "+result.selectedIndex; end
lines=[selection;"Seed evaluation: 1";result.diagnostics];
for j=1:numel(records)
    e=records{j}; lines(end+1,1)="Evaluation "+j+": "+e.classification+"; HARD "+e.hardFeasibility; %#ok<AGROW>
    if strlength(e.exceptionId)>0, lines(end+1,1)=e.exceptionId; end %#ok<AGROW>
    if numel(lines)>=10, lines(end+1,1)="Complete history and evidence retained in result/UserData."; break; end %#ok<AGROW>
end
text(ax,0,1,join(lines,newline),'Interpreter','none','VerticalAlignment','top','FontSize',11,'Color',[.46,.46,.46]);
f.UserData=result; figures(end+1,1)=f;
f=frame('Actuation coordinate changes'); ax=axes('Parent',f);
changes=cell2mat(cellfun(@(e)(e.x_m-result.problem.initial_m)',records,'UniformOutput',false));
if ~isempty(changes)
    plot(ax,x,changes,'o-'); legend(ax,cellfun(@(v)v.id,result.problem.variables),'Interpreter','none','Location','eastoutside');
end
xlabel(ax,'Unique evaluation ID'); ylabel(ax,'Requested coordinate change [m]'); grid(ax,'on'); f.UserData=result;
figures(end+1,1)=f;
if ~isempty(indices)
    candidates=cellfun(@(e)e.candidate,records(indices),'UniformOutput',false);
    targets=fsd.analysis.plotDesignTargetEvaluation(result.problem.specification,candidates);
    for j=1:numel(targets)
        targets(j).Position=[50,50,1500,900];
        set(findall(targets(j),'Type','legend'),'Location','eastoutside');
    end
    figures=[figures;targets(:)];
end
for j=indices(:)'
    e=records{j}; p=e.actuationEvidence; if isempty(p), continue; end
    f=frame("Actuation curves evaluation "+j+" — "+e.classification);
    handles=fsd.analysis.plotActuationSweep(p.analysis,f);
    valid=p.sweep.converged & ~reshape([p.sweep.results.isIllConditioned],[],1);
    branch=arrayfun(@(s)s.diagnostics.selectedCandidateIndex,p.sweep.results);
    for k=1:numel(handles.lines)
        line=handles.lines(k); line.Color=[.5,.5,.5];
        [xx,yy]=gapped(line.XData,line.YData,valid,diff(branch)==0);
        line.XData=xx; line.YData=yy;
    end
    f.UserData=e; figures(end+1,1)=f; %#ok<AGROW>
    if ~isempty(e.mechanicalEvidence)
        f=frame("Mechanical curves evaluation "+j+" — "+e.classification);
        fsd.analysis.plotSpringDamperSweep(e.mechanicalEvidence.analysis,e.mechanical,e.actuation,f);
        f.UserData=e; figures(end+1,1)=f; %#ok<AGROW>
    end
    candidates=find(p.sweep.converged);
    if ~isempty(candidates)
        [~,near]=min(abs(p.sweep.requestedWheelTravel_m(candidates))); index=candidates(near);
        f=frame("Actuation geometry evaluation "+j+" — "+e.classification); ax=axes('Parent',f);
        suspensionHandles=fsd.geometry.plotDoubleWishboneGeometry(e.geometry,ax); hold(ax,'on');
        suspensionHandles.upright.Color=[.5,.5,.5];
        handles=fsd.kinematics.plotActuationResult(e.actuation,p.sweep.results(index),ax);
        % Display the same infinite line near the actual rocker, including rear
        % corners. The canonical closest-to-origin point is not a bearing.
        centre=p.sweep.results(index).diagnostics.rockerCircleCenter_m;
        offset=centre-e.actuation.rocker.axis.point_m;
        handles.rockerAxis.XData=handles.rockerAxis.XData+offset(1);
        handles.rockerAxis.YData=handles.rockerAxis.YData+offset(2);
        handles.rockerAxis.ZData=handles.rockerAxis.ZData+offset(3);
        handles.rockerAxis.Color=[.5,.5,.5]; handles.axisPoint.Visible='off';
        title(ax,"Evaluation "+j+"; existing sample z="+p.sweep.requestedWheelTravel_m(index)+" m",'Interpreter','none');
        f.UserData=struct('evaluation',e,'sampleIndex',index,'posePolicy',"EXISTING_CONVERGED_SAMPLE_NEAREST_ZERO");
        figures(end+1,1)=f; %#ok<AGROW>
    end
end
for j=1:numel(figures)
    axesList=findall(figures(j),'Type','axes');
    for k=1:numel(axesList)
        axesList(k).XAxis.Exponent=0; axesList(k).YAxis.Exponent=0;
    end
    set(findall(figures(j),'Type','legend'),'Location','eastoutside');
end
end

function f = frame(name)
f=figure('Name',name,'Position',[50,50,1500,900]); theme(f,'dark');
end

function [xx,yy] = gapped(x,y,valid,connected)
% Presentation only: preserve native sample values, insert separators at gaps.
x=x(:); y=y(:); y(~valid)=NaN; xx=zeros(0,1); yy=xx;
for j=1:numel(x)
    xx(end+1,1)=x(j); yy(end+1,1)=y(j); %#ok<AGROW>
    if j<numel(x) && ~connected(j), xx(end+1,1)=NaN; yy(end+1,1)=NaN; end %#ok<AGROW>
end
end
