function yes = steeringRecoverableFailure(stage,identifier)
%STEERINGRECOVERABLEFAILURE Closed opt-in domain extension; never a wildcard catch.
allowed=strings(0,1);
if stage=="BUILDER"
    allowed=["fsd:model:CoincidentTieRod","fsd:model:CoincidentUprightPoints", ...
        "fsd:model:DegenerateUpright","fsd:model:DegenerateRackAxis"];
elseif stage=="ANALYSIS"
    allowed="fsd:analysis:DegenerateWheelHeading";
end
yes=recoverableFailure(stage,identifier) || ismember(string(identifier),allowed);
end
