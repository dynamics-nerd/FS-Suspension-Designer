function r=arbCoordinateCore(prepared,z)
%ARBCOORDINATECORE One geometric path query shared by mechanics and inspection.
r=struct('kind',"AntiRollBarPathState",'barIdentity',prepared.bar.identity,'wheelTravel_m',z, ...
    'available',false,'status',"MISSING_DRIVER_PATH",'angles_rad',nan(2,1), ...
    'first_per_m',nan(2,1),'second_per_m2',nan(2,1),'driverPoints_m',nan(2,3), ...
    'armPoints_m',nan(2,3),'ends',{{}},'segmentIds',zeros(2,1),'branchSigns',zeros(2,1), ...
    'bilateralCurvatureAvailable',false,'approximation',"SAMPLED_DRIVER_PATH_APPROXIMATION");
if numel(prepared.paths)~=2, return; end
if any(~isfinite(z)), r.status="INVALID_INPUT"; return; end
p=prepared.bar.definition.parameters;
if any(z<p.wheelTravelDomain_m(:,1)|z>p.wheelTravelDomain_m(:,2)), r.status="WHEEL_TRAVEL_LIMIT"; return; end
resolved=true; r.ends=cell(2,1);
for side=1:2
    v=arbPathValue(prepared,side,z(side)); r.segmentIds(side)=v.segmentId;
    r.ends{side}=v.endState;
    if ~v.available, r.status=v.status; return; end
    e=v.endState; r.ends{side}=e; r.angles_rad(side)=e.angle_rad;
    r.first_per_m(side)=v.first; r.second_per_m2(side)=v.second;
    r.driverPoints_m(side,:)=e.driverPoint_m; r.armPoints_m(side,:)=e.armPoint_m;
    r.branchSigns(side)=e.branchSign; resolved=resolved&&v.curvatureAvailable;
end
r.bilateralCurvatureAvailable=resolved; r.available=true; r.status="AVAILABLE";
end
