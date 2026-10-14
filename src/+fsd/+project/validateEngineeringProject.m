function valid = validateEngineeringProject(project)
%VALIDATEENGINEERINGPROJECT Structural integrity; missing inputs remain permissible.
projectRequire(isequaln(project,projectCore(project.definition)),'Project identity or definition mismatch.');
valid=true;
end
