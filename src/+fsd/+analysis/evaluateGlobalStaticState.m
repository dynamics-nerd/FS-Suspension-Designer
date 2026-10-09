function state = evaluateGlobalStaticState(system, q)
%EVALUATEGLOBALSTATICSTATE Evaluate prescribed SI q, never certify a solved equilibrium.
q = globalCoordinateInput(q);
prepared = fsd.analysis.prepareGlobalStaticSystem(system);
state = globalStateCore(prepared,q);
end
