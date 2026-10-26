function result=evaluateAntiRollBar(definition,source)
%EVALUATEANTIROLLBAR Sampled ARB adapter; reuse existing finite primitive kernel.
fsd.packaging.validateAntiRollBarDefinition(definition);
need(isstruct(source)&&isscalar(source)&&isfield(source,'kind'),'An ARB resource or stored study is required.');
if source.kind=="AntiRollBar"
    fsd.model.validateAntiRollBar(source); bar=source; states={};
    if bar.definition.representation=="COAXIAL_TORSION"&&fsd.model.antiRollBarReadiness(bar,'GEOMETRY').status=="READY"
        states={struct('available',true,'driverPoints_m',bar.definition.parameters.driverPoints_m, ...
            'armPoints_m',bar.definition.parameters.armPoints_m)};
    end
    mode="NOMINAL_DECLARATION";
else
    need(isstruct(source)&&isscalar(source)&&all(isfield(source,{'prepared','requestedWheelTravel_m'})),'Stored ARB study required.');
    bar=source.prepared.bar;
    states={};
    if bar.definition.representation=="COAXIAL_TORSION"
        canonical=fsd.analysis.analyzeAntiRollBarKinematicSweep(source.prepared,source.requestedWheelTravel_m);
        if source.kind=="AntiRollBarKinematicSweep", need(isequaln(source,canonical),'Crossed kinematic source.');
        elseif source.kind=="AntiRollBarSweep"
            expected=fsd.analysis.analyzeAntiRollBarSweep(source.prepared,source.requestedWheelTravel_m);
            sourceNoTime=rmfield(source,'elapsedTime_s'); expectedNoTime=rmfield(expected,'elapsedTime_s');
            need(isequaln(sourceNoTime,expectedNoTime),'Crossed mechanical source.');
        else, need(false,'Unsupported study source.');
        end
        states=canonical.responses;
    end
    mode="VALIDATED_SAMPLED_DRIVER_PATH";
end
result=struct('schemaVersion',"0.23.0",'kind',"AntiRollBarPackagingResult",'definition',definition, ...
    'source',source,'barIdentity',bar.identity,'mode',mode,'status',"NOT_EVALUATED", ...
    'checks',{{}},'resolved',{{}},'coverage',struct('required',0,'evaluated',0), ...
    'limitation',"Simplified occupied material; sampled clearance only, no continuous collision or manufacturing certificate.");
if bar.definition.representation~="COAXIAL_TORSION", result.status="NOT_SUPPORTED"; return; end
need(isequaln(definition.definition.frame,bar.definition.referenceFrame),'Packaging and ARB coordinate frames differ.');
if isempty(states), result.status="INCOMPLETE"; return; end
d=definition.definition; checks=cell(numel(states)*numel(d.pairs),1); resolved=cell(numel(states),1); row=0;
for k=1:numel(states)
    state=states{k}; volumes=d.obstacles; ids=cellfun(@(v)v.definitionSI.id,volumes,'UniformOutput',false);
    ids=string(ids(:)); volumes=volumes(:);
    for c=1:numel(d.components)
        component=d.components{c}; volume=[];
        if state.available
            first=point(bar,state,component.firstPoint); second=point(bar,state,component.secondPoint);
            if all(isfinite([first,second])), volume=primitive(component,d.frame,first,second,bar.definition.revision); end
        end
        volumes{end+1,1}=volume; ids(end+1,1)=component.id; %#ok<AGROW> Explicit component set.
    end
    resolved{k}=volumes;
    for j=1:numel(d.pairs)
        p=d.pairs{j}; a=volumes{ids==p.first}; b=volumes{ids==p.second};
        row=row+1; check=struct('sampleIndex',k,'pairId',p.id,'status',"INCOMPLETE", ...
            'distance_m',NaN,'requiredClearance_m',p.requiredClearance_m,'kernel',[]);
        if state.available&&~isempty(a)&&~isempty(b)&&~isempty(p.requiredClearance_m)
            kernel=fsd.packaging.distance(a,b); check.kernel=kernel; check.distance_m=kernel.distance_m;
            if kernel.status=="EVALUATED"
                if kernel.intersection, check.status="COLLISION_DETECTED";
                elseif kernel.distance_m+kernel.numericBudget_m<p.requiredClearance_m, check.status="LOW_CLEARANCE";
                elseif kernel.distance_m-kernel.numericBudget_m>=p.requiredClearance_m, check.status="CLEAR_SAMPLED";
                end
            elseif kernel.status=="NOT_EVALUATED", check.status="NOT_EVALUATED";
            end
        end
        checks{row}=check;
    end
end
result.checks=checks; result.resolved=resolved;
result.coverage.required=numel(checks);
if isempty(checks), return; end
statuses=string(cellfun(@(c)c.status,checks,'UniformOutput',false));
result.coverage.evaluated=sum(ismember(statuses,["COLLISION_DETECTED","LOW_CLEARANCE","CLEAR_SAMPLED"]));
if any(statuses=="COLLISION_DETECTED"), result.status="COLLISION_DETECTED";
elseif any(statuses=="LOW_CLEARANCE"), result.status="LOW_CLEARANCE";
elseif any(statuses=="INCOMPLETE"), result.status="INCOMPLETE";
elseif any(statuses=="NOT_EVALUATED"), result.status="NOT_EVALUATED";
else, result.status="CLEAR_SAMPLED";
end
end
function p=point(bar,state,id)
points=fsd.geometry.antiRollBarPoints(bar,state); found=points.ids==string(id); p=nan(1,3);
if any(found), p=points.xyz_m(found,:); end
end
function volume=primitive(c,frame,first,second,revision)
T=eye(4); T(1:3,4)=first'; dimensions=c.radius_m;
if c.shape=="CAPSULE"
    delta=second-first; length_m=norm(delta); R=eye(3);
    if length_m>0
        z=delta'/length_m; [~,i]=min(abs(z)); basis=zeros(3,1); basis(i)=1;
        x=cross(basis,z); x=x/norm(x); R=[x,cross(z,x),z];
    end
    T=[R,mean([first;second],1)';0 0 0 1];
    if ~isempty(dimensions), dimensions=[dimensions,length_m]; end
end
d=struct('id',c.id,'componentId',c.id,'componentType',"OTHER",'role',"OCCUPIED", ...
    'frame',frame,'shape',c.shape,'dimensions',dimensions,'transform',T, ...
    'binding',struct('mode',"FIXED",'cornerId',"",'pointIds',strings(0,1)), ...
    'source',c.source,'fidelity',"DECLARED_SIMPLIFIED_PRIMITIVE",'sourceRevision',revision, ...
    'provenance',c.source);
volume=fsd.packaging.createVolume(d,'m');
end
function need(ok,message)
assert(ok,'fsd:packaging:InvalidAntiRollBar',message);
end
