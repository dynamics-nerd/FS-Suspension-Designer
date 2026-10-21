function encoded=encodeStorageGraph(value,onYield)
%ENCODESTORAGEGRAPH Lossless plain-value DAG; structural interning, no raw cache.
% Parent keys encode shape, ordered field IDs and exact child node IDs. Thus
% equality follows inductively, without scanning/storing complete snapshots.
% Small dense primitives use an injective class/shape/flag/bit key. The128
% element threshold bounds key allocation only; larger/sparse arrays are stored
% verbatim, never truncated, rounded or rejected because of their size.
% Optional cooperative I/O callback, never stored in the graph. The256-visit
% scheduling quantum is not a numerical tolerance or data/capacity limit.
if nargin<2, onYield=[]; end
projectRequire(isempty(onYield) || (isa(onYield,'function_handle') && isscalar(onYield)), ...
    'Cooperative conversion callback must be empty or a scalar function handle.');
visits=0; if ~isempty(onYield), onYield(); end
nodes=cell(0,1); types=zeros(0,1,'uint8'); texts=cell(0,1);
textMap=containers.Map('KeyType','char','ValueType','double');
scalarStrings=containers.Map('KeyType','char','ValueType','double');
internMap=containers.Map('KeyType','char','ValueType','double');
fieldLists=containers.Map('KeyType','char','ValueType','any');
root=visit(value);
encoded=struct('format','FSD_VALUE_GRAPH_V1','root',root,'types',types,'nodes',{nodes},'texts',{texts});
if ~isempty(onYield), onYield(); end
    function id=visit(v)
        if ~isempty(onYield)
            visits=visits+1; if mod(visits,256)==0, onYield(); end
        end
        if isstring(v)
            if isscalar(v)
                key='M'; if ~ismissing(v), key=['T',char(v)]; end
                if isKey(scalarStrings,key), id=uint32(scalarStrings(key)); return; end
            end
            ids=zeros(size(v),'uint32');
            for k=1:numel(v), if ~ismissing(v(k)), ids(k)=textId(char(v(k))); end, end
            signature=['T',shapeKey(size(v)),bytes(ids)];
            id=intern(signature,uint8(2),{size(v),ids});
            if isscalar(v), scalarStrings(key)=double(id); end
        elseif isstruct(v)
            names=fieldnames(v); fields=zeros(numel(names),1,'uint32'); refs=zeros(numel(names),numel(v),'uint32');
            % Reuse only exact ordered field-name -> text-ID lists. Never
            % cache a source subtree or skip visiting any field value.
            fieldKey=['F',bytes(uint64([numel(names);cellfun('length',names)])),bytes(uint16([names{:}]))];
            knownFields=isKey(fieldLists,fieldKey);
            if knownFields, fields=fieldLists(fieldKey); end
            for k=1:numel(names)
                if ~knownFields, fields(k)=textId(names{k}); end
                for j=1:numel(v), refs(k,j)=visit(v(j).(names{k})); end
            end
            if ~knownFields, fieldLists(fieldKey)=fields; end
            signature=['S',shapeKey(size(v)),bytes(uint64(numel(names))),bytes(fields),bytes(refs)];
            id=intern(signature,uint8(3),{size(v),fields,refs});
        elseif iscell(v)
            refs=zeros(size(v),'uint32');
            for k=1:numel(v), refs(k)=visit(v{k}); end
            signature=['C',shapeKey(size(v)),bytes(refs)];
            id=intern(signature,uint8(4),{size(v),refs});
        else
            projectRequire(isnumeric(v) || islogical(v) || ischar(v),'Storage supports only plain MATLAB values.');
            signature=primitiveKey(v);
            if isempty(signature), id=append(uint8(1),v);
            else, id=intern(signature,uint8(1),v); end
        end
    end
    function id=intern(signature,type,data)
        if isKey(internMap,signature), id=uint32(internMap(signature));
        else, id=append(type,data); internMap(signature)=double(id); end
    end
    function id=append(type,data)
        projectRequire(numel(nodes)<double(intmax('uint32')),'Storage index overflow.');
        id=uint32(numel(nodes)+1); nodes{end+1,1}=data; types(end+1,1)=type;
    end
    function id=textId(s)
        key=['T',s];
        if isKey(textMap,key), id=uint32(textMap(key));
        else, texts{end+1,1}=s; id=uint32(numel(texts)); textMap(key)=double(id); end
    end
end
function key=primitiveKey(v)
key='';
supported={'double','single','uint8','uint16','uint32','uint64','int8','int16','int32','int64','logical','char'};
if numel(v)>128 || issparse(v) || ~ismember(class(v),supported), return; end
if islogical(v), data=char(uint8(v(:))');
elseif ischar(v), data=bytes(uint16(v));
elseif isreal(v), data=bytes(v);
else, data=[bytes(real(v)),bytes(imag(v))];
end
key=['P',class(v),char(0),char(uint8(isreal(v))),shapeKey(size(v)),data];
end
function key=shapeKey(shape)
key=bytes(uint64([numel(shape),shape]));
end
function key=bytes(v)
key=char(reshape(typecast(v(:),'uint8'),1,[]));
end
