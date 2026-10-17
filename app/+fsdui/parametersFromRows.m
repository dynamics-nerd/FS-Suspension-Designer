function parameters = parametersFromRows(rows,existing,corner,concept)
%PARAMETERSFROMROWS Reuse native factories, preserving unedited record metadata.
% Preflight every JSON cell, including unchanged rows, before constructing edits.
extras=cell(size(rows,1),1);
for j=1:size(rows,1), extras{j}=readExtra(rows{j,11},j,string(rows{j,1})); end
parameters=existing;
for j=1:size(rows,1)
    id=string(rows{j,1}); found=0;
    for k=1:numel(parameters)
        p=parameters{k}; if concept, p=p.parameter; end
        if p.definitionSI.id==id, found=k; break; end
    end
    if found>0
        record=parameters{found}; p=record; if concept, p=p.parameter; end
        catalog=struct('id',id,'unit',p.definitionSI.unit);
        before=fsdui.parameterRows(catalog,{record},concept);
        if isequaln(rows(j,:),before), continue; end
        input=rmfield(p.definitionSI,{'id','quantity','unit','scope','binding'});
        input.metadata=p.metadata;
    else
        input=struct();
    end
    input.value=fsdui.numberList(rows{j,2});
    assert(numel(input.value)<=1,'fsd:ui:Scalar','A parameter requires a scalar or a blank value.');
    input.bounds=fsdui.numberList(rows{j,3})';
    input.type=string(rows{j,5}); input.availability=string(rows{j,6});
    input.sourceKind=string(rows{j,7}); input.sourceNote=string(rows{j,8});
    if found==0 || ~strcmp(rows{j,11},before{11})
        extra=extras{j};
        for name=string(fieldnames(extra))', input.(name)=extra.(name); end
    end
    if concept
        input.confirmation=string(rows{j,9});
        if found>0
            input.origin=record.origin; input.diagnostics=record.diagnostics;
            if ismember(record.state,["UNSUPPORTED","INVALID_INPUT"]) && ...
                    isempty(input.value) && isempty(input.bounds) && input.availability==p.definitionSI.availability
                input.state=record.state;
            end
        end
        if ~isfield(input,'origin'), input.origin=struct(); end
        input.origin.reference=string(rows{j,10});
        parameter=fsd.project.createConceptParameter(id,input,string(rows{j,4}));
    else
        parameter=fsd.construction.createSeedParameter(id,corner,input,string(rows{j,4}));
    end
    if found>0, parameters{found}=parameter;
    else, parameters{end+1,1}=parameter; %#ok<AGROW> Small explicit catalog, not an optimizer loop.
    end
end
end

function extra=readExtra(text,row,id)
allowed=["ruleReference","derivationReference"];
try
    raw=strtrim(string(text));
    assert(isscalar(raw) && ~ismissing(raw) && startsWith(raw,'{') && endsWith(raw,'}'));
    extra=jsondecode(raw);
    assert(isstruct(extra) && isscalar(extra));
catch
    error('fsd:ui:ExtraJSON','Row %d (%s), Extra JSON: supply one JSON object with ruleReference / derivationReference only.',row,id);
end
checkRootKeys(char(raw),allowed,row,id);
for key=string(fieldnames(extra))'
    % Exact allowlist also rejects case/normalized variants of explicit columns.
    if ~ismember(key,allowed)
        error('fsd:ui:ExtraJSON','Row %d (%s), Extra JSON key "%s" is not allowed. Explicit columns cannot be overridden; only ruleReference / derivationReference are accepted.',row,id,key);
    end
    value=extra.(key);
    if key=="derivationReference"
        valid=(ischar(value) && (isrow(value) || isempty(value))) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value));
        if ~valid, extraError(row,id,key,'must be a text scalar'); end
    else
        if ~isstruct(value) || ~isscalar(value), extraError(row,id,key,'must be one object (or {})'); end
        fields=["organizer","version","ruleId","quantity","source","status","applicability"];
        names=string(fieldnames(value));
        unknown=setdiff(names,fields);
        if ~isempty(unknown), extraError(row,id,key+"."+unknown(1),'is not a canonical rule-reference field'); end
        if ~isempty(names) && ~all(ismember(fields,names)), extraError(row,id,key,'requires all seven canonical fields, or {}'); end
        for name=names'
            v=value.(name);
            if ~ischar(v) || ~isrow(v) || isempty(v), extraError(row,id,key+"."+name,'must be nonempty text'); end
        end
    end
end
end
function checkRootKeys(raw,allowed,row,id)
% jsondecode normalizes struct field names and collapses one-object arrays.
% Tokenize strings/containers ONLY to check original root keys and containers;
% jsondecode remains the JSON parser and the native factories remain validators.
tokens=regexp(raw,'"(?:[^"\\]|\\.)*"|[{}\[\],:]','match');
depth=0; seen=strings(0,1);
for j=1:numel(tokens)
    token=tokens{j};
    if ismember(token,{'{','['}), depth=depth+1;
    elseif ismember(token,{'}',']'}), depth=depth-1;
    elseif depth==1 && startsWith(token,'"') && j<numel(tokens) && strcmp(tokens{j+1},':')
        key=string(jsondecode(token));
        if ~ismember(key,allowed) || ~strcmp(token,['"',char(key),'"']) || any(seen==key)
            extraError(row,id,key,'must be one literal canonical complementary key, without duplicates or column overrides');
        end
        seen(end+1,1)=key; %#ok<AGROW> At most two allowed root fields.
        if key=="ruleReference" && ~strcmp(tokens{j+2},'{')
            extraError(row,id,key,'must be a JSON object, not an array');
        end
    end
end
end
function extraError(row,id,key,reason)
error('fsd:ui:ExtraJSON','Row %d (%s), Extra JSON key "%s" %s.',row,id,key,reason);
end
