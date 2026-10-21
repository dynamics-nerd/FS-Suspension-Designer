function valid=validateEngineeringProject(project)
%VALIDATEENGINEERINGPROJECT Full canonical input and historical ledger boundary.
context=validationContext(); valid=context.project(project);
end
