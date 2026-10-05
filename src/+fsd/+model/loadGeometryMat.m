function geometry = loadGeometryMat(filePath)
%LOADGEOMETRYMAT Load and revalidate one canonical geometry MAT file.

if ~(ischar(filePath) || (isstring(filePath) && isscalar(filePath)))
    error("fsd:model:InvalidMatPath", "MAT file path must be text.");
end
filePath = string(filePath);
[~, ~, extension] = fileparts(filePath);
if lower(string(extension)) ~= ".mat" || ~isfile(filePath)
    error("fsd:model:InvalidMatPath", ...
        "Geometry MAT file does not exist or has the wrong extension.");
end
loaded = load(filePath, "geometry");
if ~isfield(loaded, "geometry")
    error("fsd:model:InvalidMatContents", ...
        "MAT file does not contain a variable named geometry.");
end
geometry = loaded.geometry;
fsd.model.validateDoubleWishboneGeometry(geometry);
end

