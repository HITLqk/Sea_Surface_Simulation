function [along,crosswind,cumulative] = integrated_elfouhaily_mss(U10,kMaximum,cfg)
%INTEGRATED_ELFOUHAILY_MSS Directional MSS integrated to kMaximum [rad/m].

k = logspace(-5,log10(kMaximum),40000)';
K = k';
[PsiAlong,~] = thesis_elfouhaily_spectrum(K,K,zeros(size(K)), ...
    U10,cfg.inverseWaveAge,cfg.windDirectionDeg,cfg);
[PsiCross,~] = thesis_elfouhaily_spectrum(K,zeros(size(K)),K, ...
    U10,cfg.inverseWaveAge,cfg.windDirectionDeg,cfg);
sumCuts = PsiAlong+PsiCross;
S = pi*K.*sumCuts;
delta = (PsiAlong-PsiCross)./max(sumCuts,realmin);
alongIntegrand = K.^2.*S.*(0.5+0.25*delta);
crossIntegrand = K.^2.*S.*(0.5-0.25*delta);
along = trapz(K,alongIntegrand);
crosswind = trapz(K,crossIntegrand);
if nargout > 2
    cumulative = table(k,cumtrapz(k,alongIntegrand'), ...
        cumtrapz(k,crossIntegrand'),'VariableNames', ...
        {'K','AlongMss','CrossMss'});
    cumulative.TotalMss = cumulative.AlongMss+cumulative.CrossMss;
end
end
