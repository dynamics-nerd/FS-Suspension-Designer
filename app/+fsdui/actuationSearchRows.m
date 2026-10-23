function [targets,parameters,constraints] = actuationSearchRows(definition)
%ACTUATIONSEARCHROWS Lossless declarations displayed in engineering units.
targets=cell(0,16); parameters=cell(0,11); constraints=cell(0,9);
if isempty(definition), return; end
s=definition.specification.definitionSI; catalog=fsd.model.designMetricCatalog();
targets=cell(numel(s.targets.definitionSI.targets),16);
for j=1:size(targets,1)
    d=s.targets.definitionSI.targets{j}.definitionSI; unit=displayUnit(d.unit);
    quantity=catalog(string({catalog.id})==d.metricId).quantity;
    targets(j,:)={char(d.id),char(d.metricId),char(d.sourceType),char(d.sourceId),char(d.type),char(d.strength), ...
        n(1000*d.x),n(convert(d.value,quantity,unit)), ...
        n(convert(d.tolerance,quantity,unit)),n(convert(d.lower,quantity,unit)), ...
        n(convert(d.upper,quantity,unit)),n(convert(d.normalizationScale,quantity,unit)), ...
        n(d.weight),char(unit),char(d.sourceNote),char(d.normalizationNote)};
end
parameters=cell(numel(s.parameters),11);
for j=1:size(parameters,1)
    d=s.parameters{j}.definitionSI;
    binding=d.binding;
    if startsWith(binding,'HARDPOINT_'), binding=extractAfter(binding,'HARDPOINT_'); end
    unit=displayUnit(d.unit); factor=fsd.model.convertDesignUnits(1,d.quantity,unit);
    parameters(j,:)={char(d.id),char(d.scope.id),char(binding), ...
        char(d.type),n(d.value/factor),n(d.bounds/factor),n(d.comparisonTolerance/factor), ...
        char(d.availability),char(d.sourceKind),char(d.sourceNote),char(unit)};
end
constraints=cell(numel(s.constraints),9);
for j=1:size(constraints,1)
    d=s.constraints{j}.definitionSI;
    constraints(j,:)={char(d.id),char(d.scope.id),char(d.type),char(d.strength), ...
        n(1000*d.position),n(1000*reshape(d.bounds',[],1)),n(1000*d.comparisonTolerance),char(d.sourceNote),char(d.scope.cornerId)};
end
end
function unit=displayUnit(unit)
switch string(unit)
    case 'm', unit="mm";
    case 'rad', unit="deg";
    case 'N/m', unit="N/mm";
    otherwise, unit=string(unit);
end
end
function y=convert(x,quantity,to)
factor=fsd.model.convertDesignUnits(1,quantity,to); y=x/factor;
end
function text=n(v)
text=char(strjoin(compose('%.17g',v(:)),' '));
end
