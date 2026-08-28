function stats = calculate_parametric_surface_mss(X,Y,Z,windDirectionDeg,options)
%CALCULATE_PARAMETRIC_SURFACE_MSS Area-weighted slopes from physical facets.
%   Slopes are computed from the actual (X,Y,Z) triangle normals, so any
%   horizontal Lie/Riesz displacement is included. Cox-Munk-compatible MSS
%   uses upward, nonvertical facets and horizontal projected-area weights.

arguments
    X (:,:) double
    Y (:,:) double
    Z (:,:) double
    windDirectionDeg (1,1) double
    options.ExcludedVertexMask (:,:) logical = false(size(X))
    options.MinimumNormalZ (1,1) double = 0.02
end

assert(isequal(size(X),size(Y),size(Z),size(options.ExcludedVertexMask)), ...
    'X, Y, Z, and ExcludedVertexMask must have identical sizes.');

[nRows,nColumns] = size(X);
[column,row] = meshgrid(1:nColumns-1,1:nRows-1);
v00 = sub2ind([nRows,nColumns],row(:),column(:));
v10 = sub2ind([nRows,nColumns],row(:),column(:)+1);
v01 = sub2ind([nRows,nColumns],row(:)+1,column(:));
v11 = sub2ind([nRows,nColumns],row(:)+1,column(:)+1);
faces = [v00,v10,v11; v00,v11,v01];

vertices = [X(:),Y(:),Z(:)];
edge1 = vertices(faces(:,2),:)-vertices(faces(:,1),:);
edge2 = vertices(faces(:,3),:)-vertices(faces(:,1),:);
areaVector = cross(edge1,edge2,2);
areaVectorNorm = vecnorm(areaVector,2,2);
normalZ = areaVector(:,3)./max(areaVectorNorm,eps);

excluded = any(options.ExcludedVertexMask(faces),2);
finiteFacet = all(isfinite(areaVector),2) & areaVectorNorm > eps;
upward = normalZ > options.MinimumNormalZ;
valid = finiteFacet & upward & ~excluded;

projectedArea = 0.5*areaVector(:,3);
slopeX = -areaVector(:,1)./areaVector(:,3);
slopeY = -areaVector(:,2)./areaVector(:,3);

windAngle = deg2rad(windDirectionDeg);
slopeAlong = slopeX*cos(windAngle)+slopeY*sin(windAngle);
slopeCross = -slopeX*sin(windAngle)+slopeY*cos(windAngle);

weights = projectedArea(valid);
assert(any(valid) && sum(weights) > 0, ...
    'No upward nonvertical facets remain for MSS calculation.');

along = slopeAlong(valid);
crosswind = slopeCross(valid);
meanAlong = sum(weights.*along)/sum(weights);
meanCross = sum(weights.*crosswind)/sum(weights);

stats.mssAlong = sum(weights.*(along-meanAlong).^2)/sum(weights);
stats.mssCross = sum(weights.*(crosswind-meanCross).^2)/sum(weights);
stats.mssTotal = stats.mssAlong+stats.mssCross;
stats.meanSlopeAlong = meanAlong;
stats.meanSlopeCross = meanCross;
stats.validProjectedArea = sum(weights);
stats.validFacetCount = nnz(valid);
stats.excludedFacetCount = nnz(excluded);
stats.nearVerticalFacetCount = nnz(finiteFacet & ...
    abs(normalZ) <= options.MinimumNormalZ);
stats.overturnedFacetCount = nnz(finiteFacet & normalZ < 0);
stats.overturnedSurfaceAreaFraction = sum(0.5*areaVectorNorm( ...
    finiteFacet & normalZ < 0))/sum(0.5*areaVectorNorm(finiteFacet));
end

