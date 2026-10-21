function prepared=preparePackagingScenario(project,scenario,context)
%PREPAREPACKAGINGSCENARIO Stored native evidence only; canonical compatibility.
d=scenario.definition;
projectRequire(d.scope.kind=="CORNER" && isempty(d.specification) && isempty(fieldnames(d.options)) && ...
    isempty(d.symmetryLinks) && isempty(d.conceptDependencies) && isempty(d.targetOrigins), ...
    'Packaging currently evaluates one explicit corner with no optimizer/target controls.');
% Reuse the native registry/origin-binding gate rather than invent another one.
nominal=fsd.project.createEngineeringScenario(struct('id',d.id,'engine',"STATIC_GEOMETRY",'scope',d.scope));
prepared=context.prepare(project,nominal); prepared.scenario=scenario; prepared.plan=d.plan;
prepared.readiness.engine="PACKAGING";
prepared.readiness.limitations=["Simplified occupied solids; no exact CAD/manufacturing or continuous-motion certification."; ...
    "Packaging consumes stored native states and never executes BUMP/search implicitly."];
prepared.packagingDefinition=[]; prepared.packagingGeometry=[]; prepared.packagingSource=[];
if prepared.readiness.status~="READY", return; end
inputs=d.inputs;
projectRequire(isequal(sort(string(fieldnames(inputs))),sort(["packagingId";"selection";"parent";"candidateIndex"])), ...
    'Packaging needs packagingId, REGISTRY/CANDIDATE/SEED selection, parent and candidateIndex.');
registry=project.definition.resources; selected=[];
if isfield(registry,'packaging')
    for j=1:numel(registry.packaging)
        if registry.packaging{j}.definitionSI.id==string(inputs.packagingId), selected=registry.packaging{j}; break; end
    end
end
if isempty(selected)
    prepared.readiness.status="MISSING_DATA"; prepared.readiness.missing="PACKAGING:"+string(inputs.packagingId); return;
end
projectRequire(ismember(string(inputs.selection),["REGISTRY","CANDIDATE","SEED"]),'Unknown packaging selection.');
projectRequire(isfield(d.plan,'mode') && isfield(d.plan,'requested_m') && ...
    isequal(sort(string(fieldnames(d.plan))),sort(["mode";"requested_m"])),'Explicit packaging mode/grid required.');
g=prepared.resources.geometries{1}; registryContext=prepared.context; source=[]; parentContext=[];
if ~isempty(inputs.parent)
    parent=inputs.parent;
    projectRequire(ismember(parent.engine,["BUMP","CORNER_SYNTHESIS","AXLE_SYNTHESIS"]), ...
        'Only native BUMP/corner/axle evidence is adapted; no recursive packaging parent.');
    % Ledger is excluded from configuration identity. Avoid recursive validation
    % of the current packaging ledger while invoking the PUBLIC compatibility API.
    configuration=project; configuration.definition.results=cell(0,1); configuration.definition.derivations=cell(0,1);
    % Private preparation receives a canonically validated configuration (or
    % one constructed by projectCore). Validate the external parent, not that
    % same immutable configuration again for every stored check.
    context.reference(parent);
    compatibility=compatibilityCore(parent,configuration,parent.kind=="PackagingSourceReference",context);
    if ~ismember(compatibility.status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"])
        prepared.readiness.status="BLOCKED_BY_DEPENDENCY";
        prepared.readiness.missing="STALE_PARENT:"+parent.id; return;
    end
    parentContext=parent.prepared.context;
    if inputs.selection=="REGISTRY"
        projectRequire(parent.engine=="BUMP" && isempty(inputs.candidateIndex),'REGISTRY sampled packaging requires a BUMP parent.');
        source=parent.nativePayload.sweep;
    else
        projectRequire(endsWith(parent.engine,'SYNTHESIS'),'Candidate packaging requires stored synthesis evidence.');
        history=parent.nativePayload; index=inputs.candidateIndex;
        projectRequire(isnumeric(index) && isreal(index) && isscalar(index) && isfinite(index) && ...
            index>=1 && fix(index)==index && index<=numel(history.search.records),'Explicit stored candidate index required.');
        record=history.search.records{index};
        if isempty(record.candidate)
            prepared.readiness.status="MISSING_DATA"; prepared.readiness.missing="CANDIDATE_HAS_NO_GEOMETRY_OR_SOURCES"; return;
        end
        candidates=record.candidate.definitionSI.geometries; g=[];
        for j=1:numel(candidates), if candidates{j}.cornerId==d.scope.id, g=candidates{j}; break; end, end
        if isempty(g)
            prepared.readiness.status="MISSING_DATA"; prepared.readiness.missing="CANDIDATE_GEOMETRY:"+d.scope.id; return;
        end
        if inputs.selection=="SEED"
            if parent.engine=="CORNER_SYNTHESIS", seed=history.problem.seed;
            else
                seed=history.problem.seedAxle.leftGeometry;
                if seed.cornerId~=d.scope.id, seed=history.problem.seedAxle.rightGeometry; end
            end
            projectRequire(isequaln(fsd.model.geometryIdentity(g),fsd.model.geometryIdentity(seed)), ...
                'SEED index must identify actual seed geometry, not an arbitrary candidate.');
        end
        if string(d.plan.mode)=="BUMP"
            sources=record.candidate.definitionSI.sources;
            for j=1:numel(sources)
                s=sources{j};
                if s.type=="BUMP" && s.model.cornerId==d.scope.id, source=s.sweep; break; end
            end
        end
    end
elseif inputs.selection~="REGISTRY" || string(d.plan.mode)~="NOMINAL" || ~isempty(inputs.candidateIndex)
    prepared.readiness.status="MISSING_DATA"; prepared.readiness.missing="NATIVE_PARENT_RESULT"; return;
end
if string(d.plan.mode)=="NOMINAL", source=[]; end
if string(d.plan.mode)=="BUMP" && isempty(source)
    prepared.readiness.status="MISSING_DATA"; prepared.readiness.missing="NATIVE_BUMP_SAMPLES"; return;
end
% Validate state/model/grid without computing packaging distances at readiness.
projectRequire(ismember(string(d.plan.mode),["NOMINAL","BUMP"]),'Unsupported packaging motion domain.');
if string(d.plan.mode)=="NOMINAL"
    projectRequire(isempty(d.plan.requested_m),'Nominal plan has no sampled grid.');
else
    fsd.kinematics.validateBumpSweepResult(source);
    projectRequire(isequaln(source.geometryIdentity,fsd.model.geometryIdentity(g)) && ...
        isequaln(source.requestedWheelTravel_m,d.plan.requested_m(:)),'Packaging parent geometry/grid differs.');
end
prepared.resources.packaging={selected}; prepared.packagingDefinition=selected;
prepared.packagingGeometry=g; prepared.packagingSource=source;
prepared.context=struct('engine',"PACKAGING",'scenario',scenario.identity,'registry',registryContext, ...
    'packaging',selected.identity,'geometry',fsd.model.geometryIdentity(g),'frame',g.referenceFrame,'parent',parentContext);
end
