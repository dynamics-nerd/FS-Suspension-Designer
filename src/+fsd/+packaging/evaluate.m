function result=evaluate(definition,geometry,plan,source)
%EVALUATE Nominal or explicitly supplied BUMP samples; no implicit forward solve.
% CLEAR_SAMPLED applies only to declared primitives/pairs/regions and samples.
fsd.packaging.validateDefinition(definition); fsd.model.validateDoubleWishboneGeometry(geometry);
assert(isstruct(plan) && isscalar(plan) && isequal(sort(string(fieldnames(plan))),sort(["mode";"requested_m"])) && ...
    isscalar(string(plan.mode)) && ismember(string(plan.mode),["NOMINAL","BUMP"]), ...
    'fsd:packaging:InvalidPlan','Explicit NOMINAL/BUMP plan and requested_m required.');
plan.mode=string(plan.mode);
if plan.mode=="NOMINAL"
    assert(isempty(plan.requested_m) && isempty(source),'fsd:packaging:InvalidPlan','Nominal has no sampled source/grid.');
    count=1;
else
    grid=plan.requested_m;
    assert(isnumeric(grid) && isreal(grid) && isvector(grid) && ~isempty(grid) && all(isfinite(grid)), ...
        'fsd:packaging:InvalidPlan','Explicit finite BUMP requests required.');
    plan.requested_m=double(grid(:)); count=numel(grid);
    if ~isempty(source)
        fsd.kinematics.validateBumpSweepResult(source);
        assert(isequaln(source.geometryIdentity,fsd.model.geometryIdentity(geometry)) && ...
            isequaln(source.requestedWheelTravel_m,plan.requested_m), ...
            'fsd:packaging:GeometryMismatch','Source geometry/grid differs from the requested evaluation.');
    end
end
d=definition.definitionSI; states=cell(count,1); checks=cell(count*numel(d.pairs),1);
regions=cell(count*numel(d.regions),1); checkIndex=0; regionIndex=0; validStates=false(count,1);
volumeIds=string(cellfun(@(v)v.definitionSI.id,d.volumes,'UniformOutput',false));
for sample=1:count
    native=[]; requested=NaN; sourceStatus="NOMINAL";
    available=plan.mode=="NOMINAL" || ~isempty(source);
    if plan.mode=="BUMP"
        requested=plan.requested_m(sample); sourceStatus="SOURCE_MISSING";
        if available, native=source.results(sample); sourceStatus=string(native.status); end
    end
    validStates(sample)=available && (isempty(native) || native.converged);
    if available
        [volumes,diagnostics,points]=fsd.packaging.resolveVolumes(definition,geometry,native);
    else
        volumes=cell(size(d.volumes)); diagnostics=repmat("SOURCE_MISSING",size(volumes));
        points=geometry.hardpoints; points.xyz_m(:)=NaN;
    end
    states{sample}=struct('sampleIndex',sample,'requested_m',requested,'sourceStatus',sourceStatus, ...
        'valid',validStates(sample),'volumes',{volumes},'volumeDiagnostics',diagnostics,'points',points);
    for j=1:numel(d.pairs)
        p=d.pairs{j}; a=find(volumeIds==p.first); b=find(volumeIds==p.second);
        check=struct('sampleIndex',sample,'pairId',p.id,'firstVolume',p.first,'secondVolume',p.second, ...
            'firstComponent',d.volumes{a}.definitionSI.componentId,'secondComponent',d.volumes{b}.definitionSI.componentId, ...
            'status',"INCOMPLETE",'evaluated',false,'distance_m',NaN,'margin_m',NaN, ...
            'requiredClearance_m',p.requiredClearance_m,'witnesses_m',nan(2,3), ...
            'intersection',false,'numericBudget_m',NaN,'broadPhaseSeparated',false, ...
            'exception',p.exception,'diagnostic',"Source/dimensions/pose unavailable.");
        if ~isempty(p.exception)
            check.status="EXEMPT_CONTACT"; check.diagnostic="Explicit exact-pair exception: "+p.exception.reason;
        elseif ~validStates(sample)
            check.diagnostic="Required sample is unavailable: "+sourceStatus;
        elseif isempty(volumes{a}) || isempty(volumes{b})
            check.diagnostic=diagnostics(a)+" / "+diagnostics(b);
        else
            separation=fsd.packaging.distance(volumes{a},volumes{b});
            for name=["distance_m","witnesses_m","intersection","numericBudget_m","broadPhaseSeparated","diagnostic"]
                check.(name)=separation.(name);
            end
            check.status=separation.status;
            if separation.status=="EVALUATED"
                check.evaluated=true; check.margin_m=check.distance_m-p.requiredClearance_m;
                if separation.intersection, check.status="COLLISION_DETECTED";
                elseif check.margin_m<0, check.status="LOW_CLEARANCE";
                elseif check.margin_m<=separation.numericBudget_m
                    check.status="INCOMPLETE"; check.diagnostic="Clearance boundary numerically unresolved; not a physical margin.";
                else, check.status="CLEAR_SAMPLED";
                end
            end
        end
        checkIndex=checkIndex+1; checks{checkIndex}=check;
    end
    for j=1:numel(d.regions)
        regionIndex=regionIndex+1;
        regions{regionIndex}=regionCheck(d.regions{j},points,geometry,volumes,volumeIds,sample,validStates(sample));
    end
