function projectRoot = setupProject()
%SETUPPROJECT Add the FS Suspension Designer source root to the MATLAB path.
%   PROJECTROOT = SETUPPROJECT() adds only the parent of the +fsd namespace.
%   Call this function once per MATLAB session from the repository root.

projectRoot = fileparts(mfilename("fullpath"));
sourceRoot = fullfile(projectRoot, "src");

if ~isfolder(sourceRoot)
    error("fsd:setupProject:MissingSource", ...
        "Expected source folder does not exist: %s", sourceRoot);
end

addpath(sourceRoot);
end

