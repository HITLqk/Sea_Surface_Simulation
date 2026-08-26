function windAtTwelve = U10_U12(windAtTen)
%U10_U12 Reproduce the wind transformation used by the archived MSS plot.
%   The original project called this function but did not retain its source.
%   U12 = 1.6*U10^0.8 reproduces both Cox-Munk bounds in cox_munk.png.
%   This is a legacy figure-compatibility relation, not a recommended
%   atmospheric wind-height conversion for a new validation experiment.

validateattributes(windAtTen,{'numeric'}, ...
    {'real','finite','nonnegative'},mfilename,'windAtTen');
windAtTwelve = 1.6.*windAtTen.^0.8;
end
