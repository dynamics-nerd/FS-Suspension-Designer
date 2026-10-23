function response = operationBody(request,received)
%OPERATIONBODY Shared execution/receipt contract; verification never runs a solver.
verifying=nargin==2; referenceSweep=[];
timer=tic; project=request.project; a=request.arguments; value=[];
switch request.action
    case "NEW"
        concept=fsd.project.createVehicleConcept(struct('id',string(a.id)));
        project=fsd.project.createEngineeringProject(struct('concept',concept));
    case "DEMO"
        root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
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
    case "ACTUATION_CONFIG"
        [project,value]=fsd.project.configureActuationResources(project,a.cornerId, ...
            a.definition,a.lengthUnit,a.mechanicalDefinition,a.units);
    case "ACTUATION_RUN"
        assert(ismember(string(a.engine),["ACTUATION","MECHANICAL"]), ...
            'fsd:ui:InvalidOperation','Select ACTUATION or MECHANICAL explicitly.');
        scenario=fsd.project.createEngineeringScenario(struct('id',"UI_"+a.engine+"_"+a.cornerId, ...
            'engine',string(a.engine),'scope',fsd.model.designScope('CORNER',a.cornerId),'plan',a.plan));
        project=fsdui.upsertScenario(project,scenario);
        [value,project]=runScenario(project,scenario.definition.id,a.resultId);
    case "ACTUATION_ADOPT"
        records=project.definition.results;
        found=cellfun(@(r)string(r.id)==string(a.resultId),records);
        assert(nnz(found)==1,'fsd:ui:MissingResult','Select one stored synthesis result.');
        project=fsd.project.adoptActuationCandidate(project,records{found},a.index);
    case "BUILD"
        result=runScenario(project,"UI_BUILD_"+a.scope,a.resultId);
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
            [value{j},project]=runScenario(project,scenario.definition.id,a.resultId+"_"+corners(j));
        end
    case "SPECIFICATION"
        scenario=fsd.project.createEngineeringScenario(a.definition);
        project=fsdui.upsertScenario(project,scenario);
        value=fsd.project.designReadiness(project,scenario.definition.id);
    case "SYNTHESIS"
        [value,project]=runScenario(project,a.scenarioId,a.resultId);
    case "REFERENCE_TARGETS"
        % Explicit user-requested software reference: a NEW solve, never an optimum.
        root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
        old=path; cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'examples'));
        [~,definition]=parametricSeedInputs('FRONT',.005);
        source=latestSeed(project);
        reference=fsd.construction.buildParametricSeed(definition,source.referenceParameters);
        g=reference.geometries{1}; z=[-.01;0;.01];
        if verifying
            sweep=received.referenceSweep;
            fsd.kinematics.validateBumpSweepResult(sweep);
            assert(isequaln(sweep.geometryIdentity,fsd.model.geometryIdentity(g)) && ...
                isequaln(sweep.requestedWheelTravel_m,z), ...
                'fsd:ui:SemanticMismatch','Reference sweep differs from the requested reference geometry/grid.');
        else
            sweep=fsd.kinematics.solveBumpSweep(g,z,'m');
        end
        referenceSweep=sweep;
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
        matches=cellfun(@(r)string(r.id)==string(a.resultId),records);
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
        if verifying
            assert(isequaln(fsdui.fileStamp(a.file),a.sourceStamp), ...
                'fsd:ui:FileChanged','Source changed during load; response rejected.');
        end
        project=fsd.project.loadEngineeringProject(a.file);
    case {"PACKAGING_DEFINITION","PACKAGING_DEMO"}
        if request.action=="PACKAGING_DEMO"
            root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
            old=path; cleanup=onCleanup(@()path(old)); addpath(fullfile(root,'examples'));
            gs=project.definition.resources.geometries; match=cellfun(@(g)g.cornerId==a.cornerId,gs);
            assert(nnz(match)==1,'fsd:ui:MissingGeometry','Build the selected corner first.');
            definition=packagingInputs(gs{match},project.definition.revision);
        else
            definition=a.definition; fsd.packaging.validateDefinition(definition);
        end
        resources=project.definition.resources;
        if ~isfield(resources,'packaging'), resources.packaging={}; end
        keep=~cellfun(@(d)d.definitionSI.id==definition.definitionSI.id,resources.packaging);
        resources.packaging=[resources.packaging(keep);{definition}];
        project=fsd.project.reviseEngineeringProject(project,struct('resources',resources)); value=definition;
    case {"PACKAGING_RUN","PACKAGING_COMPARE"}
        parent=[];
        if strlength(string(a.parentId))>0
            rs=project.definition.results; match=cellfun(@(r)string(r.id)==string(a.parentId),rs);
            assert(nnz(match)==1,'fsd:ui:MissingResult','Select an existing native parent result.'); parent=rs{match};
        end
        selections=string(a.selection); indices=a.index;
        if request.action=="PACKAGING_COMPARE"
            assert(~isempty(parent) && endsWith(parent.engine,'SYNTHESIS'),'fsd:ui:PackagingInput','Comparison needs a compatible synthesis result.');
            selections=["SEED";"CANDIDATE"]; indices=[1;a.index];
        end
        value=cell(numel(selections),1);
        for j=1:numel(selections)
            selection=selections(j); index=indices(j); if selection=="REGISTRY", index=[]; end
            plan=fsdui.packagingPlan(parent,selection,index,a.cornerId,a.mode);
            scenario=fsd.project.createPackagingScenario("UI_PACK_"+a.cornerId+"_"+selection+"_"+j, ...
                a.cornerId,a.packagingId,plan,parent,selection,index);
            project=fsdui.upsertScenario(project,scenario);
            [r,project]=runScenario(project,scenario.definition.id,a.resultId+"_"+j);
            value{j}=r;
        end
    case "SAVE"
        if verifying
            stored=fsd.project.loadEngineeringProject(a.temporaryFile);
            assert(isequaln(stored,project),'fsd:ui:SemanticMismatch', ...
                'Temporary MAT does not contain the requested project.');
        else
            fsd.project.saveEngineeringProject(project,a.temporaryFile,false);
        end
    case "VALIDATE"
        value=fsd.project.validateEngineeringProject(project);
    case "COMPATIBILITY"
        value=fsd.project.resultCompatibilities(project);
    otherwise
        error('fsd:ui:UnknownOperation','Unknown UI operation.');
