function reference = davis_2025_mss_reference(windSpeeds)
%DAVIS_2025_MSS_REFERENCE Band-limited hurricane MSS parameterization.
%   The fit is valid for U10 in [2,52] m/s and k in [0.01,1] rad/m.

U10 = windSpeeds(:);
assert(all(U10 >= 2 & U10 <= 52), ...
    'Davis 2025 reference is only valid for U10 in [2,52] m/s.');
MssBandLimited = 0.0250*tanh(0.0476*U10)-0.0020;
MssAligned = (0.0236+0.0037)*tanh(0.0502*U10)-0.0028;
MssCrossing = 0.0236*tanh(0.0502*U10)-0.0028;
PlantLower = repmat(0.04,size(U10));
PlantCenter = repmat(0.08,size(U10));
PlantUpper = repmat(0.12,size(U10));
reference = table(U10,MssBandLimited,MssAligned,MssCrossing, ...
    PlantLower,PlantCenter,PlantUpper);
end
