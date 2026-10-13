function quality = rackQuality(steering,sweep)
%RACKQUALITY Same closure derivative, using the actually prescribed inner joint.
geometries={steering.frontAxleGeometry.leftGeometry;steering.frontAxleGeometry.rightGeometry};
sides=["leftResult","rightResult"]; current=cell(2,1); zero=current;
for j=1:2
    poses=vertcat(sweep.results.(sides(j)));
    adapter=struct('results',poses,'converged',sweep.converged);
    current{j}=bumpQuality(geometries{j},adapter,vertcat(poses.tieRodInboardCurrent_m));
    neutral=vertcat(poses.rackZeroKinematicResult);
    zero{j}=bumpQuality(geometries{j},struct('results',neutral,'converged',reshape([neutral.converged],[],1)));
end
reliable=current{1}.reliable & current{2}.reliable & zero{1}.reliable & zero{2}.reliable;
quality=struct('policy',"NATIVE_RACK_PRESCRIBED_INNER_LOCAL_CLOSURE_GUARDS", ...
    'left',current{1},'right',current{2},'leftRackZero',zero{1},'rightRackZero',zero{2}, ...
    'reliable',reliable,'connected',reliable(1:end-1)&reliable(2:end),'allReliable',all(reliable));
end
