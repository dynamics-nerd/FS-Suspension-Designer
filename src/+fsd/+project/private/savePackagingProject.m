function savePackagingProject(project,file)
%SAVEPACKAGINGPROJECT Native v0.19 MAT, bounded ledger (including non-Packaging history).
% Do not send the complete nested string/object graph to the v7 serializer.
records=project.definition.results; configuration=project;
configuration.definition.results=cell(0,1);
names=arrayfun(@(j)sprintf('FSD_RESULT_%06d',j),1:numel(records),'UniformOutput',false);
envelope=struct('kind','FsdEngineeringProjectStorage','schemaVersion','0.19.0', ...
    'encoding','FSD_VALUE_GRAPH_V1','configuration',fsd.project.encodeStorageGraph(configuration), ...
    'resultNames',{names},'resultShape',size(records));
info=whos('envelope'); largest=info.bytes;
% An operation-local32MiB I/O work buffer avoids encoding small graphs twice.
% This is NOT a project/history limit. Uncached records use the bounded
% one-at-a-time fallback below; no value or historical evidence is pruned.
cacheBudget=32*1024^2; cachedBytes=0; cache=cell(size(records));
% Measure one encoded record at a time, keeping only the budgeted graphs.
for j=1:numel(records)
    encoded=fsd.project.encodeStorageGraph(records{j}); % Measure without retaining all records.
    info=whos('encoded');
    largest=max(largest,info.bytes);
    if info.bytes<=cacheBudget-cachedBytes
        cache{j}=encoded; cachedBytes=cachedBytes+info.bytes;
    end
end
clear encoded;
% Official v7 per-variable limit is 2^31 bytes. WHOS is an in-memory
% preflight estimate, not a serialized-size proof or engineering threshold.
% v7.3 permits larger values; the final inventory also detects skipped records.
format='-v7'; if largest>=2^31, format='-v7.3'; end
save(file,'envelope',format);
for j=1:numel(records)
    if isempty(cache{j}), encoded=fsd.project.encodeStorageGraph(records{j});
    else, encoded=cache{j}; end
    cache{j}=[]; piece=struct(); piece.(names{j})=encoded;
    save(file,'-struct','piece','-append');
    clear piece encoded;
end
variables=whos('-file',file);
projectRequire(isequal(sort(string({variables.name})),sort(["envelope",string(names)])), ...
    'MAT storage is missing a required variable; no successful save asserted.');
end
