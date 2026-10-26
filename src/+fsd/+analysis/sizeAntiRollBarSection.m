function result=sizeAntiRollBarSection(target_Nm_per_rad,G_Pa,length_m,innerDiameter_m)
%SIZEANTIROLLBARSECTION Determined scalar inverse; user target, not an optimum.
if nargin<4, innerDiameter_m=0; end % explicit SOLID syntax with three arguments
v=cellfun(@scalar,{target_Nm_per_rad,G_Pa,length_m,innerDiameter_m});
assert(all(v(1:3)>0)&&v(4)>=0, ...
    'fsd:analysis:InvalidAntiRollBar','Positive target/G/length and nonnegative inner diameter required.');
v=double(v); outer=(v(4)^4+32*v(3)*v(1)/(pi*v(2)))^.25;
assert(isfinite(outer)&&outer>v(4),'fsd:analysis:InvalidAntiRollBar','Section inverse is not numerically resolved.');
result=struct('kind',"AntiRollBarSectionSizing",'target_Nm_per_rad',v(1),'G_Pa',v(2), ...
    'effectiveLength_m',v(3),'innerDiameter_m',v(4),'outerDiameter_m',outer, ...
    'assumption',"Circular linear-elastic active span only; user-declared target, not optimized vehicle setup.");
end
function v=scalar(v)
assert((isa(v,'double')||isa(v,'single')||isinteger(v))&&isreal(v)&&isscalar(v)&&isfinite(v), ...
    'fsd:analysis:InvalidAntiRollBar','Finite real built-in scalar required.');
if isinteger(v)
    x=double(v); assert(abs(x)<=flintmax&&isequal(cast(x,'like',v),v), ...
        'fsd:analysis:InvalidAntiRollBar','Unsafe integer conversion.');
end
v=double(v);
end
