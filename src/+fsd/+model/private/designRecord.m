function record = designRecord(kind, definition)
%DESIGNRECORD Small plain struct with a canonical, non-hashed identity.
metadata = definition.metadata; definition = rmfield(definition,"metadata");
designRequire(isstruct(metadata) && isscalar(metadata),"Metadata must be a scalar struct.");
record = struct("schemaVersion","0.11.0","kind",kind,"definitionSI",definition, ...
    "identity",struct("schemaVersion","1.0.0","kind",kind+"Identity","definitionSI",definition), ...
    "metadata",metadata);
end
