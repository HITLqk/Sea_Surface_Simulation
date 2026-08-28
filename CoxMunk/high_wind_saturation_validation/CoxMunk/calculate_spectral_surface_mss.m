function stats = calculate_spectral_surface_mss(Z,KX,KY,windDirectionDeg)
%CALCULATE_SPECTRAL_SURFACE_MSS Exact periodic-grid spectral derivatives.

Zhat = fft2(Z);
slopeX = real(ifft2(1i*KX.*Zhat));
slopeY = real(ifft2(1i*KY.*Zhat));
windAngle = deg2rad(windDirectionDeg);
along = slopeX*cos(windAngle)+slopeY*sin(windAngle);
crosswind = -slopeX*sin(windAngle)+slopeY*cos(windAngle);
along = along-mean(along,'all');
crosswind = crosswind-mean(crosswind,'all');
stats.mssAlong = mean(along.^2,'all');
stats.mssCross = mean(crosswind.^2,'all');
stats.mssTotal = stats.mssAlong+stats.mssCross;
stats.meanSlopeAlong = 0;
stats.meanSlopeCross = 0;
stats.overturnedSurfaceAreaFraction = 0;
end
