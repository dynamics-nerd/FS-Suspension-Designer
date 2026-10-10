function f = designAuditFixture()
%DESIGNAUDITFIXTURE Native, independently valid sources; no forged solver output.
% All parameters inherit documented analytical/example fixtures, not FS targets.
f.example = designTargetEvaluationExample(false);
f.bumpA = f.example.candidates{1}.definitionSI.sources{1};
f.bumpB = f.example.candidates{2}.definitionSI.sources{1};
f.bumpB.id = "OTHER_BUMP";
f.mechA = f.example.candidates{1}.definitionSI.sources{2};
f.mechB = f.example.candidates{2}.definitionSI.sources{2};
f.mechB.id = "OTHER_MECHANICAL";
a = f.mechA.auxiliary; s = f.mechA.result.source.sweep;
f.actA = struct("id","ACT_FL","type","ACTUATION","model",a,"sweep",s, ...
    "result",fsd.analysis.analyzeActuationSweep(a,s));
a = f.mechB.auxiliary; s = f.mechB.result.source.sweep;
f.actB = struct("id","OTHER_ACT","type","ACTUATION","model",a,"sweep",s, ...
    "result",fsd.analysis.analyzeActuationSweep(a,s));
[v,d,u] = vehicleFixture();
f.loadsA = loads(v,"LOADS_A",.5);
d.totalMass = 200; v = fsd.model.createVehicleParameters(d,u);
f.loadsB = loads(v,"LOADS_B",.5);
[system,options] = globalStaticFixture();
f.global = struct("id","GLOBAL","type","GLOBAL_STATIC","model",system, ...
    "result",fsd.analysis.solveGlobalStaticEquilibrium(system,zeros(7,1),options));
f.globalLoads = loads(system.vehicle,"GLOBAL_LOADS",NaN);
native = system.sources{1};
f.globalMech = struct("id","GLOBAL_MECH","type","MECHANICAL", ...
    "model",native.springDamper,"result",native.mechanical);
f.globalBump = bump(native.geometry,[-.01;0;.01],"GLOBAL_BUMP");
axle = analyticAxleFixture(); steering = fsd.model.createSteeringSystem(axle,2,"m");
s = fsd.kinematics.solveRackSweep(steering,[-.005;0;.005],0,"m");
f.rack = struct("id","RACK","type","RACK","model",steering,"sweep",s, ...
    "result",fsd.analysis.analyzeRackSweep(steering,s));
s = fsd.kinematics.solveAxleRollSweep(axle,[-.01;0;.01],0,"rad","m");
f.roll = struct("id","ROLL","type","ROLL","model",axle,"sweep",s, ...
    "result",fsd.analysis.analyzeAxleRollSweep(axle,s));
f.axleLeft = bump(axle.leftGeometry,[-.01;0;.01],"AXLE_LEFT");
f.axleRight = bump(axle.rightGeometry,[-.01;0;.01],"AXLE_RIGHT");
rear = translationAxleFixture("REAR");
f.rear = bump(rear.leftGeometry,[-.01;0;.01],"REAR_BUMP");
end

function source = loads(vehicle,id,crossweight)
d = struct("mode","UNDERDETERMINED","sourceKind","KNOWN");
if isfinite(crossweight), d.mode = "CROSSWEIGHT_SPECIFIED"; d.crossweight = crossweight; end
loadCase = fsd.model.createVehicleLoadCase(vehicle,d);
source = struct("id",id,"type","STATIC_LOADS","model",vehicle, ...
    "result",fsd.analysis.analyzeStaticVehicleLoads(vehicle,loadCase));
end

function source = bump(geometry,z,id)
s = fsd.kinematics.solveBumpSweep(geometry,z,"m");
source = struct("id",id,"type","BUMP","model",geometry,"sweep",s, ...
    "result",fsd.analysis.analyzeBumpSweep(geometry,s));
end
