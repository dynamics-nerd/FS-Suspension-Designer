function derivative = secondOrderDerivative(x, y)
%SECONDORDERDERIVATIVE Local quadratic derivative on nonuniform samples.

x = double(x(:));
y = double(y(:));
count = numel(x);
if count ~= numel(y) || count < 3 || any(~isfinite(x)) || ...
        any(~isfinite(y)) || numel(unique(x)) ~= count
    error("fsd:analysis:InvalidDerivativeSamples", ...
        "Derivative samples must be finite, distinct and contain at least 3 points.");
end
derivative = zeros(count, 1);
for index = 1:count
    if index == 1
        sampleIndices = 1:3;
    elseif index == count
        sampleIndices = count-2:count;
    else
        sampleIndices = index-1:index+1;
    end
    xs = x(sampleIndices);
    ys = y(sampleIndices);
    evaluationPoint = x(index);
    derivative(index) = quadraticDerivative(xs, ys, evaluationPoint);
end
end

function value = quadraticDerivative(x, y, evaluationPoint)
value = 0;
for j = 1:3
    others = setdiff(1:3, j);
    denominator = (x(j)-x(others(1))) * (x(j)-x(others(2)));
    basisDerivative = (2*evaluationPoint - ...
        x(others(1)) - x(others(2))) / denominator;
    value = value + y(j) * basisDerivative;
end
end
