function value=arbPackagingConfiguration(mode,input,bar)
%ARBPACKAGINGCONFIGURATION Explicit mm input boundary to native primitive checks.
if string(mode)=="ROWS"
    components={ ...
        'SHAFT','CAPSULE','ARB_AXIS_LEFT','ARB_AXIS_RIGHT','',''; ...
        'LEFT_ARM','CAPSULE','ARB_AXIS_LEFT','ARB_ARM_LEFT','',''; ...
        'RIGHT_ARM','CAPSULE','ARB_AXIS_RIGHT','ARB_ARM_RIGHT','',''; ...
        'LEFT_LINK','CAPSULE','ARB_ARM_LEFT','ARB_DRIVER_LEFT','',''; ...
        'RIGHT_LINK','CAPSULE','ARB_ARM_RIGHT','ARB_DRIVER_RIGHT','',''; ...
        'LEFT_SUPPORT','SPHERE','ARB_SUPPORT_LEFT','ARB_SUPPORT_LEFT','',''; ...
        'RIGHT_SUPPORT','SPHERE','ARB_SUPPORT_RIGHT','ARB_SUPPORT_RIGHT','',''};
    value=struct('components',{components},'obstacles',{cell(0,6)},'pairs',{cell(0,4)},'note','');
    if isempty(input), return; end
    d=input.definition; value.components=cell(numel(d.components),6); value.note=char(d.provenance);
    for k=1:numel(d.components)
        c=d.components{k}; radius=''; if ~isempty(c.radius_m), radius=mat2str(c.radius_m*1000,17); end
        value.components(k,:)={char(c.id),char(c.shape),char(c.firstPoint),char(c.secondPoint),radius,char(c.source)};
    end
    for k=1:numel(d.obstacles)
        v=d.obstacles{k}.definitionSI;
        value.obstacles(k,:)={char(v.id),char(v.shape),mat2str(v.transform(1:3,4)'*1000,17), ...
            mat2str(v.dimensions*1000,17),mat2str(v.transform(1:3,1:3),17),char(v.provenance)};
    end
    for k=1:numel(d.pairs)
        p=d.pairs{k}; clearance=''; if ~isempty(p.requiredClearance_m), clearance=mat2str(p.requiredClearance_m*1000,17); end
        value.pairs(k,:)={char(p.id),char(p.first),char(p.second),clearance};
    end
    return;
end
assert(string(mode)=="DEFINITION"&&~isempty(bar)&&~isempty(bar.definition.referenceFrame), ...
    'fsd:ui:ArbInput','A geometric ARB with an explicit parent frame is required for packaging.');
r=input; components={}; obstacles={}; pairs={};
for k=1:size(r.components,1)
    row=r.components(k,:); if all(strlength(string(row))==0), continue; end
    radius=optionalScalar(row{5})/1000; source=string(row{6});
    if isempty(radius)&&strlength(source)==0, source="UNKNOWN physical radius; no material clearance asserted"; end
    components{end+1,1}=struct('id',string(row{1}),'shape',string(row{2}),'firstPoint',string(row{3}), ...
        'secondPoint',string(row{4}),'radius_m',radius,'source',source); %#ok<AGROW> User rows.
end
for k=1:size(r.obstacles,1)
    row=r.obstacles(k,:); if all(strlength(string(row))==0), continue; end
    center=list(row{3}); assert(numel(center)==3,'fsd:ui:ArbInput','Obstacle centre needs three explicit mm coordinates.');
    shape=string(row{2}); rotation=eye(3);
    if strlength(string(row{5}))>0
        values=list(row{5}); assert(numel(values)==9,'fsd:ui:ArbInput','Rotation needs nine row-ordered values.'); rotation=reshape(values,3,3)';
    else
        assert(ismember(shape,["SPHERE","AABB"]),'fsd:ui:ArbInput','Supply explicit orientation for this obstacle.');
    end
    note=string(row{6}); dimensions=list(row{4})/1000;
    if isempty(dimensions)&&strlength(note)==0, note="UNKNOWN dimensions"; end
    v=struct('id',string(row{1}),'componentId',string(row{1}),'componentType',"OBSTACLE",'role',"OCCUPIED", ...
        'frame',bar.definition.referenceFrame,'shape',shape,'dimensions',dimensions(:)', ...
        'transform',[rotation,center(:)/1000;0 0 0 1], ...
        'binding',struct('mode',"FIXED",'cornerId',"",'pointIds',strings(0,1)), ...
        'source',note,'fidelity',"DECLARED_SIMPLIFIED_OBSTACLE",'sourceRevision',bar.definition.revision,'provenance',note);
    obstacles{end+1,1}=fsd.packaging.createVolume(v,'m'); %#ok<AGROW>
end
for k=1:size(r.pairs,1)
    row=r.pairs(k,:); if all(strlength(string(row))==0), continue; end
    pairs{end+1,1}=struct('id',string(row{1}),'first',string(row{2}),'second',string(row{3}), ...
        'requiredClearance_m',optionalScalar(row{4})/1000); %#ok<AGROW>
end
value=fsd.packaging.createAntiRollBarDefinition(struct('id',bar.definition.id+"_PACKAGING", ...
    'frame',bar.definition.referenceFrame,'components',{components},'obstacles',{obstacles},'pairs',{pairs}, ...
    'provenance',string(r.note)));
end
function v=list(raw)
v=fsdui.numberList(regexprep(string(raw),'[\[\];,]',' '));
end
function v=optionalScalar(raw)
v=[]; if strlength(string(raw))==0, return; end
v=list(raw); assert(isscalar(v),'fsd:ui:ArbInput','One numeric value required.');
end
