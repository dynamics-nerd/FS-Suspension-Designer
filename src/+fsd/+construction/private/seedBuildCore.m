function result = seedBuildCore(definition,references)
%SEEDBUILDCORE Rigid construction and native validators, never a nonlinear solve.
readiness=seedInputCore(definition,references); d=definition.definitionSI;
references=references(:); if ~isempty(references), [~,order]=sort(cellfun(@(p)p.definitionSI.id,references)); references=references(order); end
result=struct('schemaVersion',"0.17.0",'kind',"ParametricSeedResult",'definition',definition, ...
    'referenceParameters',{references},'readiness',readiness,'nominalStatus',"NOT_BUILT", ...
    'sampledStatus',"NOT_CHECKED",'geometries',{{}},'axle',[],'frames',{{}},'derivations',{{}}, ...
    'consistency',[],'constraintAssessment',[],'diagnostics',readiness.diagnostics,'identity',[]);
if readiness.status~="READY", return; end
try
    corner=d.cornerId; if corner=="FRONT", corner="FL"; end
    [g,frame,deps]=seedCornerCore(corner,d.parameters,references);
    result.geometries={g}; result.frames={frame}; result.derivations={deps};
    if d.cornerId=="FRONT"
        if d.symmetry=="MIRROR_FL"
            opposite=fsd.geometry.reflectDoubleWishboneGeometry(g); S=diag([1,-1,1]);
            otherFrame=frame; otherFrame.cornerId="FR"; otherFrame.origin_m=frame.origin_m*S;
            otherFrame.rotationMatrix=S*frame.rotationMatrix*S; otherFrame.wheelAxis=frame.wheelAxis*S;
            otherFrame.wheelPlane.point_m=frame.wheelPlane.point_m*S;
            otherFrame.wheelPlane.unitNormal=frame.wheelPlane.unitNormal*S;
            otherDeps=deps; otherDeps.cornerId="FR"; otherDeps.reflectionOf="FL"; otherDeps.pointIds=opposite.hardpoints.ids;
        else
            [opposite,otherFrame,otherDeps]=seedCornerCore('FR',d.rightParameters,references);
        end
        result.geometries{2,1}=opposite; result.frames{2,1}=otherFrame; result.derivations{2,1}=otherDeps;
        result.axle=fsd.model.createAxleGeometry(g,opposite);
    end
    result.consistency=fsd.construction.checkConceptGeometryConsistency(result.geometries,references,definition);
    seedRequire(~result.consistency.hasMismatch,'CONCEPT_GEOMETRY_MISMATCH');
    spec=fsd.model.createDesignSpecification(struct('id',d.id+"_NOMINAL",'constraints',{d.constraints}));
    candidate=fsd.model.createDesignCandidate(struct('id',d.id+"_SEED",'geometries',{result.geometries}));
    result.constraintAssessment=fsd.analysis.evaluateDesignCandidate(spec,candidate);
    cs=result.constraintAssessment.constraintAssessments;
    for j=1:numel(cs)
        seedRequire(cs{j}.strength~="HARD" || cs{j}.status=="SAMPLED_PASS", "NOMINAL_HARD_CONSTRAINT:"+cs{j}.id);
    end
    result.nominalStatus="VALID";
    result.identity=struct('schemaVersion',"0.17.0",'definition',definition.identity, ...
        'references',{cellfun(@(p)p.identity,references,'UniformOutput',false)}, ...
        'geometries',{cellfun(@fsd.model.geometryIdentity,result.geometries,'UniformOutput',false)});
catch cause
    allowed=["fsd:construction:InvalidInput","fsd:model:CoincidentUBJLBJ","fsd:model:CoincidentUcaPivots", ...
        "fsd:model:CoincidentLcaPivots","fsd:model:CoincidentWheelReferences","fsd:model:CoincidentTieRod", ...
        "fsd:model:CoincidentUprightPoints","fsd:model:ZeroLengthUcaLink","fsd:model:ZeroLengthLcaLink", ...
        "fsd:model:DegenerateUpright","fsd:model:NonFiniteCoordinate","fsd:model:WheelAxisNotOutward", ...
        "fsd:synthesis:DegenerateWishbone"];
    if ~ismember(string(cause.identifier),allowed), rethrow(cause); end
    result.nominalStatus="INVALID"; result.diagnostics(end+1,1)=string(cause.identifier)+":"+string(cause.message);
    result.geometries={}; result.axle=[]; result.frames={}; result.derivations={}; result.identity=[];
end
end
