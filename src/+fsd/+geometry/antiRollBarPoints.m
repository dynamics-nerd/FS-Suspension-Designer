function points=antiRollBarPoints(bar,state)
%ANTIROLLBARPOINTS Declared shaft/supports and available arm/link endpoints.
if nargin<2, state=[]; end
fsd.model.validateAntiRollBar(bar); r=fsd.model.antiRollBarReadiness(bar,'GEOMETRY');
assert(r.status=="READY",'fsd:geometry:AntiRollBarNotReady',strjoin([r.status;r.missing],'; '));
p=bar.definition.parameters; e=p.axisDirection_unit;
centers=p.armPoints_m-(p.armPoints_m-p.axisPoint_m)*(eye(3)-e'*e);
arms=p.armPoints_m; drivers=p.driverPoints_m;
supports=p.supports_m; if isempty(supports), supports=nan(2,3); end
if ~isempty(state)
    assert(isstruct(state)&&isscalar(state)&&all(isfield(state,{'available','armPoints_m','driverPoints_m'}))&& ...
        islogical(state.available)&&isscalar(state.available)&& ...
        isnumeric(state.armPoints_m)&&isreal(state.armPoints_m)&&isequal(size(state.armPoints_m),[2,3])&& ...
        isnumeric(state.driverPoints_m)&&isreal(state.driverPoints_m)&&isequal(size(state.driverPoints_m),[2,3]), ...
        'fsd:geometry:InvalidAntiRollBar','An explicit available ARB coordinate state is required.');
    if state.available
        assert(all(isfinite([state.armPoints_m;state.driverPoints_m]),'all'), ...
            'fsd:geometry:InvalidAntiRollBar','Available geometric points must be finite.');
    end
    if state.available, arms=state.armPoints_m; drivers=state.driverPoints_m;
    else, arms=nan(2,3); drivers=nan(2,3); end
end
points=struct('ids',["ARB_AXIS_LEFT";"ARB_AXIS_RIGHT";"ARB_ARM_LEFT";"ARB_ARM_RIGHT"; ...
    "ARB_DRIVER_LEFT";"ARB_DRIVER_RIGHT";"ARB_SUPPORT_LEFT";"ARB_SUPPORT_RIGHT"], ...
    'xyz_m',[centers;arms;drivers;supports],'referenceFrame',bar.definition.referenceFrame);
end
