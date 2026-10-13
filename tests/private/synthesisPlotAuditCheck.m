function reports = synthesisPlotAuditCheck(result,folder,appearance,indices)
%SYNTHESISPLOTAUDITCHECK Native objects/PNG: text, contrast, targets and no solves.
if nargin<4, indices=[]; explicit=false; else, explicit=true; end
if ~isfolder(folder), mkdir(folder); end
profile clear; profile on;
if explicit, figures=fsd.synthesis.plotSynthesisResult(result,indices);
else, figures=fsd.synthesis.plotSynthesisResult(result); end
profile off; info=profile('info'); names=string({info.FunctionTable.FunctionName});
assert(~any(contains(names,["solveBump","fsolve","fzero"])));
if explicit, count=numel(indices);
else, count=numel(unique([1;result.feasibleIndices])); end
if count<2 || isscalar(result.search.records)
    assert(~any(contains(names,'compareSynthesisCandidates')),'A single candidate must not call comparison.');
end
cleanup=onCleanup(@() close(figures)); reports=cell(numel(figures),1);
for i=1:numel(figures)
    fig=figures(i); theme(fig,appearance); file=fullfile(folder,appearance+"-"+i+".png");
    % Immediate first export also runs in the fresh-session verification entrypoint.
    exportgraphics(fig,file,'Resolution',120); pixels=double(imread(file))/255;
    background=reshape(pixels(1,1,:),1,3); expected=[0,0,0];
    if appearance=="light", expected=[1,1,1]; end
    assert(isequal(background,expected),'PNG must use the requested local theme.');
    axes=findall(fig,'Type','axes');
    for ax=axes'
        assert(contrast(ax.XColor,ax.Color)>=4.5 && contrast(ax.YColor,ax.Color)>=4.5);
        if strcmp(ax.Visible,'on')
            assert(strlength(string(ax.YLabel.String))>0);
        end
    end
    text=findall(fig,'Type','text'); visibleText=0;
    for obj=text'
        if isempty(obj.String), continue; end
        color=obj.Color;
        if ~isnumeric(color), continue; end
        assert(contrast(color,background)>=4.5,'Text must contrast with the exported exterior.');
        visibleText=visibleText+nnz(all(abs(pixels-reshape(color,1,1,3))<=2/255,3));
    end
    assert(visibleText>=20,'Exported PNG must contain actual foreground text pixels.');
    target=findobj(fig,'Type','line','DisplayName','Target');
    if ~isempty(target)
        assert(any(arrayfun(@(ax) strlength(string(ax.XLabel.String))>0,axes)),'Native two-panel figure needs bottom-axis units.');
        targets=result.problem.specification.definitionSI.targets.definitionSI.targets;
        matched=targets(cellfun(@(t) contains(string(fig.Name),t.definitionSI.id),targets));
        assert(isscalar(matched),'Target figure must have one exact requirement.'); td=matched{1}.definitionSI;
        assert(isequaln(target.XData(:),td.x(:)) && isequaln(target.YData(:),td.value(:)));
        reports{i}=designTargetRenderCheck(fig,file);
    else
        assert(all(arrayfun(@(ax) strcmp(ax.Visible,'off') || strlength(string(ax.XLabel.String))>0,axes)));
        reports{i}=struct('file',string(file),'background',background,'textPixels',visibleText);
    end
end
if isempty(result.feasibleIndices) || isnan(result.selectedIndex)
    details=findobj(figures,'Name','Inverse synthesis diagnostics');
    if ~isempty(details)
        text=findall(details,'Type','text'); labels=strings(0,1);
        for obj=text'
            part=string(obj.String); labels=[labels;part(:)]; %#ok<AGROW>
        end
        assert(any(contains(labels,'NO_AUTOMATIC_WINNER')));
        assert(isnan(details.UserData.selectedIndex));
    end
end
trace=figures(1); assert(isequaln(trace.UserData.records,result.search.records));
scores=findobj(trace,'Type','line','Marker','o');
expected=cellfun(@(e) e.score,result.search.records);
assert(any(arrayfun(@(line) isequaln(line.YData(:),expected(:)),scores)),'Trace must retain score gaps.');
end

function value = contrast(a,b)
value=(max(luminance(a),luminance(b))+.05)/(min(luminance(a),luminance(b))+.05);
end
function value = luminance(rgb)
linear=rgb/12.92; mask=rgb>.04045; linear(mask)=((rgb(mask)+.055)/1.055).^2.4;
value=sum(linear.*[.2126,.7152,.0722]);
end
