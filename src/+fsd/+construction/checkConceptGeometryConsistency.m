function report = checkConceptGeometryConsistency(geometries,referenceParameters,definition)
%CHECKCONCEPTGEOMETRYCONSISTENCY Contact/wheel references, no silent adjustment.
seedRequire(iscell(geometries) && (isvector(geometries) || isempty(geometries)), 'Geometry cell vector required.');
seedReferenceCore(referenceParameters);
if nargin<3, definition=[]; else, fsd.construction.validateParametricSeedDefinition(definition); end
rows=repmat(struct('id',"",'status',"UNKNOWN",'actual',[],'expected',[], ...
    'comparisonTolerance',[],'unit',"m",'diagnostic',""),0,1);
ids=strings(numel(geometries),1);
for j=1:numel(geometries)
    g=geometries{j}; fsd.model.validateDoubleWishboneGeometry(g); ids(j)=g.cornerId;
    s=1; if ismember(g.cornerId,["FL","RL"]), s=-1; end
    trackId="FRONT_TRACK"; rear=ismember(g.cornerId,["RL","RR"]); if rear, trackId="REAR_TRACK"; end
    [track,ts]=seedReferenceValue(referenceParameters,trackId);
    [wb,ws]=seedReferenceValue(referenceParameters,'WHEELBASE');
    cp=fsd.model.getPoint(g,g.cornerId+"_CONTACT_PATCH"); expected=[0,NaN,0];
    if rear, expected(1)=NaN; if ~isempty(wb), expected(1)=wb; end, end
    if ~isempty(track), expected(2)=s*track/2; end
    for axis=1:3
        row=compareRow(g.cornerId+"_CONTACT_"+string(axis),cp(axis),expected(axis));
        if row.status=="UNKNOWN", row.diagnostic=ts; if axis==1, row.diagnostic=ws; end, end
        rows(end+1,1)=row; %#ok<AGROW>
    end
    rows(end+1,1)=compareRow(g.cornerId+"_FRAME",double(g.metadata.coordinateSystem=="X_REAR_Y_RIGHT_Z_UP"),1,'1'); %#ok<AGROW>
    radius=norm(fsd.model.getPoint(g,g.cornerId+"_WHEEL_CENTER")-cp);
    contact=fsd.geometry.geometricWheelContact(fsd.model.getPoint(g,g.cornerId+"_WHEEL_CENTER"),g.wheel.wheelAxis,radius);
    if contact.status=="FINITE", delta=max(abs(contact.point_m-cp)); else, delta=Inf; end
    rows(end+1,1)=compareRow(g.cornerId+"_WHEEL_DATUM",delta,0); %#ok<AGROW>
    ps={};
    if ~isempty(definition)
        d=definition.definitionSI;
        if d.cornerId==g.cornerId || (d.cornerId=="FRONT" && ismember(g.cornerId,["FL","FR"]))
            ps=d.parameters;
            if g.cornerId=="FR" && d.cornerId=="FRONT" && d.symmetry=="NONE", ps=d.rightParameters; end
        end
    end
    metrics=["NOMINAL_TOE","NOMINAL_CAMBER","WHEEL_EFFECTIVE_RADIUS"];
    actuals=[fsd.analysis.toeFromWheelAxis(g.wheel.wheelAxis,g.cornerId), ...
        fsd.analysis.camberFromWheelAxis(g.wheel.wheelAxis,g.cornerId),radius];
    for k=1:3
        expectedValue=[]; index=find(cellfun(@(p)p.definitionSI.id==metrics(k),ps));
        if ~isempty(index), [expectedValue,~]=seedPhysicalValue(ps{index}.definitionSI); end
        unit='rad'; if k==3, unit='m'; end
        rows(end+1,1)=compareRow(g.cornerId+"_"+metrics(k),actuals(k),expectedValue,unit); %#ok<AGROW>
    end
end
seedRequire(numel(unique(ids))==numel(ids),'Duplicate corner geometry.');
for axle=["FRONT","REAR"]
    pair=["FL","FR"]; ref="FRONT_TRACK"; if axle=="REAR", pair=["RL","RR"]; ref="REAR_TRACK"; end
    [expected,~]=seedReferenceValue(referenceParameters,ref); actual=[];
    if all(ismember(pair,ids))
        left=geometries{ids==pair(1)}; right=geometries{ids==pair(2)};
        a=fsd.model.getPoint(left,pair(1)+"_CONTACT_PATCH"); b=fsd.model.getPoint(right,pair(2)+"_CONTACT_PATCH");
        actual=b(2)-a(2);
    end
    rows(end+1,1)=compareRow(ref,actual,expected); %#ok<AGROW>
end
% Front-to-rear separation needs both axle datums, not a claimed wheelbase input.
actual=[]; [wb,~]=seedReferenceValue(referenceParameters,'WHEELBASE');
front=find(ismember(ids,["FL","FR"]),1); rear=find(ismember(ids,["RL","RR"]),1);
if ~isempty(front) && ~isempty(rear)
    a=fsd.model.getPoint(geometries{front},ids(front)+"_CONTACT_PATCH");
    b=fsd.model.getPoint(geometries{rear},ids(rear)+"_CONTACT_PATCH"); actual=b(1)-a(1);
end
rows(end+1,1)=compareRow('WHEELBASE',actual,wb);
row=compareRow('UNLOADED_RADIUS_AS_EFFECTIVE_RADIUS',[],[]);
row.status="NOT_APPLICABLE"; row.diagnostic="No automatic equality between unloaded tire radius and nominal effective wheel circle.";
rows(end+1,1)=row;
report=struct('schemaVersion',"0.17.0",'kind',"ConceptGeometryConsistency",'checks',rows, ...
    'hasMismatch',any(string({rows.status})=="MISMATCH"),'verificationDomain',"SUPPLIED_NOMINAL_GEOMETRIES_ONLY");
end

function row = compareRow(id,actual,expected,unit)
if nargin<4, unit='m'; end
row=struct('id',string(id),'status',"UNKNOWN",'actual',actual,'expected',expected,'comparisonTolerance',[],'unit',string(unit),'diagnostic',"");
if isempty(actual) || isempty(expected) || any(isnan([actual,expected])), return; end
t=fsd.model.numericTolerances(); scale=max([1,abs(actual),abs(expected)]);
row.comparisonTolerance=t.RelTol*(1+scale);
if string(unit)=="m", row.comparisonTolerance=t.AbsTol_m+t.RelTol*scale; end
row.status="MATCH"; if ~isfinite(actual) || abs(actual-expected)>row.comparisonTolerance, row.status="MISMATCH"; end
end
