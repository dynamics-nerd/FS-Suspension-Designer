function payload=executeArbScenario(p)
%EXECUTEARBSCENARIO Generate each required native driver path only once.
sources={};
if p.scenario.definition.engine=="ARB_SIZING"
    payload=assembleArbPayload(p,{},[]); return;
end
if p.bar.definition.representation=="COAXIAL_TORSION"
    sources=cell(2,1);
    for side=1:2
        g=p.resources.geometries{side};
        bump=fsd.kinematics.solveBumpSweep(g,p.plan.driverTravel_m{side},'m',p.driverOptions);
        source=struct('geometry',g,'bump',bump);
        if p.bar.definition.drivers(side)=="ROCKER"
            a=resourceFind(p.resources,'actuations',g.cornerId);
            source.actuation=a; source.actuationSweep=fsd.kinematics.solveActuationSweep(a,bump);
        end
        sources{side}=source;
    end
end
motion=[];
if p.plan.motion=="ROLL"
    axle=fsd.model.createAxleGeometry(p.resources.geometries{1},p.resources.geometries{2});
    motion=fsd.kinematics.solveAxleRollSweep(axle,p.plan.rollAngles_rad,p.plan.axleHeave_m,'rad','m',p.options);
end
payload=assembleArbPayload(p,sources,motion);
end
