function candidate = scenarioCandidate(p,payload)
%SCENARIOCANDIDATE Bind declared aliases to actual native evidence, no new curves.
requests=fsd.project.specificationSources(p.scenario.definition.specification); sources=cell(0,1);
ids=strings(0,1); resources=p.resources;
for j=1:numel(requests)
    q=requests{j}; if ismember(q.sourceId,ids), continue; end
    s=struct('id',q.sourceId,'type',q.sourceType,'model',[],'auxiliary',[],'sweep',[],'result',[]);
    switch q.sourceType
        case "BUMP"
            s.model=resources.geometries{1}; s.sweep=payload.sweep; s.result=payload.analysis;
            if ismember(p.scenario.definition.engine,["ACTUATION","MECHANICAL"])
                s.sweep=payload.bump; s.result=fsd.analysis.analyzeBumpSweep(s.model,s.sweep);
            end
        case "ROLL"
            s.model=fsd.model.createAxleGeometry(resources.geometries{1},resources.geometries{2});
            s.sweep=payload.sweep; s.result=payload.analysis;
        case "RACK", s.model=resources.steerings{1}; s.sweep=payload.sweep; s.result=payload.analysis;
        case "ACTUATION"
            s.model=resources.actuations{1}; s.sweep=payload.sweep; s.result=payload.actuationAnalysis;
        case "MECHANICAL"
            s.model=resources.mechanicals{1}; s.auxiliary=resources.actuations{1}; s.result=payload.analysis;
        otherwise, projectRequire(false,'Source has no analysis adapter.');
    end
    ids(end+1,1)=q.sourceId; sources{end+1,1}=s; %#ok<AGROW>
end
definition=struct('id',p.scenario.definition.id+'_EVIDENCE','geometries',{resources.geometries},'sources',{sources});
if ~isempty(resources.actuations), definition.actuations=resources.actuations; end
candidate=fsd.model.createDesignCandidate(definition);
end
