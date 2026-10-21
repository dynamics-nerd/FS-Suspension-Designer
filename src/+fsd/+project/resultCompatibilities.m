function reports=resultCompatibilities(project)
%RESULTCOMPATIBILITIES Validate one immutable project, classify its full ledger.
% Public trust boundary: no unvalidated result or configuration can bypass it.
context=validationContext(); context.project(project);
reports=cell(size(project.definition.results));
for j=1:numel(reports)
    reports{j}=compatibilityCore(project.definition.results{j},project,false,context);
end
end
