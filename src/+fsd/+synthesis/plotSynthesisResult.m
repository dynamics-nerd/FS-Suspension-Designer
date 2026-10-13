function figures = plotSynthesisResult(result,indices)
%PLOTSYNTHESISRESULT Trace, variables, quality counts and native v0.11 target plots.
fsd.synthesis.validateSynthesisResult(result);
if nargin<2
    indices=unique([1;result.feasibleIndices],'stable');
    indices=indices(cellfun(@(e) ~isempty(e.candidate),result.search.records(indices)));
end
candidates=cell(0,1);
if ~isempty(indices)
    requireSynthesis(isnumeric(indices) && isreal(indices) && isvector(indices) && ...
        all(isfinite(indices)) && all(indices>=1 & indices<=numel(result.search.records) & fix(indices)==indices) && ...
        numel(unique(indices))==numel(indices),'Explicit unique evaluation indices required.');
    requireSynthesis(all(cellfun(@(e) ~isempty(e.candidate),result.search.records(indices))), ...
        'Failed pipeline has no candidate to plot.');
    if numel(indices)>=2, fsd.synthesis.compareSynthesisCandidates(result,indices); end
    candidates=cellfun(@(e) e.candidate,result.search.records(indices),'UniformOutput',false);
end
fig=figure('Name','Inverse synthesis trace'); theme(fig,'dark');
tiledlayout(fig,4,1); records=result.search.records; n=numel(records); x=(1:n)';
ax=nexttile; score=cellfun(@(e) e.score,records); plot(ax,x,score,'o-'); grid(ax,'on');
xlabel(ax,'Unique evaluation ID'); ylabel(ax,'SOFT score [1]'); title(ax,'Eligible explored scores only; NaN is unavailable');
ax=nexttile; values=cell2mat(cellfun(@(e) e.u',records,'UniformOutput',false));
if ~isempty(values)
    plot(ax,x,values,'o-'); legend(ax,cellfun(@(v) v.id,result.problem.variables),'Interpreter','none','Location','best');
end
grid(ax,'on'); xlabel(ax,'Unique evaluation ID'); ylabel(ax,'Coordinates [1]');
ax=nexttile; eligible=cellfun(@(e) e.eligible,records);
plot(ax,x,cumsum(eligible),'o-',x,cumsum(~eligible),'x-'); grid(ax,'on');
legend(ax,{'Sampled eligible','Failed / incomplete / HARD rejected'},'Location','best');
xlabel(ax,'Unique evaluation ID'); ylabel(ax,'Candidate count'); title(ax,result.search.stopReason,'Interpreter','none');
ax=nexttile; history=result.search.history;
plot(ax,(1:numel(history))',cellfun(@(h) h.step,history),'o-'); grid(ax,'on');
xlabel(ax,'Attempt ID (including cache hits)'); ylabel(ax,'Poll step [1]');
title(ax,'Budgeted local search; no global convergence claim');
figures=fig;
fig.UserData=struct('diagnostics',result.diagnostics,'records',{records},'selectedIndex',result.selectedIndex);
if numel(indices)<2 || isempty(result.feasibleIndices)
    figures(end+1,1)=plotDiagnostics(result);
end
if ~isempty(indices)
    targetFigures=fsd.analysis.plotDesignTargetEvaluation(result.problem.specification,candidates);
    for k=1:numel(targetFigures)
        lines=findobj(targetFigures(k),'Type','line');
        for i=indices(:)'
            e=records{i}; candidateId=e.candidate.definitionSI.id;
            for j=1:numel(lines)
                name=string(lines(j).DisplayName);
                if name==candidateId || startsWith(name,candidateId+" ")
                    lines(j).DisplayName=string(lines(j).DisplayName)+" | synthesis "+e.classification;
                end
            end
        end
    end
    figures=[figures;targetFigures];
end
end

function fig = plotDiagnostics(result)
% No candidate/assessment is required. Show status of every attempted geometry.
fig=figure('Name','Inverse synthesis diagnostics'); theme(fig,'dark'); tiledlayout(fig,3,1);
records=result.search.records; labels=cellfun(@(e) e.classification,records); kinds=unique(labels,'stable');
[~,status]=ismember(labels,kinds); ax=nexttile;
plot(ax,1:numel(records),status,'o','LineStyle','none'); grid(ax,'on');
yticks(ax,1:numel(kinds)); yticklabels(ax,kinds); ax.TickLabelInterpreter='none';
xlabel(ax,'Unique evaluation ID'); ylabel(ax,'Classification [category]');
title(ax,sprintf('Eligible %d / %d; stop %s',numel(result.feasibleIndices),numel(records),result.search.stopReason),'Interpreter','none');
ax=nexttile([2,1]); axis(ax,'off'); focus=result.selectedIndex;
selection="NO_AUTOMATIC_WINNER";
if isnan(focus), focus=1; else, selection="Selected explored evaluation "+string(focus); end
e=records{focus}; lines=[selection;"Seed evaluation: 1; displayed evaluation: "+string(focus); ...
    "State: "+e.classification;"Evidence: "+e.evidenceStatus; ...
    "Stage: "+e.failureStage;"Error: "+e.exceptionId;e.exceptionMessage;result.diagnostics];
scoreText="Unavailable"; if isfinite(e.score), scoreText=string(e.score); end
lines=[lines(1:4);"Score [1]: "+scoreText;lines(5:end)];
for i=1:numel(e.changes)
    c=e.changes{i}; lines(end+1,1)=c.hardpointId+" "+c.component+": "+string(c.seed_m)+" -> "+string(c.candidate_m)+" m"; %#ok<AGROW>
end
if isempty(e.changes), lines(end+1,1)="Hardpoints: no coordinate changes"; end
% Presentation-only wrapping keeps native identifiers readable at first export.
wrapped=strings(0,1);
for line=lines(:)'
    chars=char(line);
    for start=1:64:numel(chars), wrapped(end+1,1)=string(chars(start:min(start+63,numel(chars)))); end %#ok<AGROW>
end
text(ax,0,1,join(wrapped,newline),'Units','normalized','VerticalAlignment','top', ...
    'Interpreter','none','Color',[.46,.46,.46],'FontSize',9);
fig.UserData=struct('diagnostics',result.diagnostics,'records',{records},'displayedEvaluationId',focus, ...
    'selectedIndex',result.selectedIndex);
end
