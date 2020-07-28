


%%
%This version is modified to maximize the sampling rate. To do this the
%code only allows one channel to be sampled at any given time. This assumes
%each transmit cycle is essentially identical (which, given the relatively
%low freqencies should be a decent assumption).

%%
% close all
clear all
addpath([pwd '\Called_Functions'])

d  = daq.getDevices;
devID = d(1).ID;
s = daq.createSession('ni');
% s.Rate=107e3;



DrivemT = 22; %Not accurate--  needs to be calibrated
% fDrive = 10.7e3;
% fDrive = 24.3e3;
fDrive = 25e3;
% fDrive = 40e3;

if fDrive==10.7e3
    mTpermVDrive = 0.0288; %10.7 kHz
    s.Rate=246.1e3;
elseif fDrive ==24.3e3
    mTpermVDrive = 0.0416; %25 kHz Outdated value!!
    s.Rate=1e6;
elseif fDrive == 40e3
    mTpermVDrive = 0.0376; %40.0 kHz
    s.Rate=240e3;
end
fs = s.Rate;
% DriveAmp = DrivemT/mTpermVDrive/1000;
DriveAmp = 0.67;
BiasGain = db2mag(27); %Measured into 8 Ohms resistive load
BiasImpedance = 6;%Ohms
TargetBiasCurrent = 7; %Amps
BiasAmp = TargetBiasCurrent*BiasImpedance/BiasGain;
fBias = 20;


RepeatTests = 1; %Number of times "Magnetometry" will be averaged


MeasureTime = 2; %Seconds per acquisition phase


    Drive.Name = 'OPA549'; %Drive Amplifier name
    Drive.Volts = num2str(DriveAmp); 
    Drive.mT = num2str(DrivemT);
    Drive.Freq = num2str(fDrive);
    Drive.PowerSupplyName= 'ExTech Instruments 382275 SMPS';
    Bias.Name = 'RCF IPS700';
    Bias.Volts = num2str(BiasAmp);
    Bias.mT = num2str(0);
    Bias.Freq = num2str(fBias);
Concentration =input('Concentration = ');
% Concentration = 0;
Name = input('Test name for save');
% Name = 'Test';
Particles = input('Particle name');
% Particles = 'Test';


PTime = .1;%Pause time between phases -- can be used to lower duty cycle if there is heating issues

AO0 = addAnalogOutputChannel(s,devID,'ao0','Voltage');
AO1 = addAnalogOutputChannel(s,devID,'ao1','Voltage');

Ch1 = addAnalogInputChannel(s,devID,'ai1','Voltage');
Ch1.TerminalConfig = 'SingleEnded';


a = arduino('COM4','Nano3');
Step = 'A0';
DirPin = 'D5';
EnablePin = 'D3';
ButtonPin = 'D4';
configurePin(a,DirPin,'DigitalOutput') %direction
writeDigitalPin(a,DirPin,1) %1 left, 0 right
configurePin(a,Step,'DigitalOutput') %step
writeDigitalPin(a,Step,1)
configurePin(a,EnablePin,'DigitalOutput') %enable
writeDigitalPin(a,EnablePin,1) %1 disable, 0 enable
configurePin(a,ButtonPin,'DigitalInput') %button
ButtonStatus = readDigitalPin(a,ButtonPin);


BulbLocation=231; %for us, this is the number of steps which set a bulb to be in the correct location

PointsPerBiasPeriod = fs/fBias;
BiasPeriods_Crop = 2;
PointsToCrop = BiasPeriods_Crop*PointsPerBiasPeriod;


VoltsPerAmp = 0.04;
TeslaPerAmp_Bias = .006;


%% Run N points to position sample

% This pulses the sample in 200 steps and then goes slowly in while
% recording and sets the position with max signal to be the location which
% data should be recorded at

writeDigitalPin(a,EnablePin,0)
writeDigitalPin(a,DirPin,1)
%back to position 0
ButtonStatus = readDigitalPin(a,ButtonPin);
while ButtonStatus==1
    ButtonStatus = readDigitalPin(a,ButtonPin);
    writeDigitalPin(a,Step,1);
    writeDigitalPin(a,Step,0);
end

writeDigitalPin(a,DirPin,0) %change direction
pause(PTime);

for j=1:200
    writeDigitalPin(a,Step,1);
    writeDigitalPin(a,Step,0);
end
N = 45; %N is the number of pulses that the motor turns while evaluating signal between each pulse
%45 full steps is sufficient for our hardware setup
F0Mag = zeros(N,1);
figure(2),clf
for i = 1:N
    data = SendData(s,DriveAmp,0,fs,.2, fBias, fDrive);
    [F0Mag_Tmp,~]=FourierAmplitude_2(data(:,1),fs,fDrive,1);
    F0Mag(i) = F0Mag_Tmp(1);
