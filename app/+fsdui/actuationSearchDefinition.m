function definition = actuationSearchDefinition(corner,targets,parameters,constraints,plan,options,composite,previous)
%ACTUATIONSEARCHDEFINITION Adapt explicit declarations to native synthesis.
if nargin<8, previous=[]; end
oldTargets={}; oldParameters={}; oldConstraints={};
if ~isempty(previous)
    assert(previous.engine=="ACTUATION_SYNTHESIS" && previous.scope.id==string(corner), ...
        'fsd:ui:UnsupportedEditor','The stored synthesis belongs to another family/corner.');
    old=previous.specification.definitionSI;
    oldTargets=old.targets.definitionSI.targets; oldParameters=old.parameters; oldConstraints=old.constraints;
end
ts=cell(size(targets,1),1);
for j=1:numel(ts)
    r=targets(j,:); [d,original]=base(oldTargets,string(r{1}));
    if ~isempty(original)
        sample=previous; sample.specification=fsd.model.createDesignSpecification(struct('id',"ROW", ...
            'targets',fsd.model.createSuspensionDesignTargets({original})));
        displayed=fsdui.actuationSearchRows(sample);
        if isequaln(r,displayed), ts{j}=original; continue; end
    end
    d.id=string(r{1}); d.metricId=string(r{2}); d.sourceType=string(r{3}); d.sourceId=string(r{4});
    d.scope=fsd.model.designScope('CORNER',corner); d.type=string(r{5}); d.strength=string(r{6});
    d.independentVariable="WHEEL_TRAVEL"; d.x=fsdui.numberList(r{7});
    for pair={8,'value';9,'tolerance';10,'lower';11,'upper';12,'normalizationScale';13,'weight'}'
        d.(pair{2})=fsdui.numberList(r{pair{1}});
    end
    d.sourceNote=string(r{15}); d.normalizationNote=string(r{16});
    if ~isempty(original)
        assert(d.metricId==original.definitionSI.metricId,'fsd:ui:UnsupportedEditor', ...
            'Use a new target ID when changing its physical metric; retained annotations must not be reinterpreted.');
        catalog=fsd.model.designMetricCatalog(); quantity=catalog(string({catalog.id})==d.metricId).quantity;
        factor=fsd.model.convertDesignUnits(1,quantity,string(r{14}));
        d.numericalTolerance=d.numericalTolerance/factor; d.physicalUncertainty=d.physicalUncertainty/factor;
    end
    ts{j}=fsd.model.createDesignTarget(d,string(r{14}),'mm');
end
ps=cell(size(parameters,1),1);
for j=1:numel(ps)
    r=parameters(j,:); [d,original]=base(oldParameters,string(r{1}));
    if ~isempty(original)
        sample=previous; dd=previous.specification.definitionSI; dd.parameters={original}; dd.constraints={};
        sample.specification=fsd.model.createDesignSpecification(dd); [~,displayed]=fsdui.actuationSearchRows(sample);
        if isequaln(r,displayed), ps{j}=original; continue; end
    end
    d.id=string(r{1}); d.quantity="LENGTH"; binding=string(r{3});
    if ismember(binding,["SPRING_RATE","SPRING_PRELOAD"])
        d.scope=fsd.model.designScope('COMPONENT',string(r{2}),corner); d.binding=binding;
        if binding=="SPRING_RATE", d.quantity="STIFFNESS"; end
    else
        d.scope=fsd.model.designScope('HARDPOINT',string(r{2}),corner); d.binding="HARDPOINT_"+binding;
    end
    d.type=string(r{4}); d.value=fsdui.numberList(r{5});
    d.bounds=fsdui.numberList(r{6})'; d.comparisonTolerance=fsdui.numberList(r{7});
    d.availability=string(r{8}); d.sourceKind=string(r{9}); d.sourceNote=string(r{10});
    ps{j}=fsd.model.createDesignParameter(d,string(r{11}));
end
cs=cell(size(constraints,1),1);
for j=1:numel(cs)
    r=constraints(j,:); [d,original]=base(oldConstraints,string(r{1}));
    if ~isempty(original)
        sample=previous; dd=previous.specification.definitionSI; dd.constraints={original}; dd.parameters={};
        sample.specification=fsd.model.createDesignSpecification(dd); [~,~,displayed]=fsdui.actuationSearchRows(sample);
        if isequaln(r,displayed), cs{j}=original; continue; end
    end
    assert(string(r{9})==string(corner),'fsd:ui:ActuationInput','Constraint corner must match the fixed suspension.');
    d.id=string(r{1}); d.scope=fsd.model.designScope('HARDPOINT',string(r{2}),corner);
    d.type=string(r{3}); d.strength=string(r{4}); d.position=fsdui.numberList(r{5})';
    v=fsdui.numberList(r{6});
    assert(isempty(v) || numel(v)==6,'fsd:ui:ActuationInput','Box requires Xmin Xmax Ymin Ymax Zmin Zmax.');
    d.bounds=[]; if ~isempty(v), d.bounds=reshape(v,2,3)'; end
    d.comparisonTolerance=fsdui.numberList(r{7}); d.sourceNote=string(r{8});
    cs{j}=fsd.model.createDesignConstraint(d,'mm');
end
sd=struct('id',"UI_ACT_SPEC_"+corner);
if ~isempty(previous), sd=previous.specification.definitionSI; sd.metadata=previous.specification.metadata; end
sd.parameters=ps; sd.constraints=cs; sd.targets=fsd.model.createSuspensionDesignTargets(ts);
if ~isempty(previous), sd.targets.metadata=previous.specification.definitionSI.targets.metadata; end
sd.compositeScore=logical(composite); spec=fsd.model.createDesignSpecification(sd);
origins=cellfun(@(t)struct('targetId',t.definitionSI.id,'kind',"USER_DEFINED", ...
    'reference',"",'note',t.definitionSI.sourceNote),ts,'UniformOutput',false);
if ~isempty(previous)
    for j=1:numel(ts)
        for k=1:numel(oldTargets)
            if isequaln(ts{j},oldTargets{k})
                origins{j}=[];
                for q=1:numel(previous.targetOrigins)
                    if previous.targetOrigins{q}.targetId==ts{j}.definitionSI.id, origins{j}=previous.targetOrigins{q}; end
                end
            end
        end
    end
end
origins=origins(~cellfun(@isempty,origins));
definition=struct('id',"UI_ACT_SEARCH_"+corner,'engine',"ACTUATION_SYNTHESIS", ...
    'scope',fsd.model.designScope('CORNER',corner),'specification',spec, ...
    'plan',plan,'options',options,'targetOrigins',{origins});
if ~isempty(previous)
    names=["conceptDependencies","name","description","inputs","symmetryLinks"];
    for name=names, definition.(name)=previous.(name); end
end
s=fsd.project.createEngineeringScenario(definition); definition=s.definition;
end
function [d,original]=base(entries,id)
d=struct(); original=[];
for j=1:numel(entries)
    if entries{j}.definitionSI.id==id
        original=entries{j}; d=original.definitionSI; d.metadata=original.metadata; return;
    end
end
end
