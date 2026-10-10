function bindings = designCandidateAssociations(candidate,sources)
%DESIGNCANDIDATEASSOCIATIONS Physical input identities on prevalidated objects.
% One candidate = one configuration/vehicle/load case, with four independent corners.
% Sweeps, solver options and response values are NOT physical model identities.
bindings = struct("domain",{},"key",{},"identity",{},"owner",{});
d = candidate.definitionSI;
for i = 1:numel(d.geometries)
    geometry(d.geometries{i},"registered geometry");
end
if ~isempty(d.vehicle), bind("VEHICLE","VEHICLE",d.vehicle.identity,"registered vehicle"); end
for i = 1:numel(sources)
    s = sources{i}; m = s.model; owner = s.type+":"+s.id;
    switch s.type
        case "BUMP"
            geometry(m,owner);
        case {"RACK","ROLL"}
            axle = m;
            if s.type == "RACK"
                bind("STEERING","FRONT",m.identity,owner); axle = m.frontAxleGeometry;
            end
            geometry(axle.leftGeometry,owner); geometry(axle.rightGeometry,owner);
        case "ACTUATION"
            actuation(m.identity,owner);
        case "MECHANICAL"
            mechanical(m,owner);
        case "STATIC_LOADS"
            bind("VEHICLE","VEHICLE",m.identity,owner);
            bind("LOAD_CASE","VEHICLE",s.result.loadCase.identity,owner);
        case "GLOBAL_STATIC"
            bind("VEHICLE","VEHICLE",m.vehicle.identity,owner);
            bind("LOAD_CASE","VEHICLE",m.loadCase.identity,owner);
            context = struct("massApproximation",m.options.massApproximation, ...
                "unsprungPositionAssumption",m.options.unsprungPositionAssumption, ...
                "unsprungMass_kg",m.unsprungMass_kg,"roadHeight_m",m.options.roadHeight_m, ...
                "coordinateSystem",m.coordinateSystem,"rotationOrder",m.rotationOrder);
            bind("GLOBAL_CONTEXT","VEHICLE",context,owner);
            for j = 1:numel(m.sources)
                geometry(m.sources{j}.geometry,owner);
                actuation(m.sources{j}.actuation.identity,owner);
                mechanical(m.sources{j}.springDamper,owner);
                bind("VERTICAL_TIRE",m.cornerIds(j),m.tires{j}.identity,owner);
            end
    end
end

    function geometry(g,owner)
        bind("GEOMETRY",string(g.cornerId),fsd.model.geometryIdentity(g),owner);
    end
    function actuation(identity,owner)
        bind("GEOMETRY",string(identity.cornerId),identity.cornerGeometryIdentity,owner);
        bind("ACTUATION",string(identity.cornerId),identity,owner);
    end
    function mechanical(m,owner)
        actuation(m.actuationIdentity,owner);
        bind("SPRING_DAMPER",string(m.cornerId),m.identity,owner);
    end
    function bind(domain,key,identity,owner)
        % At most four keys per corner domain; no pairwise source-tree traversal.
        bindingIndex = find(string({bindings.domain}) == domain & string({bindings.key}) == key);
        if isempty(bindingIndex)
            bindings(end+1) = struct("domain",domain,"key",key,"identity",identity,"owner",owner);
        elseif ~isequaln(bindings(bindingIndex).identity,identity)
            error("fsd:analysis:InvalidDesignCandidate", ...
                "INCOMPATIBLE_SOURCE_ASSOCIATION %s/%s between %s and %s.", ...
                domain,key,bindings(bindingIndex).owner,owner);
        end
    end
end
