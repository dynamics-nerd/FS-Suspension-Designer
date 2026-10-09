function [J, count] = globalJacobian(p, q, o, state)
%GLOBALJACOBIAN Derivative of the gradient; no reliance on unresolved path curvature.
J = nan(7); count = 0;
for i = 1:7
    h = eps^(1/3)*o.coordinateScales(i);
    a = q; b = q; a(i) = q(i)-h; b(i) = q(i)+h;
    minusOK = a(i) >= o.bounds(i,1); plusOK = b(i) <= o.bounds(i,2);
    if minusOK
        minus = globalStateCore(p,a); count = count+1; minusOK = minus.feasible;
    end
    if plusOK
        plus = globalStateCore(p,b); count = count+1; plusOK = plus.feasible;
    end
    if minusOK && plusOK
        J(:,i) = (plus.residual-minus.residual)/(2*h);
    elseif plusOK
        J(:,i) = (plus.residual-state.residual)/h;
    elseif minusOK
        J(:,i) = (state.residual-minus.residual)/h;
    end
end
end
