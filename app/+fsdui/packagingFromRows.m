function definition=packagingFromRows(id,volumes,pairs,regions,frame,existing)
%PACKAGINGFROMROWS Explicit SI table adapter. Validate all rows before Apply.
vs=cell(size(volumes,1),1); ps=cell(size(pairs,1),1); rs=cell(size(regions,1),1);
for j=1:numel(vs)
    row=volumes(j,:); origin=frame;
    if ~isempty(existing)
        old=existing.definitionSI.volumes; matched=false;
        for k=1:numel(old)
            if old{k}.definitionSI.id==string(row{1}), origin=old{k}.definitionSI.frame; matched=true; break; end
        end
        if ~matched
            sameFrame=cellfun(@(v)isequaln(v.definitionSI.frame,frame),old);
            assert(all(sameFrame),'fsd:ui:PackagingFrame', ...
                'A new/renamed ID cannot silently reframe an imported declaration. Define its explicit frame through the core API.');
        end
    end
    position=numeric(row{7},3); rotation=numeric(row{8},9);
    binding=struct('mode',string(row{9}),'cornerId',string(row{10}), ...
        'pointIds',splitIds(row{11}));
    dimensionsText=strtrim(string(row{6})); measure="RADIUS";
    if startsWith(dimensionsText,'D:')
        measure="DIAMETER"; dimensionsText=extractAfter(dimensionsText,2);
    end
    d=struct('id',string(row{1}),'componentId',string(row{2}),'componentType',string(row{3}), ...
        'role',string(row{4}),'shape',string(row{5}),'dimensions',fsdui.numberList(dimensionsText)', ...
        'transform',[reshape(rotation,3,3),position(:);0 0 0 1],'binding',binding,'frame',origin, ...
        'source',string(row{12}),'fidelity',string(row{13}),'sourceRevision',numeric(row{14},1), ...
        'provenance',string(row{15}));
    vs{j}=fsd.packaging.createVolume(d,'m',measure);
end
for j=1:numel(ps)
    row=pairs(j,:); exception=[];
    if strlength(strtrim(string(row{5})))>0
        raw=strtrim(string(row{5}));
        assert(startsWith(raw,'{') && endsWith(raw,'}'),'fsd:ui:PackagingInput','Pair %d exception requires one JSON object.',j);
        exception=jsondecode(raw);
        assert(isstruct(exception) && isscalar(exception),'fsd:ui:PackagingInput','Pair %d exception requires one object.',j);
    end
    ps{j}=struct('id',string(row{1}),'first',string(row{2}),'second',string(row{3}), ...
        'requiredClearance_m',numeric(row{4},1),'exception',exception);
end
for j=1:numel(rs)
    row=regions(j,:);
    rs{j}=struct('id',string(row{1}),'cornerId',string(row{2}),'pointId',string(row{3}), ...
        'mode',string(row{4}),'volumeId',string(row{5}),'target_m',fsdui.numberList(row{6})', ...
        'tolerance_m',fsdui.numberList(row{7}),'clearance_m',fsdui.numberList(row{8}), ...
        'source',string(row{9}),'provenance',string(row{10}));
end
definition=fsd.packaging.createDefinition(struct('id',string(id),'volumes',{vs},'pairs',{ps},'regions',{rs}));
end
function value=numeric(text,count)
value=fsdui.numberList(text);
assert(numel(value)==count,'fsd:ui:PackagingInput','Expected %d explicit finite numeric entries; blank does not imply zero.',count);
end
function ids=splitIds(text)
text=strtrim(string(text));
if strlength(text)==0, ids=strings(0,1); else, ids=split(text,[" ",",",";"]); ids=ids(strlength(ids)>0); end
end
