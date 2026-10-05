function saveGeometryMat(filePath, geometry)
%SAVEGEOMETRYMAT Save one validated geometry in canonical MAT form.

fsd.model.validateDoubleWishboneGeometry(geometry);
filePath = normalizeMatPath(filePath);
save(filePath, "geometry", "-mat");
end

function filePath = normalizeMatPath(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("fsd:model:InvalidMatPath", "MAT file path must be text.");
end
filePath = string(value);
[parent, ~, extension] = fileparts(filePath);
if lower(string(extension)) ~= ".mat"
    error("fsd:model:InvalidMatPath", ...
        "Canonical geometry persistence requires a .mat file.");
end
if strlength(parent) > 0 && ~isfolder(parent)
    error("fsd:model:InvalidMatPath", ...
        "Parent folder does not exist: %s", parent);
end
end

