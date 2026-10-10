function report = designExteriorTextCheck(fig, filename)
%DESIGNEXTERIORTEXTCHECK Two-panel PNG oracle: text vs REAL exterior backgrounds.
% Known reference layout, not OCR or a universal screenshot/accessibility checker.
% Regions cover title/scientific multiplier, y labels/ticks, x label/ticks, gap.
pixels = double(imread(filename))/255; height = size(pixels,1); width = size(pixels,2);
regions = [0,1,0,.035; 0,.07,0,1; 0,1,.94,1; 0,1,.40,.55];
names = ["TITLE_AND_EXPONENT","Y_LABELS_AND_TICKS","X_LABEL_AND_TICKS","PANEL_GAP_AND_TICKS"];
target = findobj(fig,"Type","line","DisplayName","Target"); foreground = target.Parent.XColor;
ratios = zeros(4,1); backgrounds = zeros(4,3); textColors = zeros(4,3); counts = zeros(4,1);
for i = 1:4
    columns = max(1,floor(regions(i,1)*width)+1):min(width,ceil(regions(i,2)*width));
    rows = max(1,floor(regions(i,3)*height)+1):min(height,ceil(regions(i,4)*height));
    samples = reshape(pixels(rows,columns,:),[],3);
    quantized = round(samples*255); keys = quantized*[65536;256;1];
    common = mode(keys); backgrounds(i,:) = [floor(common/65536),mod(floor(common/256),256),mod(common,256)]/255;
    matches = all(abs(samples-foreground) <= 2/255,2); counts(i) = nnz(matches);
    assert(counts(i) >= 20,"fsd:tests:ExteriorTextMissing","No readable text pixels in %s.",names(i));
    textColors(i,:) = median(samples(matches,:),1);
    ratios(i) = contrast(textColors(i,:),backgrounds(i,:));
    assert(ratios(i) >= 4.5,"fsd:tests:ExteriorTextContrast", ...
        "%s: text/background PNG contrast %.6f is below 4.5:1.",names(i),ratios(i));
end
axesObjects = findall(fig,"Type","axes"); axisRatios = zeros(numel(axesObjects),3);
for i = 1:numel(axesObjects)
    ax = axesObjects(i);
    axisRatios(i,:) = [contrast(ax.XColor,ax.Color),contrast(ax.YColor,ax.Color),contrast(ax.ZColor,ax.Color)];
    assert(all(axisRatios(i,:) >= 4.5),"Axis colors must contrast with their effective background.");
    assert(strlength(string(ax.YLabel.String)) > 0,"Both panel units must remain labelled.");
end
report = struct("regionNames",names,"regionFractions",regions,"pngBackgroundRGB",backgrounds, ...
    "pngTextRGB",textColors,"textPixelCounts",counts,"textContrast",ratios,"axisContrast",axisRatios);
end

function ratio = contrast(first,second)
first = luminance(first); second = luminance(second);
ratio = (max(first,second)+.05)/(min(first,second)+.05);
end

function value = luminance(rgb)
linear = rgb/12.92; mask = rgb > .04045;
linear(mask) = ((rgb(mask)+.055)/1.055).^2.4;
value = sum(linear.*[.2126,.7152,.0722]);
end
