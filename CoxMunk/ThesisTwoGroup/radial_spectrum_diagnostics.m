function radial = radial_spectrum_diagnostics(Hlinear,Hmodified,K,kp,cfg)
%RADIAL_SPECTRUM_DIAGNOSTICS Omnidirectional realized spectra and dressing.

positiveK = K(K > 0 & K <= cfg.lieOutputPeakMultiple*kp);
edges = logspace(log10(min(positiveK)),log10(max(positiveK)), ...
    cfg.spectralRadialBins+1);
centers = sqrt(edges(1:end-1).*edges(2:end));
linearSpectrum = nan(size(centers));
modifiedSpectrum = nan(size(centers));
for index = 1:numel(centers)
    selected = K >= edges(index) & K < edges(index+1);
    width = edges(index+1)-edges(index);
    if any(selected,'all')
        linearSpectrum(index) = sum(abs(Hlinear(selected)).^2)/width;
        modifiedSpectrum(index) = sum(abs(Hmodified(selected)).^2)/width;
    end
end
valid = isfinite(linearSpectrum) & linearSpectrum > 0;
radial.K = centers(valid)';
radial.LinearSpectrum = linearSpectrum(valid)';
radial.ModifiedSpectrum = modifiedSpectrum(valid)';
radial.LinearMssIntegrand = radial.K.^2.*radial.LinearSpectrum;
radial.ModifiedMssIntegrand = radial.K.^2.*radial.ModifiedSpectrum;
ratioValid = radial.LinearMssIntegrand >= ...
    cfg.spectralRatioMssFloorFraction*max(radial.LinearMssIntegrand);
radial.DressingRatio = nan(size(radial.LinearSpectrum));
radial.DressingRatio(ratioValid) = radial.ModifiedSpectrum(ratioValid)./ ...
    radial.LinearSpectrum(ratioValid);
end
