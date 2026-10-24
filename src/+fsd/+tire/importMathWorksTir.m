function descriptor=importMathWorksTir(file,sourceNote)
%IMPORTMATHWORKSTIR Optional public-API import; never a native tire conversion.
% Requires Extended Tire Features for Vehicle Dynamics Blockset. The original
% text and the provider's parameter interpretation are retained as plain data.
% Import is not evidence of calibration or source-parameter completeness.
% Public contracts: tireModel.import and tireModel.struct (MathWorks R2026b).
if nargin<2, sourceNote=""; end
assert(textScalar(file)&&textScalar(sourceNote),'fsd:tire:InvalidMathWorksImport', ...
    'Scalar file path and source note required.');
file=string(file); sourceNote=string(sourceNote);
[~,name,ext]=fileparts(file);
assert(strcmpi(ext,'.tir')&&isfile(file),'fsd:tire:InvalidMathWorksImport','Existing .tir file required.');
assert(~isempty(which('tireModel'))&&~isempty(which('tireData')), ...
    'fsd:tire:MissingMathWorksTireAPI','Install/enable Extended Tire Features for Vehicle Dynamics Blockset.');
% Only the provider interprets the file; no custom .tir parser is used.
model=tireModel.import(file);
assert(isscalar(model),'fsd:tire:InvalidMathWorksImport','One tire model required.');
parameters=struct(model);
if isfield(parameters,'SourcePath'), parameters=rmfield(parameters,'SourcePath'); end
assert(plain(parameters),'fsd:tire:InvalidMathWorksImport','Provider parameters must contain plain values only.');
[family,variant]=identify(parameters);
addons=matlab.addons.installedAddons;
hit=string(addons.Identifier)=="VDYNTIRE";
assert(nnz(hit)==1&&addons.Enabled(hit),'fsd:tire:MissingMathWorksTireAPI', ...
    'Enabled VDYNTIRE package and its version must be identifiable.');
provider=struct('name',"MathWorks",'package', ...
    "Extended Tire Features for Vehicle Dynamics Blockset", ...
    'identifier',"VDYNTIRE",'packageVersion',string(addons.Version(hit)), ...
    'matlabVersion',string(version),'matlabRelease',string(version('-release')));
descriptor=struct('schemaVersion',"0.22.0",'kind',"MathWorksTireDescriptor", ...
    'provider',provider,'family',family,'variant',variant, ...
    'coordinateSystem',"ISO",'units',"SI",'sourceFilename',string(name)+string(ext), ...
    'sourceText',fileread(file),'parameters',parameters,'sourceNote',sourceNote, ...
    'evidence',"IMPORTED_UNVERIFIED",'interpretation', ...
    "Parameters are MathWorks import interpretation; source completeness, calibration and predictive validity are not certified.");
descriptor.identity=descriptor;
end

function [family,variant]=identify(p)
% Read documented parameter values from struct(model), never protected Type.
if isfield(p,'FITTYP')&&isscalar(p.FITTYP)&&ismember(p.FITTYP,[6,62])
    family="MAGIC_FORMULA"; variant="MF"+string(p.FITTYP);
    % Public new('MF52')->export/import in VDYNTIRE26.2.3 emits FITTYP=6.
    if p.FITTYP==6, variant="MF52"; end
elseif isfield(p,'modified_dugoff')&&isscalar(p.modified_dugoff)
    family="DUGOFF"; variant="DUGOFF_NOMINAL";
    if p.modified_dugoff, variant="DUGOFF_MODIFIED"; end
elseif all(isfield(p,{'muMIN','muMAX','ScaleFctr'}))
    family="FIALA"; variant="FIALA";
else
    error('fsd:tire:UnsupportedMathWorksFamily','Unrecognized public parameter signature; no family conversion attempted.');
end
end
function tf=textScalar(v)
tf=(isstring(v)&&isscalar(v)&&~ismissing(v))||(ischar(v)&&(isrow(v)||isempty(v)));
end
function tf=plain(v)
if isstruct(v), tf=all(cellfun(@plain,struct2cell(v)),'all');
elseif iscell(v), tf=all(cellfun(@plain,v),'all');
else, tf=isnumeric(v)||islogical(v)||ischar(v)||isstring(v);
end
end
