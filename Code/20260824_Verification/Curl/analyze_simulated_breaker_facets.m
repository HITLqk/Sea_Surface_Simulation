function sample = analyze_simulated_breaker_facets(surfaceData, batch)
%ANALYZE_SIMULATED_BREAKER_FACETS Extract paired patch facet statistics.

facesAll = surfaceData.faces;
support = surfaceData.support(:);
facetSupport = mean(support(facesAll),2);
selected = facetSupport >= batch.patchFacetThreshold;
faces = facesAll(selected,:);
assert(~isempty(faces),'No facets remain after breaking-patch extraction.');

[areaB,normalBraw] = geometry(surfaceData.vertices,faces);
[area0,normal0] = geometry(surfaceData.verticesBaseline,faces);
overturnFraction = sum(areaB(normalBraw(:,3)<0))/sum(areaB);

% Guimaraes MAT files provide a single-valued visible upper patch and its
% Delaunay normals are oriented upward. Apply the same convention here for
% a like-for-like orientation-distribution comparison. The raw overturned
% area fraction is retained as a separate diagnostic.
normalB = orient_upward(normalBraw);
normal0 = orient_upward(normal0);

azimuth = surfaceData.cfg.patch.propagationDirectionDeg + ...
    batch.radar.relativeAzimuthDeg;
s = [sind(batch.radar.incidenceDeg)*cosd(azimuth), ...
    sind(batch.radar.incidenceDeg)*sind(azimuth), ...
    cosd(batch.radar.incidenceDeg)];

alphaB = acosd(min(1,max(-1,normalB*s.')));
alpha0 = acosd(min(1,max(-1,normal0*s.')));
radarAreaB = areaB.*max(cosd(alphaB),0);
radarArea0 = area0.*max(cosd(alpha0),0);
horizontalArea0 = area0.*abs(normal0(:,3));
footprintArea = sum(horizontalArea0);

sample.breakingAreaBins = weighted_bins(alphaB,areaB,batch.angleEdgesDeg);
sample.backgroundAreaBins = weighted_bins(alpha0,area0,batch.angleEdgesDeg);
sample.breakingRadarBins = weighted_bins(alphaB,radarAreaB,batch.angleEdgesDeg);
sample.backgroundRadarBins = weighted_bins(alpha0,radarArea0,batch.angleEdgesDeg);
sample.breakingCumulativeArea = arrayfun(@(d)sum(radarAreaB(alphaB<=d)), ...
    batch.toleranceDeg);
sample.backgroundCumulativeArea = arrayfun(@(d)sum(radarArea0(alpha0<=d)), ...
    batch.toleranceDeg);

sample.facetCount = size(faces,1);
sample.footprintArea = footprintArea;
sample.breakingSurfaceArea = sum(areaB);
sample.backgroundSurfaceArea = sum(area0);
sample.surfaceAreaRatio = sum(areaB)/sum(area0);
sample.overturnedAreaFraction = overturnFraction;

mask = surfaceData.breakingMask;
u = surfaceData.localU(mask);
v = surfaceData.localV(mask);
z = surfaceData.Z(mask);
sample.effectiveLength = range(v);
sample.effectiveWidth = range(u);
sample.verticalExtent = range(z);
sample.aspectRatio = sample.effectiveLength/max(sample.effectiveWidth,eps);
end

function [area,normal] = geometry(vertices,faces)
e1 = vertices(faces(:,2),:)-vertices(faces(:,1),:);
e2 = vertices(faces(:,3),:)-vertices(faces(:,1),:);
nvec = cross(e1,e2,2);
twiceArea = vecnorm(nvec,2,2);
valid = twiceArea>eps & isfinite(twiceArea);
assert(all(valid),'Degenerate facets found in the selected patch.');
area = 0.5*twiceArea;
normal = nvec./twiceArea;
end

function normal = orient_upward(normal)
flip = normal(:,3)<0;
normal(flip,:) = -normal(flip,:);
end

function bins = weighted_bins(values,weights,edges)
[~,~,index] = histcounts(values,edges);
valid = index>0;
bins = accumarray(index(valid),weights(valid),[numel(edges)-1,1],@sum,0).';
end

