function report = designTargetRenderCheck(fig, filename)
%DESIGNTARGETRENDERCHECK Real PNG + final sRGB contrast, not just initial handles.
% 3:1 is a graphical acceptance criterion, NOT an engineering tolerance.
target = findobj(fig,"Type","line","DisplayName","Target"); ax = target.Parent;
% A mouse hovering over visible axes must not add a toolbar to QA screenshots.
axesObjects = findall(fig,"Type","axes");
for i = 1:numel(axesObjects), axesObjects(i).Toolbar.Visible = "off"; end
before = [target.Color;ax.XColor;ax.Color];
beforeContrast = colorContrast(target.Color,ax.Color);
assert(beforeContrast >= 3.5,"Target must also contrast before export.");
lastwarn(""); exportgraphics(fig,filename,"Resolution",120);
[warningText,warningId] = lastwarn;
assert(isempty(warningText),"fsd:tests:RenderWarning","%s: %s",warningId,warningText);
after = [target.Color;ax.XColor;ax.Color];
contrast = colorContrast(target.Color,ax.Color);
assert(contrast >= 3.5,"fsd:tests:TargetContrast","Target contrast lacks margin above 3:1.");
pixels = double(imread(filename))/255;
assert(size(pixels,3) == 3,"PNG must be RGB.");
[targetPixels,pngTarget] = matchingPixels(pixels,target.Color);
[backgroundPixels,pngBackground] = matchingPixels(pixels,ax.Color);
assert(targetPixels > 30 && backgroundPixels > 1000,"Effective PNG colors must exist.");
pngContrast = colorContrast(pngTarget,pngBackground);
assert(pngContrast >= 3.5,"PNG contrast lacks margin above 3:1.");
bandContrast = zeros(2,1); bandPixels = zeros(2,1);
names = ["Lower acceptance","Upper acceptance"];
for i = 1:2
    band = findobj(fig,"Type","line","DisplayName",names(i));
    bandContrast(i) = colorContrast(band.Color,ax.Color);
    bandPixels(i) = matchingPixels(pixels,band.Color);
    assert(bandContrast(i) >= 3 && bandPixels(i) > 30,"Acceptance bands must remain perceptible.");
end
actual = findobj(ax,"Type","line","Marker","o");
candidateColors = zeros(numel(actual),3);
for i = 1:numel(actual)
    candidateColors(i,:) = actual(i).Color;
    assert(norm(actual(i).Color-target.Color) > .1,"Target/candidate colors must differ.");
    assert(matchingPixels(pixels,actual(i).Color) > 10,"Candidate color must survive PNG export.");
end
if numel(actual) == 2
    assert(norm(candidateColors(1,:)-candidateColors(2,:)) > .1,"Candidates must be distinct.");
end
legendObject = findobj(fig,"Type","legend");
assert(any(string(legendObject.String) == "Target"),"Target must be identified in legend.");
assert(strlength(string(ax.YLabel.String)) > 0 && strlength(string(ax.Title.String)) > 0, ...
    "Labels/title must be present.");
report = struct("beforeRGB",before,"afterRGB",after,"theme",string(fig.Theme.BaseColorStyle), ...
    "beforeContrast",beforeContrast,"targetContrast",contrast,"pngContrast",pngContrast,"bandContrast",bandContrast, ...
    "targetPixels",targetPixels,"backgroundPixels",backgroundPixels,"bandPixels",bandPixels, ...
    "pngTargetRGB",pngTarget,"pngBackgroundRGB",pngBackground, ...
    "candidateColors",candidateColors,"warningText",string(warningText),"pngPath",string(filename));
end

function [count,rgb] = matchingPixels(pixels,color)
% Two quantization levels allow rounding/antialiasing; count solid stroke pixels.
matches = all(abs(pixels-reshape(color,1,1,3)) <= 2/255,3); count = nnz(matches);
samples = reshape(pixels,[],3); rgb = median(samples(matches(:),:),1);
end

function ratio = colorContrast(first,second)
ratio = (max(luminance(first),luminance(second))+.05)/(min(luminance(first),luminance(second))+.05);
end

function value = luminance(rgb)
% IEC sRGB transfer function / WCAG relative luminance, dimensionless.
linear = rgb/12.92; mask = rgb > .04045;
linear(mask) = ((rgb(mask)+.055)/1.055).^2.4;
value = sum(linear.*[.2126,.7152,.0722]);
end
