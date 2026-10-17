function rows = specRows(spec,kind)
%SPECROWS Display a native specification without rerunning any physics.
switch kind
    case 'targets'
        entries=spec.targets.definitionSI.targets; rows=cell(numel(entries),15);
        for j=1:numel(entries)
            d=entries{j}.definitionSI;
            rows(j,:)={char(d.id),char(d.metricId),char(d.sourceId),char(d.scope.id),char(d.type),char(d.strength), ...
                n(d.x),n(d.value),n(d.tolerance),n(d.lower),n(d.upper),n(d.normalizationScale),n(d.weight),char(d.sourceNote),char(d.normalizationNote)};
        end
    case 'parameters'
        entries=spec.parameters; rows=cell(numel(entries),10);
        for j=1:numel(entries)
            d=entries{j}.definitionSI;
            rows(j,:)={char(d.id),char(d.scope.cornerId),char(d.scope.id),char(extractAfter(d.binding,'HARDPOINT_')), ...
                char(d.type),n(d.value),n(d.bounds),n(d.comparisonTolerance),char(d.availability),char(d.sourceNote)};
        end
    case 'constraints'
        entries=spec.constraints; rows=cell(numel(entries),9);
        for j=1:numel(entries)
            d=entries{j}.definitionSI;
            rows(j,:)={char(d.id),char(d.scope.cornerId),char(d.scope.id),char(d.type),char(d.strength), ...
                n(d.position),n(reshape(d.bounds',[],1)),n(d.comparisonTolerance),char(d.sourceNote)};
        end
end
end
function text = n(v)
text=char(strjoin(compose('%.17g',v(:)),' '));
end
