function value=decodeStorageGraph(encoded,onYield)
%DECODESTORAGEGRAPH Backward-only plain-value DAG, no class loading/evaluation.
% This is a storage decoder, not a substitute for canonical project validation.
% Optional cooperative I/O scheduling, with no change to stored values/bits.
if nargin<2, onYield=[]; end
require(isempty(onYield) || (isa(onYield,'function_handle') && isscalar(onYield)), ...
    'Cooperative conversion callback must be empty or a scalar function handle.');
if ~isempty(onYield), onYield(); end
require(isstruct(encoded) && isscalar(encoded) && ...
    isequal(sort(fieldnames(encoded)),sort({'format';'root';'types';'nodes';'texts'})) && ...
    isequal(encoded.format,'FSD_VALUE_GRAPH_V1'),'Invalid value graph.');
types=encoded.types; nodes=encoded.nodes; texts=encoded.texts; root=encoded.root;
require(isa(types,'uint8') && iscolumn(types) && iscell(nodes) && iscolumn(nodes) && ...
    numel(types)==numel(nodes) && iscell(texts) && (iscolumn(texts) || isempty(texts)) && ...
    all(cellfun(@(s)ischar(s) && (isrow(s) || isempty(s)),texts)) && ...
    isa(root,'uint32') && isscalar(root) && root>=1 && root==numel(nodes),'Invalid graph inventory.');
values=cell(size(nodes));
for i=1:numel(nodes)
    if ~isempty(onYield) && mod(i,256)==0, onYield(); end
    d=nodes{i};
    switch types(i)
        case 1
            require(isnumeric(d) || islogical(d) || ischar(d),'Invalid primitive node.'); values{i}=d;
        case 2
            require(iscell(d) && isequal(size(d),[1 2]),'Invalid text node.');
            shape=d{1}; ids=d{2}; checkShape(shape);
            require(isa(ids,'uint32') && isequal(size(ids),shape) && all(ids<=numel(texts),'all'),'Invalid text references.');
            data=repmat({''},shape); present=ids~=0; data(present)=texts(ids(present));
            v=reshape(string(data),shape); v(~present)=missing; values{i}=v;
        case 3
            require(iscell(d) && isequal(size(d),[1 3]),'Invalid struct node.');
            shape=d{1}; fields=d{2}; refs=d{3}; checkShape(shape);
            require(isa(fields,'uint32') && (iscolumn(fields) || isempty(fields)) && ...
                all(fields>=1 & fields<=numel(texts)),'Invalid field references.');
            names=texts(fields);
            require(numel(unique(names))==numel(names),'Duplicate struct fields.');
            require(isa(refs,'uint32') && isequal(size(refs),[numel(fields),prod(shape)]) && ...
                all(refs>=1 & refs<i,'all'),'Invalid/forward graph references.');
            try
                template=cell2struct(cell(numel(names),1),names,1);
            catch
                require(false,'Invalid native struct fields.');
            end
            require(isequal(fieldnames(template),names(:)),'Struct fields must round-trip without normalization.');
            v=repmat(template,shape);
            for j=1:numel(v), for k=1:numel(names), v(j).(names{k})=values{refs(k,j)}; end, end
            values{i}=v;
        case 4
            require(iscell(d) && isequal(size(d),[1 2]),'Invalid cell node.');
            shape=d{1}; refs=d{2}; checkShape(shape);
            require(isa(refs,'uint32') && isequal(size(refs),shape) && all(refs>=1 & refs<i,'all'),'Invalid cell references.');
            values{i}=reshape(values(refs),shape);
        otherwise
            require(false,'Unknown graph node type.');
    end
end
value=values{root};
if ~isempty(onYield), onYield(); end
end
function checkShape(shape)
require(isa(shape,'double') && isrow(shape) && numel(shape)>=2 && all(isfinite(shape)) && ...
    all(shape>=0 & fix(shape)==shape),'Invalid node shape.');
end
function require(condition,message)
assert(condition,'fsd:project:InvalidInput','%s',message);
end
