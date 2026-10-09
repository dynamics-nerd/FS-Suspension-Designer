function [alternatives, selected, status] = globalSelectionTestCall(attempts, options)
%GLOBALSELECTIONTESTCALL Isolated contract test of the production private selector.
% MATLAB resolves the current folder; do not copy code or add private folders
% to the path. Restore the caller's folder even if the tested function throws.
root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
originalFolder = pwd;
cleanup = onCleanup(@() cd(originalFolder));
cd(fullfile(root,"src","+fsd","+analysis","private"));
[alternatives, selected, status] = globalSelectionCore(attempts,options);
end
