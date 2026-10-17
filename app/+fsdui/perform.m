function response = perform(request)
%PERFORM Value-only worker boundary. All engineering is delegated to public APIs.
timer=tic; project=request.project; a=request.arguments; value=[];
switch request.action
    case "NEW"
        concept=fsd.project.createVehicleConcept(struct('id',string(a.id)));
        project=fsd.project.createEngineeringProject(struct('concept',concept));
    case "DEMO"
        root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
        old=path; cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'examples'));
        [concept,definition]=parametricSeedInputs('FRONT');
        project=fsd.project.createEngineeringProject(struct('concept',concept));
        project=fsdui.upsertScenario(project,buildScenario(definition));
    case "VEHICLE"
        concept=fsd.project.createVehicleConcept(a.definition);
        project=fsd.project.reviseEngineeringProject(project,struct('concept',concept));
    case "DECISIONS"
        definition=fsd.construction.createParametricSeedDefinition(a.definition);
        project=fsdui.upsertScenario(project,buildScenario(definition));
    case "READINESS"
        value=fsd.project.designReadiness(project,a.scenarioId);
    case "BUILD"
        result=fsd.project.runEngineeringScenario(project,"UI_BUILD_"+a.scope,a.resultId);
        if result.nativePayload.seed.nominalStatus=="VALID"
            project=fsd.project.registerParametricSeed(project,result);
        else
            project=fsd.project.attachEngineeringResult(project,result);
        end
        value=result;
    case "BUMP"
        corners=a.scope; if a.scope=="FRONT", corners=["FL","FR"]; end
        value=cell(numel(corners),1);
        for j=1:numel(corners)
            scenario=fsd.project.createEngineeringScenario(struct('id',"UI_BUMP_"+corners(j), ...
                'engine',"BUMP",'scope',fsd.model.designScope('CORNER',corners(j)), ...
                'plan',a.plan));
            project=fsdui.upsertScenario(project,scenario);
            value{j}=fsd.project.runEngineeringScenario(project,scenario.definition.id,a.resultId+"_"+corners(j));
            project=fsd.project.attachEngineeringResult(project,value{j});
        end
    case "SPECIFICATION"
        scenario=fsd.project.createEngineeringScenario(a.definition);
        project=fsdui.upsertScenario(project,scenario);
        value=fsd.project.designReadiness(project,scenario.definition.id);
    case "SYNTHESIS"
        value=fsd.project.runEngineeringScenario(project,a.scenarioId,a.resultId);
        project=fsd.project.attachEngineeringResult(project,value);
    case "REFERENCE_TARGETS"
        % Explicit user-requested software reference: a NEW solve, never an optimum.
        root=fileparts(fileparts(fileparts(mfilename('fullpath'))));
        old=path; cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'examples'));
        [~,definition]=parametricSeedInputs('FRONT',.005);
        source=latestSeed(project);
        reference=fsd.construction.buildParametricSeed(definition,source.referenceParameters);
        g=reference.geometries{1}; z=[-.01;0;.01];
        sweep=fsd.kinematics.solveBumpSweep(g,z,'m');
        analysis=fsd.analysis.analyzeBumpSweep(g,sweep);
        seed=source.geometries{1}; ps=cell(2,1);
        for j=1:2
            hp=seed.hardpoints.ids(j); v=seed.hardpoints.xyz_m(j,3);
            ps{j}=fsd.model.createDesignParameter(struct('id',"UPPER_Z_"+j,'quantity',"LENGTH", ...
                'scope',fsd.model.designScope('HARDPOINT',hp,'FL'),'type',"FREE",'binding',"HARDPOINT_Z", ...
                'value',v,'bounds',v+[-.01,.01],'availability',"ASSUMED",'sourceKind',"ASSUMED", ...
                'sourceNote',"Explicit illustrative bounds from conceptToSeedExample, not FS advice"),'m');
        end
        targets=cell(3,1);
        d=struct('id',"CAMBER_TARGET",'metricId',"CAMBER",'sourceType',"BUMP",'sourceId',"BUMP_FL", ...
            'scope',fsd.model.designScope('CORNER','FL'),'type',"CURVE_TARGET",'strength',"SOFT", ...
            'independentVariable',"WHEEL_TRAVEL",'x',z,'value',analysis.camber_rad,'tolerance',1e-7, ...
            'normalizationScale',.01,'normalizationNote',"ASSUMED software scale",'weight',1, ...
            'sourceNote',"Explicitly requested reachable software reference; not vehicle-performance targets");
        targets{1}=fsd.model.createDesignTarget(d,'rad','m');
        d.id="TOE_TARGET"; d.metricId="TOE"; d.value=analysis.toe_rad;
        targets{2}=fsd.model.createDesignTarget(d,'rad','m');
        d=rmfield(d,{'value','tolerance','weight'}); d.id="TOE_LIMIT"; d.type="CURVE_BAND";
        d.strength="HARD"; d.lower=-.2; d.upper=.2;
        targets{3}=fsd.model.createDesignTarget(d,'rad','m');
        spec=fsd.model.createDesignSpecification(struct('id',"UI_SPEC_FL",'parameters',{ps}, ...
            'targets',fsd.model.createSuspensionDesignTargets(targets),'compositeScore',true));
        origins=cellfun(@(t)struct('targetId',t.definitionSI.id,'kind',"ASSUMED",'reference', ...
            "conceptToSeedExample",'note',"Explicit software demonstration, not an optimized setup"),targets,'UniformOutput',false);
        options=struct('maxEvaluations',28,'maxIterations',12,'initialStep',.25,'minimumStep',1/128,'stopAtScore',1e-8);
        scenario=fsd.project.createEngineeringScenario(struct('id',"UI_SEARCH_FL",'engine',"CORNER_SYNTHESIS", ...
            'scope',fsd.model.designScope('CORNER','FL'),'specification',spec,'targetOrigins',{origins}, ...
            'plan',struct('travel_m',z),'options',options));
        project=fsdui.upsertScenario(project,scenario); value=scenario;
    case "ADOPT"
        records=project.definition.results;
        matches=cellfun(@(r)r.id==a.resultId,records);
        assert(nnz(matches)==1,'fsd:ui:MissingResult','Select an existing result.');
        result=records{matches}; compatibility=fsd.project.resultCompatibility(result,project);
        assert(ismember(compatibility.status,["CURRENT_EXECUTION","REUSABLE_DEPENDENCIES"]), ...
            'fsd:ui:StaleResult','Cannot adopt a stale result.');
        payload=result.nativePayload; index=a.index;
        assert(index>=1 && index<=numel(payload.search.records) && fix(index)==index, ...
            'fsd:ui:InvalidSelection','Candidate index outside history.');
        e=payload.search.records{index};
        assert(e.eligible,'fsd:ui:Ineligible','Only eligible candidates may be adopted explicitly.');
        if result.engine=="CORNER_SYNTHESIS"
            gs={e.geometry};
        elseif result.engine=="AXLE_SYNTHESIS"
            gs={e.axle.leftGeometry;e.axle.rightGeometry};
        else
            error('fsd:ui:UnsupportedAdoption','Only corner and axle synthesis adoption is supported.');
        end
        resources=project.definition.resources;
        corners=cellfun(@(g)g.cornerId,gs);
        keep=~cellfun(@(g)ismember(g.cornerId,corners),resources.geometries);
        resources.geometries=[resources.geometries(keep);gs(:)];
        if isfield(resources,'seedBindings')
            keep=~cellfun(@(b)any(ismember(cellfun(@(g)g.cornerId,b.construction.geometries),corners)),resources.seedBindings);
            resources.seedBindings=resources.seedBindings(keep);
        end
        % Existing incompatible steering/actuation is rejected by native validation.
        project=fsd.project.reviseEngineeringProject(project,struct('resources',resources));
    case "LOAD"
        project=fsd.project.loadEngineeringProject(a.file);
    case "SAVE"
        fsd.project.saveEngineeringProject(project,a.temporaryFile,false);
    case "VALIDATE"
        value=fsd.project.validateEngineeringProject(project);
    case "COMPATIBILITY"
        value=cellfun(@(r)fsd.project.resultCompatibility(r,project),project.definition.results,'UniformOutput',false);
    otherwise
        error('fsd:ui:UnknownOperation','Unknown UI operation.');
end
compatibility={};
if ~isequaln(project,request.project) && ~isempty(project.definition.results)
    compatibility=cellfun(@(r)fsd.project.resultCompatibility(r,project),project.definition.results,'UniformOutput',false);
end
response=struct('operationId',request.operationId,'epoch',request.epoch,'action',request.action, ...
    'project',project,'value',{value},'compatibility',{compatibility},'elapsed_s',toc(timer));
end

function scenario = buildScenario(definition)
corner=definition.definitionSI.cornerId; kind="CORNER"; if corner=="FRONT", kind="AXLE"; end
scenario=fsd.project.createEngineeringScenario(struct('id',"UI_BUILD_"+corner,'engine',"PARAMETRIC_SEED", ...
    'scope',fsd.model.designScope(kind,corner),'inputs',struct('definition',definition)));
end

function seed = latestSeed(project)
bindings=project.definition.resources.seedBindings;
assert(~isempty(bindings),'fsd:ui:MissingSeed','Build the illustrative FRONT seed first.');
seed=bindings{end}.construction;
assert(seed.definition.definitionSI.cornerId=="FRONT",'fsd:ui:DemoScope','Reference targets require the illustrative FRONT seed.');
end
