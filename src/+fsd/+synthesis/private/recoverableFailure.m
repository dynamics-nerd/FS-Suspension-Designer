function yes = recoverableFailure(stage,identifier)
%RECOVERABLEFAILURE Closed domain-error policy; unknown/infrastructure errors escape.
switch stage
    case "BUILDER"
        allowed=["fsd:model:CoincidentUcaPivots","fsd:model:CoincidentLcaPivots", ...
            "fsd:model:ZeroLengthUcaLink","fsd:model:ZeroLengthLcaLink", ...
            "fsd:synthesis:DegenerateWishbone"];
    case "BUMP"
        allowed="fsd:kinematics:InvalidWheelAxisOrientation";
    case "ANALYSIS"
        allowed=["fsd:analysis:DegenerateCasterProjection", ...
            "fsd:analysis:DegenerateKingpinProjection","fsd:analysis:DegenerateToeProjection", ...
            "fsd:analysis:InvalidWheelAxisOrientation"];
    otherwise
        allowed=strings(0,1);
end
yes=ismember(string(identifier),allowed);
end
