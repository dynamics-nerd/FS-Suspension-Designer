function rows = parameterRows(catalog,parameters,concept)
%PARAMETERROWS Presentation only; absent values stay blank, never zero.
rows=cell(numel(catalog),11);
for j=1:numel(catalog)
    rows(j,:)={char(catalog(j).id),'','',char(catalog(j).unit),'KNOWN','NOT_PROVIDED','UNSPECIFIED','','DECLARED','','{}'};
    for k=1:numel(parameters)
        record=parameters{k}; p=record;
        if concept, p=record.parameter; end
        d=p.definitionSI;
        if d.id~=catalog(j).id, continue; end
        rows(j,2:8)={numbers(d.value),numbers(d.bounds),char(d.unit),char(d.type),char(d.availability),char(d.sourceKind),char(d.sourceNote)};
        if concept, rows(j,9:10)={char(record.confirmation),char(record.origin.reference)}; end
        rows{j,11}=jsonencode(struct('ruleReference',d.ruleReference,'derivationReference',d.derivationReference));
    end
end
end
function s=numbers(v)
s=char(strjoin(compose('%.17g',v),' '));
end
