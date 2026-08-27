function reference = two_group_mss_references(windSpeeds,cfg)
%TWO_GROUP_MSS_REFERENCES External MSS laws and generating-spectrum moments.

U10 = windSpeeds(:);
U12p5 = U10/0.98;
CoxMunkAlong = 3.16e-3*U12p5;
CoxMunkCross = 3e-3+1.92e-3*U12p5;
CoxMunkTotal = CoxMunkAlong+CoxMunkCross;

TgrsHuTotal = zeros(size(U10));
low = U10 < 7;
middle = U10 >= 7 & U10 < 13.3;
high = U10 >= 13.3;
TgrsHuTotal(low) = 14.6e-3*sqrt(U10(low));
TgrsHuTotal(middle) = 3e-3+5.12e-3*U10(middle);
TgrsHuTotal(high) = 138e-3*log10(U10(high))-84e-3;
TgrsGamma = repmat(0.864,size(U10));
TgrsHuAlong = TgrsHuTotal./(1+TgrsGamma.^2);
TgrsHuCross = TgrsHuTotal-TgrsHuAlong;

[GuerinAlong,GuerinCross] = guerin_at_winds(U10);
GuerinTotal = GuerinAlong+GuerinCross;
GuerinGamma = sqrt(GuerinCross./GuerinAlong);

ElfouhailyAlong = zeros(size(U10));
ElfouhailyCross = zeros(size(U10));
for index = 1:numel(U10)
    [ElfouhailyAlong(index),ElfouhailyCross(index)] = ...
        integrated_elfouhaily_mss(U10(index), ...
        cfg.maximumOpticalWavenumber,cfg);
end
ElfouhailyTotal = ElfouhailyAlong+ElfouhailyCross;
ElfouhailyGamma = sqrt(ElfouhailyCross./ElfouhailyAlong);

reference = table(U10,CoxMunkAlong,CoxMunkCross,CoxMunkTotal, ...
    GuerinAlong,GuerinCross,GuerinTotal,GuerinGamma, ...
    TgrsHuAlong,TgrsHuCross,TgrsHuTotal,TgrsGamma, ...
    ElfouhailyAlong,ElfouhailyCross,ElfouhailyTotal,ElfouhailyGamma);
end

function [along,crosswind] = guerin_at_winds(U10)
grid = (3:0.5:15)';
alongData = 0.01*[1.10 1.16 1.24 1.34 1.46 1.59 1.74 1.91 2.09 ...
    2.28 2.49 2.68 2.86 3.05 3.23 3.42 3.60 3.79 3.98 4.13 ...
    4.40 4.46 4.52 4.75 4.86]';
crossData = 0.01*[0.97 1.03 1.11 1.20 1.28 1.37 1.45 1.53 1.62 ...
    1.70 1.79 1.88 1.98 2.08 2.20 2.33 2.46 2.59 2.72 2.83 ...
    3.00 3.06 3.10 3.26 3.36]';
along = interp1(grid,alongData,U10,'linear',NaN);
crosswind = interp1(grid,crossData,U10,'linear',NaN);
end
