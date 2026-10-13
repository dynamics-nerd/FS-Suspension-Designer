function evaluation = zeroLengthBuilderFailureCall(space,u,id)
%ZEROLENGTHBUILDERFAILURECALL Test-only broken internal invariant, not public API.
% Exercise a real MATLAB field-access exception inside BUILDER without adding
% fault-injection hooks to production or changing any physical source.
space.seed.hardpoints=rmfield(space.seed.hardpoints,'sourceNote');
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); original=pwd;
cleanup=onCleanup(@() cd(original)); cd(fullfile(root,'src','+fsd','+synthesis','private'));
evaluation=evaluateCore(space,u,id);
end
