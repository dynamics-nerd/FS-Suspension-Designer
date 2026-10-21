function [volumes,pairs,regions]=packagingRows(definition)
%PACKAGINGROWS Presentation-only flattening; no inferred physical dimensions.
volumes=cell(0,15); pairs=cell(0,5); regions=cell(0,10);
if isempty(definition), return; end
d=definition.definitionSI;
for j=1:numel(d.volumes)
    v=d.volumes{j}.definitionSI; T=v.transform;
    volumes(j,:)={char(v.id),char(v.componentId),char(v.componentType),char(v.role),char(v.shape), ...
        numbers(v.dimensions),numbers(T(1:3,4)),numbers(reshape(T(1:3,1:3),[],1)), ...
        char(v.binding.mode),char(v.binding.cornerId),idsText(v.binding.pointIds), ...
        char(v.source),char(v.fidelity),numbers(v.sourceRevision),char(v.provenance)};
end
for j=1:numel(d.pairs)
    p=d.pairs{j}; exception=''; if ~isempty(p.exception), exception=jsonencode(p.exception); end
    pairs(j,:)={char(p.id),char(p.first),char(p.second),numbers(p.requiredClearance_m),exception};
end
for j=1:numel(d.regions)
    r=d.regions{j}; regions(j,:)={char(r.id),char(r.cornerId),char(r.pointId),char(r.mode),char(r.volumeId), ...
        numbers(r.target_m),numbers(r.tolerance_m),numbers(r.clearance_m),char(r.source),char(r.provenance)};
end
end
function s=numbers(values)
if isempty(values), s=''; return; end
s=char(join(compose('%.17g',values(:)),' '));
end
function s=idsText(ids)
if isempty(ids), s=''; else, s=char(join(ids,' ')); end
end
