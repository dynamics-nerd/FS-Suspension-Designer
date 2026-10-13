function [geometry, changes] = buildCore(space,x_m)
%BUILDCORE Rebuild canonical topology; unchanged coordinates/provenance preserved.
coordinateCore(space,x_m,"NORMALIZE"); x_m = x_m(:); seed = space.seed;
xyz = seed.hardpoints.xyz_m; provenance = struct('sourceKind',seed.hardpoints.sourceKind,'sourceNote',seed.hardpoints.sourceNote);
changes = cell(0,1);
for i = 1:numel(space.variables)
    v = space.variables{i}; xyz(v.row,v.column) = x_m(i);
    if x_m(i) ~= v.initial_m
        provenance.sourceKind(v.row,v.column) = "DERIVED";
        provenance.sourceNote(v.row,v.column) = "Synthesis coordinate "+v.id+"; design provenance: "+v.parameter.sourceKind+" / "+v.parameter.sourceNote;
        changes{end+1,1} = struct('id',v.id,'hardpointId',v.hardpointId,'component',v.component, ...
            'seed_m',v.initial_m,'candidate_m',x_m(i)); %#ok<AGROW>
    end
end
geometry = fsd.model.createDoubleWishboneGeometry(seed.cornerId,seed.hardpoints.ids,xyz,'m',seed.wheel.wheelAxis,provenance);
geometry.hardpoints.displayName = seed.hardpoints.displayName;
% Factory normalization must not change an unselected wheel-axis input by roundoff.
geometry.wheel = seed.wheel;
geometry.referenceFrame = seed.referenceFrame; geometry.metadata = seed.metadata;
% Existing factory rejects coincident points. Also reject collinear arm triangles.
tol = fsd.model.numericTolerances();
for arm = ["UCA","LCA"]
    p = fsd.model.getPoint(geometry,seed.cornerId+"_"+arm+"_FWD_CHASSIS");
    q = fsd.model.getPoint(geometry,seed.cornerId+"_"+arm+"_AFT_CHASSIS");
    joint = "UBJ"; if arm=="LCA", joint = "LBJ"; end
    b = fsd.model.getPoint(geometry,seed.cornerId+"_"+joint);
    if ~(norm(cross(q-p,b-p))>tol.AbsTol_m*max([norm(q-p),norm(b-p),1])+tol.RelTol*norm(q-p)*norm(b-p))
        error('fsd:synthesis:DegenerateWishbone','Degenerate wishbone triangle.');
    end
end
fsd.model.validateDoubleWishboneGeometry(geometry);
end
