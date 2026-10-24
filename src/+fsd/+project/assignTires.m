function project=assignTires(project,assignments)
%ASSIGNTIRES Replace explicit corner assignments, retaining all tire revisions.
fsd.project.validateEngineeringProject(project); resources=project.definition.resources;
resources.tireAssignments=assignments;
project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
end
