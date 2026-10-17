function definition = searchDefinition(scope,targets,variables,constraints,travel,solverOptions,searchOptions,previous)
%SEARCHDEFINITION Adapt explicit table declarations to native v0.11-v0.13 contracts.
oldTargets={}; oldParameters={}; oldConstraints={};
if nargin<8, previous=[]; end
if ~isempty(previous)
    assert(ismember(previous.engine,["CORNER_SYNTHESIS","AXLE_SYNTHESIS"]), ...
        'fsd:ui:UnsupportedEditor','This editor does not replace other native synthesis families.');
    if isfield(previous.plan,'roll') && ~isempty(previous.plan.roll)
        error('fsd:ui:UnsupportedEditor','A native ROLL plan is preserved but is not editable in this BUMP-only editor.');
    end
    old=previous.specification.definitionSI;
    oldTargets=old.targets.definitionSI.targets; oldParameters=old.parameters; oldConstraints=old.constraints;
    assert(all(cellfun(@(t)t.definitionSI.sourceType=="BUMP",oldTargets)) && ...
        all(cellfun(@(p)startsWith(p.definitionSI.binding,"HARDPOINT_"),oldParameters)), ...
        'fsd:ui:UnsupportedEditor','This editor preserves, but cannot reinterpret, non-BUMP targets or non-hardpoint parameters.');
    if isfield(previous.plan,'leftBump')
        assert(isequaln(previous.plan.leftBump,previous.plan.rightBump), ...
            'fsd:ui:UnsupportedEditor','Distinct left/right native plans are preserved; this editor requires a shared BUMP plan.');
    end
end
ts=cell(size(targets,1),1);
for j=1:numel(ts)
    r=targets(j,:); corner=string(r{4});
    d=struct('id',string(r{1}),'metricId',string(r{2}),'sourceId',string(r{3}), ...
        'sourceType',"BUMP",'scope',fsd.model.designScope('CORNER',corner), ...
        'type',string(r{5}),'strength',string(r{6}),'independentVariable',"WHEEL_TRAVEL", ...
        'x',fsdui.numberList(r{7}),'value',fsdui.numberList(r{8}),'tolerance',fsdui.numberList(r{9}), ...
        'lower',fsdui.numberList(r{10}),'upper',fsdui.numberList(r{11}), ...
        'normalizationScale',fsdui.numberList(r{12}),'weight',fsdui.numberList(r{13}), ...
        'sourceNote',string(r{14}),'normalizationNote',string(r{15}));
    d=overlay(base(oldTargets,d.id),d);
    ts{j}=fsd.model.createDesignTarget(d,'rad','m');
end
ps=cell(size(variables,1),1);
for j=1:numel(ps)
    r=variables(j,:);
    original=base(oldParameters,string(r{1}));
    provenance="UNSPECIFIED";
    if isfield(original,'sourceKind'), provenance=original.sourceKind; end
    if ismember(string(r{9}),["KNOWN","ASSUMED","DERIVED"]), provenance=string(r{9}); end
    d=struct('id',string(r{1}),'quantity',"LENGTH",'scope', ...
        fsd.model.designScope('HARDPOINT',string(r{3}),string(r{2})),'binding',"HARDPOINT_"+string(r{4}), ...
        'type',string(r{5}),'value',fsdui.numberList(r{6}),'bounds',fsdui.numberList(r{7})', ...
        'comparisonTolerance',fsdui.numberList(r{8}),'availability',string(r{9}), ...
        'sourceKind',provenance,'sourceNote',string(r{10}));
    d=overlay(original,d);
    ps{j}=fsd.model.createDesignParameter(d,'m');
end
cs=cell(size(constraints,1),1);
for j=1:numel(cs)
    r=constraints(j,:); bound=fsdui.numberList(r{7});
    if ~isempty(bound), assert(numel(bound)==6,'fsd:ui:Box','Box requires Xmin Xmax Ymin Ymax Zmin Zmax.'); bound=reshape(bound,2,3)'; end
    position=fsdui.numberList(r{6})';
    d=struct('id',string(r{1}), ...
        'scope',fsd.model.designScope('HARDPOINT',string(r{3}),string(r{2})), ...
        'type',string(r{4}),'strength',string(r{5}),'position',position,'bounds',bound, ...
        'comparisonTolerance',fsdui.numberList(r{8}),'sourceNote',string(r{9}));
    cs{j}=fsd.model.createDesignConstraint(overlay(base(oldConstraints,d.id),d),'m');
end
sd=struct('id',"UI_SPEC_"+scope,'compositeScore',true);
if ~isempty(previous)
    sd=previous.specification.definitionSI; sd.metadata=previous.specification.metadata;
end
sd.parameters=ps; sd.constraints=cs; sd.targets=fsd.model.createSuspensionDesignTargets(ts);
if ~isempty(previous)
    sd.targets.metadata=previous.specification.definitionSI.targets.metadata;
    fsd.model.validateSuspensionDesignTargets(sd.targets); % Display metadata is outside physical identity.
end
spec=fsd.model.createDesignSpecification(sd);
plan=struct('travel_m',travel(:),'solverOptions',solverOptions);
engine="CORNER_SYNTHESIS"; kind="CORNER";
if scope=="FRONT"
    engine="AXLE_SYNTHESIS"; kind="AXLE"; plan=struct('leftBump',plan,'rightBump',plan);
end
origins=cellfun(@(t)struct('targetId',t.definitionSI.id,'kind',"USER_DEFINED",'reference',"", ...
    'note',t.definitionSI.sourceNote),ts,'UniformOutput',false);
if ~isempty(previous)
    for j=1:numel(ts)
        for k=1:numel(oldTargets)
            if isequaln(ts{j},oldTargets{k})
                for q=1:numel(previous.targetOrigins)
                    if previous.targetOrigins{q}.targetId==ts{j}.definitionSI.id, origins{j}=previous.targetOrigins{q}; end
                end
            end
        end
    end
end
definition=struct('id',"UI_SEARCH_"+scope,'engine',engine,'scope',fsd.model.designScope(kind,scope), ...
    'specification',spec,'targetOrigins',{origins},'plan',plan,'options',searchOptions);
if ~isempty(previous)
    % Retain native symmetry links, concept dependencies, notes and inputs.
    definition=overlay(previous,definition);
end
scenario=fsd.project.createEngineeringScenario(definition); definition=scenario.definition;
end

function d=base(entries,id)
d=struct();
for j=1:numel(entries)
    if entries{j}.definitionSI.id==id
        d=entries{j}.definitionSI; d.metadata=entries{j}.metadata; return;
    end
end
end
function d=overlay(d,edited)
for field=string(fieldnames(edited))', d.(field)=edited.(field); end
end
