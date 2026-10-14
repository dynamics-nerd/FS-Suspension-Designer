function record = conceptParameterCore(id,input,unit)
%CONCEPTPARAMETERCORE Reuse v0.11 roles, units and finite value/range checks.
id=projectText(id); catalog=fsd.project.conceptParameterCatalog(); index=find(string({catalog.id})==id);
projectRequire(isscalar(index),'Unknown concept parameter ID.'); entry=catalog(index);
projectRequire(isstruct(input) && isscalar(input),'Concept parameter definition must be a scalar struct.');
d=input; confirmation="DECLARED"; state="";
origin=struct('actor',"",'date',"",'reference',"",'limitations',strings(0,1)); diagnostics=strings(0,1);
if isfield(d,'confirmation'), confirmation=projectText(d.confirmation); d=rmfield(d,'confirmation'); end
if isfield(d,'state'), state=projectText(d.state); d=rmfield(d,'state'); end
if isfield(d,'diagnostics'), diagnostics=reshape(string(d.diagnostics),[],1); d=rmfield(d,'diagnostics'); end
if isfield(d,'origin')
    supplied=d.origin; d=rmfield(d,'origin');
    projectRequire(isstruct(supplied) && isscalar(supplied) && ...
        all(ismember(string(fieldnames(supplied)),string(fieldnames(origin)))),'Unknown origin field.');
    for name=string(fieldnames(supplied))', origin.(name)=supplied.(name); end
end
for name=["actor","date","reference"], origin.(name)=projectText(origin.(name),true); end
origin.limitations=reshape(string(origin.limitations),[],1);
projectRequire(~any(ismissing(origin.limitations)) && ~any(ismissing(diagnostics)),'Missing provenance text.');
projectRequire(any(confirmation==["DECLARED","VERIFIED","PENDING_CONFIRMATION"]),'Unknown confirmation state.');
projectRequire(~any(isfield(d,["id","quantity","unit","scope","binding"])), ...
    'ID, quantity, scope and binding are fixed by the concept parameter catalog.');
d.id=id; d.quantity=entry.quantity; d.scope=fsd.model.designScope('VEHICLE','VEHICLE'); d.binding="NONE";
if ~isfield(d,'type'), d.type="KNOWN"; end
p=fsd.model.createDesignParameter(d,unit); n=p.definitionSI;
values=[n.value,n.bounds];
projectRequire(all(values>=entry.minimum & values<=entry.maximum),'Concept value/range outside the quantity domain.');
if entry.minimumExclusive, projectRequire(all(values>entry.minimum),'Positive concept value/range required.'); end
if ~isempty(n.bounds)
    projectRequire(n.sourceKind~="UNSPECIFIED" && strlength(string(n.sourceNote))>0, ...
        'Intervals require declared provenance and justification, even without a nominal.');
end
if confirmation=="VERIFIED"
    projectRequire(n.sourceKind=="KNOWN" && strlength(origin.reference)>0 && ...
        (~isempty(n.value) || ~isempty(n.bounds)),'VERIFIED requires known data and a supplied reference.');
end
inferred="UNKNOWN";
if ~isempty(n.value), inferred="AVAILABLE"; elseif ~isempty(n.bounds), inferred="AVAILABLE_RANGE"; end
if n.availability=="NOT_APPLICABLE", inferred="NOT_APPLICABLE"; end
if n.availability=="INVALID", inferred="INVALID_INPUT"; end
if n.availability=="PENDING_CALCULATION", inferred="DERIVABLE"; end
if confirmation=="PENDING_CONFIRMATION", inferred="PENDING_CONFIRMATION"; end
if strlength(state)==0, state=inferred; end
projectRequire(any(state==["AVAILABLE","AVAILABLE_RANGE","UNKNOWN","NOT_APPLICABLE", ...
    "UNSUPPORTED","INVALID_INPUT","DERIVABLE","PENDING_CONFIRMATION"]),'Unknown concept data state.');
if ismember(state,["UNSUPPORTED","INVALID_INPUT"])
    projectRequire(isempty(n.value) && isempty(n.bounds) && ~isempty(diagnostics), ...
        'Unsupported/invalid data need diagnostics and no usable numerical value.');
else
    projectRequire(state==inferred,'Concept state contradicts native availability or confirmation.');
end
record=struct('schemaVersion',"0.16.0",'kind',"ConceptParameter",'id',id,'parameter',p, ...
    'state',state,'confirmation',confirmation,'origin',origin,'diagnostics',diagnostics);
plainProjectData(record);
record.identity=struct('schemaVersion',"0.16.0",'kind',"ConceptParameterIdentity",'id',id, ...
    'parameterIdentity',p.identity,'state',state,'confirmation',confirmation,'origin',origin,'diagnostics',diagnostics);
end