end
statuses=string(cellfun(@(c)c.status,[checks;regions],'UniformOutput',false));
exempt=statuses=="EXEMPT_CONTACT"; effective=statuses(~exempt);
coverageComplete=all(validStates) && ~isempty(effective) && all(ismember(effective, ...
    ["CLEAR_SAMPLED","COLLISION_DETECTED","LOW_CLEARANCE"]));
status="NOT_EVALUATED";
if any(effective=="COLLISION_DETECTED"), status="COLLISION_DETECTED";
elseif any(effective=="LOW_CLEARANCE"), status="LOW_CLEARANCE";
elseif coverageComplete, status="CLEAR_SAMPLED";
elseif ~isempty(effective), status="INCOMPLETE";
end
distances=cellfun(@(c)c.distance_m,checks); margins=cellfun(@(c)c.margin_m,checks);
minimum=NaN; worstCheck=NaN;
if any(isfinite(distances)), minimum=min(distances(isfinite(distances))); end
finite=find(isfinite(margins));
if ~isempty(finite), [~,k]=min(margins(finite)); worstCheck=finite(k); end
coverage=struct('domain',plan.mode,'requestedSamples',count,'resolvedSamples',nnz(validStates), ...
    'failedSamples',find(~validStates),'requiredChecks',numel(effective), ...
    'evaluatedChecks',nnz(ismember(effective,["CLEAR_SAMPLED","COLLISION_DETECTED","LOW_CLEARANCE"])), ...
    'notEvaluatedChecks',nnz(effective=="NOT_EVALUATED"),'incompleteChecks',nnz(effective=="INCOMPLETE"), ...
    'exemptChecks',nnz(exempt),'complete',coverageComplete);
result=struct('schemaVersion',"0.19.0",'kind',"PackagingResult",'definition',definition, ...
    'geometry',geometry,'plan',plan,'source',source,'status',status,'coverage',coverage, ...
    'states',{states},'checks',{checks},'regions',{regions},'minimumObservedDistance_m',minimum, ...
    'worstCheckIndex',worstCheck,'limitations',["Only declared simplified volumes and pairs were checked."; ...
    "A collision between requested samples can be missed. No continuous clearance guarantee."; ...
    "CLEAR_SAMPLED is not CAD, manufacturing, structural or regulatory approval."]);
end

function row=regionCheck(r,points,geometry,volumes,ids,sample,valid)
row=struct('sampleIndex',sample,'regionId',r.id,'pointId',r.pointId,'status',"INCOMPLETE", ...
    'margin_m',NaN,'point_m',nan(1,3),'diagnostic',"Point/source/region unavailable.");
index=find(points.ids==r.pointId);
if ~valid || r.cornerId~=geometry.cornerId || numel(index)~=1, return; end
p=points.xyz_m(index,:); row.point_m=p;
if r.mode=="FIXED"
    row.margin_m=r.tolerance_m-norm(p-r.target_m);
else
    v=volumes{ids==r.volumeId};
    if isempty(v) || isempty(v.definitionSI.dimensions), return; end
    d=v.definitionSI; local=(p-d.transform(1:3,4)')*d.transform(1:3,1:3);
    switch d.shape
        case "SPHERE", insideClearance=d.dimensions(1)-norm(local);
        case "CAPSULE"
            half=d.dimensions(2)/2;
            insideClearance=d.dimensions(1)-norm(local-[0 0 min(half,max(-half,local(3)))]);
        case {"AABB","OBB"}
            delta=abs(local)-d.dimensions/2;
            if all(delta<=0), insideClearance=-max(delta); else, insideClearance=-norm(max(delta,0)); end
        otherwise
            row.status="NOT_EVALUATED"; row.diagnostic="Unsupported region primitive."; return;
    end
    if r.mode=="INSIDE", row.margin_m=insideClearance-r.clearance_m;
    else, row.margin_m=-insideClearance-r.clearance_m;
    end
end
if ~isfinite(row.margin_m), row.diagnostic="Point-region numerical range exceeded."; return; end
row.status="CLEAR_SAMPLED"; row.diagnostic="Explicit point-region constraint, not generated hardpoints.";
if row.margin_m<0, row.status="LOW_CLEARANCE"; end
end
