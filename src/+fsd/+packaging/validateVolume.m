function valid=validateVolume(volume)
%VALIDATEVOLUME Reconstruct the explicit canonical record, including provenance.
assert(isstruct(volume) && isscalar(volume) && isfield(volume,'definitionSI'), ...
    'fsd:packaging:InvalidVolume','A PackagingVolume record is required.');
expected=fsd.packaging.createVolume(volume.definitionSI,'m');
assert(isequaln(volume,expected),'fsd:packaging:InvalidVolume','Volume differs from its canonical definition.');
valid=true;
end
