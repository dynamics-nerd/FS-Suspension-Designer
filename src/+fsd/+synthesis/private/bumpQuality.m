function quality = bumpQuality(geometry,sweep)
%BUMPQUALITY Local closure orientation and reciprocal conditioning, not proof of branch uniqueness.
% Infinitesimal world-axis rotations about WC; translations scaled by Lref.
c = geometry.cornerId;
in = c+"_"+["UCA_FWD_CHASSIS";"UCA_AFT_CHASSIS";"LCA_FWD_CHASSIS";"LCA_AFT_CHASSIS";"TIE_ROD_INBOARD"];
out = c+"_"+["UBJ";"UBJ";"LBJ";"LBJ";"TIE_ROD_OUTBOARD"];
p = zeros(5,3); b = p;
for i=1:5, p(i,:)=fsd.model.getPoint(geometry,in(i)); b(i,:)=fsd.model.getPoint(geometry,out(i)); end
wc = fsd.model.getPoint(geometry,c+"_WHEEL_CENTER");
lengths = vecnorm(b-p,2,2); scale = max(lengths);
[referenceRcond,referenceOrientation] = closure(b,wc,p,lengths,scale);
count = numel(sweep.results); conditioning = nan(count,1); orientation = conditioning;
for k=1:count
    r = sweep.results(k); if ~r.converged, continue; end
    current = r.state.xyz_m; index = zeros(5,1);
    for i=1:5, index(i)=find(r.state.pointIds==out(i)); end
    [conditioning(k),orientation(k)] = closure(current(index,:),r.state.wheelCenter_m,p,lengths,scale);
end
threshold = sqrt(eps('double')); % numerical near-singularity gate, no manufacturing meaning
reliable = sweep.converged & conditioning>threshold & referenceRcond>threshold & ...
    orientation==referenceOrientation;
quality = struct('policy',"LOCAL_CLOSURE_ORIENTATION_1",'referenceRcond',referenceRcond, ...
    'referenceOrientation',referenceOrientation,'rcond',conditioning,'orientation',orientation, ...
    'reliable',reliable,'connected',reliable(1:end-1)&reliable(2:end), ...
    'threshold',threshold,'lengthScale_m',scale,'allReliable',all(reliable), ...
    'branchPolicy',"NATIVE_STATIC_CONTINUATION_WITH_LOCAL_ORIENTATION_GUARD");
end

function [condition,orientation] = closure(b,wc,p,lengths,scale)
u = (b-p)./vecnorm(b-p,2,2); lever = b-wc;
J = [u(:,1:2)*scale,cross(lever,u,2)]./lengths;
condition = rcond(J); orientation = sign(det(J));
end