end
compatibility={};
append=isfield(request,'ledgerPolicy') && request.ledgerPolicy=="APPEND";
if ~append && ~isequaln(project,request.project) && ~isempty(project.definition.results)
    compatibility=fsd.project.resultCompatibilities(project);
end
response=struct('operationId',request.operationId,'epoch',request.epoch,'action',request.action, ...
    'project',project,'value',{value},'compatibility',{compatibility},'elapsed_s',toc(timer));
response=fsdui.workerResponse(response,request);
if request.action=="REFERENCE_TARGETS", response.referenceSweep=referenceSweep; end

    function [result,attached] = runScenario(input,scenarioId,resultId)
        if ~verifying
            if nargout==1
                result=fsd.project.runEngineeringScenario(input,scenarioId,resultId);
            else
                [result,attached]=fsd.project.runEngineeringScenario(input,scenarioId,resultId);
            end
            return;
        end
        % The caller has canonically validated the supplied records first.
        % Bind their actual execution snapshot, not a response-supplied label.
        values=received.value; if ~iscell(values), values={values}; end
        match=cellfun(@(r)string(r.id)==string(resultId),values);
        assert(nnz(match)==1,'fsd:ui:SemanticMismatch','Requested result ID is missing or ambiguous.');
        result=values{match};
        scenarios=input.definition.scenarios;
        selected=cellfun(@(s)string(s.definition.id)==string(scenarioId),scenarios);
        assert(nnz(selected)==1,'fsd:ui:SemanticMismatch','Requested scenario is missing or ambiguous.');
        scenario=scenarios{selected};
        d=input.definition; d.results=cell(0,1); d.derivations=cell(0,1);
        snapshot=fsd.project.createEngineeringProject(d);
        assert(string(result.engine)==string(scenario.definition.engine) && ...
            isequaln(result.scenarioAtExecution,scenario) && ...
            isequaln(result.projectAtExecution,snapshot), ...
            'fsd:ui:SemanticMismatch','Result execution does not match the pending operation.');
        if nargout>1, attached=fsd.project.attachEngineeringResult(input,result); end
    end
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
