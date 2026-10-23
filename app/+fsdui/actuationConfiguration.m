function args = actuationConfiguration(corner,architecture,body,mode,points,enabled,law,mechanics,compression,rebound)
%ACTUATIONCONFIGURATION Presentation parsing only; native factories own physics.
assert(ismember(string(architecture),["PUSHROD","PULLROD"]) && ...
    ismember(string(body),["UPRIGHT","UCA","LCA"]) && ismember(string(mode),["YZ_PLANE","XZ_PLANE","CUSTOM"]) && ...
    (~enabled || ismember(string(law),["LINEAR_ASYMMETRIC","TABULATED_FORCE_VELOCITY"])), ...
    'fsd:ui:ActuationInput','Select architecture, attachment body, rocker orientation and enabled coilover law explicitly.');
assert(isequal(size(points),[6,7]) && isequal(size(mechanics),[8,5]), ...
    'fsd:ui:ActuationInput','The fixed parameter rows must be preserved.');
[template,mt]=fsdui.actuationRows([],[]);
assert(isequal(string(points(:,1)),string(template(:,1))) && ...
    isequal(string(points(:,5)),string(template(:,5))) && ...
    isequal(string(mechanics(:,1)),string(mt(:,1))) && isequal(string(mechanics(:,3)),string(mt(:,3))), ...
    'fsd:ui:ActuationInput','Parameter IDs and declared display units cannot be reinterpreted.');
xyz=nan(6,3); provenance=struct();
for j=1:6
    if j==3 && string(mode)~="CUSTOM", continue; end
    for k=1:3, xyz(j,k)=scalar(points{j,k+1},false,points{j,1}); end
    provenance.(points{j,1})=source(points{j,6},points{j,7},points{j,1});
end
axis=struct('point',xyz(2,:));
if string(mode)=="CUSTOM", axis.direction=xyz(3,:); end
if string(mode)~="CUSTOM" && any(~cellfun(@(x)isempty(fsdui.numberList(x)),points(3,2:4)))
    direction=zeros(1,3);
    for k=1:3, direction(k)=scalar(points{3,k+1},false,'AXIS_DIRECTION'); end
    axis.direction=direction; % Native factory rejects a direction contradicting its preset.
end
metadata=struct('parameterProvenance',provenance);
definition=struct('actuationType',string(architecture), ...
    'suspensionAttachment',struct('body',string(body),'point',xyz(1,:)), ...
    'rocker',struct('orientationMode',string(mode),'axis',axis, ...
    'actuationRodPoint',xyz(4,:),'damperPoint',xyz(5,:)), ...
    'damper',struct('chassisPoint',xyz(6,:)),'metadata',metadata);
units=struct('length',"mm",'springRate',"N/mm",'dampingCoefficient',"N/(mm/s)",'velocity',"mm/s");
mechanical=[];
if enabled
    v=cell(8,1); provenance=struct();
    for j=1:8
        unused=j>=7 && string(law)=="TABULATED_FORCE_VELOCITY";
        optional=ismember(j,4:6) || unused;
        v{j}=scalar(mechanics{j,2},optional,mechanics{j,1});
        if ~isempty(v{j}) || (unused && j>=7)
            provenance.(mechanics{j,1})=source(mechanics{j,4},mechanics{j,5},mechanics{j,1});
        end
    end
    spring=struct('modelType',"LINEAR_COMPRESSION",'rate',v{1},'freeLength',v{2}, ...
        'preloadCompression',v{3},'solidHeight',v{4});
    damper=struct('modelType',string(law),'minimumLength',v{5},'maximumLength',v{6});
    if string(law)=="LINEAR_ASYMMETRIC"
        damper.compressionCoefficient=v{7}; damper.reboundCoefficient=v{8};
    else
        assert(string(law)=="TABULATED_FORCE_VELOCITY",'fsd:ui:ActuationInput','Unsupported damper law.');
        damper.compressionTable=tableValues(compression); damper.reboundTable=tableValues(rebound);
    end
    mechanical=struct('configuration',"COILOVER",'spring',spring,'damper',damper, ...
        'metadata',struct('parameterProvenance',provenance));
end
args=struct('cornerId',string(corner),'definition',definition,'lengthUnit',"mm", ...
    'mechanicalDefinition',mechanical,'units',units);
end

function v=scalar(input,optional,id)
v=fsdui.numberList(input);
assert((optional && isempty(v)) || (isscalar(v) && isfinite(v)), ...
    'fsd:ui:ActuationInput','%s requires an explicit finite scalar; optional bounds may be blank.',id);
end
function p=source(kind,note,id)
kind=string(kind); note=string(note);
assert(isscalar(kind) && ismember(kind,["KNOWN","ASSUMED","DERIVED"]) && ...
    isscalar(note) && ~ismissing(note) && strlength(strtrim(note))>0, ...
    'fsd:ui:ActuationInput','%s requires KNOWN/ASSUMED/DERIVED and an explicit source note.',id);
p=struct('sourceKind',kind,'sourceNote',note);
end
function values=tableValues(rows)
assert(size(rows,2)==2 && size(rows,1)>=2,'fsd:ui:ActuationInput','Provide at least two speed/force rows for each branch.');
values=zeros(size(rows));
for j=1:size(rows,1), for k=1:2, values(j,k)=scalar(rows{j,k},false,'DAMPER_TABLE'); end, end
end
