function bar=findAntiRollBar(project,id,revision)
%FINDANTIROLLBAR Resolve an exact immutable revision, never implicit latest.
bar=[]; resources=project.definition.resources;
if ~isfield(resources,'antiRollBars'), return; end
match=cellfun(@(b)b.definition.id==string(id)&&b.definition.revision==revision,resources.antiRollBars);
assert(nnz(match)<=1,'fsd:project:InvalidInput','Ambiguous ARB revision.');
if any(match), bar=resources.antiRollBars{match}; fsd.model.validateAntiRollBar(bar); end
end
