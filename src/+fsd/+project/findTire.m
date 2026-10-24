function tire=findTire(project,id,revision)
%FINDTIRE Exact immutable resource lookup, not an implicit latest revision.
tire=[]; r=project.definition.resources;
if isfield(r,'tires')
    match=cellfun(@(x)string(x.definition.id)==string(id)&&x.definition.revision==revision,r.tires);
    assert(nnz(match)<=1,'fsd:project:InvalidInput','Ambiguous tire revision.');
    if any(match), tire=r.tires{match}; fsd.tire.validate(tire); end
end
end
