function figures = plotSteeringSynthesisResult(result,indices)
%PLOTSTEERINGSYNTHESISRESULT Native curves/gaps, joint trace and changed coordinates.
fsd.synthesis.validateSteeringSynthesisResult(result);
if nargin<2, figures=jointSynthesisPlot(result);
else, figures=jointSynthesisPlot(result,indices); end
for j=1:numel(figures)
    figures(j).Name=replace(string(figures(j).Name),"Axle","Steering");
end
% A native solved sample, never a synthesized neutral pose or another solve.
views=figures;
for j=1:numel(views)
    e=views(j).UserData;
    if ~isstruct(e) || ~isfield(e,'kind') || e.kind~="SteeringSynthesisEvaluation", continue; end
    p=e.physical{4};
    if isempty(p) || isempty(p.analysis), continue; end
    available=find(p.sweep.converged); if isempty(available), continue; end
    [~,nearest]=min(abs(p.sweep.requestedRackTravel_m(available))); k=available(nearest);
    f=figure('Name',"Solved steering mechanism evaluation "+e.evaluationId,'Position',[50,50,1100,750]);
    theme(f,'dark'); ax=axes('Parent',f);
    h=fsd.analysis.plotSteeringSystem(e.steering,p.sweep.results(k),p.analysis.states(k),ax);
    set([h.staticRack;h.currentRack],'Color',[.5,.5,.5]);
    title(ax,"Evaluation "+e.evaluationId+" | "+e.classification+" | "+string(ax.Title.String),'Interpreter','none');
    f.UserData=struct('evaluation',e,'rackSampleIndex',k,'posePolicy',"EXISTING_CONVERGED_SAMPLE_NEAREST_CENTER");
    figures(end+1,1)=f; %#ok<AGROW>
end
fig=figure('Name','Steering design coordinate changes','Position',[50,50,1100,700]);
theme(fig,'dark'); ax=axes(fig); records=result.search.records;
values=cell2mat(cellfun(@(e) e.x_m',records,'UniformOutput',false))-result.problem.initial_m';
if ~isempty(values)
    plot(ax,(1:numel(records))',values,'o-');
    legend(ax,cellfun(@(v) v.id,result.problem.variables),'Interpreter','none','Location','eastoutside');
end
xlabel(ax,'Unique joint evaluation ID'); ylabel(ax,'Independent coordinate change [m]'); grid(ax,'on');
title(ax,'Authorized design coordinates, not rack motion'); fig.UserData=result;
figures(end+1,1)=fig;
end
