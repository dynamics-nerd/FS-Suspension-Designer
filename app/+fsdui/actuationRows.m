function [points,mechanics,compression,rebound] = actuationRows(actuation,mechanical)
%ACTUATIONROWS Display-only mm/N/mm conversion; blanks remain unknown.
roles=["SUSPENSION_ATTACHMENT";"ROCKER_AXIS_POINT";"AXIS_DIRECTION"; ...
    "ROD_ROCKER";"DAMPER_ROCKER";"DAMPER_CHASSIS"];
points=cell(6,7);
for j=1:6
    unit="mm"; if j==3, unit="1"; end
    points(j,:)={char(roles(j)),'','','',char(unit),'UNSPECIFIED',''};
end
names=["SPRING_RATE";"FREE_LENGTH";"PRELOAD";"SOLID_HEIGHT"; ...
    "MIN_LENGTH";"MAX_LENGTH";"COMPRESSION_COEFFICIENT";"REBOUND_COEFFICIENT"];
units=["N/mm";"mm";"mm";"mm";"mm";"mm";"N/(mm/s)";"N/(mm/s)"];
mechanics=cell(8,5);
for j=1:8, mechanics(j,:)={char(names(j)),'',char(units(j)),'UNSPECIFIED',''}; end
compression=cell(0,2); rebound=cell(0,2);
if isempty(actuation), return; end
values=[actuation.suspensionAttachment.pointStatic_m;actuation.rocker.axis.point_m; ...
    actuation.rocker.axis.direction_unit;actuation.rocker.actuationRodPoint.pointStatic_m; ...
    actuation.rocker.damperPoint.pointStatic_m;actuation.damper.chassisPoint.point_m];
values([1,2,4:6],:)=1000*values([1,2,4:6],:);
points(:,2:4)=num2cell(values);
points=restoreProvenance(points,actuation.metadata,6,7);
if isempty(mechanical), return; end
s=mechanical.spring; d=mechanical.damper;
values={s.rate_N_per_m/1000;1000*s.freeLength_m;1000*s.preloadCompression_m; ...
    1000*s.solidHeight_m;1000*d.minimumLength_m;1000*d.maximumLength_m; ...
    d.compressionCoefficient_Ns_per_m/1000;d.reboundCoefficient_Ns_per_m/1000};
for j=1:8, if ~isempty(values{j}), mechanics{j,2}=values{j}; end, end
mechanics=restoreProvenance(mechanics,mechanical.metadata,4,5);
if ~isempty(d.compressionTable), compression=num2cell(d.compressionTable.*[1000,1]); end
if ~isempty(d.reboundTable), rebound=num2cell(d.reboundTable.*[1000,1]); end
end

function rows=restoreProvenance(rows,metadata,kindColumn,noteColumn)
for j=1:size(rows,1)
    if isfield(metadata,'sourceKind'), rows{j,kindColumn}=char(string(metadata.sourceKind)); end
    if isfield(metadata,'sourceNote'), rows{j,noteColumn}=char(string(metadata.sourceNote)); end
    if isfield(metadata,'parameterProvenance') && isfield(metadata.parameterProvenance,rows{j,1})
        p=metadata.parameterProvenance.(rows{j,1});
        rows{j,kindColumn}=char(p.sourceKind); rows{j,noteColumn}=char(p.sourceNote);
    end
end
end
