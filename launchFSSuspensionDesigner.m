function app = launchFSSuspensionDesigner()
%LAUNCHFSSUSPENSIONDESIGNER Open the editable native R2026b App Designer app.
root=fileparts(mfilename('fullpath')); setupProject(); addpath(fullfile(root,'app'));
app=FSSuspensionDesigner();
end
