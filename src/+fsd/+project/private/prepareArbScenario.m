function p=prepareArbScenario(project,scenario)
%PREPAREARBSCENARIO Explicit source declarations/readiness, no mechanism solve.
d=scenario.definition;
r=struct('scenarioId',d.id,'engine',d.engine,'scope',d.scope,'status',"READY", ...
    'missing',strings(0,1),'diagnostics',strings(0,1), ...
    'limitations',["Preliminary elastic ARB model; no structural certification.";"Sampled paths, not a dynamic vehicle or experimental validation."]);
p=struct('schemaVersion',"0.16.0",'kind',"PreparedEngineeringScenario",'scenario',scenario, ...
    'resources',resourceCore(struct()),'bar',[],'plan',d.plan,'options',d.options, ...
    'driverOptions',struct(),'context',[],'readiness',r);
try
    projectRequire(d.scope.kind=="AXLE"&&isempty(d.specification)&&isempty(d.symmetryLinks)&& ...
        isempty(d.targetOrigins)&&isempty(d.conceptDependencies),'ARB analysis requires axle scope without targets.');
    projectRequire(all(ismember(string(fieldnames(d.inputs)),["arbId","arbRevision"])),'Unknown ARB inputs.');
    projectRequire(all(ismember(string(fieldnames(d.plan)),["motion","wheelTravel_m","driverTravel_m","rollAngles_rad","axleHeave_m","packaging","target"])), ...
        'Unknown ARB plan fields.');
    for key=["arbId","arbRevision"], if ~isfield(d.inputs,key), r.missing(end+1,1)="INPUT:"+key; end, end
    if ~isempty(r.missing), r.status="MISSING_DATA"; p.readiness=r; return; end
    projectRequire(isstring(d.inputs.arbId)&&isscalar(d.inputs.arbId)&&isnumeric(d.inputs.arbRevision)&& ...
        isscalar(d.inputs.arbRevision)&&isfinite(d.inputs.arbRevision),'Exact ARB revision required.');
    p.bar=fsd.project.findAntiRollBar(project,d.inputs.arbId,d.inputs.arbRevision);
    if isempty(p.bar), r.status="MISSING_DATA"; r.missing="ARB:REGISTER_REVISION"; p.readiness=r; return; end
    projectRequire(p.bar.definition.axleId==d.scope.id,'ARB belongs to another axle.');
    if d.engine=="ARB_SIZING"
        projectRequire(isempty(fieldnames(d.options))&&all(ismember(string(fieldnames(d.plan)),"target")), ...
            'Section sizing consumes a user target only, without motion/options.');
        if p.bar.definition.representation~="COAXIAL_TORSION", r.status="UNSUPPORTED"; r.diagnostics="Equivalent linear coupling does not define a shaft section."; end
        if ~isfield(d.plan,'target'), r.missing(end+1,1)="PLAN:target";
        else
            target=d.plan.target;
            projectRequire(isstruct(target)&&isscalar(target)&&all(ismember(string(fieldnames(target)), ...
                ["sourceKind";"sourceNote";"stiffness_Nm_per_rad"])),'Explicit sizing target and provenance required.');
            for key=["stiffness_Nm_per_rad","sourceKind","sourceNote"]
                if ~isfield(target,key)||isempty(target.(key))|| ...
                        (isstring(target.(key))&&isscalar(target.(key))&&ismember(target.(key),["","UNSELECTED"]))
                    r.missing(end+1,1)="TARGET:"+key; continue;
                end
                if key=="stiffness_Nm_per_rad"
                    v=target.(key); projectRequire(isnumeric(v)&&isreal(v)&&isscalar(v)&&isfinite(v)&&v>0,'Positive user target required.');
                elseif key=="sourceKind"
                    projectRequire(isstring(target.(key))&&isscalar(target.(key))&&ismember(target.(key),["KNOWN","ASSUMED","DERIVED","FIXED"]),'Explicit target source kind required.');
                else
                    projectRequire(isstring(target.(key))&&isscalar(target.(key))&&strlength(strtrim(target.(key)))>0,'Explicit target source note required.');
                end
            end
        end
        for key=["G_Pa","effectiveLength_m"]
            if isempty(p.bar.definition.parameters.(key)), r.missing(end+1,1)="PARAMETER:"+key; end
        end
        if p.bar.definition.section=="UNKNOWN", r.missing(end+1,1)="SECTION:SELECT";
        elseif p.bar.definition.section=="TUBULAR"&&(isempty(p.bar.definition.parameters.innerDiameter_m)||p.bar.definition.parameters.innerDiameter_m<=0), r.missing(end+1,1)="PARAMETER:POSITIVE_INNER_DIAMETER"; end
        if ~isempty(r.missing)&&r.status=="READY", r.status="MISSING_DATA"; end
        p.context=struct('engine',d.engine,'scenario',scenario.identity,'bar',p.bar.identity,'resources',p.resources, ...
            'plan',p.plan,'options',p.options,'driverOptions',p.driverOptions);
        p.readiness=r; return;
    end
    projectRequire(~isfield(p.plan,'target'),'Sizing target belongs to ARB_SIZING only.');
    operation="MECHANICAL"; if d.engine=="ARB_KINEMATICS", operation="GEOMETRY"; end
    ready=fsd.model.antiRollBarReadiness(p.bar,operation); r.status=ready.status; r.missing=ready.missing;
    if ~isfield(p.plan,'motion'), p.plan.motion="PRESCRIBED"; end
    projectRequire(isstring(p.plan.motion)&&isscalar(p.plan.motion)&&ismember(p.plan.motion,["PRESCRIBED","ROLL"]),'Unknown motion.');
    if p.plan.motion=="PRESCRIBED"
        if ~isfield(p.plan,'wheelTravel_m')||isempty(p.plan.wheelTravel_m), r.missing(end+1,1)="PLAN:wheelTravel_m";
        else
            z=p.plan.wheelTravel_m;
            projectRequire(isnumeric(z)&&isreal(z)&&size(z,2)==2&&~isempty(z)&&all(isfinite(z),'all'),'N-by-2 explicit wheel samples required.');
            p.plan.wheelTravel_m=double(z);
        end
        p.options=fsd.kinematics.solverSettings(d.options);
        p.driverOptions=p.options;
    else
        for key=["rollAngles_rad","axleHeave_m"], if ~isfield(p.plan,key)||isempty(p.plan.(key)), r.missing(end+1,1)="PLAN:"+key; end, end
        if all(isfield(p.plan,{'rollAngles_rad','axleHeave_m'}))&&~isempty(p.plan.rollAngles_rad)&&~isempty(p.plan.axleHeave_m)
            a=p.plan.rollAngles_rad; h=p.plan.axleHeave_m;
            projectRequire(isnumeric(a)&&isreal(a)&&isvector(a)&&~isempty(a)&&all(isfinite(a))&&all(abs(a)<pi/2)&& ...
                isnumeric(h)&&isreal(h)&&isscalar(h)&&isfinite(h),'Explicit finite roll angles and axle heave required.');
            p.plan.rollAngles_rad=double(a(:)); p.plan.axleHeave_m=double(h);
        end
        p.options=fsd.kinematics.rollSolverSettings(d.options);
        p.driverOptions=fsd.kinematics.solverSettings(struct());
    end
    geometric=p.bar.definition.representation=="COAXIAL_TORSION";
    if isfield(p.plan,'packaging')
        fsd.packaging.validateAntiRollBarDefinition(p.plan.packaging);
        if ~geometric, r.status="UNSUPPORTED"; r.diagnostics="Equivalent ARB has no physical packaging geometry."; end
    end
    if geometric
        if ~isfield(p.plan,'driverTravel_m'), r.missing(end+1,1)="PLAN:driverTravel_m";
        else
            projectRequire(iscell(p.plan.driverTravel_m)&&numel(p.plan.driverTravel_m)==2,'Two driver sampling paths required.');
            for side=1:2
                z=p.plan.driverTravel_m{side};
                if isempty(z), r.missing(end+1,1)="PLAN:driverTravel_m:"+side; continue; end
                projectRequire(isnumeric(z)&&isreal(z)&&isvector(z)&&numel(z)>=3&& ...
                    all(isfinite(z))&&(all(diff(z)>0)||all(diff(z)<0)),'Strictly ordered driver sampling paths required.');
                p.plan.driverTravel_m{side}=double(z(:));
            end
        end
    end
    if geometric||p.plan.motion=="ROLL"
        ids=["FL","FR"]; if d.scope.id=="REAR", ids=["RL","RR"]; end
        for side=1:2
            g=resourceFind(project.definition.resources,'geometries',ids(side));
            if isempty(g), r.missing(end+1,1)="GEOMETRY:"+ids(side); else, p.resources.geometries{side,1}=g; end
            if geometric&&p.bar.definition.drivers(side)=="ROCKER"
                a=resourceFind(project.definition.resources,'actuations',ids(side));
                if isempty(a), r.missing(end+1,1)="ACTUATION:"+ids(side); else, p.resources.actuations{end+1,1}=a; end
            end
        end
        if numel(p.resources.geometries)==2&&all(~cellfun(@isempty,p.resources.geometries))
            projectRequire(isequaln(p.resources.geometries{1}.referenceFrame,p.resources.geometries{2}.referenceFrame),'Two complete axle frames must agree.');
            if geometric, projectRequire(isequaln(p.resources.geometries{1}.referenceFrame,p.bar.definition.referenceFrame),'ARB and suspension coordinate frames differ.'); end
        end
    end
    if ~isempty(r.missing)&&r.status=="READY", r.status="MISSING_DATA"; end
    p.context=struct('engine',d.engine,'scenario',scenario.identity,'bar',p.bar.identity, ...
        'resources',p.resources,'plan',p.plan,'options',p.options,'driverOptions',p.driverOptions);
catch cause
    if ~startsWith(string(cause.identifier),["fsd:project:","fsd:model:","fsd:kinematics:","fsd:packaging:"]), rethrow(cause); end
    r.status="INVALID_INPUT"; r.diagnostics=string(cause.identifier)+": "+string(cause.message);
end
p.readiness=r;
end
