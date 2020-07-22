

%This script is currently organized in sections which should be run
%independently. e.g. it doesnt usually make sense to run it top to bottom
%(though you can). Usually we run the top initialization and then the last
%section.


%%
% close all
clear all
addpath([pwd '\Called_Functions'])

d  = daq.getDevices;
devID = d(1).ID;
s = daq.createSession('ni');
% s.Rate=107e3;



DrivemT = 15;
% fDrive = 10.7e3;
fDrive = 24.3e3;
% fDrive = 40e3;

if fDrive==10.7e3
    mTpermVApex = 0.0288; %10.7 kHz
    s.Rate=246.1e3;
elseif fDrive ==24.3e3
    mTpermVApex = 0.0416; %24.3 kHz
    s.Rate=243e3*2;
elseif fDrive == 40e3
    mTpermVApex = 0.0376; %40.0 kHz
    s.Rate=240e3;
end
fs = s.Rate;
DriveAmp = DrivemT/mTpermVApex/1000;
BiasAmp = 1.3;
fBias = 20;
RepeatTests = 1; %Number of times "Magnetometry" will be averaged
MeasureTime = 4; %Seconds per acquisition phase
    Drive.Name = 'Apex PA12A'; %Drive Amplifier name
    Drive.Volts = num2str(DriveAmp); 
    Drive.mT = num2str(DrivemT);
    Drive.Freq = num2str(fDrive);
    Drive.PowerSupplyName= 'BK Precision';
    Bias.Name = 'Crown XTi2002';
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
Ch2 = addAnalogInputChannel(s,devID,'ai2','Voltage');
Ch2.TerminalConfig = 'SingleEnded';

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



%% adjust gradiometer

%this section runs pulses through the Tx and plots them so you can adjust
%the Rx position until a minima is found (which would mean minimum
%feedthrough) We achive ~65-70 dB relative to if the Rx is half out and the
%signal is maximized

figure(2),clf
figure(1),clf
% for K = 1:2
M=1;
FMag = zeros(1,M);
for i = 1:M
    data = SendData(s,DriveAmp,0,fs,1, fBias, fDrive);
    [FMag(i),~]=FourierAmplitude(data(:,1),fs,fDrive,1);
    figure(2),plot(i,FMag(i),'rd','LineWidth',3)
    rmsvalue(i)=rms((data(:,1)-mean(data(:,1))));
    figure(1),plot(i,rmsvalue(i),'rd')
    hold on
    if i>50
        xlim([i-50 i])
    else
        xlim([0 i])
    end
end
% K
% Noise = std(F0Mag)/2.23/100*1e9
% end
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
    [F0Mag(i),~]=FourierAmplitude_2(data(:,1),fs,fDrive,1);
%     [FMag(j,i,:),FPhase(j,i,:)]=FourierAmplitude_2(data(:,1),fs,fDrive,FPick);

    figure(2),plot(i,F0Mag(i),'rd','LineWidth',3)
    hold on
    
    writeDigitalPin(a,Step,1);
    writeDigitalPin(a,Step,0);
    
    
end
writeDigitalPin(a,EnablePin,1)

[AmplitudeMax, BulbLocation]=max(F0Mag);
BulbLocation=BulbLocation+200;
%% Detection
% This mode should be used if you are uncertain if there are particles, it
% was developed for a collaborator who had samples but was uncertain if any
% superparamagnetic material was included. ~100-200 ng can be confidently
% be detected.


%This section runs the sample in and out while simultaneously recording the
%collected data can be compared to a sensitivity profile and the signal's
%fit to the sensitivity profile corresponds to the likelihood SPIO particles are
%being scanned

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
N = 45; %move until limit
Trials = 10; %Trials is the number of times the sample will go in and out
FPick = 1; %Keep this at 1
FMag = zeros(Trials,2*N,3);
FPhase=zeros(Trials,2*N,3);
figure(2),clf
t = linspace(0,.2,0.2*fs+5);%The plus 5 accounts for the padded zeros
t = t(round(length(t)/10):end); %Crops the initial transient
SendData(s,DriveAmp,0,fs,5, fBias, fDrive);
data = SendData(s,DriveAmp,0,fs,.2, fBias, fDrive);
data = data(round(length(data(:,1))/10):end,:);


for j = 1:Trials
    data = SendData(s,DriveAmp,0,fs,.2, fBias, fDrive);
    data = data(round(length(data(:,1))/10):end,:);
    Correction=data(:,1); %Correction is the baseline signal when the sample is most out
    for i = 1:N
        writeDigitalPin(a,EnablePin,1); %Disable motor
        data = SendData(s,DriveAmp,0,fs,.2, fBias, fDrive);
        data = data(round(length(data(:,1))/10):end,:);
        data(:,1) = data(:,1)-Correction;
        [FMag(j,i,:),FPhase(j,i,:)]=FourierAmplitude_2(data(:,1),fs,fDrive,FPick);
        
        figure(2),plot(i,FMag(j,i,1),'rd','LineWidth',3)
        writeDigitalPin(a,EnablePin,0); %Enable motor/fan
        writeDigitalPin(a,Step,1);%move
        writeDigitalPin(a,Step,0);
        
        hold on
    end
    writeDigitalPin(a,DirPin,1);
    for i = 1:N
        writeDigitalPin(a,EnablePin,1);
        data = SendData(s,DriveAmp,0,fs,.2, fBias, fDrive);
        data = data(round(length(data(:,1))/10):end,:);
        data(:,1) = data(:,1)-Correction;
        [FMag(j,N+i,:),~]=FourierAmplitude_2(data(:,1),fs,fDrive,FPick);
        figure(2),plot(N-i+1,FMag(j,N+i,1),'rd','LineWidth',3)
        writeDigitalPin(a,EnablePin,0);
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
        
        hold on
    end
    writeDigitalPin(a,DirPin,0);
    disp(num2str(j))
