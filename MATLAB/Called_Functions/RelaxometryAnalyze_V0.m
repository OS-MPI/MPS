%% Relaxometery
clear
% load('VivoAgar_15mTDrive_75mTBias_25kHz_Relx.mat') ; Col='r';
% load('Vivo2020_15mTDrive_75mTBias_25kHz_Relx.mat') ; Col = 'b';
% load('Ocean_15mTDrive_75mTBias_25kHz_Relx.mat'); Col = 'g';
load('Azano_15mTDrive_75mTBias_25kHz_Relx.mat'); Col = 'm';

Data_Sig = AllData;
Fd = 24.3e3;
% Fd = 10.7e3;
Fd = fDrive;
fBias = 4;
Fs = fs;
Conc = .5;
L = length(Data_Sig);             % Length of signal
t = linspace(0,L/fs,L);
ScaleFactor = 4;
fs = fs*ScaleFactor;
tt = linspace(t(1),t(end),length(t)*ScaleFactor);
Data_Sig = interp1(t,AllData,tt,'spline');
AllDataBias = interp1(t,AllDataBias,tt);
AllDataBias = reshape(AllDataBias,size(Data_Sig,1),size(Data_Sig,2));

t = tt;
if mod(L,2)~=0
    Data_Sig = Data_Sig(1:end-1);
    L=L-1;
end
Y_signal = fft(Data_Sig);
P2 = abs(Y_signal/L);
Mag = P2(1:L/2+1);
Phase = angle(Y_signal(1:L/2+1));
Phase(Mag<1e-6)=0;
f = fs*(0:(L/2))/L; %Freq. vector
fs =fs/2;

FundamentalFit = -1*cos(2*pi*f(Mag==max(Mag))*t+Phase(Mag==max(Mag)));

Shift=220;
SmoothBias = smooth(AllDataBias,20);
PaddedBias = [SmoothBias(end-Shift:end);SmoothBias(1:end-Shift-1)];
PaddedBias = reshape(PaddedBias,size(Data_Sig,1),size(Data_Sig,2));

LeftIndex = diff(Data_Sig)>0;

RightIndex = diff(Data_Sig)<0;

LSigData = Data_Sig(LeftIndex);
tL = t(LeftIndex);
RSigData = Data_Sig(RightIndex);
tR = t(RightIndex);
LBiasData = PaddedBias(LeftIndex);
RBiasData = PaddedBias(RightIndex);
% fs = round(fs/2);
if length(LSigData)>length(RSigData)
    LSigData = LSigData(1:length(RSigData));
    LBiasData= LBiasData(1:length(RSigData));
    tL=tL(1:length(RSigData));
elseif length(RSigData)>length(LSigData)
    RSigData = RSigData(1:length(LSigData));
    RBiasData= RBiasData(1:length(LSigData));
    tR=tR(1:length(LSigData));
end
LData = repmat([LSigData' LBiasData'],2,1);
RData = repmat([RSigData' RBiasData'],2,1);

DataStack(:,:,1) = LData;
DataStack(:,:,2) = RData;
clear LData RData

%%

smoothPts = 100;

Gain = 100;
Turns_Rx = 450;
Wire_D_Rx = 0.15e-3;%m
LayerGap_Rx= Wire_D_Rx;
Solenoid_Length_Rx = 10e-3;
TubeDiam_Rx = .006; %Sets the ID of the bias coil

[P_Rx] = Coil_Sensitivity_2(Wire_D_Rx,LayerGap_Rx,Solenoid_Length_Rx,Turns_Rx,TubeDiam_Rx);

for LR = 1:2
    
    BulbVol = 18e-9; %m^3
    DataScaled = DataStack(:,1,LR)/(P_Rx*Gain*DrivemT/1000*Fd*BulbVol);
    
    
    DataSig = DataScaled;
    BiasSig = DataStack(:,2,LR);
    LPConv = ones(smoothPts,1);
    BiasSig = BiasSig-mean(BiasSig);
    BiasSig = BiasSig/.04*.006;
    
    LPBias = conv(LPConv',(BiasSig)')/smoothPts;
    LPBias = LPBias(smoothPts:end);
    
    LPBiasCrop = LPBias;
    LPCroppedSig = smooth(abs(DataSig),smoothPts);
    LPCroppedSig = LPCroppedSig(1:length(LPBiasCrop));
    
    SpeedFac = 100;
    
    m = zeros(round(fs/(2*fBias)/SpeedFac),2);%m = magnetic moment
    for K=1:2
        StartingPoint = find(abs(LPBiasCrop) == min(abs(LPBiasCrop)), 1 )+round(fs/(4*fBias)); %location in the vector closest to zero- DC bias
        if K==2; StartingPoint=StartingPoint+round(fs/(2*fBias)); end
        Chi = repmat(LPCroppedSig,1,2);
        Chi = smooth(Chi,smoothPts);
        LPBiasCrop = repmat(LPBiasCrop,1,2);
        
        X = LPBiasCrop(StartingPoint:StartingPoint+round(fs/(2*fBias)));
        Y = Chi(StartingPoint:StartingPoint+round(fs/(2*fBias)));
        %     figure(2),plot(Y)
        %hold on
        Count = 1;
        for i = 2:SpeedFac:length(X)
%             m(i-1,K) = trapz(X(1:i),Y(1:i));
            m(Count,K) = trapz(X(1:i),Y(1:i));
            Count = Count+1;
            

        end
        
%         m(:,K) = m(:,K)-m(round(length(m)/2),K);
        shifting = (max(m(:,K))+min(m(:,K)))/2;
        m(:,K)=m(:,K)-shifting;
        
        
        
    end
    figure(95),subplot(2,1,1),plot(X(1:i),Y(1:i),[Col '-'])
    hold on
    xlabel('External Field (T/\mu_0)')
    xlim([-.02 .02])
    ylabel('dM/dH')
    m(:,1)=flipud(m(:,1));
    m2=mean(m(:,K),2);
    
    shifting = (max(m2)+min(m2))/2;
    m2=m2-shifting;
    Mag = m2/(4*pi*10e-7)/Conc;% Conc is is mg/ml which is also kg/m^3. division by 1000 is to make mT into T
%     Mag = Mag(1:SpeedFac:length(Mag));
    figure(95),subplot(2,1,2),plot(X(2:SpeedFac:end),Mag,[Col '-'],'LineWidth',1.3)
    xlabel('External Magnetic Field /T')
    xlim([-.02 .02])
    ylabel('Magnetization [Am^2/kg]')
    %legend('VivoTrax', 'Ocean NanoTech', 'Location', 'SE')
    hold on
    
end