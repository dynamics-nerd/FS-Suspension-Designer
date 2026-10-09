function derivative = globalPpDerivative(pp)
%GLOBALPPDERIVATIVE Differentiate the same piecewise polynomial, base MATLAB.
[breaks,coefs,~,order,dim] = unmkpp(pp);
if order == 1
    coefs = zeros(size(coefs));
else
    coefs = coefs(:,1:end-1).*(order-1:-1:1);
end
derivative = mkpp(breaks,coefs,dim);
end
