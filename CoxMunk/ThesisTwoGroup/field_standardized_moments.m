function moments = field_standardized_moments(values)
%FIELD_STANDARDIZED_MOMENTS Toolbox-free skewness and excess kurtosis.

values = values(:);
centered = values-mean(values);
variance = mean(centered.^2);
if variance <= realmin
    moments.skewness = 0;
    moments.excessKurtosis = 0;
    return;
end
moments.skewness = mean(centered.^3)/variance^(3/2);
moments.excessKurtosis = mean(centered.^4)/variance^2-3;
end
