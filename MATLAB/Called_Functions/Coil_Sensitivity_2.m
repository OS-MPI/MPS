function [P] = Coil_Sensitivity_2(Wire_D,LayerGap,Solenoid_Length,Turns,TubeDiam)



TubeCircum = pi*TubeDiam;%meters

TurnsPerLayer = Solenoid_Length/Wire_D;

Layers = ceil(Turns/TurnsPerLayer);

B_Rx= zeros(1,Layers);
if Layers>2
    TotalLength = TurnsPerLayer*(ones(1,round(Layers))*TubeCircum+(0:round(Layers)-1)*LayerGap*pi+2*(0:round(Layers)-1)*Wire_D*pi);
    %total length is a vector of lengths for each layer of wire where
    %the first position is the first layer
    CurrentLength = 0;
    
    for i = 1:Layers
        
        ii = i-.1;
        K =floor(ii/2); %to double count, so 1,1,2,2,3,3,....
        [~, B_Rx(i)] = LayerField(Wire_D,TubeDiam+(K)*LayerGap+i*Wire_D,Solenoid_Length);
        %B is the field along the axis, B_Rx is the |B| at the sample
        CurrentLength = CurrentLength+TotalLength(K+1); %counting total length
        
    end
end
B_Rx = sum(B_Rx); %the sum of the field contributions from each layer

P = B_Rx/(4*pi*10e-7); %P is the coil sensitivity 

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


B_Rx = max(B); %This line selects where the center of the sample will be in this case B(850)...
% represents 85% the length of the solenoid because there
% are 1000 points being solved for across the solenoid's
% axis

end

