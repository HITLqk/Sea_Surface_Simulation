function reference = guerin_2023_mss_reference()
%GUERIN_2023_MSS_REFERENCE IASI directional MSS values from Table 1.
%   MSS values in the paper are reported as percentages and are converted
%   here to dimensionless variances.

U10 = (3:0.5:15)';
MssAlong = 0.01*[ ...
    1.10 1.16 1.24 1.34 1.46 1.59 1.74 1.91 2.09 2.28 ...
    2.49 2.68 2.86 3.05 3.23 3.42 3.60 3.79 3.98 4.13 ...
    4.40 4.46 4.52 4.75 4.86]';
MssCross = 0.01*[ ...
    0.97 1.03 1.11 1.20 1.28 1.37 1.45 1.53 1.62 1.70 ...
    1.79 1.88 1.98 2.08 2.20 2.33 2.46 2.59 2.72 2.83 ...
    3.00 3.06 3.10 3.26 3.36]';
MssTotal = MssAlong+MssCross;

% Cox-Munk wind was measured at 12.5 m. Guerin et al. multiply it by
% approximately 0.98 when expressing the abscissa as U10.
U12p5 = U10/0.98;
CoxMunkAlong = 3.16e-3*U12p5;
CoxMunkCross = 3.0e-3+1.92e-3*U12p5;
CoxMunkTotal = CoxMunkAlong+CoxMunkCross;

reference = table(U10,MssAlong,MssCross,MssTotal, ...
    CoxMunkAlong,CoxMunkCross,CoxMunkTotal);
end
