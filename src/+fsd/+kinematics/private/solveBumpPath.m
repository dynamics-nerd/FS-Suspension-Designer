function results = solveBumpPath(geometry, targets_m, settings)
%SOLVEBUMPPATH Solve bump with the static tie-rod inboard position.

tieInboardStatic_m = fsd.model.getPoint(geometry, ...
    string(geometry.cornerId) + "_TIE_ROD_INBOARD");
tieTargets_m = repmat(tieInboardStatic_m, numel(targets_m), 1);
raw = solveCornerPath(geometry, targets_m, tieTargets_m, settings);
cells = cell(numel(raw), 1);
for index = 1:numel(raw)
    cells{index} = kinematicResultFromRaw(raw(index));
end
results = vertcat(cells{:});
end