end
writeDigitalPin(a,EnablePin,1)

% [AmplitudeMax, IndexMax]=max(F0Mag);
% IndexMax=IndexMax+200;

%% Acquire data with sample in
%back to position 0

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
    data = SendData(s,DriveAmp,BiasAmp,fs,MeasureTime, fBias, fDrive);%acquire data, with bias field and drive field
    Data_Sample = data;
    BiasData1 = data(:,2)-mean(data(:,2)); %The current sense has a DC offset (it is centered around 2.5V), this takes it off
    
    pause(PTime);
    data = SendData(s,0,BiasAmp,fs,MeasureTime, fBias, fDrive); %Acquire data with the drive coil off to account for bias coil inducing signal
    Data_NoDrive = data;
    BiasData2 = data(:,2)-mean(data(:,2)); %Subtracting the inherent DC bias in the current sense signal 
    
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
    
    data = SendData(s,DriveAmp,0,fs,MeasureTime, fBias, fDrive);
    Data_NoBias = data;
    %BiasData2 = data(:,2)-mean(data(:,2));
    writeDigitalPin(a,EnablePin,0)
    writeDigitalPin(a,DirPin,0)
    for j=1:10
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,EnablePin,1)
    %Subtract data with and without sample
    substraction = Data_Sample(:,1)-Data_NoDrive(:,1)-Data_NoBias(:,1);
    BiasData =mean([BiasData1 BiasData2],2);
    
    %calculate average of one period (without first period)
    period=fs/fBias;
    all_data=zeros(period,(MeasureTime*fBias)-1);
    one_bias=zeros(period,(MeasureTime*fBias)-1);
    
    for i=1:((MeasureTime*fBias)-1)
        all_data(:,i)=substraction((period*i+2):(period*(i+1)+1));
        one_bias(:,i)=BiasData((period*i+2):(period*(i+1)+1));
    end
    average_data(:,LoopNum) = mean(all_data,2);
    average_bias(:,LoopNum) = mean(one_bias,2);
    
    norm_average_data(:,LoopNum)=(average_data(:,LoopNum)-mean(average_data(:,LoopNum)))/max(abs(average_data(:,LoopNum)-mean(average_data(:,LoopNum))));%normalizing
    norm_average_bias(:,LoopNum)=(average_bias(:,LoopNum)-mean(average_bias(:,LoopNum)))/max(abs(average_bias(:,LoopNum)-mean(average_bias(:,LoopNum))));
    
    tBiasPeriod = 1/fs:1/fs:1/fBias;
    figure,plot(tBiasPeriod,norm_average_data(:,LoopNum), 'b')
    hold on
    plot(tBiasPeriod,norm_average_bias(:,LoopNum), 'r')
    xlabel('Time [s]')
    legend('Signal', 'Biasing','Location','northwest')
    disp(num2str(LoopNum))
end

SignalData_OneBiasPeriod = mean(average_data,2);
BiasData_OnePeriod = mean(average_bias,2);

norm_SignalData=(SignalData_OneBiasPeriod-mean(SignalData_OneBiasPeriod))/max(abs(SignalData_OneBiasPeriod-mean(SignalData_OneBiasPeriod)));
norm_BiasData=(BiasData_OnePeriod-mean(BiasData_OnePeriod))/max(abs(BiasData_OnePeriod-mean(BiasData_OnePeriod)));

removeChannel(s,4); %Removing the biasing channel to limit the number of input signals and maximize sampling rate
Ch2 = addAnalogInputChannel(s,devID,'ai3','Voltage');% Adding drive current sense
Ch2.TerminalConfig = 'SingleEnded';

data_Drive_IMon = SendData(s,DriveAmp,0,fs,MeasureTime, fBias, fDrive);%acquire data, with bias field and drive field

%plot normalized averaged data
figure,plot(tBiasPeriod,norm_SignalData, 'b')
hold on
plot(tBiasPeriod,norm_BiasData, 'r')
title(Name)
xlabel('Time [s]')
legend('measured Rx voltage (normalized and background subtracted)','measured Bias current (Hall, normalized)','Location','northwest')
disp(num2str(LoopNum))

%plot Langevin curve
%L = @(X,A,B) A.*(coth(X*B)-1./(X*B));
Shift=220; %This shifts the bias points and corresponds to the delay due to eddy currents in the copper tube from the Bias field. 
SmoothBias = smooth(BiasData_OnePeriod,20); %Simple running average smoothing
ShiftedBias = [SmoothBias(end-Shift:end);SmoothBias(1:end-Shift-1)];
DataNew = [SignalData_OneBiasPeriod,ShiftedBias];
Data.DataRep = repmat(DataNew,2,1);%By repeating the signal it limits likelihood of errors later on
[Data.BiasFieldVector,Data.Susceptibility,Data.Magnetization]=Magnetometry_V0(Data.DataRep,1,size(SignalData_OneBiasPeriod,1),50,fBias,Concentration,fs,fDrive, '-',DrivemT,1);
% [SignalSim,MSim] = SignalSim_Experimental(X(2:end),m,.040,fs,10000,3);

ExportData_V0(Name,Concentration,Particles,RepeatTests,'Magnetometry',MeasureTime,fs,Drive,Bias,Data,0,0,0)


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




