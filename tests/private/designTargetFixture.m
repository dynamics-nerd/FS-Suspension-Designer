function [target, definition] = designTargetFixture(type, metric, extra)
%DESIGNTARGETFIXTURE All numbers are test specifications, not FS recommendations.
if nargin < 1, type = "POINT_TARGET"; end
if nargin < 2, metric = "DAMPER_COMPRESSION"; end
if nargin < 3, extra = struct(); end
catalog = fsd.model.designMetricCatalog; m = catalog(string({catalog.id}) == metric);
definition = struct("id","TEST_REQUIREMENT","metricId",metric,"sourceId","MECH_FL", ...
    "sourceType","MECHANICAL","scope",fsd.model.designScope("CORNER","FL"), ...
    "type",type,"strength","SOFT","independentVariable","WHEEL_TRAVEL", ...
    "x",0,"sourceNote","Independent analytical fixture");
for name = string(fieldnames(extra))', definition.(name) = extra.(name); end
xunit = "m";
if definition.independentVariable == "ROLL_ANGLE", xunit = "rad";
elseif definition.independentVariable == "NONE", xunit = "1"; end
target = fsd.model.createDesignTarget(definition,m.unit,xunit);
end
