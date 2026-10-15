function source = seedBumpSource(geometry,sweep,plan)
%SEEDBUMPSOURCE Preserve native failure/convergence plus the existing branch guard.
fsd.kinematics.validateBumpSweepResult(sweep);
projectRequire(isequaln(sweep.geometryIdentity,fsd.model.geometryIdentity(geometry)), 'Seed BUMP geometry differs.');
source=struct('geometry',geometry,'sweep',sweep,'quality',fsd.synthesis.bumpSweepQuality(geometry,sweep), ...
    'analysis',[],'analysisStatus',"AVAILABLE",'diagnostics',strings(0,1), ...
    'execution',struct('geometryIdentity',fsd.model.geometryIdentity(geometry),'plan',plan));
try
    source.analysis=fsd.analysis.analyzeBumpSweep(geometry,sweep);
catch cause
    allowed=["fsd:analysis:DegenerateCasterProjection","fsd:analysis:DegenerateKingpinProjection", ...
        "fsd:analysis:DegenerateToeProjection","fsd:analysis:InvalidWheelAxisOrientation"];
    if ~ismember(string(cause.identifier),allowed), rethrow(cause); end
    source.analysisStatus="UNAVAILABLE_NATIVE_ANALYSIS";
    source.diagnostics=string(cause.identifier)+":"+string(cause.message);
end
end
