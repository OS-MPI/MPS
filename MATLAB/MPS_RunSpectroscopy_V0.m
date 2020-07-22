% close all
clear all

%%

%This script is to operate in "spectroscopy mode" meaning that it will
%excite the particles at the Tx frequency and a high amplitude (enough to
%elicit non-linearities) and then evaluate the frequency spectra of these
%signals. This can be thought of what is happening at the FFL/FFP during
%imaging (if the FFL/FFP isnt moving quickly)


%%


d  = daq.getDevices;
devID = d(1).ID;
s = daq.createSession('ni');
% s.Rate=107e3;
% s.Rate=243e3;
% s.Rate=246.1e3;
s.Rate=1e6;
OnlyRx = 1;
fs = s.Rate;
if OnlyRx==1
    s.Rate = 2*s.Rate;
    fs = s.Rate;
end
DrivemT = 15;
% fDrive = 10.7e3;
fDrive = 25e3;
% fDrive = 40e3;

if fDrive==10.7e3
    mTpermVApex = 0.0288; %10.7 kHz
elseif fDrive ==25e3
    mTpermVApex = 0.0416; %24.3 kHz
elseif fDrive == 40e3
    mTpermVApex = 0.0376; %40.0 kHz
end
% DriveAmp = 0.20;
DriveAmp = DrivemT/mTpermVApex/1000;
BiasAmp = 2.5; 
fBias = 4;

RepeatTests = 5;
MeasureTime = 4;

Concentration =input('Concentration = ');

PTime = 2;
Ch1 = addAnalogInputChannel(s,devID,'ai1','Voltage');
Ch1.TerminalConfig = 'SingleEnded';
if OnlyRx==0 %By only measuring only the Rx and not current as well, you can increase the sampling rate
    Ch3 = addAnalogInputChannel(s,devID,'ai3','Voltage');
    Ch3.TerminalConfig = 'SingleEnded';
end
AO0 = addAnalogOutputChannel(s,devID,'ao0','Voltage');

a = arduino();
Step = 'A0';
configurePin(a,'D5','DigitalOutput') %direction
writeDigitalPin(a,'D5',1) %1 left, 0 right
configurePin(a,Step,'DigitalOutput') %step
writeDigitalPin(a,Step,1)
configurePin(a,'D3','DigitalOutput') %enable
writeDigitalPin(a,'D3',1) %1 disable, 0 enable
configurePin(a,'D4','DigitalInput') %button
ButtonStatus = readDigitalPin(a,'D4');
IndexMax=231;


%% Run N points to position sample
writeDigitalPin(a,'D3',0)
writeDigitalPin(a,'D5',1)
%back to position 0
ButtonStatus = readDigitalPin(a,'D4');
while ButtonStatus==1
    ButtonStatus = readDigitalPin(a,'D4');
    writeDigitalPin(a,Step,1);
    writeDigitalPin(a,Step,0);
end

writeDigitalPin(a,'D5',0) %change direction
pause(PTime);

for j=1:200
    writeDigitalPin(a,Step,1);
    writeDigitalPin(a,Step,0);
end
N = 45; %move until limit
F0Mag = zeros(N,1);
figure(2),clf
for i = 1:N
    data = SendData(s,DriveAmp,fs,.2,fDrive);
    [F0Mag(i),~]=FourierAmplitude(data(:,1),fs,fDrive,1);
    figure(2),plot(i,F0Mag(i),'rd','LineWidth',3)

    writeDigitalPin(a,Step,1);
    writeDigitalPin(a,Step,0);

    hold on
end
writeDigitalPin(a,'D3',1)

[AmplitudeMax, IndexMax]=max(F0Mag);
IndexMax=IndexMax+200;

%% Acquire data with sample in
%back to position 0

for LoopNum=1:RepeatTests
    writeDigitalPin(a,'D3',0)
    writeDigitalPin(a,'D5',1);
    ButtonStatus = readDigitalPin(a,'D4');
    while ButtonStatus==1
        ButtonStatus = readDigitalPin(a,'D4');
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    pause(PTime);
    %move to sample position
    writeDigitalPin(a,'D5',0);
    for j=1:IndexMax
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,'D3',1)
    pause(PTime);  
    data = SendData(s,DriveAmp,fs,MeasureTime, fDrive);
    Data_Sample = data;
    if OnlyRx==0
        DriveIMonData = data(:,2);
    end
    
    %Acquire data with sample out
    %back to position 0
    writeDigitalPin(a,'D3',0)
    writeDigitalPin(a,'D5',1);
    ButtonStatus = readDigitalPin(a,'D4');
    while ButtonStatus==1
        ButtonStatus = readDigitalPin(a,'D4');
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,'D3',1)

    
    data = SendData(s,DriveAmp,fs,MeasureTime, fDrive);
    Data_NoSample = data;
    
    writeDigitalPin(a,'D3',0)
    writeDigitalPin(a,'D5',0)
    for j=1:10
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,'D3',1)
    %Subtract data with and without sample
    Subtraction = Data_Sample(:,1)-Data_NoSample(:,1);
    if OnlyRx==0
        DataIteration(:,:,LoopNum) = [Subtraction DriveIMonData];
    else
        DataIteration(:,:,LoopNum) = Subtraction;
    end
    
end
if RepeatTests>1
    Data = mean(DataIteration,3);
else
    Data = DataIteration;
end

Data = Data(1:end-4,:);

L = length(Data(:,1));             % Length of signal
if mod(L,2)~=0
    Data= Data(1:end-1,:);
    L=L-1;

end
Y_signal = fft(Data(:,1));
P2 = abs(Y_signal/L); 
Mag = P2(1:L/2+1); 
Phase = angle(Y_signal(1:L/2+1));
Phase(Mag<1e-6)=0;

f = fs*(0:(L/2))/L; %Freq. vector
figure(12),semilogy(f,Mag,'k','LineWidth',1.5)
hold on
semilogy(f(mod(f,fDrive)==0 & f~= 0), Mag(mod(f,fDrive)==0 & f~= 0),'ko','LineWidth',2)
xlabel('Frequency')
ylabel('Spectral Amplitude')
if OnlyRx==0
    figure,plot(Data(:,2))
end
%%


function [data] = SendData(s,DriveAmp,fs,PulseTime, fDrive)

timepts = 0:1/fs:PulseTime;

DriveFunk = @(t) DriveAmp* sin(2*pi*fDrive*t);
DriveData = DriveFunk(timepts);


queueOutputData(s,[DriveData 0 0 0 0]')
data = startForeground(s);


end



