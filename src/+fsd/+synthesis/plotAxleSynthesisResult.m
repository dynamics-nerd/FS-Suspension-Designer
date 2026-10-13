function figures = plotAxleSynthesisResult(result,indices)
%PLOTAXLESYNTHESISRESULT Both geometries, native targets and complete search trace.
fsd.synthesis.validateAxleSynthesisResult(result); records=result.search.records;
if nargin<2
    indices=1;
    if isfinite(result.selectedIndex), indices=unique([1;result.selectedIndex],'stable'); end
    indices=indices(cellfun(@(e) ~isempty(e.candidate),records(indices)));
end
requireSynthesis(isnumeric(indices) && isreal(indices) && (isvector(indices) || isempty(indices)) && ...
    all(isfinite(indices) & indices>=1 & indices<=numel(records) & indices==fix(indices)) && ...
    numel(unique(indices))==numel(indices),'Unique recorded indices required.');
requireSynthesis(all(cellfun(@(e) ~isempty(e.candidate),records(indices))),'Rejected builder has no physical candidate.');
fig=figure('Name','Axle synthesis trace','Position',[50,50,1100,900]); theme(fig,'dark'); tiledlayout(fig,4,1);
x=(1:numel(records))'; ax=nexttile;
plot(ax,x,cellfun(@(e) e.score,records),'o-'); grid(ax,'on');
xlabel(ax,'Unique axle evaluation ID'); ylabel(ax,'SOFT score [1]'); title(ax,'Explored eligible scores; NaN is unavailable');
ax=nexttile; values=cell2mat(cellfun(@(e) e.u',records,'UniformOutput',false));
if ~isempty(values)
    plot(ax,x,values,'o-'); legend(ax,cellfun(@(v) v.id,result.problem.variables),'Interpreter','none','Location','best');
end
grid(ax,'on'); xlabel(ax,'Unique axle evaluation ID'); ylabel(ax,'Independent u [1]');
ax=nexttile; eligible=cellfun(@(e) e.eligible,records);
plot(ax,x,cumsum(eligible),'o-',x,cumsum(~eligible),'x-'); grid(ax,'on');
legend(ax,{'Sampled eligible','Rejected / incomplete'},'Location','best');
xlabel(ax,'Unique axle evaluation ID'); ylabel(ax,'Axle count'); title(ax,result.search.stopReason,'Interpreter','none');
ax=nexttile; history=result.search.history;
plot(ax,1:numel(history),cellfun(@(h) h.step,history),'o-'); grid(ax,'on');
xlabel(ax,'Attempt ID (including cache)'); ylabel(ax,'Poll step [1]'); title(ax,'Local bounded search, not global optimality');
fig.UserData=result; figures=fig;
diagnostic=figure('Name','Axle synthesis diagnostics','Position',[50,50,1000,800]); theme(diagnostic,'dark'); tiledlayout(diagnostic,3,1);
ax=nexttile; labels=cellfun(@(e) e.classification,records); kinds=unique(labels,'stable'); [~,status]=ismember(labels,kinds);
plot(ax,x,status,'o','LineStyle','none'); yticks(ax,1:numel(kinds)); yticklabels(ax,kinds); ax.TickLabelInterpreter='none';
xlabel(ax,'Unique axle evaluation ID'); ylabel(ax,'State'); grid(ax,'on');
ax=nexttile([2,1]); axis(ax,'off'); selection="NO_AUTOMATIC_WINNER";
if isfinite(result.selectedIndex), selection="Selected explored axle evaluation "+string(result.selectedIndex); end
lines=[selection;"Seed evaluation: 1";result.diagnostics];
for i=1:numel(records)
    e=records{i}; lines(end+1,1)="Evaluation "+i+": "+e.classification; %#ok<AGROW>
    if strlength(e.exceptionId)>0, lines(end+1,1)=e.exceptionId; end %#ok<AGROW>
    for j=1:3
        p=e.physical{j}; if isempty(p) || strlength(p.exceptionId)==0, continue; end
        lines(end+1,1)=p.scopeId+" "+p.failureStage+": "+p.exceptionId; %#ok<AGROW>
    end
    if numel(lines)>=12, lines(end+1,1)="All attempts/evidence retained in figure UserData and result."; break; end %#ok<AGROW>
end
wrapped=strings(0,1);
for line=lines(:)'
    chars=char(line);
    for start=1:68:numel(chars), wrapped(end+1,1)=string(chars(start:min(start+67,numel(chars)))); end %#ok<AGROW>
end
text(ax,0,1,join(wrapped,newline),'Units','normalized','VerticalAlignment','top','Interpreter','none','FontSize',9);
diagnostic.UserData=result; figures(end+1,1)=diagnostic;
if isempty(indices), return; end
candidates=cellfun(@(e) e.candidate,records(indices),'UniformOutput',false);
targetFigures=fsd.analysis.plotDesignTargetEvaluation(result.problem.specification,candidates);
for k=1:numel(targetFigures)
    lines=findobj(targetFigures(k),'Type','line');
    for i=indices(:)'
        e=records{i}; id=e.candidate.definitionSI.id;
        for j=1:numel(lines)
            name=string(lines(j).DisplayName);
            if name==id || startsWith(name,id+" "), lines(j).DisplayName=name+" | axle synthesis "+e.classification; end
        end
    end
end
figures=[figures;targetFigures];
for i=indices(:)'
    e=records{i}; f=figure('Name',"Axle geometry evaluation "+i,'Position',[50,50,1200,700]); theme(f,'dark'); tiledlayout(f,1,2);
    for j=1:2
        ax=nexttile; g=e.axle.leftGeometry; if j==2, g=e.axle.rightGeometry; end
        % Neutral native data-driven strokes preserve visibility in both themes.
        h=fsd.geometry.plotDoubleWishboneGeometry(g,ax);
        set([h.uca;h.lca;h.tieRod;h.upright;h.wheelReference],'Color',[.5,.5,.5]);
        set(h.wheelAxis,'Color',[.5,.5,.5]); set(h.hardpoints,'MarkerFaceColor',[.5,.5,.5]);
        title(ax,g.cornerId+" | evaluation "+i+" | "+e.classification,'Interpreter','none');
    end
    f.UserData=e; figures(end+1,1)=f; %#ok<AGROW>
end
end
