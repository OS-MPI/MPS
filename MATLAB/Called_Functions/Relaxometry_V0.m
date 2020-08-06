function [Outputs,Colors] = Relaxometry_V0(Data_Sig,ExternalField,Fd,fs,InterpTF,InterpFactor,Conc,PlotLims)

%% Description

% This function takes in the following:
%   Data_Sig is the signal due to particles
%   ExternalField is the sum of any external field signal, so it could be a
%   current sense of drive and bias, or a sense coil inside the bore.
%   Fd: Drive frequency
%   fs: Sampling freq.
%   InterpTF: True/False if you want to interpolate data. 1 = interpolate
%   InterpFactor: How much you want to interpolate data by. 2 would be
%   effectively doubling fs
%   Conc: Particle concentration. eventually will be used to calibrate it.
%   not used now.
%   PlotLims is the X-axis limits for the figures which have external field
%   on the x axis
% I largely reference the following for the methods used here
% N. Garraud et al., “Benchtop magnetic particle relaxometer for detection, characterization and analysis of magnetic nanoparticles,” Phys. Med. Biol., vol. 63, no. 17, 2018.
% L. M. Bauer et al., “Eddy current-shielded x-space relaxometer for sensitive magnetic nanoparticle characterization,” Rev. Sci. Instrum., vol. 87, no. 5, 2016.

%% Color definitions:
RawData = [.2 .5 .8];
VelCorColor = [.4 .7 .2];
LProfileColor= [.8 .3 .3];
RProfileColor= [.8 .8 .1];

%%
Data_Sig = Data_Sig/Conc;

L = length(Data_Sig);   % Length of signal
t = linspace(0,L/fs,L); %Time Vector
t = t';
if InterpTF == 1
    
    fs = fs*InterpFactor;
    tt = linspace(t(1),t(end),length(t)*InterpFactor);
    Data_Sig = interp1(t,Data_Sig,tt,'spline');
    
    ExternalField = interp1(t,ExternalField,tt);
    
    t = tt';
    L = length(Data_Sig);
end

if size(Data_Sig,1)<size(Data_Sig,2) %Making sure it is a column
    Data_Sig=Data_Sig';
end
if size(t,1)<size(t,2) %Making sure it is a column
    t=t';
end
if size(ExternalField,1)<size(ExternalField,2)%Making sure it is a column
    ExternalField=ExternalField';
end
%% Plotting initial data
PlotInitial = 1;
if PlotInitial==1
    figure,subplot(2,1,1),plot(t,Data_Sig/max(abs(Data_Sig)),'Color',RawData)
    ylabel('Normalized Rx Signal')
    title('Input Data')
    subplot(2,1,2),plot(t,ExternalField/max(abs(ExternalField)),'Color',RawData)
    ylabel('Normalized Excitation Field')
    xlabel('Time (seconds)')

end
%%

PeriodsPerBucket = 1;
PointsPerPeriod = fs/Fd;

if mod(L,2)~=0 %If there is an odd num of samples make it even
    Data_Sig = Data_Sig(1:end-1);
    t= t(1:end-1);
    ExternalField = ExternalField(1:end-1);
    
    L=L-1;
end

dt = t(2)-t(1);
Velocity = diff(ExternalField);
VelocityTimes = t+dt/2;
Velocity = interp1(VelocityTimes(1:end-1),Velocity,t,'spline');
SmoothPoints = fs/Fd/10;
Velocity = smooth(Velocity,SmoothPoints);
HighVelocity = find(abs(Velocity)>max(abs(Velocity))/2); %preventing division by zero by only picking data with high velocity



VelCorrectedSig = Data_Sig(HighVelocity)./abs(Velocity(HighVelocity)); %Velocity correcting by dividing by the external field rate of change (velocity)
t_VelCor = t(HighVelocity);
%% Plotting Velocity Correction


PlotVelCor = 1;
if PlotVelCor==1
    figure,subplot(2,1,1),plot(t,Data_Sig/max(abs(Data_Sig)),'Color',RawData)
    hold on,subplot(2,1,1),plot(t_VelCor,VelCorrectedSig/max(abs(VelCorrectedSig)),'Color',VelCorColor)
    ylabel('Normalized Rx Signal')
    xlabel('Time (Seconds)')
    legend('Original Data','Vel. Corrected')
    title('Input Data')
    subplot(2,1,2),plot(ExternalField,Data_Sig/max(abs(Data_Sig)),'Color',RawData)
    hold on,subplot(2,1,2),plot(ExternalField(HighVelocity),VelCorrectedSig/max(abs(VelCorrectedSig)),'Color',VelCorColor)
    ylabel('Normalized Rx Signal')
    xlabel('External Field(T/\mu_0)')
    legend('Original Data','Vel. Corrected')
    xlim([-PlotLims PlotLims])
    
end


%%
ExternalField = ExternalField(HighVelocity);

NumBuckets = floor(length(VelCorrectedSig)/(PeriodsPerBucket*PointsPerPeriod));


