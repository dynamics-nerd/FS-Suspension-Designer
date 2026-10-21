function result=distance(first,second)
%DISTANCE Exact finite-primitive separation, not conservative AABB distance.
fsd.packaging.validateVolume(first); fsd.packaging.validateVolume(second);
a=first.definitionSI; b=second.definitionSI;
assert(a.binding.mode=="FIXED" && b.binding.mode=="FIXED",'fsd:packaging:UnresolvedBinding','Resolve mobile bindings before distance checks.');
assert(isequaln(a.frame,b.frame),'fsd:packaging:FrameMismatch','Volumes must share the complete parent frame.');
assert(a.role=="OCCUPIED" && b.role=="OCCUPIED",'fsd:packaging:FreeRegion','Free regions are not occupied collision geometry.');
result=struct('status',"NOT_EVALUATED",'intersection',false,'distance_m',NaN, ...
    'witnesses_m',nan(2,3),'aabbLowerBound_m',NaN,'broadPhaseSeparated',false, ...
    'numericBudget_m',NaN,'diagnostic',"Unsupported primitive pair; no distance asserted.");
if isempty(a.dimensions) || isempty(b.dimensions)
    result.status="INCOMPLETE"; result.diagnostic="Missing explicit physical dimensions."; return;
end
if a.shape=="CYLINDER" || b.shape=="CYLINDER", return; end
boxA=ismember(a.shape,["AABB","OBB"]); boxB=ismember(b.shape,["AABB","OBB"]);
[lowA,highA]=bounds(a); [lowB,highB]=bounds(b);
if any(~isfinite([lowA highA lowB highB]))
    result.status="INCOMPLETE"; result.diagnostic="Numerical range exceeded while resolving primitive bounds."; return;
end
result.aabbLowerBound_m=norm(max([lowA-highB;lowB-highA;zeros(1,3)],[],1));
result.broadPhaseSeparated=result.aabbLowerBound_m>0;
if ~boxA && ~boxB
    [a0,a1,ra]=segment(a); [b0,b1,rb]=segment(b);
    [centre,p,q]=fsd.packaging.segmentDistance(a0,a1,b0,b1);
    signed=centre-ra-rb;
    witnesses=nan(2,3);
    if signed>0
        direction=(q-p)/centre; witnesses=[p+ra*direction;q-rb*direction];
    end
elseif boxA && boxB
    [signed,witnesses]=boxDistance(a,b,result.broadPhaseSeparated);
else
    if boxA, box=a; capsule=b; else, box=b; capsule=a; end
    [p0,p1,radius]=segment(capsule);
    [centre,p,q]=segmentBox(p0,p1,box); signed=centre-radius;
    witnesses=nan(2,3);
    if signed>0
        witnesses=[p+radius*(q-p)/centre;q];
        if boxA, witnesses=flipud(witnesses); end
    end
end
tol=fsd.model.numericTolerances();
result.numericBudget_m=tol.AbsTol_m+tol.RelTol*max([1,abs(lowA),abs(highA),abs(lowB),abs(highB)]);
if ~isfinite(signed) || (signed>0 && any(~isfinite(witnesses),'all'))
    result.status="INCOMPLETE"; result.diagnostic="Numerical range exceeded; no finite separation/witnesses certified."; return;
end
result.status="EVALUATED"; result.intersection=signed<=0;
result.distance_m=max(0,signed); result.witnesses_m=witnesses;
result.diagnostic="Unsigned minimum separation; penetration depth not computed. Broad phase is a lower bound only.";
end

function [p0,p1,radius]=segment(d)
radius=d.dimensions(1); centre=d.transform(1:3,4)'; p0=centre; p1=centre;
if d.shape=="CAPSULE"
    half=d.dimensions(2)*d.transform(1:3,3)'/2; p0=centre-half; p1=centre+half;
end
end
function [low,high]=bounds(d)
if ismember(d.shape,["AABB","OBB"])
    centre=d.transform(1:3,4)'; half=(abs(d.transform(1:3,1:3))*d.dimensions(:)/2)'; low=centre-half; high=centre+half;
else
    [p,q,radius]=segment(d); low=min(p,q)-radius; high=max(p,q)+radius;
end
end
function [distance_m,p,q]=segmentBox(p0,p1,box)
R=box.transform(1:3,1:3); centre=box.transform(1:3,4)';
a=(p0-centre)*R; v=(p1-p0)*R; half=box.dimensions/2;
knots=[0;1];
for j=1:3
    if v(j)~=0
        t=([-half(j);half(j)]-a(j))/v(j); knots=[knots;t(t>0 & t<1)]; %#ok<AGROW> Six box-face crossings maximum.
    end
end
knots=unique(knots); candidates=knots;
for j=1:numel(knots)-1
    middle=(knots(j)+knots(j+1))/2; at=a+middle*v;
    active=abs(at)>half; target=min(half,max(-half,at));
    denominator=sum(v(active).^2);
    if denominator>0
        t=-sum(v(active).*(a(active)-target(active)))/denominator;
        if t>knots(j) && t<knots(j+1), candidates(end+1,1)=t; end %#ok<AGROW> One stationary point per interval.
    end
end
points=a+candidates.*v; closest=min(half,max(-half,points));
[~,index]=min(sum((points-closest).^2,2));
p=points(index,:)*R'+centre; q=closest(index,:)*R'+centre; distance_m=norm(p-q);
end
function [distance_m,witnesses]=boxDistance(a,b,separated)
Ra=a.transform(1:3,1:3); Rb=b.transform(1:3,1:3);
ca=a.transform(1:3,4)'; cb=b.transform(1:3,4)';
% A disjoint broad-phase AABB already proves no intersection; skip SAT then.
if ~separated
    axes=[Ra,Rb];
    for j=1:3
        for k=1:3
            axis=cross(Ra(:,j),Rb(:,k));
            if norm(axis)>0, axes(:,end+1)=axis/norm(axis); end %#ok<AGROW> At most 15 separating axes.
        end
    end
    for axis=axes
        radiusA=sum(abs(Ra'*axis).*a.dimensions(:)/2);
        radiusB=sum(abs(Rb'*axis).*b.dimensions(:)/2);
        if abs((cb-ca)*axis)>radiusA+radiusB, separated=true; break; end
    end
end
if ~separated, distance_m=0; witnesses=nan(2,3); return; end
[va,ea]=vertices(a); [vb,eb]=vertices(b); distance_m=Inf; witnesses=nan(2,3);
for j=1:8
    [d,p,q]=segmentBox(va(j,:),va(j,:),b);
    if d<distance_m, distance_m=d; witnesses=[p;q]; end
    [d,p,q]=segmentBox(vb(j,:),vb(j,:),a);
    if d<distance_m, distance_m=d; witnesses=[q;p]; end
end
for j=1:12
    for k=1:12
        [d,p,q]=fsd.packaging.segmentDistance(va(ea(j,1),:),va(ea(j,2),:),vb(eb(k,1),:),vb(eb(k,2),:));
        if d<distance_m, distance_m=d; witnesses=[p;q]; end
    end
end
end
function [points,edges]=vertices(d)
signs=[-1 -1 -1;1 -1 -1;-1 1 -1;1 1 -1;-1 -1 1;1 -1 1;-1 1 1;1 1 1];
points=(signs.*d.dimensions/2)*d.transform(1:3,1:3)'+d.transform(1:3,4)';
edges=[1 2;3 4;5 6;7 8;1 3;2 4;5 7;6 8;1 5;2 6;3 7;4 8];
end
