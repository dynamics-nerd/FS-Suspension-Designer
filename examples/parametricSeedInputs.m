function [concept,definition] = parametricSeedInputs(corner,variation)
%PARAMETRICSEEDINPUTS Explicit illustrative decisions, NOT recommended FS dimensions.
% No initial absolute hardpoint array. The family reconstructs every native point.
if nargin<1, corner="FL"; end
if nargin<2, variation=0; end
corner=string(corner); parameterCorner=corner; if corner=="FRONT", parameterCorner="FL"; end
ids=["WHEELBASE","FRONT_TRACK","REAR_TRACK","VEHICLE_MASS","WHEEL_UNLOADED_RADIUS_FRONT"];
values=[1.6,1.3,1.2,200,.27]; units=["m","m","m","kg","m"];
ps=cell(numel(ids),1);
for j=1:numel(ids)
    ps{j}=fsd.project.createConceptParameter(ids(j),struct('type',"ASSUMED",'value',values(j), ...
        'availability',"ASSUMED",'sourceKind',"ASSUMED",'sourceNote',"Illustrative software fixture, no measured car"),units(j));
end
concept=fsd.project.createVehicleConcept(struct('id',"PARAMETRIC_DEMO",'parameters',{ps}, ...
    'architectures',struct('frontSuspension',"DOUBLE_WISHBONE",'rearSuspension',"DOUBLE_WISHBONE")));
catalog=fsd.construction.seedParameterCatalog();
% effective radius .25m is declared separately from unloaded radius .27m.
v=[.25,0,0,0, .03,-.05,.17, -.02,-.05,-.17, .05,-.08,-.02, ...
    -.01,.4,.35,.22,.04,-.02, .005,.4,.15,.23,.02,.02, .04,.39,.25];
v(16)=v(16)+variation; % explicit UCA midpoint height variation, not wheel travel
parameters=cell(numel(catalog),1);
for j=1:numel(catalog)
    parameters{j}=fsd.construction.createSeedParameter(catalog(j).id,parameterCorner, ...
        struct('type',"ASSUMED",'value',v(j),'availability',"ASSUMED",'sourceKind',"ASSUMED", ...
        'sourceNote',"Explicit illustrative geometry decision; not FS recommendation"),catalog(j).unit);
end
d=struct('id',"PARAMETRIC_"+corner,'cornerId',corner,'family',"INDEPENDENT_DOUBLE_WISHBONE", ...
    'parameters',{parameters});
if corner=="FRONT", d.symmetry="MIRROR_FL"; end
definition=fsd.construction.createParametricSeedDefinition(d);
end
