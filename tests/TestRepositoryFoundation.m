classdef TestRepositoryFoundation < matlab.unittest.TestCase
    % Tests the repository foundation shared by all milestones.

    properties (TestParameter)
        RequiredDocument = { ...
            "architecture.md", ...
            "coordinate-system.md", ...
            "data-model.md", ...
            "conventions.md", ...
            "equations.md", ...
            "roadmap.md"}
    end

    properties
        ProjectRoot
        OriginalPath
    end

    methods (TestMethodSetup)
        function addSourceToPath(testCase)
            testCase.ProjectRoot = fileparts(fileparts(mfilename("fullpath")));
            testCase.OriginalPath = path;
            testCase.addTeardown(@() path(testCase.OriginalPath));
            addpath(fullfile(testCase.ProjectRoot, "src"));
        end
    end

    methods (Test)
        function packageIsReachable(testCase)
            testCase.verifyEqual(fsd.version(), "0.3.0");
        end

        function requiredDocumentationExists(testCase, RequiredDocument)
            documentPath = fullfile(testCase.ProjectRoot, "docs", RequiredDocument);
            testCase.verifyTrue(isfile(documentPath), ...
                sprintf("Missing required document: %s", documentPath));
        end
    end
end
