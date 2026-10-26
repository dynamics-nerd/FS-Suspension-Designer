function payload=assembleArbPayload(p,sources,motion)
%ASSEMBLEARBPAYLOAD Shared algebraic reconstruction; never forward suspension solves.
if p.scenario.definition.engine=="ARB_SIZING"
    projectRequire(isempty(sources)&&isempty(motion),'Sizing must not fabricate kinematic evidence.');
    parameters=p.bar.definition.parameters; inner=0;
    if p.bar.definition.section=="TUBULAR", inner=parameters.innerDiameter_m; end
    sizing=fsd.analysis.sizeAntiRollBarSection(p.plan.target.stiffness_Nm_per_rad,parameters.G_Pa,parameters.effectiveLength_m,inner);
    payload=struct('sizing',sizing,'target',p.plan.target); return;
end
if p.bar.definition.representation=="COAXIAL_TORSION"
    projectRequire(iscell(sources)&&numel(sources)==2,'Two exact native source paths required.');
    for side=1:2
        source=sources{side}; g=p.resources.geometries{side};
        projectRequire(isequaln(source.geometry,g)&&isfield(source,'bump'),'Crossed ARB parent geometry.');
        fsd.kinematics.validateBumpSweepResult(source.bump);
        projectRequire(isequaln(source.bump.geometryIdentity,fsd.model.geometryIdentity(g))&& ...
            isequaln(source.bump.requestedWheelTravel_m,p.plan.driverTravel_m{side}),'Crossed ARB source grid.');
        expectedFields=["bump";"geometry"];
        if p.bar.definition.drivers(side)=="ROCKER"
            a=resourceFind(p.resources,'actuations',g.cornerId);
            projectRequire(isequaln(source.actuation,a),'Crossed rocker model.');
            fsd.kinematics.validateActuationSweepResult(source.actuationSweep,a);
            projectRequire(isequaln(source.actuationSweep.sourceGeometryIdentity,fsd.model.geometryIdentity(g))&& ...
                isequaln(source.actuationSweep.requestedWheelTravel_m,source.bump.requestedWheelTravel_m)&& ...
                numel(source.actuationSweep.results)==numel(source.bump.results),'Crossed rocker path.');
            for k=1:numel(source.bump.results)
                projectRequire(isequaln(source.actuationSweep.results(k).sourceResult,source.bump.results(k)),'Crossed rocker parent sample.');
            end
            expectedFields=sort([expectedFields;"actuation";"actuationSweep"]);
        end
        projectRequire(isequal(sort(string(fieldnames(source))),expectedFields),'Unexpected ARB source fields.');
    end
else
    projectRequire(isempty(sources),'Equivalent ARB must not fabricate geometry sources.');
end
if p.plan.motion=="ROLL"
    fsd.kinematics.validateAxleRollSweepResult(motion);
    axle=fsd.model.createAxleGeometry(p.resources.geometries{1},p.resources.geometries{2});
    projectRequire(isequaln(motion.axleIdentity,fsd.model.axleIdentity(axle))&& ...
        isequaln(motion.requestedBodyRollAngle_rad,p.plan.rollAngles_rad)&& ...
        isequaln(motion.requestedAxleHeave_m,p.plan.axleHeave_m),'Crossed ARB roll conditions.');
    z=nan(numel(motion.results),2);
    for k=1:numel(motion.results)
        if motion.results(k).converged, z(k,:)=motion.results(k).wheelTravel_m; end
    end
else
    projectRequire(isempty(motion),'Unexpected ARB motion evidence.'); z=p.plan.wheelTravel_m;
end
prepared=fsd.analysis.prepareAntiRollBar(p.bar,sources);
if p.scenario.definition.engine=="ARB_KINEMATICS"
    study=fsd.analysis.analyzeAntiRollBarKinematicSweep(prepared,z);
else
    study=fsd.analysis.analyzeAntiRollBarSweep(prepared,z);
end
packaging=[];
if isfield(p.plan,'packaging'), packaging=fsd.packaging.evaluateAntiRollBar(p.plan.packaging,study); end
payload=struct('sources',{sources},'motion',motion,'study',study,'packaging',packaging);
end
