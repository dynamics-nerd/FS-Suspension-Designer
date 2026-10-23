function system=globalScenarioSystem(p,sources)
%GLOBALSCENARIOSYSTEM Exact native aggregate of the four declared corner paths.
system=fsd.model.createGlobalStaticSystem(p.vehicle,p.loadCase,sources,p.tires,p.plan.systemOptions);
end
