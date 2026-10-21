function [project,reports]=mergeEngineeringProjectHistory(updated,original)
%MERGEENGINEERINGPROJECTHISTORY Append a worker delta without pruning old evidence.
% Both external values are validated. No identity-only proof or global cache.
context=validationContext(); context.project(original); context.project(updated);
projectRequire(updated.id==original.id && updated.definition.revision>=original.definition.revision, ...
    'Worker configuration belongs to another project or an older revision.');
d=updated.definition;
d.results=[original.definition.results;d.results];
d.derivations=[original.definition.derivations;d.derivations];
% Both immutable input ledgers are fully validated above. Compose those exact
% values, never data supplied under an ID-only proof. Only configuration needs
% canonical reconstruction; revalidating the combined ledger adds no guarantee.
records=d.results; derivations=d.derivations; d.results=cell(0,1); d.derivations=cell(0,1);
project=projectCore(d,context);
ids=cellfun(@(r)string(r.id),records);
projectRequire(numel(unique(ids))==numel(ids),'Duplicate result IDs.');
[~,order]=sort(ids); project.definition.results=records(order);
project.definition.derivations=derivations;
reports=cell(size(project.definition.results));
for j=1:numel(reports)
    reports{j}=compatibilityCore(project.definition.results{j},project,false,context);
end
end
