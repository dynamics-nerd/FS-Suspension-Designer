function value=arbPathValue(prepared,side,z)
%ARBPATHVALUE Exact analytic link closure on one segmented sampled driver path.
p=prepared.bar.definition.parameters; path=prepared.paths{side};
value=struct('available',false,'status',"OUTSIDE_SAMPLED_DRIVER_PATH",'segmentId',0, ...
    'first',NaN,'second',NaN,'curvatureAvailable',false,'endState',[]);
for k=1:numel(path.segments)
    s=path.segments{k}; if z<s.interval_m(1)||z>s.interval_m(2), continue; end
    a=ppval(s.pp,z); b=ppval(s.first,z); c=ppval(s.second,z);
    e=fsd.geometry.antiRollBarClosure(p,side,a(1:3)',a(4),s.branchSign);
    value.segmentId=k; value.endState=e; value.status=e.status;
    if ~e.available, return; end
    v=e.armPoint_m-e.driverPoint_m; pa=e.armTangent_m; paa=e.armSecond_m;
    dz=b(1:3)'; ddz=c(1:3)'; ga=e.closureFirst_m2; gz=-2*dot(v,dz);
    first=-gz/ga;
    gaa=2*(dot(pa,pa)+dot(v,paa)); gaz=-2*dot(dz,pa); gzz=2*(dot(dz,dz)-dot(v,ddz));
    second=-(gzz+2*gaz*first+gaa*first^2)/ga;
    if any(~isfinite([first,second])), value.status="NUMERICALLY_UNRESOLVED"; return; end
    resolved=z>s.interval_m(1)+64*eps(max(abs(z),1))&&z<s.interval_m(2)-64*eps(max(abs(z),1));
    breaks=s.pp.breaks; knot=find(abs(breaks-z)<=64*eps(max(abs(z),1)),1);
    if ~isempty(knot)&&knot>1&&knot<numel(breaks)
        % Same dimensional position-curvature budget as historical WC paths.
        left=reshape(s.second.coefs((knot-2)*4+(1:4),:),4,[]);
        right=reshape(s.second.coefs((knot-1)*4+(1:4),:),4,[]);
        h=breaks(knot)-breaks(knot-1); lv=left(:,1)*h+left(:,2); rv=right(:,2);
        resolved=resolved&&all(abs(lv(1:3)-rv(1:3))<=1e-6+1e-3*max(abs(lv(1:3)),abs(rv(1:3))));
    end
    value.available=true; value.first=first; value.second=second; value.curvatureAvailable=resolved; return;
end
if z>=min(path.requested_m)&&z<=max(path.requested_m), value.status="FAILED_OR_DISCONNECTED_DRIVER_PATH"; end
end
