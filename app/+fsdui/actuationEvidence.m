function e = actuationEvidence(result,index)
%ACTUATIONEVIDENCE Presentation of canonically received stored evidence only.
% Native validation is owned by Controller/project. No fresh solve or analysis.
if nargin<2, index=1; end
e=struct('geometry',[],'actuation',[],'sweep',[],'kinematic',[],'mechanical',[], ...
    'travel_mm',[],'values',struct(),'rows',{cell(0,14)},'diagnostics',strings(0,1));
p=result.nativePayload;
if result.engine=="ACTUATION_SYNTHESIS"
    assert(index>=1 && index<=numel(p.search.records) && index==fix(index), ...
        'fsd:ui:InvalidSelection','Select a stored candidate.');
    r=p.search.records{index}; e.geometry=r.geometry; e.actuation=r.actuation;
    e.diagnostics=["Candidate "+index+": "+r.classification;"Reason: "+r.reason];
    if ~isempty(r.actuationEvidence)
        e.sweep=r.actuationEvidence.sweep; e.kinematic=r.actuationEvidence.analysis;
    end
    if ~isempty(r.mechanicalEvidence), e.mechanical=r.mechanicalEvidence.analysis; end
else
    assert(ismember(result.engine,["ACTUATION","MECHANICAL"]), ...
        'fsd:ui:ActuationInput','Select native actuation or mechanical evidence.');
    e.geometry=result.prepared.resources.geometries{1}; e.actuation=result.prepared.resources.actuations{1};
    e.sweep=p.sweep; e.kinematic=p.actuationAnalysis;
    if result.engine=="MECHANICAL", e.mechanical=p.analysis; end
end
if isempty(e.kinematic), return; end
a=e.kinematic; e.travel_mm=1000*a.achievedWheelTravel_m;
e.values=struct('COMPRESSION_MM',1000*a.damperCompression_m, ...
    'LENGTH_MM',1000*a.damperLength_m,'ROCKER_DEG',rad2deg(a.rockerAngle_rad), ...
    'MOTION_RATIO',a.damperMotionRatio,'INSTALLATION_RATIO',a.installationRatio);
n=numel(e.travel_mm); m=e.mechanical;
for name=["SPRING_N","SPRING_WHEEL_N","DAMPER_N","DAMPER_WHEEL_N","RATE_N_MM","ELASTIC_N_MM","GEOMETRIC_N_MM"]
    e.values.(name)=nan(n,1);
end
if ~isempty(m)
    e.values.SPRING_N=m.springAxialForce_N; e.values.SPRING_WHEEL_N=m.springWheelResistance_N;
    e.values.DAMPER_N=m.damperAxialResistance_N; e.values.DAMPER_WHEEL_N=m.damperWheelResistance_N;
    e.values.RATE_N_MM=m.wheelRateTotal_N_per_m/1000;
    e.values.ELASTIC_N_MM=m.wheelRateElastic_N_per_m/1000;
    e.values.GEOMETRIC_N_MM=m.wheelRateGeometric_N_per_m/1000;
end
e.rows=cell(n,14);
for j=1:n
    mechanical="NOT_REQUESTED";
    if ~isempty(m)
        mechanical=strjoin([m.springStatus(j),m.damperStatus(j),m.wheelRateStatus(j), ...
            m.damperTravelStatus(j),m.springSolidStatus(j),m.stiffnessDiagnostic(j)],' | ');
    end
    e.rows(j,:)={j,e.travel_mm(j),e.values.LENGTH_MM(j),e.values.COMPRESSION_MM(j), ...
        e.values.ROCKER_DEG(j),e.values.MOTION_RATIO(j),e.values.SPRING_N(j), ...
        e.values.SPRING_WHEEL_N(j),e.values.DAMPER_N(j),e.values.RATE_N_MM(j), ...
        char(a.actuationStatus(j)),char(a.motionRatioStatus),char(mechanical),char(e.sweep.results(j).failureReason)};
end
e.diagnostics=[e.diagnostics;"MR: "+a.motionRatioStatus; ...
    "Stored poses only; missing limits mean UNKNOWN, not safe."; ...
    "Axial spring/damper forces and signed wheel resistance are not structural rod forces or tire normal loads."];
end
