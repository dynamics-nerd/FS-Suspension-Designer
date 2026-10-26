function project=assignAntiRollBars(project,assignments)
%ASSIGNANTIROLLBARS Explicit axle-to-resource/revision mapping.
fsd.project.validateEngineeringProject(project); resources=project.definition.resources;
resources.arbAssignments=assignments;
project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
end
