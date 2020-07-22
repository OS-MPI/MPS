



%%
% close all
clear all
addpath([pwd '\Called_Functions'])

d  = daq.getDevices;
devID = d(1).ID;
s = daq.createSession('ni');
% s.Rate=107e3;



DrivemT = 40;
% fDrive = 10.7e3;
% fDrive = 24.3e3;
fDrive = 25e3;
% fDrive = 40e3;

if fDrive==10.7e3
    mTpermVApex = 0.0288; %10.7 kHz
    s.Rate=246.1e3;
elseif fDrive ==25e3
    mTpermVApex = 0.0416; %25 kHz Outdated value!!
    s.Rate=1e6;
elseif fDrive == 40e3
    mTpermVApex = 0.0376; %40.0 kHz
    s.Rate=240e3;
end
fs = s.Rate;
DriveAmp = DrivemT/mTpermVApex/1000;
BiasAmp = 1.3;
fBias = 10;



MeasureTime = 1; %Seconds per acquisition phase
    Drive.Name = 'Apex PA12A'; %Drive Amplifier name
    Drive.Volts = num2str(DriveAmp); 
    Drive.mT = num2str(DrivemT);
    Drive.Freq = num2str(fDrive);
    Drive.PowerSupplyName= 'BK Precision';
    Bias.Name = 'Crown XTi2002';
    Bias.Volts = num2str(BiasAmp);
    Bias.mT = num2str(0);
    Bias.Freq = num2str(fBias);
% Concentration =input('Concentration = ');
Concentration = 1;
% Name = input('Test name for save');
Name = 'Grad_Adjust';
% Particles = input('Particle name');
Particles = 'Grad_Adjust';



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
TeslaPerAmp = .006;

%% adjust gradiometer

%this section runs pulses through the Tx and plots them so you can adjust
%the Rx position until a minima is found (which would mean minimum
%feedthrough) We achive ~65-70 dB relative to if the Rx is half out and the
%signal is maximized

figure(2),clf
figure(1),clf
% for K = 1:2
M=200;
FMag = zeros(M,3);
F0Mag = zeros(M,1);
rmsvalue = zeros(M,1);

for i = 1:M
    data = SendData(s,DriveAmp/5,0,fs,1, fBias, fDrive);
    [FMag(i,:),~]=FourierAmplitude_2(data(:,1),fs,fDrive,1);
    F0Mag(i)=FMag(i,1);
    figure(2),plot(i,F0Mag(i),'rd','LineWidth',3)
    rmsvalue(i)=rms((data(:,1)-mean(data(:,1))));
    figure(1),plot(i,rmsvalue(i),'rd')
    hold on
    if i>50
        xlim([i-50 i])
    else
        xlim([0 i])
    end
end
Data.Gradiometer_Adjustment_Vals.rms = rmsvalue;
Data.Gradiometer_Adjustment_Vals.F0 = F0Mag;
% K
% Noise = std(F0Mag)/2.23/100*1e9
% end
ExportData_V0(Name,Concentration,Particles,RepeatTests,'Grad_Adjust',MeasureTime,fs,Drive,Bias,Data,0,0,0)


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




