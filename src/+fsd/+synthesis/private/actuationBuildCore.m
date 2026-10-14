function [actuation,mechanical,changes,diagnostics] = actuationBuildCore(space,x)
%ACTUATIONBUILDCORE Native factories; fixed suspension and oriented rocker axis.
coordinateCore(space,x,"NORMALIZE"); x=double(x(:)); changes=cell(0,1);
actuation=space.seedActuation; mechanical=space.seedMechanical; points=space.seedPoints_m;
for j=1:numel(x)
    v=space.variables{j}; points(v.row,v.column)=x(j);
end
axisChanged=~isequaln(points(5,:),space.seedPoints_m(5,:));
if axisChanged
    k=space.dependentAxisComponent; others=setdiff(1:3,k); u=actuation.rocker.axis.direction_unit;
    points(5,k)=-sum(points(5,others).*u(others))/u(k);
end
if ~isequaln(x,space.initial_m)
    tolerance=fsd.model.numericTolerances();
    scale=max([abs(points(2,:)),abs(points(3,:)),abs(points(4,:)),1]);
    threshold=tolerance.AbsTol_m+tolerance.RelTol*scale;
    if norm(points(1,:)-points(2,:))<=threshold
        error('fsd:synthesis:ZeroLengthActuationRod','Native rod minimum-length condition violated.');
    end
    if norm(points(3,:)-points(4,:))<=threshold
        error('fsd:synthesis:ZeroLengthActuationDamper','Native damper minimum-length condition violated.');
    end
    axis=struct('point',points(5,:),'direction',actuation.rocker.axis.direction_unit);
    definition=struct('actuationType',actuation.actuationType, ...
        'suspensionAttachment',struct('body',actuation.suspensionAttachment.body,'point',points(1,:)), ...
        'rocker',struct('orientationMode',actuation.rocker.orientationMode,'axis',axis, ...
        'actuationRodPoint',points(2,:),'damperPoint',points(3,:)), ...
        'damper',struct('chassisPoint',points(4,:)),'metadata',actuation.metadata);
    actuation=fsd.model.createActuationGeometry(space.seed,definition,'m');
    % Immutable oriented direction; do not re-normalize it through a second factory.
    actuation.rocker.axis.direction_unit=space.seedActuation.rocker.axis.direction_unit;
    if ~axisChanged, actuation.rocker.axis.point_m=space.seedActuation.rocker.axis.point_m; end
    actuation.metadata.sourceKind="DERIVED";
    actuation.metadata.sourceNote="v0.15 geometry reconstructed from explicit seed and authorized design coordinates";
    actuation.identity=fsd.model.actuationIdentity(actuation); fsd.model.validateActuationGeometry(actuation);
    if ~isempty(mechanical)
        s=mechanical.spring; d=mechanical.damper;
        spring=struct('modelType',s.modelType,'rate',s.rate_N_per_m,'freeLength',s.freeLength_m, ...
            'preloadCompression',s.preloadCompression_m,'solidHeight',s.solidHeight_m);
        damper=struct('modelType',d.modelType,'minimumLength',d.minimumLength_m,'maximumLength',d.maximumLength_m);
        if d.modelType=="LINEAR_ASYMMETRIC"
            damper.compressionCoefficient=d.compressionCoefficient_Ns_per_m;
            damper.reboundCoefficient=d.reboundCoefficient_Ns_per_m;
        else
            damper.compressionTable=d.compressionTable; damper.reboundTable=d.reboundTable;
        end
        definition=struct('configuration',mechanical.configuration,'spring',spring,'damper',damper,'metadata',mechanical.metadata);
        units=struct('length',"m",'springRate',"N/m",'dampingCoefficient',"N*s/m",'velocity',"m/s");
        mechanical=fsd.model.createSpringDamperModel(actuation,definition,units);
    end
end
actual=zeros(5,3);
for j=1:5, actual(j,:)=fsd.model.getActuationDesignPoint(actuation,space.pointIds(j)); end
for row=1:5
    for column=1:3
        before=space.seedPoints_m(row,column); after=actual(row,column); if before==after, continue; end
        indices=find(cellfun(@(v)v.row==row && v.column==column,space.variables));
        parameterId="DERIVED_CANONICAL_AXIS_POINT"; provenance="DERIVED"; note="Canonical oriented line, not a bearing position";
        requested=points(row,column);
        if ~isempty(indices)
            v=space.variables{indices}; parameterId=v.id; provenance=v.parameter.sourceKind; note=v.parameter.sourceNote;
        end
        components=["X","Y","Z"];
        changes{end+1,1}=struct('parameterId',parameterId,'hardpointId',space.pointIds(row), ...
            'component',components(column),'before_m',before,'requested_m',requested,'after_m',after, ...
            'sourceKind',"DERIVED",'inputSourceKind',provenance,'inputSourceNote',note); %#ok<AGROW>
    end
end
diagnostics=struct('verificationDomain',"NOMINAL_GEOMETRY_ONLY",'collisionStatus',"NOT_CHECKED", ...
    'suspensionIdentity',space.seedIdentity,'actuationType',actuation.actuationType, ...
    'seedRodLength_m',space.seedActuation.actuationRod.staticLength_m,'rodLength_m',actuation.actuationRod.staticLength_m, ...
    'seedDamperLength_m',space.seedActuation.damper.staticLength_m,'damperLength_m',actuation.damper.staticLength_m, ...
    'seedAxis',space.seedActuation.rocker.axis,'axis',actuation.rocker.axis, ...
    'dependentAxisComponent',space.dependentAxisComponent,'requestedPoints_m',points,'actualPoints_m',actual);
end
