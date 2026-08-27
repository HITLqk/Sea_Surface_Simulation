function metrics = spectral_surface_metrics(H,KX,KY)
%SPECTRAL_SURFACE_METRICS Parseval-consistent slopes and MSS diagnostics.

[Ny,Nx] = size(H);
etaComplex = ifft2(H)*Nx*Ny;
sxComplex = ifft2(1i*KX.*H)*Nx*Ny;
syComplex = ifft2(1i*KY.*H)*Nx*Ny;
metrics.eta = real(etaComplex);
metrics.sx = real(sxComplex);
metrics.sy = real(syComplex);
metrics.along = sum(KX.^2.*abs(H).^2,'all');
metrics.cross = sum(KY.^2.*abs(H).^2,'all');
metrics.total = metrics.along+metrics.cross;
metrics.gamma = sqrt(metrics.cross/max(metrics.along,realmin));
metrics.spatialTotal = mean(metrics.sx.^2+metrics.sy.^2,'all');
metrics.mssRelativeError = abs(metrics.spatialTotal-metrics.total)/ ...
    max(metrics.total,realmin);
metrics.hermitianResidual = hermitian_residual(H);
metrics.imaginaryElevationResidual = max(abs(imag(etaComplex)),[],'all')/ ...
    max(max(abs(real(etaComplex)),[],'all'),realmin);
end
