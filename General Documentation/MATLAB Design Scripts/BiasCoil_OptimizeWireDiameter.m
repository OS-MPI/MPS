clear; clc;
close all;

set(0,'DefaultFigureWindowStyle','docked');


% WireDList = .0001:.0001:.01; %The list of wire diameters to test
WireDList= .00083; %Meters
CoilCost = zeros(1,length(WireDList));

for j = 1:length(WireDList)
    Solenoid_Length = .096;%meters
    TubeDiam = .054; %Sets the ID of the bias coil
    TubeCircum = pi*TubeDiam;%meters
    
    ResistanceGoal = 4.7;%Ohms
    CuResistivity = 1.7e-8; %ohm*m
    
    ILim = 5; %The maximum current the amplifier allows
    
    Wire_D = WireDList(j);%meters
    Wire_A = pi/4*Wire_D^2;%m^2
    Wire_L = ResistanceGoal*Wire_A/CuResistivity; %solving for total wire length
    
    TurnsPerLayer = Solenoid_Length/Wire_D;
    Turns = Wire_L/TubeCircum;
    Layers = ceil(Turns/TurnsPerLayer);
    
    LayerGap = .004*2;
    
    CuDensity = 9e3; %kg/m^3
    CuCostPerkg = 30;%USD
    
    CoilMass = Wire_A*Wire_L*CuDensity;
    CoilVol =  Wire_A*Wire_L;
    
    VolumetricPowerDensity = ILim^2*ResistanceGoal/CoilVol; %volumetric power assuming ILim @ DC
    CoilCost(j) = CoilMass*CuCostPerkg;
   
    B_Rx= 0;
    if Layers>2
        TotalLength = TurnsPerLayer*(ones(1,round(Layers))*TubeCircum+floor((0:round(Layers)-1)/2)*LayerGap*pi+2*(0:round(Layers)-1)*Wire_D*pi);
        %total length is a vector of lengths for each layer of wire where
        %the first position is the first layer
        CurrentLength = 0;
        i = 0;
        while CurrentLength<Wire_L %doesnt allow overshooting or having partial layers
            i = i+1;
            ii = i-.1;
            K =floor(ii/2); %to double count, so 1,1,2,2,3,3,....
            [B(i,:), B_Rx(i)] = LayerField(Wire_D,TubeDiam+(K)*LayerGap+i*Wire_D,Solenoid_Length);
            %B is the field along the axis, B_Rx is the |B| at the sample
            CurrentLength = CurrentLength+TotalLength(K+1); %counting total length
            
        end
    end
    B_Rx_Tot(j) = sum(B_Rx); %the sum of the field contributions from each layer
end



function [B,B_Rx] = LayerField(wire_d,Turn_diam,L)
radius = Turn_diam/2;

mu0 = 4*pi*1e-7; % [Tm/A]
n = 1/wire_d; %turn density

x = linspace(0,L,1e3);
Ipk = 1;

x1 = 0;%Front face of solenoid is 0, x1 can be negative values to plot values over a larger FOV
x2 = L; %End face of region is L if you want to only plot until the end of the solenoid

term1 = (x-x1)./sqrt((x-x1).^2 + radius^2);
term2 = (x-x2)./sqrt((x-x2).^2 + radius^2);
B = (Ipk*mu0*n/2)*(term1-term2);


B_Rx = B(850); %This line selects where the center of the sample will be in this case B(850)...
               % represents 85% the length of the solenoid because there
               % are 1000 points being solved for across the solenoid's
               % axis
figure(1), plot(x,B) %comment out this line if you test multiple wire diamters! Or you will plot lots of lines on the figure...
hold on
end

