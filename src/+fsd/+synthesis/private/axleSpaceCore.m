function space = axleSpaceCore(left,right,spec,plan,links,extraRoles)
%AXLESPACECORE Compose existing corner bindings, not two independent searches.
axle=fsd.model.createAxleGeometry(left,right);
requireSynthesis(isequaln(left.referenceFrame,right.referenceFrame),'Seeds must share the complete vehicle reference frame.');
fsd.model.validateDesignSpecification(spec);
fsd.model.designVariableSpace(spec,true);
requireSynthesis(isstruct(plan) && isscalar(plan) && all(isfield(plan,{'leftBump','rightBump'})) && ...
    all(ismember(string(fieldnames(plan)),["leftBump","rightBump","roll"])), 'Explicit left/right BUMP plans required.');
if ~isfield(plan,'roll'), plan.roll=[]; end
roll=plan.roll;
if ~isempty(roll)
    requireSynthesis(isstruct(roll) && isscalar(roll) && all(isfield(roll,{'angles_rad','axleHeave_m'})) && ...
        all(ismember(string(fieldnames(roll)),["angles_rad","axleHeave_m","solverOptions"])), 'Explicit ROLL angle/heave plan required.');
    roll.angles_rad=orderedGrid(roll.angles_rad);
    requireSynthesis(all(abs(roll.angles_rad)<pi/2) && isnumeric(roll.axleHeave_m) && isreal(roll.axleHeave_m) && ...
        isscalar(roll.axleHeave_m) && isfinite(roll.axleHeave_m),'Invalid ROLL angle/heave.');
    if ~isfield(roll,'solverOptions'), roll.solverOptions=struct(); end
    roll=struct('angles_rad',roll.angles_rad,'axleHeave_m',double(roll.axleHeave_m), ...
        'solverOptions',fsd.kinematics.rollSolverSettings(roll.solverOptions));
    % Native static road/contact prerequisite, algebraic only (no solve).
    fsd.analysis.geometricWheelContact(left); fsd.analysis.geometricWheelContact(right);
end
corners=[left.cornerId;right.cornerId]; seeds={left;right}; d=spec.definitionSI;
for i=1:numel(d.parameters)
    p=d.parameters{i}.definitionSI;
    if any(p.type==["FREE","RANGE"]) || (p.type=="FIXED" && p.binding~="NONE")
        requireSynthesis(ismember(p.scope.cornerId,corners) && ismember(p.binding,["HARDPOINT_X","HARDPOINT_Y","HARDPOINT_Z"]), ...
            'Only bound coordinates on this axle can be controlled.');
    end
end
for i=1:numel(d.constraints)
    requireSynthesis(ismember(d.constraints{i}.definitionSI.scope.cornerId,corners),'Constraint outside this axle.');
end
sourceIds={strings(0,1);strings(0,1);strings(0,1)};
targets=d.targets.definitionSI.targets;
for i=1:numel(targets)
    t=targets{i}.definitionSI;
    if ~isempty(t.requiredSourceIdentity)
        error('fsd:synthesis:UnsupportedTarget','Target %s locks a source identity while geometry must change.',t.id);
    end
    if t.sourceType=="BUMP" && ismember(t.metricId,["CAMBER","TOE","BUMP_STEER","CASTER","KPI"]) && ismember(t.scope.id,corners)
        j=find(corners==t.scope.id);
    elseif t.sourceType=="ROLL" && ismember(t.metricId,["CAMBER","ROAD_CAMBER","TOE", ...
            "ROLL_CENTER_HEIGHT","ROLL_CENTER_ROAD_HEIGHT","ROLL_CENTER_Y","WHEEL_CENTER_TRACK_CHANGE"]) && ...
            ((t.scope.kind=="CORNER" && ismember(t.scope.id,corners)) || (t.scope.kind=="AXLE" && t.scope.id==axle.axleId))
        if isempty(roll)
            error('fsd:synthesis:MissingAnalysisPlan','Target %s requires an explicit native ROLL plan.',t.id);
        end
        requireSynthesis(t.conditions.axleHeave_m==roll.axleHeave_m,'Target ROLL heave differs from the execution plan.');
        j=3;
    else
        error('fsd:synthesis:UnsupportedTarget','Target %s requires unsupported axle reconstruction %s/%s/scope %s.', ...
            t.id,t.sourceType,t.metricId,t.scope.id);
    end
    sourceIds{j}(end+1,1)=t.sourceId;
