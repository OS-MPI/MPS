%% Assume optimum noise is when thermal noise = pre-amp noise
function [IdealTurns,IdealR] = Preamp_Coil_NoiseMatching(PreampNoise,WireDia)
% Enter preamp noise in nanovolts
% Enter wire diameter in mm




Resistivity = 1.7e-8; %Ohm-meter

WireDia = WireDia/1000;%meters Remove this line if you enter wire in meters
CoilMeanDia =10;%mm
CoilMeanDia= CoilMeanDia/1000;%meters
WireArea = (pi/4*WireDia^2);%meters^2

JohnsonNoise = @(N)0.13*sqrt(pi*CoilMeanDia*N*Resistivity/WireArea);%nV/sqrt(Hz) at room temp. This approximation is from Wikipedia


Turns = @(N) PreampNoise-JohnsonNoise(N); %Function to solve for ideal turns
Resist = @(R) PreampNoise-0.13*sqrt(R); %Function to solve for ideal resistance to match noise generation

% Syntax for following functions is: mybisect(Function, Left start point,
% Right start point, bisection iterations performed)

IdealTurns = mybisect(Turns,0,100000,50); 
IdealR = mybisect(Resist,0,10000,50);
%% If current noise is included
in = 1e-3; %nv/sqrt(Hz) taken from a datasheet
CurrentNoise = @(R) in*R;
TotalNoise = @(R) Resist(R)+CurrentNoise(R);
IdealR_Plus_Current = mybisect(TotalNoise,0,10000,50);