%     [FMag(j,i,:),FPhase(j,i,:)]=FourierAmplitude_2(data(:,1),fs,fDrive,FPick);

    figure(2),plot(i,F0Mag(i),'rd','LineWidth',3)
    hold on
    
    writeDigitalPin(a,Step,1);
    writeDigitalPin(a,Step,0);
    
    
end
writeDigitalPin(a,EnablePin,1)

[AmplitudeMax, BulbLocation]=max(F0Mag);
BulbLocation=BulbLocation+200;

%% Acquire data with sample in
%back to position 0
removeChannel(s,3); %Removing the Drive Current signal channel to limit the number of input signals and maximize sampling rate
Ch1 = addAnalogInputChannel(s,devID,'ai1','Voltage');% Adding Bias current sense
Ch1.TerminalConfig = 'SingleEnded';
LoopFigNum = 10;


for LoopNum=1:RepeatTests %The number of times the "magnetometry" procedure will be repeated. i.e. how many times the sample goes in and out
    writeDigitalPin(a,EnablePin,0) %Enables the motor
    writeDigitalPin(a,DirPin,1); %Tells the motor to move out
    ButtonStatus = readDigitalPin(a,ButtonPin);% Checks if it is already home
    while ButtonStatus==1 %while it isnt home, keep moving backwards
        ButtonStatus = readDigitalPin(a,ButtonPin);
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    pause(PTime); %optional pause 
    %move to sample position
    writeDigitalPin(a,DirPin,0);%change direction so it goes it.
    for j=1:BulbLocation %for the number of steps to takes to get to the right locations
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,EnablePin,1) %Disable motor while sending/Rx data
    pause(PTime);%optional pause
    Data_Sample_TMP = SendData(s,DriveAmp,BiasAmp,fs,MeasureTime, fBias, fDrive);%acquire data, with bias field and drive field
    Data_Sample(:,LoopNum) = Data_Sample_TMP(PointsToCrop:end);
    
    NumBiasPeriods = round(length(Data_Sample(:,LoopNum))/PointsPerBiasPeriod);
    ExtraPoints = mod(length(Data_Sample(:,LoopNum)),NumBiasPeriods);
    
    
    pause(PTime);
    Data_NoDrive_TMP = SendData(s,0,BiasAmp,fs,MeasureTime, fBias, fDrive); %Acquire data with the drive coil off to account for bias coil inducing signal
    Data_NoDrive(:,LoopNum) = Data_NoDrive_TMP(PointsToCrop:end);
    
    %Acquire data with sample out
    %back to position 0
    writeDigitalPin(a,EnablePin,0)
    writeDigitalPin(a,DirPin,1);
    ButtonStatus = readDigitalPin(a,ButtonPin);
    while ButtonStatus==1
        ButtonStatus = readDigitalPin(a,ButtonPin);
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,EnablePin,1)
    pause(PTime);
    
   
    Data_NoBias_TMP = SendData(s,DriveAmp,0,fs,MeasureTime, fBias, fDrive);
    Data_NoBias(:,LoopNum) = Data_NoBias_TMP(PointsToCrop:end);
    writeDigitalPin(a,EnablePin,0)
    writeDigitalPin(a,DirPin,0)
    for j=1:10
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,EnablePin,1)
    %Subtract data with and without sample
    SubtractedData(:,LoopNum) = Data_Sample(:,LoopNum)-Data_NoDrive(:,LoopNum)-Data_NoBias(:,LoopNum);

    
    %calculate average of one period (without first period)
    period=fs/fBias;
    all_data=zeros(period,(MeasureTime*fBias)-1);
    one_bias=zeros(period,(MeasureTime*fBias)-1);
    
 
    Data_Reshape = reshape(SubtractedData(1:end-ExtraPoints,LoopNum),PointsPerBiasPeriod,NumBiasPeriods)';


    average_Signaldata(:,LoopNum) = mean(Data_Reshape,1);

    
    norm_average_data=(average_Signaldata(:,LoopNum)-mean(average_Signaldata(:,LoopNum)))/max(abs(average_Signaldata(:,LoopNum)-mean(average_Signaldata(:,LoopNum))));%normalizing
        
    tBiasPeriod = 1/fs:1/fs:1/fBias;
    figure(LoopFigNum),plot(tBiasPeriod,norm_average_data, 'b')
    title(['Data from trial number ' num2str(LoopNum)])
    xlabel('Time [s]')
    legend('Signal', 'Biasing','Location','northwest')
    disp(num2str(LoopNum))
