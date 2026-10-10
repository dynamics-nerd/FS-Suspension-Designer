function figures = plotDesignTargetEvaluation(specification, candidates)
%PLOTDESIGNTARGETEVALUATION Actual/target/bands/errors with gaps; no engineering solve.
if ~iscell(candidates), candidates = {candidates}; end
fsd.model.validateDesignSpecification(specification);
assessments = cell(size(candidates));
for i = 1:numel(candidates)
    assessments{i} = fsd.analysis.evaluateDesignCandidate(specification,candidates{i});
end
targets = specification.definitionSI.targets.definitionSI.targets;
figures = gobjects(numel(targets),1);
for j = 1:numel(targets)
    t = targets{j}.definitionSI;
    figures(j) = figure("Name","Design requirement "+t.id);
    % Local deterministic fallback: auto can change themes during first export.
    % Set the WHOLE figure before creating children; never alter user preferences.
    % Callers can subsequently use theme(fig,"light") for a coherent light view.
    theme(figures(j),"dark");
    tiledlayout(figures(j),2,1);
    ax = nexttile; hold(ax,"on"); err = nexttile; hold(err,"on");
    % Fixed sRGB grays contrast with BOTH MATLAB light and dark backgrounds.
    % Do not capture XColor: hidden figures can apply their theme only at export.
    % These are presentation colors, not engineering constants (see docs).
    % The declared target has its own knots, independent of candidate grids.
    xTarget = t.x; if isempty(xTarget), xTarget = 0; end
    nominal = declaredValues(t.value,xTarget);
    lower = declaredValues(t.lower,xTarget); upper = declaredValues(t.upper,xTarget);
    if ~isempty(t.value), lower = nominal-t.tolerance; upper = nominal+t.tolerance; end
    plot(ax,xTarget,nominal,"s--","Color",[.5,.5,.5],"LineWidth",2,"MarkerSize",7,"DisplayName","Target");
    plot(ax,xTarget,lower,".:","Color",[.45,.45,.45],"LineWidth",1.5,"DisplayName","Lower acceptance");
    plot(ax,xTarget,upper,".:","Color",[.45,.45,.45],"LineWidth",1.5,"DisplayName","Upper acceptance");
    ax.ColorOrderIndex = 1;
    for i = 1:numel(candidates)
        a = assessments{i}.targetAssessments{j}; y = a.compared; y(~a.valid) = NaN;
        [xPlot,yPlot] = disconnectedPlot(a.x,y,a.connected);
        coverage = sprintf("; domain coverage %.1f%%",100*a.domainCoverage);
        plot(ax,xPlot,yPlot,"o-","LineWidth",1.5,"DisplayName",assessments{i}.candidateId+" — "+a.status+coverage);
        [xError,yError] = disconnectedPlot(a.x,a.deviation,a.connected);
        plot(err,xError,yError,"o-","LineWidth",1.5,"DisplayName",assessments{i}.candidateId);
        bad = a.valid & a.violation > 0;
        plot(ax,a.x(bad),y(bad),"rx","HandleVisibility","off");
    end
    ylabel(ax,t.metricId+" ["+t.unit+"]","Interpreter","none");
    title(ax,t.id+" — declared target / evaluated samples only","Interpreter","none"); legend(ax,"Location","best","Interpreter","none"); grid(ax,"on");
    ylabel(err,"Signed deviation ["+t.unit+"]"); xlabel(err,t.independentVariable+" ["+t.xUnit+"]","Interpreter","none"); grid(err,"on");
end
end

function values = declaredValues(values,x)
if isempty(values), values = nan(size(x)); end
end

function [x,y] = disconnectedPlot(x,y,connected)
% Duplicate/NaN separator breaks even a branch gap between two valid samples.
outX = zeros(0,1); outY = zeros(0,1);
for i = 1:numel(x)
    outX(end+1,1) = x(i); outY(end+1,1) = y(i); %#ok<AGROW>
    if i < numel(x) && ~connected(i)
        outX(end+1,1) = NaN; outY(end+1,1) = NaN; %#ok<AGROW>
    end
end
x = outX; y = outY;
end
