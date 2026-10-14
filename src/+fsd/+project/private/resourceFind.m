function value = resourceFind(resources,family,id)
%RESOURCEFIND Explicit resource key; never manufactures a missing opposite side.
value=[]; entries=resources.(family);
for j=1:numel(entries)
    key="FRONT"; if isfield(entries{j},'cornerId'), key=entries{j}.cornerId; end
    if key==id, value=entries{j}; return; end
end
end
