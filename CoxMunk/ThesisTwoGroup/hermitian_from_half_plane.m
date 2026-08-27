function H = hermitian_from_half_plane(candidate)
%HERMITIAN_FROM_HALF_PLANE Copy one discrete half-plane to its conjugate.
%   This preserves the selected half-plane phase instead of replacing signed
%   directional multipliers by their absolute values.

[Ny,Nx] = size(candidate);
[IX,IY] = meshgrid(1:Nx,1:Ny);
negativeX = mod(Nx-(IX-1),Nx)+1;
negativeY = mod(Ny-(IY-1),Ny)+1;
linear = reshape(1:numel(candidate),size(candidate));
negativeLinear = sub2ind([Ny,Nx],negativeY,negativeX);
keep = linear <= negativeLinear;
H = zeros(size(candidate),'like',candidate);
H(keep) = candidate(keep);
H(negativeLinear(keep)) = conj(candidate(keep));
selfConjugate = linear == negativeLinear;
H(selfConjugate) = real(candidate(selfConjugate));
end
