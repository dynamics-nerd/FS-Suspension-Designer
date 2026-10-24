function p=prepareGlobalScenario(project,scenario,validation)
%PREPAREGLOBALSCENARIO Four native corner declarations; never generate paths here.
d=scenario.definition; ids=["FL","FR","RL","RR"];
r=struct('scenarioId',d.id,'engine',"GLOBAL_STATIC",'scope',d.scope,'status',"READY", ...
    'missing',strings(0,1),'diagnostics',strings(0,1),'limitations', ...
    ["SAMPLED_PATH_APPROXIMATION; fixed inboards and rack zero."; ...
    "Static seven-coordinate reduced model; no dynamic vehicle prediction."; ...
    "SUPPLIED_SEEDS_ONLY; convergence, admissibility and stability are distinct."]);
p=struct('schemaVersion',"0.16.0",'kind',"PreparedEngineeringScenario", ...
    'scenario',scenario,'resources',resourceCore(struct()),'plan',d.plan,'options',d.options, ...
    'vehicle',[],'loadCase',[],'corners',{{}},'tires',{{}},'context',[],'readiness',r);
try
    projectRequire(d.scope.kind=="VEHICLE" && isempty(d.specification) && isempty(d.symmetryLinks) && ...
        isempty(d.targetOrigins) && isempty(d.conceptDependencies),'GLOBAL_STATIC requires vehicle scope without design targets.');
    names=["vehicleOptions","systemOptions","cornerPlans","initialGuesses"];
    projectRequire(all(ismember(string(fieldnames(d.plan)),names)),'Unknown global plan fields.');
    for name=names
        if ~isfield(d.plan,name), r.missing(end+1,1)="PLAN:"+name; end
    end
    library=isfield(d.inputs,'tireSource');
    if library
        projectRequire(isequal(string(fieldnames(d.inputs)),"tireSource")&& ...
            isequal(d.inputs.tireSource,"LIBRARY_ASSIGNMENTS"),'Choose exactly one global tire source.');
    else
        projectRequire(all(ismember(string(fieldnames(d.inputs)),"tires")),'Only native tires are global inputs.');
        if ~isfield(d.inputs,'tires'), r.missing(end+1,1)="INPUT:TIRES_FL_FR_RL_RR"; end
    end
    if ~isempty(r.missing), r.status="MISSING_DATA"; p.readiness=r; return; end
    c=conceptPreparation(project.definition.concept,d.plan.vehicleOptions);
    r.missing=[r.missing;c.missing]; r.diagnostics=[r.diagnostics;c.diagnostics];
    if c.status=="INVALID_INPUT", r.status=c.status; end
    p.vehicle=c.model; p.loadCase=c.loadCase;
    if ~isempty(c.model)
        for k=1:3
            if ~isfinite(c.model.cg_m(k)), r.missing(end+1,1)="CONCEPT:CG_"+extractBetween("XYZ",k,k); end
        end
    end
    so=d.plan.systemOptions;
    projectRequire(isstruct(so) && isscalar(so) && all(isfield(so, ...
        {'massApproximation','unsprungPositionAssumption','roadHeight_m'})), ...
        'Explicit mass approximation, unsprung position assumption and road height required.');
    projectRequire(all(ismember(string(fieldnames(so)),["massApproximation","unsprungPositionAssumption", ...
        "roadHeight_m","rideHeightPointsBody_m","rideHeightPointIds"])) && ...
        ismember(string(so.massApproximation),["KNOWN_UNSPRUNG_MASSES","ZERO_UNSPRUNG_APPROXIMATION"]) && ...
        string(so.unsprungPositionAssumption)=="UNSPRUNG_MASS_AT_WHEEL_CENTER" && ...
        isnumeric(so.roadHeight_m) && isscalar(so.roadHeight_m) && isreal(so.roadHeight_m) && isfinite(so.roadHeight_m), ...
        'Invalid global system options.');
    if ~isempty(c.model) && so.massApproximation=="KNOWN_UNSPRUNG_MASSES"
        for k=1:4
            if ~isfinite(c.model.unsprungMass_kg(k)), r.missing(end+1,1)="CONCEPT:UNSPRUNG_MASS_"+ids(k); end
        end
        if all(isfinite(c.model.unsprungMass_kg))
            projectRequire(c.model.totalMass_kg-sum(c.model.unsprungMass_kg)>0,'Positive sprung mass required.');
        end
    end
    points=zeros(0,3); pointIds=strings(0,1);
    if isfield(so,'rideHeightPointsBody_m'), points=so.rideHeightPointsBody_m; end
    if isfield(so,'rideHeightPointIds'), pointIds=so.rideHeightPointIds; end
    projectRequire(isnumeric(points) && isreal(points) && size(points,2)==3 && all(isfinite(points),'all') && ...
        isstring(pointIds) && iscolumn(pointIds) && ~any(ismissing(pointIds)) && ...
        all(strlength(pointIds)>0) && numel(pointIds)==size(points,1) && numel(unique(pointIds))==numel(pointIds), ...
        'Ride-height references require finite N-by-3 body points and unique nonempty string IDs.');
    p.options=fsd.analysis.globalStaticSolverSettings(d.options);
    q=d.plan.initialGuesses;
    projectRequire(isnumeric(q) && isreal(q) && size(q,1)==7 && ~isempty(q) && all(isfinite(q),'all') && ...
        all(q>=p.options.bounds(:,1) & q<=p.options.bounds(:,2),'all'),'Initial guesses must be finite 7-by-N within bounds.');
    if library
        p.tires=cell(4,1); p.verticalBindings=cell(4,1);
        registry=project.definition.resources;
        for k=1:4
            assigned={};
            if isfield(registry,'tireAssignments'), assigned=registry.tireAssignments(cellfun(@(a)a.cornerId==ids(k),registry.tireAssignments)); end
            if isempty(assigned), r.missing(end+1,1)="TIRE:"+ids(k)+":ASSIGN_LIBRARY_REVISION"; continue; end
            a=assigned{1}; tire=fsd.project.findTire(project,a.tireId,a.tireRevision);
            if isempty(tire)||~fsd.tire.capabilities(tire).vertical
                r.missing(end+1,1)="TIRE:"+ids(k)+":CONFIGURE_VERTICAL_TIRE"; continue;
            end
            p.tires{k}=fsd.tire.verticalModel(tire,ids(k));
            p.verticalBindings{k}=struct('cornerId',ids(k),'tireId',a.tireId,'vertical',tire.verticalIdentity);
        end
    else
        projectRequire(iscell(d.inputs.tires) && numel(d.inputs.tires)==4,'Four tires in FL/FR/RL/RR order required.');
        p.tires=d.inputs.tires(:);
    end
    contexts=cell(4,1); wc=nan(4,3);
    projectRequire(isstruct(d.plan.cornerPlans) && isscalar(d.plan.cornerPlans) && ...
        isequal(sort(string(fieldnames(d.plan.cornerPlans))),sort(ids(:))),'Four named corner plans required.');
    for k=1:4
        id=ids(k); tire=p.tires{k};
        if isempty(tire), r.missing(end+1,1)="TIRE:"+id+":CONFIGURE_VERTICAL_TIRE";
        else
            fsd.model.validateVerticalTireModel(tire); projectRequire(tire.cornerId==id,'Tire corner/order mismatch.');
        end
        s=fsd.project.createEngineeringScenario(struct('id',d.id+"_"+id,'engine',"MECHANICAL", ...
            'scope',fsd.model.designScope('CORNER',id),'plan',d.plan.cornerPlans.(id)));
        cp=validation.prepare(project,s); p.corners{k,1}=cp;
        r.missing=[r.missing;cp.readiness.missing]; r.diagnostics=[r.diagnostics;cp.readiness.diagnostics];
        if ~ismember(cp.readiness.status,["READY","MISSING_DATA"]), r.status=cp.readiness.status; end
        if cp.readiness.status~="READY", continue; end
        projectRequire(all(cp.plan.wheelVelocity_m_per_s==0),'Global static paths require explicit zero velocity.');
        z=cp.plan.travel_m;
        projectRequire(numel(z)>=3,'At least three explicit samples per global path required by PCHIP.');
        contexts{k}=cp.context;
        wc(k,:)=fsd.model.getPoint(cp.resources.geometries{1},id+"_WHEEL_CENTER");
        for name=["geometries","actuations","mechanicals"]
            p.resources.(name)=[p.resources.(name);cp.resources.(name)];
        end
        if k>1 && ~isempty(contexts{1})
            projectRequire(isequaln(cp.resources.geometries{1}.referenceFrame, ...
                p.corners{1}.resources.geometries{1}.referenceFrame),'All four complete vehicle frames must agree.');
        end
    end
    if ~isempty(r.missing) && r.status=="READY", r.status="MISSING_DATA"; end
    if r.status~="READY", p.readiness=r; return; end
    projectRequire(all(wc([1,3],2)<0) && all(wc([2,4],2)>0) && ...
        max(wc(1:2,1))<min(wc(3:4,1)), ...
        'Corner positions must be left/right of vehicle origin and rear stations aft of front stations.');
    p.context=struct('engine',"GLOBAL_STATIC",'scenario',scenario.identity,'corners',{contexts}, ...
        'vehicle',p.vehicle.identity,'loadCase',p.loadCase.identity,'tires',{p.tires}, ...
        'systemOptions',so,'options',p.options,'initialGuesses',q);
    if library, p.context.verticalBindings=p.verticalBindings; end
catch cause
    if ~startsWith(string(cause.identifier),["fsd:project:","fsd:model:","fsd:analysis:InvalidGlobalStaticInput"]), rethrow(cause); end
    r.status="INVALID_INPUT"; r.diagnostics(end+1,1)=string(cause.identifier)+": "+string(cause.message);
end
p.readiness=r;
end