if mod(length(VelCorrectedSig),PeriodsPerBucket*PointsPerPeriod)~=0
    VelCorrectedSig= VelCorrectedSig(1:length(VelCorrectedSig)-mod(length(VelCorrectedSig),PeriodsPerBucket*PointsPerPeriod));
    
    ExternalField = ExternalField(1:length(VelCorrectedSig)-mod(length(VelCorrectedSig),PeriodsPerBucket*PointsPerPeriod));
    Data_Sig =  Data_Sig(1:length(VelCorrectedSig)-mod(length(VelCorrectedSig),PeriodsPerBucket*PointsPerPeriod));
end

AllDataMat = sortrows([ExternalField,VelCorrectedSig]);
SigDataReshape = reshape(AllDataMat(:,2),(PointsPerPeriod*PeriodsPerBucket),NumBuckets);
BucketedBias = reshape(AllDataMat(:,1),(PointsPerPeriod*PeriodsPerBucket),NumBuckets);
MaxSig_Bucket = max(SigDataReshape);
MinSig_Bucket = min(SigDataReshape);
% LowestMax = mean(mink(MaxSig_Bucket,20));
% LowestMax = mean(MaxSig_Bucket(1:20)); %This should be the noise floor. Assuming the particles are sufficiently saturated.
LowestMax = 0;
MaxSig_Bucket = MaxSig_Bucket -LowestMax;
MinSig_Bucket = MinSig_Bucket + LowestMax;
for i = 1:NumBuckets
    MaxLoc = find(SigDataReshape(:,i)-LowestMax==MaxSig_Bucket(i));
    MaxSigBias_Bucket(i) = BucketedBias(MaxLoc,i);
    MinLoc = find(SigDataReshape(:,i)+ LowestMax==MinSig_Bucket(i));
    MinSigBias_Bucket(i) = BucketedBias(MinLoc,i);
end
Magnetization_R = cumtrapz(MaxSigBias_Bucket,MaxSig_Bucket); % cumulative trapezoidal (CumTrapz) integration of the maximal signal in each buckets gives magnetization
Magnetization_L = cumtrapz(MinSigBias_Bucket,-MinSig_Bucket);
maxMag = max(Magnetization_R-mean([Magnetization_R(1),Magnetization_R(end)]));


%% Plot Final
PlotFinal = 1;
if PlotFinal==1
    figure,  subplot(3,1,1),plot(ExternalField,VelCorrectedSig/max(abs(VelCorrectedSig)),'Color',VelCorColor)
    hold on,plot(MaxSigBias_Bucket,MaxSig_Bucket/max(MaxSig_Bucket),'Color',RProfileColor,'LineWidth',2)
    plot(MinSigBias_Bucket,MinSig_Bucket/max(abs(MinSig_Bucket)),'Color',LProfileColor,'LineWidth',2)
    ylabel('Normalized Rx Signal')
    xlabel('External Field(T/\mu_0)')
    xlim([-PlotLims PlotLims])
    legend('Vel. Corrected','Left Scanning','Right Scanning')
    
    subplot(3,1,2),hold on,plot(MaxSigBias_Bucket,MaxSig_Bucket/max(MaxSig_Bucket),'Color',RProfileColor,'LineWidth',2)
    plot(MinSigBias_Bucket,-MinSig_Bucket/max(abs(MinSig_Bucket)),'Color',LProfileColor,'LineWidth',2)
    
    ylabel('Normalized Mag. Permeability')
    xlabel('External Field(T/\mu_0)')
    xlim([-PlotLims PlotLims])
    legend('Left Scanning','Right Scanning')
    subplot(3,1,3),plot(MaxSigBias_Bucket,(Magnetization_R-mean([Magnetization_R(1),Magnetization_R(end)]))/maxMag,'Color',RProfileColor,'LineWidth',2)
    hold on
    plot(MinSigBias_Bucket,(Magnetization_L-mean([Magnetization_L(1),Magnetization_L(end)]))/maxMag,'Color',LProfileColor,'LineWidth',2)
    ylabel('Normalized Magnetization')
    xlabel('External Field(T/\mu_0)')
    xlim([-PlotLims PlotLims])
    legend('Left Scanning','Right Scanning')
end


%%
RMag_Output = (Magnetization_R-mean([Magnetization_R(1),Magnetization_R(end)]))/maxMag;
LMag_Output = (Magnetization_L-mean([Magnetization_L(1),Magnetization_L(end)]))/maxMag;


Outputs.MaxSig_Bucket = MaxSig_Bucket;
Outputs.MinSig_Bucket = MinSig_Bucket;
Outputs.RMag_Output = RMag_Output;
Outputs.LMag_Output = LMag_Output;
Outputs.MaxSigBias_Bucket = MaxSigBias_Bucket;
Outputs.MinSigBias_Bucket = MinSigBias_Bucket;
Outputs.VelCorrectedSig = VelCorrectedSig;
Outputs.BiasSig  =ExternalField;
Outputs.Data_Sig = Data_Sig;

Colors.VelCorColor = VelCorColor;
Colors.RawData = RawData;
Colors.LProfileColor= LProfileColor;
Colors.RProfileColor= RProfileColor;

end