end
clear Data_Sample_TMP Data_NoDrive_TMP Data_NoBias_TMP norm_average_data Data_Reshape

data_BiasField_SampleOut = SendData(s,0,BiasAmp,fs,MeasureTime, fBias, fDrive);%acquire data, with bias field and drive field
data_BiasField_SampleOut = data_BiasField_SampleOut(PointsToCrop:end);

SignalData_OneBiasPeriod = mean(average_Signaldata,2);


norm_SignalData=(SignalData_OneBiasPeriod-mean(SignalData_OneBiasPeriod))/max(abs(SignalData_OneBiasPeriod-mean(SignalData_OneBiasPeriod)));

removeChannel(s,3); %Removing the signal channel to limit the number of input signals and maximize sampling rate
Ch1 = addAnalogInputChannel(s,devID,'ai3','Voltage');% Adding drive current sense
Ch1.TerminalConfig = 'SingleEnded';

data_Drive_IMon = SendData(s,DriveAmp,0,fs,MeasureTime, fBias, fDrive);%acquire data, with bias field and drive field
data_Drive_IMon = data_Drive_IMon(PointsToCrop:end);
DriveIMon_Reshape = reshape(data_Drive_IMon(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
    average_Drivedata= mean(DriveIMon_Reshape,1);
    average_Drivedata = average_Drivedata-mean(average_Drivedata);
removeChannel(s,3); %Removing the Drive Current signal channel to limit the number of input signals and maximize sampling rate
Ch1 = addAnalogInputChannel(s,devID,'ai2','Voltage');% Adding Bias current sense
Ch1.TerminalConfig = 'SingleEnded';

data_Bias_IMon = SendData(s,0,BiasAmp,fs,MeasureTime, fBias, fDrive);%acquire data, with bias field and drive field
data_Bias_IMon = data_Bias_IMon(PointsToCrop:end);
BiasIMon_Reshape = reshape(data_Bias_IMon(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
    average_Biasdata = mean(BiasIMon_Reshape,1);
    average_Biasdata = average_Biasdata-mean(average_Biasdata);
   norm_BiasData= average_Biasdata/max(average_Biasdata);
%plot normalized averaged data
figure,plot(tBiasPeriod,norm_SignalData, 'b')
hold on
plot(tBiasPeriod,norm_BiasData, 'r')
title(Name)
xlabel('Time [s]')
legend('measured Rx voltage (normalized and background subtracted)','measured Bias current (Hall, normalized)','Location','northwest')
ylim([-1 1])
disp('Data Acquisition Done')

%plot Langevin curve
%L = @(X,A,B) A.*(coth(X*B)-1./(X*B));
data_Bias_IMon_Smooth= smooth(data_Bias_IMon,2000);


    Bias_IMon_InPhase_RS_TMP = reshape(data_Bias_IMon_Smooth(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
    
    Bias_IMon_InPhase_OnePeriod = mean(Bias_IMon_InPhase_RS_TMP,1);
clear BiasSmoothTmp data_Drive_IMon_SmoothTmp Bias_IMon_InPhase_RS_TMP

data_Drive_IMon_SmoothTmp = smooth(data_Drive_IMon,5);
data_Drive_IMon_SmoothTmp = data_Drive_IMon_SmoothTmp-mean(data_Drive_IMon_SmoothTmp);
DriveSmoothTmp = smooth(mean(Data_NoBias,2),5);
DriveSmoothTmp = DriveSmoothTmp-mean(DriveSmoothTmp);
Drive_IMon_InPhase = DriveSmoothTmp/max(DriveSmoothTmp)*max(data_Drive_IMon_SmoothTmp);

    Drive_IMon_InPhase_RS_TMP = reshape(Drive_IMon_InPhase(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
    
    Drive_IMon_InPhase_OnePeriod = mean(Drive_IMon_InPhase_RS_TMP,1);
clear BiasSmoothTmp data_Drive_IMon_SmoothTmp Drive_IMon_InPhase_RS_TMP
Bias_IMon_InPhase_OnePeriod = circshift(Bias_IMon_InPhase_OnePeriod,1100);
DataMat = [SignalData_OneBiasPeriod(:),Bias_IMon_InPhase_OnePeriod(:)];
Data.DataRep = repmat(DataMat,2,1);%By repeating the signal it limits likelihood of errors later on
[Data.BiasFieldVector,Data.Susceptibility,Data.Magnetization]=Magnetometry_V0(Data.DataRep,1,size(Data.DataRep(:,1),1)/2,50,fBias,Concentration,fs,fDrive, '-',DrivemT,1);
% [SignalSim,MSim] = SignalSim_Experimental(X(2:end),m,.040,fs,10000,3);
Data.DriveIMon_Raw =data_Drive_IMon;
Data.BiasIMon_Raw  = data_Bias_IMon;


% %% Relaxometry Analysis
CurrentSenseResist_Drive = 0.1; %Ohms
TeslaPerAmp_Drive = 2e-3; %Tesla

PointsPerDrivePeriod = fs/fDrive;
Bias_IMon_InPhase_OnePeriod= Bias_IMon_InPhase_OnePeriod-mean(Bias_IMon_InPhase_OnePeriod);
BiasField = Bias_IMon_InPhase_OnePeriod*TeslaPerAmp_Bias/VoltsPerAmp;
DriveField = smooth(Drive_IMon_InPhase_OnePeriod*1/CurrentSenseResist_Drive*TeslaPerAmp_Drive,PointsPerDrivePeriod/10);
BiasField = BiasField(:);
% BiasField = circshift(BiasField,00);
DriveField = DriveField(:);
TotalField =DriveField +BiasField;
Startpoint=min([find(TotalField==max(TotalField)) find(TotalField==min(TotalField))]);
SignalData_OneBiasPeriod = [SignalData_OneBiasPeriod(:);SignalData_OneBiasPeriod(:)];
TotalField = [TotalField(:);TotalField(:)];
[RelaxOutputs,RelaxColors] = Relaxometry_V0(SignalData_OneBiasPeriod(Startpoint:Startpoint+PointsPerBiasPeriod/2),TotalField(Startpoint:Startpoint+PointsPerBiasPeriod/2),fDrive,fs,1,1,1,.06);

%% Plotting and Exporting

ResultsFig = figure('Position',[100,100,1200,800]);

% figure,plot(RelaxOutputs.BiasSig,RelaxOutputs.VelCorrectedSig/max(RelaxOutputs.VelCorrectedSig))
% hold on
MagnetizationAxes = axes('Position',[.55,.05,.4,.4]);
plot(RelaxOutputs.MaxSigBias_Bucket,RelaxOutputs.MaxSig_Bucket/max(RelaxOutputs.MaxSig_Bucket),'Color',RelaxColors.RProfileColor,'LineWidth',2)
hold on
plot(RelaxOutputs.MinSigBias_Bucket,abs(RelaxOutputs.MinSig_Bucket/max(abs(RelaxOutputs.MinSig_Bucket))),'Color',RelaxColors.LProfileColor,'LineWidth',2)
plot(Data.BiasFieldVector,Data.Susceptibility/max(Data.Susceptibility),'LineWidth',2,'Color',RelaxColors.RawData)
legend('Right scanning','Left scannning','Magnetometry')

dM_dH_Axes = axes('Position',[.55,.55,.4,.4]);
plot(RelaxOutputs.MaxSigBias_Bucket,RelaxOutputs.RMag_Output,'Color',RelaxColors.RProfileColor,'LineWidth',2)
hold on
plot(RelaxOutputs.MaxSigBias_Bucket,RelaxOutputs.LMag_Output,'Color',RelaxColors.LProfileColor,'LineWidth',2)
plot(Data.BiasFieldVector(2:end),Data.Magnetization/max(abs(Data.Magnetization)),'LineWidth',2,'Color',RelaxColors.RawData)
legend('Right scanning','Left scannning','Magnetometry')
SinglePeriod_Axes = axes('Position',[.05,.05,.4,.4]);
plot(DataMat(:,1),'LineWidth',2,'Color',RelaxColors.RawData)
hold on
plot(DataMat(:,2)-mean(DataMat(:,2)),'r','LineWidth',2)
legend('Rx Signal','Bias Amplitude')
ExportData_V0(Name,Concentration,Particles,RepeatTests,'Magnetometry',MeasureTime,fs,Drive,Bias,Data,RelaxOutputs,RelaxColors,0,0,0,ResultsFig)


%%
function [data] = SendData(s,DriveAmp,BiasAmp,fs,PulseTime, fBias, fDrive)

timepts = 0:1/fs:PulseTime;

DriveFunk = @(t) DriveAmp* sin(2*pi*fDrive*t);
DriveData = DriveFunk(timepts);

BiasFunk = @(t)BiasAmp*sin(2*pi*fBias*t);
BiasData = BiasFunk(timepts);

queueOutputData(s,[[DriveData 0 0 0 0]',[BiasData 0 0 0 0]'])
data = startForeground(s);


end




