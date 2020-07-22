function [BiasField,MagSuscept,Mag] = Magnetometry_V0(Data,startpoint,endpoint,smoothPts,Fb,Conc,Fs,Fd, Line,DrivemT,Normalize)
Gain = 100; %Preamp gain
Turns_Rx = 450; %turns on half of gradiometer
Wire_D_Rx = 0.15e-3;%m
LayerGap_Rx= Wire_D_Rx; 
Solenoid_Length_Rx = 10e-3;
TubeDiam_Rx = .006; %Sets the ID of the bias coil

[P_Rx] = Coil_Sensitivity_2(Wire_D_Rx,LayerGap_Rx,Solenoid_Length_Rx,Turns_Rx,TubeDiam_Rx);


BulbVol = 18e-9; %m^3
DataScaled = Data(:,1)/(P_Rx*Gain*DrivemT/1000*Fd*BulbVol);

VoltsPerAmp = 0.04;
TeslaPerAmp = .006;

DataSig = DataScaled;
BiasSig = Data(:,2);
LPConv = ones(smoothPts,1);
BiasSig = BiasSig-mean(BiasSig);%Subtracting off DC offset
BiasSig = BiasSig/VoltsPerAmp*TeslaPerAmp; %Defining BiasSig in terms of Tesla of bias field

LPBias = conv(LPConv',(BiasSig)')/smoothPts;%Low pass filtering by convolving with a series of 1s. This could be changed to a running average or another low pass method. 
LPBias = LPBias(smoothPts:end);

LPBiasCrop = LPBias(startpoint:endpoint); %Typically 1 and end. Other versions used this line more
LPCroppedSig=FourierAnalyze_v2([DataSig BiasSig],Fs,Fd,smoothPts,1);%Evaluates the succeptibility by taking an FT and looking at the amplitude of the fundamental 
LPCroppedSig = LPCroppedSig(1:length(LPBiasCrop)); %Matching lengths

% figure,plot(LPBias(startpoint:endpoint)./max(LPBias))
% hold on
% plot(LPCroppedSig,'r')

% figure,plot(LPBiasCrop./max(LPBiasCrop),LPCroppedSig)
% figure,plot(LPBias(startpoint:endpoint)./max(LPBias),trapz(LPBias(startpoint:endpoint)./max(LPBias),LPCroppedSig))




m = zeros(round(Fs/(2*Fb)),1);%m = magnetic moment
StartingPoint = find(abs(LPBiasCrop(1:round(length(LPBiasCrop)/2))) == min(abs(LPBiasCrop(1:round(length(LPBiasCrop)/2)))), 1 )+round(Fs/(4*Fb)); %location in the vector closest to zero- DC bias
for K=1:2
    
    if K==2; StartingPoint=StartingPoint+round(Fs/(2*Fb)); end
    if K==1
        Chi = repmat(LPCroppedSig,1,2);
        LPBiasCrop = repmat(LPBiasCrop,1,2);
    end
    
    BiasField = LPBiasCrop(StartingPoint:StartingPoint+round(Fs/(2*Fb)));
    MagSuscept = Chi(StartingPoint:StartingPoint+round(Fs/(2*Fb)));
%     figure(2),plot(Y)
    %hold on
    for i = 2:length(BiasField)
        m(i-1,K) = trapz(BiasField(1:i),MagSuscept(1:i));
    end
    m(:,K) = m(:,K)-m(round(length(m)/2),K);
    shifting = (max(m(:,K))+min(m(:,K)))/2;
    m(:,K)=m(:,K)-shifting;

    
end
if Normalize==1
    figure(95),subplot(2,1,1),plot(BiasField(1:i),MagSuscept(1:i)/max(abs(MagSuscept(1:i))))
    ylabel('dM/dH (Normalized)')
else
    figure(95),subplot(2,1,1),plot(BiasField(1:i),MagSuscept(1:i))
    ylabel('dM/dH')
end
hold on
xlabel('External Magnetic Field [T]')

m(:,1)=flipud(m(:,1));
m2=mean(m,2);
Mag = m2/(4*pi*10e-7)/Conc;% Conc is is mg/ml which is also kg/m^3
if Normalize==1
    figure(95),subplot(2,1,2),plot(BiasField(2:end),Mag/max(abs(Mag)),Line,'LineWidth',1.3)
    ylabel('Magnetization [a.u.]')
else
    figure(95),subplot(2,1,2),plot(BiasField(2:end),Mag,Line,'LineWidth',1.3)
    ylabel('Magnetization [Am^2/kg]')
end
xlabel('External Magnetic Field [T]')

%legend('VivoTrax', 'Ocean NanoTech', 'Location', 'SE')
hold on
end