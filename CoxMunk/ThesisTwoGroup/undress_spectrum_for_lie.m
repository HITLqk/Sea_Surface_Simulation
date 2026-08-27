function [PsiInput,history] = undress_spectrum_for_lie( ...
    PsiTarget,KX,KY,K,dk,U10,kp,cfg)
%UNDRESS_SPECTRUM_FOR_LIE Diagnostic iterative spectral undressing.
%   This smooth radial ratio iteration is a numerical diagnostic framework,
%   not a claim of equivalence to a rigorous literature inversion.

PsiInput = max(PsiTarget,0);
Iteration = (1:cfg.undressingIterations)';
MedianCorrection = zeros(size(Iteration));
MaximumLogMismatch = zeros(size(Iteration));

positiveK = K(K > 0 & PsiTarget > 0);
edges = logspace(log10(min(positiveK)),log10(max(positiveK)), ...
    cfg.undressingRadialBins+1);
centers = sqrt(edges(1:end-1).*edges(2:end));

for iteration = 1:cfg.undressingIterations
    outputPsd = zeros(size(PsiTarget));
    for seed = reshape(cfg.undressingSeeds,1,[])
        rng(seed+1000*iteration,'twister');
        [Hinput,~] = sample_hermitian_spectrum(PsiInput,dk,dk);
        Houtput = apply_modified_lie_transform(Hinput,KX,KY,K,U10,kp,cfg);
        outputPsd = outputPsd+abs(Houtput).^2/dk^2;
    end
    outputPsd = outputPsd/numel(cfg.undressingSeeds);

    radialCorrection = ones(size(centers));
    radialMismatch = ones(size(centers));
    for bin = 1:numel(centers)
        selected = K >= edges(bin) & K < edges(bin+1) & PsiTarget > 0;
        if any(selected,'all')
            targetPower = sum(PsiTarget(selected));
            outputPower = sum(outputPsd(selected));
            radialCorrection(bin) = targetPower/max(outputPower,realmin);
            radialMismatch(bin) = outputPower/max(targetPower,realmin);
        end
    end
    radialCorrection = movmean(radialCorrection, ...
        cfg.undressingSmoothingWindow,'Endpoints','shrink');
    radialCorrection = min(max(radialCorrection, ...
        cfg.undressingCorrectionLimits(1)),cfg.undressingCorrectionLimits(2));
    correction2d = interp1(log(centers),radialCorrection,log(max(K,realmin)), ...
        'linear',1);
    PsiInput = max(PsiInput.*correction2d,0);
    PsiInput(PsiTarget == 0) = 0;
    MedianCorrection(iteration) = median(radialCorrection);
    MaximumLogMismatch(iteration) = max(abs(log(max(radialMismatch,realmin))));
end
history = table(Iteration,MedianCorrection,MaximumLogMismatch);
end
