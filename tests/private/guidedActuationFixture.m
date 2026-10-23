function [project,args,space,options] = guidedActuationFixture()
%GUIDEDACTUATIONFIXTURE Explicit historical synthetic geometry, no FS advice.
[space,options]=actuationSynthesisFixture();
[~,~,~,definition,mechanical,units]=actuationSynthesisSeed('PUSHROD','FL');
concept=fsd.project.createVehicleConcept(struct('id',"GUIDED_ACT"));
project=fsd.project.createEngineeringProject(struct('concept',concept, ...
    'resources',struct('geometries',{{space.seed}})));
args=struct('cornerId',"FL",'definition',definition,'lengthUnit',"m", ...
    'mechanicalDefinition',mechanical,'units',units);
end
