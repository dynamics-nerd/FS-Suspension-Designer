function catalog = conceptParameterCatalog()
%CONCEPTPARAMETERCATALOG Concept inputs, not a second target/physics catalog.
% CG is the operating total CG. Wheel radii are unloaded geometry, not rolling radii.
ids=["VEHICLE_MASS";"DRIVER_MASS";"WHEELBASE";"FRONT_TRACK";"REAR_TRACK"; ...
    "CG_X";"CG_Y";"CG_Z";"FRONT_WEIGHT_FRACTION";"REAR_WEIGHT_FRACTION"; ...
    "WHEEL_UNLOADED_RADIUS_FRONT";"WHEEL_UNLOADED_RADIUS_REAR";"WHEEL_WIDTH_FRONT";"WHEEL_WIDTH_REAR"; ...
    "UNSPRUNG_MASS_FL";"UNSPRUNG_MASS_FR";"UNSPRUNG_MASS_RL";"UNSPRUNG_MASS_RR"];
quantity=repmat("LENGTH",size(ids)); quantity([1,2,15:18])="MASS"; quantity(9:10)="FRACTION";
minimum=[0;0;0;0;0;-Inf;-Inf;-Inf;0;0;0;0;0;0;0;0;0;0];
maximum=inf(size(ids)); maximum(9:10)=1;
exclusive=false(size(ids)); exclusive([1,3:5,11:14])=true;
catalog=repmat(struct('id',"",'quantity',"",'unit',"",'minimum',0,'maximum',0,'minimumExclusive',false),numel(ids),1);
for j=1:numel(ids)
    [~,unit]=fsd.model.convertDesignUnits([],quantity(j),canonical(quantity(j)));
    catalog(j)=struct('id',ids(j),'quantity',quantity(j),'unit',unit, ...
        'minimum',minimum(j),'maximum',maximum(j),'minimumExclusive',exclusive(j));
end
end

function unit = canonical(quantity)
unit="m"; if quantity=="MASS", unit="kg"; elseif quantity=="FRACTION", unit="1"; end
end
