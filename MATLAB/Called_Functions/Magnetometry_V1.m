function [Output,AnalysisParams] = Magnetometry_V1(SPION_Info,Parameters, SigDataIn,  BiasDataIn,smoothPts,LineStyle,Normalize)

if nargin<7;Normalize=0;end
% Update to take in variables describing system 
% Also implement s = spectrogram(x) to make code more efficient. 


Conc = SPION_Info.Concentration;

fDrive = Parameters.fDrive;
fBias = Parameters.fBias;
fsInterp = Parameters.fsInterp;

PointsPerDrivePrd = fsInterp/fDrive;

smoothPts = ceil(smoothPts/PointsPerDrivePrd)*PointsPerDrivePrd;
AnalysisParams.SmoothingPoints = smoothPts;
Gain = Parameters.PreAmpGain; %Preamp gain
% Turns_Rx = Parameters.PreAmpTurnCount; %turns on half of gradiometer
Turns_Rx =450;
Wire_D_Rx = 0.15e-3;%m
LayerGap_Rx= Wire_D_Rx; 
Solenoid_Length_Rx = 10e-3;
TubeDiam_Rx = .006; %Sets the ID of the bias coil

[P_Rx] = Coil_Sensitivity_2(Wire_D_Rx,LayerGap_Rx,Solenoid_Length_Rx,Turns_Rx,TubeDiam_Rx);
AnalysisParams.RxSensitivity =P_Rx; %In 1/m (or Amperes per meter per amp)

SampleVolume = SPION_Info.Volume; %m^3
DataSig = SigDataIn/(P_Rx*Gain*Parameters.DriveAmp_mT/1000*2*pi*fDrive*SampleVolume*Conc);% Volts/(1/m*UL*T/sec*m^3*kg/m^3) = Volts/(T*kg/(m*sec)) = Volts/((V*sec/m^2)*kg/(m*sec)) =1/(kg/(m^3))= m^3/(kg) = 1/concentration 

AnalysisParams.TotalScalingFactor = 1/(P_Rx*Gain*Parameters.DriveAmp_mT/1000*fDrive*SampleVolume*Conc);


VoltsPerAmp = 0.04;
TeslaPerAmp = .006;

BiasSig = BiasDataIn-mean(BiasDataIn);%Subtracting off DC offset
BiasSig = BiasSig/VoltsPerAmp*TeslaPerAmp; %Defining BiasSig in terms of Tesla of bias field

LPBias = smooth(BiasSig,smoothPts);
LPBias = LPBias(round(smoothPts/2):end-round(smoothPts/2));

[SPG,fSPG,~]= spectrogram(DataSig,smoothPts,smoothPts-1,smoothPts,fsInterp); %SPG is the spectrogram and fSPG is the freqs. that correspond

fDriveSelectSig = abs(SPG(fSPG==fDrive,:)); %taking the magnitude of the specrogram at all of the points in time at the drive frequency

fDriveSelectSig = fDriveSelectSig(1:length(LPBias)); %Matching lengths

% figure,plot(LPBias(startpoint:endpoint)./max(LPBias))
% hold on
% plot(LPCroppedSig,'r')

% figure,plot(LPBiasCrop./max(LPBiasCrop),LPCroppedSig)
% figure,plot(LPBias(startpoint:endpoint)./max(LPBias),trapz(LPBias(startpoint:endpoint)./max(LPBias),LPCroppedSig))




m = zeros(round(fsInterp/(2*fBias)),1);%m = magnetic moment
StartingPoint = find(abs(LPBias(1:round(length(LPBias)/2))) == min(abs(LPBias(1:round(length(LPBias)/2)))), 1 )+round(fsInterp/(4*fBias)); %location in the vector closest to zero- DC bias
for K=1:2
    
    if K==2; StartingPoint=StartingPoint+round(fsInterp/(2*fBias)); end
    if K==1
        Chi = repmat(fDriveSelectSig,1,2);
        LPBias = repmat(LPBias,1,2);
    end
    
    BiasField = LPBias(StartingPoint:StartingPoint+round(fsInterp/(2*fBias)));
    MagSuscept = Chi(StartingPoint:StartingPoint+round(fsInterp/(2*fBias)));
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
    figure(95),subplot(2,1,1),plot(BiasField(1:i)*1000,MagSuscept(1:i)/max(abs(MagSuscept(1:i))))
    ylabel('dM/dH (Normalized)')
else
    figure(95),subplot(2,1,1),plot(BiasField(1:i)*1000,MagSuscept(1:i))
    ylabel('dM/dH [UL/(kg/m^3)]')
end
hold on
xlabel('External Magnetic Field [T]')

m(:,1)=flipud(m(:,1));
m2=mean(m,2);
Mag = m2/(4*pi*10e-7);% Conc is is mg/ml which is also kg/m^3
if Normalize==1
    figure(95),subplot(2,1,2),plot(BiasField(2:end)*1000,Mag/max(abs(Mag)),LineStyle,'LineWidth',1.3)
    ylabel('Magnetization [a.u.]')
else
    figure(95),subplot(2,1,2),plot(BiasField(2:end)*1000,Mag,LineStyle,'LineWidth',1.3)
    ylabel('Magnetization [\mu_0*Am^2/kg]')
end
xlabel('External Magnetic Field [mT]')


hold on


Output.BiasFieldPlot = BiasField(:);
Output.Susceptibility = MagSuscept(:);
Output.Magnetization = Mag(:);
end