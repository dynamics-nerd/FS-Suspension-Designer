function d = conceptDerivationCore(concept,options)
%CONCEPTDERIVATIONCORE Existing vehicle/load model, no invented CG or closures.
prepared=conceptPreparation(concept,options); loads=[]; values=cell(0,1);
append("TOTAL_MASS",prepared.totalMass_kg,"kg",prepared.massDependencies,"MASS_INCLUSION_BOOKKEEPING_V09");
if ~isempty(prepared.model)
    model=prepared.model; loads=fsd.analysis.analyzeStaticVehicleLoads(model,prepared.loadCase);
    for j=1:3
        ids=["CG_X","CG_Y","CG_Z"]; value=model.cg_m(j); if ~isfinite(value), value=[]; end
        append(ids(j),value,"m",["CG_X";"CG_Y";"CG_Z";"FRONT_WEIGHT_FRACTION";"REAR_WEIGHT_FRACTION"],"VehicleParameters_0.9.0");
    end
    append("FRONT_AXLE_LOAD",finiteOrEmpty(loads.frontAxleLoad_N),"N","STATIC_LOAD_INPUTS","StaticVehicleLoads_0.9.0");
    append("REAR_AXLE_LOAD",finiteOrEmpty(loads.rearAxleLoad_N),"N","STATIC_LOAD_INPUTS","StaticVehicleLoads_0.9.0");
    % Descriptive fraction of already computed native loads, not a new load law.
    append("FRONT_WEIGHT_FRACTION",finiteOrEmpty(loads.frontAxleLoad_N/loads.totalNormalDemand_N),"1","STATIC_LOAD_INPUTS","Native axle load / native total demand");
    append("REAR_WEIGHT_FRACTION",finiteOrEmpty(loads.rearAxleLoad_N/loads.totalNormalDemand_N),"1","STATIC_LOAD_INPUTS","Native axle load / native total demand");
    for j=1:4
        append("CORNER_LOAD_"+model.cornerIds(j),finiteOrEmpty(loads.cornerLoads_N(j)),"N","STATIC_LOAD_INPUTS","StaticVehicleLoads_0.9.0");
    end
end
d=struct('schemaVersion',"0.16.0",'kind',"ConceptDerivation",'concept',concept, ...
    'conceptIdentity',concept.identity,'options',prepared.options,'status',prepared.status, ...
    'missing',prepared.missing,'diagnostics',prepared.diagnostics,'values',{values}, ...
    'vehicle',prepared.model,'loadCase',prepared.loadCase,'loads',loads);
d.identity=struct('schemaVersion',"0.16.0",'kind',"ConceptDerivationIdentity", ...
    'conceptIdentity',concept.identity,'options',prepared.options);

    function append(id,value,unit,dependencies,method)
        status="AVAILABLE"; if isempty(value), status="MISSING_DATA"; end
        values{end+1,1}=struct('id',id,'value',value,'unit',unit,'status',status, ...
            'sourceKind',"DERIVED",'dependencies',dependencies(:),'method',method, ...
            'inputConceptIdentity',concept.identity,'warnings',"Input provenance retained; DERIVED does not mean measured.");
    end
end

function value = finiteOrEmpty(value)
if ~isfinite(value), value=[]; end
end
