function [X,Y,m2] = MagnetometryV7(Data,startpoint,endpoint,smoothPts,Fb,Conc,Fs,Fd, Line,DrivemT)
Gain = 100;
Turns_Rx = 450;
Wire_D_Rx = 0.15e-3;%m
LayerGap_Rx= Wire_D_Rx; 
Solenoid_Length_Rx = 10e-3;
TubeDiam_Rx = .006; %Sets the ID of the bias coil

[P_Rx] = Coil_Sensitivity_2(Wire_D_Rx,LayerGap_Rx,Solenoid_Length_Rx,Turns_Rx,TubeDiam_Rx);



if length(Data)>250000
    Data = Data(1:250000,:);
end

BulbVol = 18e-9; %m^3
DataScaled = Data(:,1)/(P_Rx*Gain*DrivemT/1000*Fd*BulbVol);

%M(H) = Chi*H(t) = Chi[UL]*I[amps]*P_Tx[A/M/A]*sin(2*pi*f*t)
%dM/dt = Chi*I*P_Tx*2*pi*f*cos(2*pi*f*t)
%dM/dt*mu0 = Chi* DrivemT*f*cos(2*pi*f*t)
%V(t) = P_Rx*Gain*mu0*dM/dt*Vol =  P_Rx*Gain* Chi* DrivemT*f*cos(2*pi*f*t)*Vol
%V(t)/(P_Rx*Gain*DrivemT*f*Vol) = Chi*cos(2*pi*f*t)
%[kg*m^2*s^-3*A^-1]/[m^-1*kg*A^-1*s^-2*s*-1*m^3] 

%dM/dt = Chi*I*P_Tx*2*pi*f*cos(2*pi*f*t)





DataSig = DataScaled;
BiasSig = Data(:,2);
LPConv = ones(smoothPts,1);
BiasSig = BiasSig-mean(BiasSig);
BiasSig = BiasSig/.04*.006;

LPBias = conv(LPConv',(BiasSig)')/smoothPts;
LPBias = LPBias(smoothPts:end);

LPBiasCrop = LPBias(startpoint:endpoint);
LPCroppedSig=FourierAnalyze_v2([DataSig BiasSig],Fs,Fd,smoothPts,1);
LPCroppedSig = LPCroppedSig(1:length(LPBiasCrop));

% figure,plot(LPBias(startpoint:endpoint)./max(LPBias))
% hold on
% plot(LPCroppedSig,'r')

figure,plot(LPBiasCrop./max(LPBiasCrop),LPCroppedSig)
% figure,plot(LPBias(startpoint:endpoint)./max(LPBias),trapz(LPBias(startpoint:endpoint)./max(LPBias),LPCroppedSig))




m = zeros(round(Fs/(2*Fb)),1);%m = magnetic moment
for K=1:2
    StartingPoint = find(abs(LPBiasCrop) == min(abs(LPBiasCrop)), 1 )+round(Fs/(4*Fb)); %location in the vector closest to zero- DC bias
    if K==2; StartingPoint=StartingPoint+round(Fs/(2*Fb)); end
    Chi = repmat(LPCroppedSig,1,2);
    LPBiasCrop = repmat(LPBiasCrop,1,2);
    
    X = LPBiasCrop(StartingPoint:StartingPoint+round(Fs/(2*Fb)));
    Y = Chi(StartingPoint:StartingPoint+round(Fs/(2*Fb)));
%     figure(2),plot(Y)
    %hold on
    for i = 2:length(X)
        m(i-1,K) = trapz(X(1:i),Y(1:i));
    end
    m(:,K) = m(:,K)-m(round(length(m)/2),K);
    shifting = (max(m(:,K))+min(m(:,K)))/2;
    m(:,K)=m(:,K)-shifting;

    
end
figure(95),subplot(2,1,1),plot(X(1:i),Y(1:i))
hold on
xlabel('External Magnetic Field [T]')
ylabel('dM/dH')
m(:,1)=flipud(m(:,1));
m2=mean(m,2);
Mag = m2/(4*pi*10e-7)/Conc;% Conc is is mg/ml which is also kg/m^3. division by 1000 is to make mT into T
figure(95),subplot(2,1,2),plot(X(2:end),Mag,Line,'LineWidth',1.3)
xlabel('External Magnetic Field [T]')
ylabel('Magnetization [Am^2/kg]')
%legend('VivoTrax', 'Ocean NanoTech', 'Location', 'SE')
hold on
end