function figures = plotAxleSynthesisResult(result,indices)
%PLOTAXLESYNTHESISRESULT Native joint reporting with legends outside the data.
fsd.synthesis.validateAxleSynthesisResult(result);
if nargin<2, figures=jointSynthesisPlot(result);
else, figures=jointSynthesisPlot(result,indices); end
end