end
spaces=cell(2,1);
for j=1:2
    sub=d; sub.id=d.id+"_"+corners(j); sub.compositeScore=false;
    sub.parameters=d.parameters(cellfun(@(p) p.definitionSI.scope.cornerId==corners(j),d.parameters));
    sub.constraints=d.constraints(cellfun(@(c) c.definitionSI.scope.cornerId==corners(j),d.constraints));
    selected=targets(cellfun(@(t) t.definitionSI.sourceType=="BUMP" && t.definitionSI.scope.id==corners(j),targets));
    sub.targets=fsd.model.createSuspensionDesignTargets(selected);
    name="leftBump"; if j==2, name="rightBump"; end
    if nargin==6
        spaces{j}=spaceCore(seeds{j},fsd.model.createDesignSpecification(sub),plan.(name),extraRoles);
    else
        spaces{j}=spaceCore(seeds{j},fsd.model.createDesignSpecification(sub),plan.(name));
    end
    sourceIds{j}=unique(sourceIds{j},'stable');
    if isempty(sourceIds{j}), sourceIds{j}="SYNTH_BUMP_"+corners(j); end
end
sourceIds{3}=unique(sourceIds{3},'stable');
if ~isempty(roll) && isempty(sourceIds{3}), sourceIds{3}="SYNTH_ROLL_"+axle.axleId; end
allIds=vertcat(sourceIds{:});
requireSynthesis(numel(unique(allIds))==numel(allIds),'Source IDs cannot cross corners or analysis families.');
plan=struct('leftBump',spaces{1}.plan,'rightBump',spaces{2}.plan,'roll',roll);
requireSynthesis(isstring(links) && ismatrix(links) && size(links,2)==2 && ~any(ismissing(links),'all'), ...
    'Symmetry links must be an N-by-2 string array [leftParameterId,rightParameterId].');
physical=[spaces{1}.variables;spaces{2}.variables]; count=numel(physical); leftCount=numel(spaces{1}.variables);
ids=cellfun(@(v) v.id,physical); dependent=false(count,1); partner=zeros(count,1); multiplier=ones(count,1);
if ~isempty(links)
    requireSynthesis(isequaln(right.wheel.wheelAxis,left.wheel.wheelAxis.*[1,-1,1]),'Linked symmetry requires mirrored outward wheel axes.');
end
for k=1:size(links,1)
    i=find(ids==links(k,1)); j=find(ids==links(k,2));
    requireSynthesis(isscalar(i) && isscalar(j) && i<=leftCount && j>leftCount && partner(i)==0 && ~dependent(j), ...
        'Invalid, repeated or reversed symmetry link.');
    a=physical{i}; b=physical{j};
    requireSynthesis(a.component==b.component && extractAfter(a.hardpointId,3)==extractAfter(b.hardpointId,3), ...
        'Symmetry must link corresponding hardpoint components.');
    signValue=1; if a.component=="Y", signValue=-1; end
    requireSynthesis(b.initial_m==signValue*a.initial_m,'Seeds contradict the requested exact coordinate symmetry.');
    partner(i)=j; dependent(j)=true; multiplier(j)=signValue;
end
variables=cell(0,1); map=zeros(count,1);
for i=find(~dependent)'
    v=physical{i}; members=i; j=partner(i);
    if j>0
        bounds=sort(multiplier(j)*[physical{j}.lower_m,physical{j}.upper_m]);
        v.lower_m=max(v.lower_m,bounds(1)); v.upper_m=min(v.upper_m,bounds(2)); members=[i;j];
        requireSynthesis(v.lower_m<=v.upper_m && v.initial_m>=v.lower_m && v.initial_m<=v.upper_m,'Incompatible linked bounds.');
    end
    v.physicalIndices=members; variables{end+1,1}=v; map(members)=numel(variables); %#ok<AGROW>
end
lower=cellfun(@(v) v.lower_m,variables); upper=cellfun(@(v) v.upper_m,variables); initial=cellfun(@(v) v.initial_m,variables);
requireSynthesis(all(isfinite(upper-lower)),'Joint span is not representable.');
space=struct('schemaVersion',"0.13.0",'kind',"AxleSynthesisDesignSpace",'seedAxle',axle, ...
    'seedIdentity',fsd.model.axleIdentity(axle),'cornerIds',corners,'specification',spec,'plan',plan, ...
    'symmetryLinks',links,'cornerSpaces',{spaces},'physicalVariables',{physical},'variables',{variables}, ...
    'independentIndex',map,'multiplier',multiplier,'sourceIds',{sourceIds}, ...
    'lower_m',lower,'upper_m',upper,'initial_m',initial,'active',upper>lower);
end

function grid = orderedGrid(value)
requireSynthesis(isnumeric(value) && isreal(value) && isvector(value) && ~isempty(value) && all(isfinite(value)), 'Finite ordered grid required.');
grid=double(value(:));
requireSynthesis(isscalar(grid) || all(diff(grid)>0) || all(diff(grid)<0),'Grid must be strictly monotonic.');
end
