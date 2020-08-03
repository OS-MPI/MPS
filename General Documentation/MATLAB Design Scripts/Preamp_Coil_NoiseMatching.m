%% Assume optimum noise is when thermal noise = pre-amp noise
function [IdealTurns,IdealR] = Preamp_Coil_NoiseMatching(PreampNoise,WireDia)
% Enter preamp noise in nV/sqrt(Hz)
% Enter wire diameter in mm




Resistivity = 1.7e-8; %Ohm-meter

WireDia = WireDia/1000;%meters Remove this line if you enter wire in meters
CoilMeanDia =10;%mm
CoilMeanDia= CoilMeanDia/1000;%meters
WireArea = (pi/4*WireDia^2);%meters^2

JohnsonNoise = @(N)0.13*sqrt(pi*CoilMeanDia*N*Resistivity/WireArea);%nV/sqrt(Hz) at room temp. This approximation is from Wikipedia



%% If current noise is not included
% Turns = @(Noise) (Noise/0.13).^2*WireArea/(pi*CoilMeanDia*Resistivity); %Function to solve for ideal turns as a function of preamp noise
% Resist = @(Noise) (Noise/0.13).^2; %Function to solve for ideal resistance to match noise generation

% IdealTurns = Turns(PreampNoise); 
% IdealR = Resist(PreampNoise);

%% If current noise is included
Quadratic = @(A,B,C) [(-B+sqrt(B^2-4*A*C))/(2*A),(-B-sqrt(B^2-4*A*C))/(2*A)];


in = 1e-3; %nv/sqrt(Hz) taken from a datasheet
IdealR = (real(Quadratic(in^2,0.13^2,-PreampNoise^2)));
IdealR = IdealR(IdealR>0);

IdealTurns = (real(Quadratic((in*pi*CoilMeanDia*Resistivity/WireArea)^2,0.13^2*pi*CoilMeanDia*Resistivity/WireArea,-PreampNoise^2)));
IdealTurns = IdealTurns(IdealTurns>0);
