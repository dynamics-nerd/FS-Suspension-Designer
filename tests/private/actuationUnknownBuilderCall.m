function result = actuationUnknownBuilderCall(space)
%ACTUATIONUNKNOWNBUILDERCALL Real missing-field error after private test boundary.
space.seedActuation.damper.chassisPoint=rmfield(space.seedActuation.damper.chassisPoint,'point_m');
root=fileparts(fileparts(fileparts(mfilename('fullpath')))); old=pwd;
cleanup=onCleanup(@()cd(old)); cd(fullfile(root,'src','+fsd','+synthesis','private'));
result=actuationEvaluationCore(space,coordinateCore(space,space.initial_m,"NORMALIZE"),1);
end
