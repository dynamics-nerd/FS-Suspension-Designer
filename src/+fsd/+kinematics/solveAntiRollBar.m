function state=solveAntiRollBar(bar,sources,referenceRotations,expectedBranches)
%SOLVEANTIROLLBAR Two rigid articulated links from already solved corner poses.
if nargin<3, referenceRotations=zeros(2,1); end % coordinate continuation starts at installed arm pose
if nargin<4, expectedBranches=zeros(2,1); end
r=fsd.model.antiRollBarReadiness(bar,'GEOMETRY');
assert(r.status=="READY",'fsd:kinematics:AntiRollBarNotReady',strjoin([r.status;r.missing],'; '));
assert(iscell(sources)&&numel(sources)==2&&isnumeric(referenceRotations)&&isreal(referenceRotations)&& ...
    numel(referenceRotations)==2&&all(isfinite(referenceRotations))&&isnumeric(expectedBranches)&& ...
    numel(expectedBranches)==2&&all(ismember(expectedBranches,[-1,0,1])), ...
    'fsd:kinematics:InvalidAntiRollBar','Two sources, finite reference rotations and branch signs required.');
ends=cell(2,1); z=nan(2,1);
for side=1:2
    source=sources{side}; point=fsd.kinematics.antiRollBarDriverPoint(bar,side,source);
    native=source.state; if native.kind=="ActuationResult", native=native.sourceResult; end
    z(side)=native.achievedWheelTravel_m;
    ends{side}=fsd.geometry.antiRollBarClosure(bar.definition.parameters,side,point,referenceRotations(side),expectedBranches(side));
    bounds=bar.definition.parameters.wheelTravelDomain_m(side,:);
    if z(side)<bounds(1)||z(side)>bounds(2), ends{side}.available=false; ends{side}.status="WHEEL_TRAVEL_LIMIT"; end
end
state=struct('schemaVersion',"0.23.0",'kind',"AntiRollBarKinematicState",'barIdentity',bar.identity, ...
    'sources',{sources(:)},'referenceRotations_rad',double(referenceRotations(:)), ...
    'expectedBranchSigns',double(expectedBranches(:)),'wheelTravel_m',z,'ends',{ends}, ...
    'converged',all(cellfun(@(e)e.available,ends)));
end
