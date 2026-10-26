function system=globalScenarioSystem(p,sources)
%GLOBALSCENARIOSYSTEM Exact native aggregate of the four declared corner paths.
if isfield(p,'antiRollBars')
    system=fsd.model.createGlobalStaticSystem(p.vehicle,p.loadCase,sources,p.tires,p.plan.systemOptions,p.antiRollBars);
else
    system=fsd.model.createGlobalStaticSystem(p.vehicle,p.loadCase,sources,p.tires,p.plan.systemOptions);
end
end
