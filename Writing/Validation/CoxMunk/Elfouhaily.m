function [spectrum,peakWavenumber] = Elfouhaily(k,U10,age,varargin)
%ELFOUHAILY Omnidirectional unified sea-surface elevation spectrum.
%   This local copy preserves the implementation used by the original
%   cox_munk.m so the reproduction in this directory is self-contained.

phi = 0;
if nargin == 4
    phi = varargin{1}; %#ok<NASGU>
end

g = 9.81;
dragCoefficient = 0.00144;
frictionVelocity = sqrt(dragCoefficient)*U10;
minimumPhaseWavenumber = 370.0;
minimumPhaseSpeed = 0.23;
sigma = 0.08*(1+4*age^(-3));
alphaPeak = 0.006*age^(0.55);
k0 = g/(U10^2);
peakWavenumber = k0*age^2;
peakPhaseSpeed = sqrt(g/peakWavenumber);

if frictionVelocity <= minimumPhaseSpeed
    alphaMinimum = 0.01*(1+log(frictionVelocity/minimumPhaseSpeed));
else
    alphaMinimum = 0.01*(1+3*log(frictionVelocity/minimumPhaseSpeed));
end

if age <= 1
    gamma = 1.7;
else
    gamma = 1.7+6*log(age);
end

phaseSpeed = sqrt((g./k).*(1+(k/minimumPhaseWavenumber).^2));
piersonMoskowitz = exp(-5/4*(peakWavenumber./k).^2);
peakShape = exp(-1/(2*sigma^2)*(sqrt(k/peakWavenumber)-1).^2);
peakEnhancement = gamma.^peakShape;
longSide = piersonMoskowitz.*peakEnhancement.* ...
    exp(-age/sqrt(10)*(sqrt(k/peakWavenumber)-1));
shortSide = piersonMoskowitz.*peakEnhancement.* ...
    exp(-0.25*(k/minimumPhaseWavenumber-1).^2);
longWave = 0.5*alphaPeak*(peakPhaseSpeed./phaseSpeed).*longSide;
shortWave = 0.5*alphaMinimum*(minimumPhaseSpeed./phaseSpeed).*shortSide;
spectrum = (longWave+shortWave)./(k.^3);
end
