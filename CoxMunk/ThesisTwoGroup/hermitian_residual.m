function residual = hermitian_residual(H)
%HERMITIAN_RESIDUAL Normalized H(-k)-conj(H(k)) mismatch.

[Ny,Nx] = size(H);
negativeX = [1,Nx:-1:2];
negativeY = [1,Ny:-1:2];
scale = max(max(abs(H),[],'all'),realmin);
residual = max(abs(H-conj(H(negativeY,negativeX))),[],'all')/scale;
end
