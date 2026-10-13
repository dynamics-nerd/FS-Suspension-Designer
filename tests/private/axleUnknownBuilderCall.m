function value = axleUnknownBuilderCall(space)
%AXLEUNKNOWNBUILDERCALL Real missing-field error below the private test boundary.
space.cornerSpaces{1}.seed.hardpoints=rmfield(space.cornerSpaces{1}.seed.hardpoints,'sourceNote');
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=pwd;
cleanup=onCleanup(@() cd(old)); cd(fullfile(root,'src','+fsd','+synthesis','private'));
value=axleEvaluationCore(space,coordinateCore(space,space.initial_m,"NORMALIZE"),1);
end
