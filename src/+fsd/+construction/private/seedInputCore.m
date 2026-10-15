function report = seedInputCore(definition,references)
%SEEDINPUTCORE Identify every missing decision, without nominal/physical claims.
seedReferenceCore(references); d=definition.definitionSI;
report=struct('status',"READY",'missing',strings(0,1),'diagnostics',strings(0,1));
if d.family=="UNSELECTED", report.missing(end+1,1)="FAMILY";
elseif d.family~="INDEPENDENT_DOUBLE_WISHBONE", report.status="UNSUPPORTED"; report.diagnostics="Unsupported family: "+d.family; end
for id=fsd.construction.seedReferenceIds(definition)'
    [v,status]=seedReferenceValue(references,id);
    if isempty(v), report.missing(end+1,1)="CONCEPT:"+id; report.diagnostics(end+1,1)=id+":"+status;
    elseif v<=0, report.status="INVALID_INPUT"; report.diagnostics(end+1,1)=id+":POSITIVE_DIMENSION_REQUIRED"; end
end
corners=d.cornerId; sets={d.parameters};
if d.cornerId=="FRONT"
    corners="FL"; if d.symmetry=="NONE", corners=["FL","FR"]; sets={d.parameters;d.rightParameters}; end
end
catalog=fsd.construction.seedParameterCatalog();
for j=1:numel(corners)
    ps=sets{j};
    for k=1:numel(catalog)
        id=catalog(k).id; v=[]; status="UNKNOWN";
        idx=find(cellfun(@(p)p.definitionSI.id==id,ps));
        if ~isempty(idx), [v,status]=seedPhysicalValue(ps{idx}.definitionSI); end
        if isempty(v)
            report.missing(end+1,1)=corners(j)+":"+id;
            report.diagnostics(end+1,1)=corners(j)+":"+id+":"+status;
        elseif (catalog(k).positive && v<=0) || (ismember(id,["NOMINAL_TOE","NOMINAL_CAMBER"]) && abs(v)>=pi/2)
            report.status="INVALID_INPUT"; report.diagnostics(end+1,1)=corners(j)+":"+id+":OUTSIDE_FAMILY_DOMAIN";
        end
    end
end
if ~isempty(report.missing) && report.status=="READY", report.status="MISSING_DATA"; end
end
