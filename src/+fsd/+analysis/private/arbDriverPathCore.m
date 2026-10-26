function path=arbDriverPathCore(bar,side,source)
%ARBDRIVERPATHCORE Validate once, segment native driver positions and branches.
if isfield(source,'kind')&&source.kind=="PrescribedArbDriverPath"
    assert(all(isfield(source,{'wheelTravel_m','points_m','sourceKind','sourceNote'}))&& ...
        string(source.sourceKind)=="ASSUMED"&&strlength(string(source.sourceNote))>0, ...
        'fsd:analysis:InvalidAntiRollBar','Prescribed driver paths require explicit ASSUMED provenance.');
    requested=source.wheelTravel_m; z=requested; points=source.points_m;
    valid=true(numel(z),1);
    if isfield(source,'validSamples'), valid=source.validSamples; end
    assert(islogical(valid)&&numel(valid)==numel(z),'fsd:analysis:InvalidAntiRollBar','Explicit valid sample mask required.');
else
    assert(isfield(source,'geometry'),'fsd:analysis:InvalidAntiRollBar','Native geometry missing.');
    if isfield(source,'mechanical')
        assert(all(isfield(source,{'springDamper','actuation'}))&&isfield(source.mechanical,'source')&& ...
            isfield(source.mechanical.source,'kind')&&source.mechanical.source.kind=="ActuationSweep"&& ...
            isfield(source.mechanical.source,'sweep'),'fsd:analysis:InvalidAntiRollBar', ...
            'A geometric ARB requires actual native driver poses; a prescribed coilover curve alone does not supply them.');
        fsd.analysis.validateSpringDamperSweepAnalysis(source.mechanical,source.springDamper,source.actuation);
        sweep=source.mechanical.source.sweep; fsd.kinematics.validateActuationSweepResult(sweep,source.actuation);
    elseif isfield(source,'actuationSweep')
        sweep=source.actuationSweep; fsd.kinematics.validateActuationSweepResult(sweep,source.actuation);
    else
        assert(isfield(source,'bump'),'fsd:analysis:InvalidAntiRollBar','Native BUMP source missing.');
        sweep=source.bump; fsd.kinematics.validateBumpSweepResult(sweep);
    end
    requested=sweep.requestedWheelTravel_m; samples=sweep.results;
    z=nan(numel(samples),1); points=nan(numel(samples),3); valid=false(numel(samples),1);
    for k=1:numel(samples)
        native=samples(k); good=native.converged;
        if native.kind=="ActuationResult", good=good&&~native.isIllConditioned; native=native.sourceResult; end
        z(k)=native.achievedWheelTravel_m;
        if ~good, continue; end
        s=struct('geometry',source.geometry,'state',samples(k));
        if isfield(source,'actuation'), s.actuation=source.actuation; end
        points(k,:)=fsd.kinematics.antiRollBarDriverPoint(bar,side,s); valid(k)=true;
    end
end
assert(isnumeric(requested)&&isreal(requested)&&isvector(requested)&&numel(requested)>=3&&all(isfinite(requested))&& ...
    (all(diff(requested)>0)||all(diff(requested)<0))&&isnumeric(points)&&isreal(points)&&isequal(size(points),[numel(requested),3]), ...
    'fsd:analysis:InvalidAntiRollBar','At least three strictly ordered samples and N-by-3 points required.');
z=double(z(:)); requested=double(requested(:)); points=double(points); valid=valid(:)&isfinite(z)&all(isfinite(points),2);
rotation=nan(numel(z),1); branches=zeros(numel(z),1); statuses=repmat("SOURCE_UNAVAILABLE",numel(z),1);
closureStates=cell(numel(z),1);
reference=0; branch=0;
for k=1:numel(z)
    if ~valid(k), reference=0; branch=0; continue; end
    e=fsd.geometry.antiRollBarClosure(bar.definition.parameters,side,points(k,:),reference,branch);
    closureStates{k}=e;
    statuses(k)=e.status; valid(k)=e.available;
    if e.available, rotation(k)=e.rotation_rad; branches(k)=e.branchSign; reference=e.rotation_rad; branch=e.branchSign;
    else, reference=0; branch=0;
    end
end
segments=cell(0,1); first=1;
while first<=numel(z)
    if ~valid(first), first=first+1; continue; end
    last=first;
    while last<numel(z)&&valid(last+1)&&branches(last+1)==branches(first)&& ...
            sign(z(last+1)-z(last))==sign(requested(last+1)-requested(last))&& ...
            abs(z(last+1)-z(last))>64*eps(max([abs(z(last:last+1));1]))
        last=last+1;
    end
    if last-first>=2
        indices=first:last; if z(last)<z(first), indices=fliplr(indices); end
        pp=pchip(z(indices),[points(indices,:),rotation(indices)]'); derivative=globalPpDerivative(pp);
        segments{end+1,1}=struct('interval_m',[z(indices(1)),z(indices(end))], ...
            'indices',indices,'pp',pp,'first',derivative,'second',globalPpDerivative(derivative), ...
            'branchSign',branches(first)); %#ok<AGROW> Connected source segments only.
    end
    first=last+1;
end
path=struct('segments',{segments},'requested_m',requested,'achieved_m',z,'driverPoints_m',points, ...
    'rotation_rad',rotation,'validSamples',valid,'statuses',statuses, ...
    'closureStates',{closureStates}, ...
    'approximation',"SAMPLED_DRIVER_PATH_APPROXIMATION");
end
