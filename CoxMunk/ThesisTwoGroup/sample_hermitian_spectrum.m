function [H,white] = sample_hermitian_spectrum(Psi,dkx,dky,white)
%SAMPLE_HERMITIAN_SPECTRUM Sample Fourier-series coefficients in metres.

[Ny,Nx] = size(Psi);
if nargin < 4 || isempty(white)
    white = (randn(Ny,Nx)+1i*randn(Ny,Nx))/sqrt(2);
    negativeX = [1,Nx:-1:2];
    negativeY = [1,Ny:-1:2];
    white = (white+conj(white(negativeY,negativeX)))/sqrt(2);
end
H = sqrt(max(Psi,0)*dkx*dky).*white;
end
