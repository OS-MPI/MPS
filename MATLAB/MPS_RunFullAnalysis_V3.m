


%%
%This version is designed to run a full analysis of nanoparticles and then
%save/export data in a standardized format. The goal of this will be with
%one script you can collect all necessary information to characterize a
%sample of SPIONS. It is still under construction and likely full of bugs
%or errors!


%% Setup and parameter definition
close all
clear all
addpath([pwd '\Called_Functions'])


TESTMODE = 0; %Set this to 1 to prevent the motor homing loop (If the motor isn't plugged it, it makes it a pain to debug without this)

tic
StartTic = 1;
%%%%%%%%%%%%%%%%%%%%%
%%%% SPION Info %%%%%%
SPION_Info.Name = 'VivoTrax9ug';
SPION_Info.Manufacturer = 'Magnetic Insight';
SPION_Info.Lot = '';
SPION_Info.DateMade = ''; %DD-MMM-YYYY
SPION_Info.CoreSize = 999; %nm
SPION_Info.HydroSize = 999; %nm
SPION_Info.Concentration = .5; %mg Fe/ml
SPION_Info.Volume = 18e-3; %ml
SPION_Info.Coating = '';
SPION_Info.Notes = 'There is a small bubble';


%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% User data %%%%%%%%
UserData.Date = date;
UserData.Name = 'Eli Mattingly';
UserData.Location = 'Martinos Center, Boston, MA, USA';


%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Magnetometry %%%%%%%
fs =1e6; % Sampling rate in Hz -- Target value
Results.Magnetometry.Parameters.fs = fs;
fDrive = 24.3e3;


Results.Magnetometry.Parameters.fDrive = fDrive;
Results.Magnetometry.Parameters.fsInterp = floor(fs/fDrive)*fDrive;
fsInterp= Results.Magnetometry.Parameters.fsInterp;
fBias = 20; %Hz
Results.Magnetometry.Parameters.fBias = fBias;
Results.Magnetometry.Parameters.BiasWaveShape = 'Sine';
Results.Magnetometry.Parameters.BiasAmp_AmpName = 'RCF IPS700';

Results.Magnetometry.Parameters.DriveAmp_AmpName = 'OPA549_Single_BoardRev2';
Results.Magnetometry.Parameters.DriveImonVoltsPerAmp = 0.1;
Results.Magnetometry.Parameters.Drive_mTPerAmp = 2;
Results.Magnetometry.Parameters.BiasImonVoltsPerAmp = 0.04;
Results.Magnetometry.Parameters.Bias_mTPerAmp = 6;
Results.Magnetometry.Parameters.PowerSupplyName = 'Tenma 72-7245';
Results.Magnetometry.Parameters.PreAmpName = 'INA217 V0';
Results.Magnetometry.Parameters.PreAmpGain = 100; %Check Value
Results.Magnetometry.Parameters.PreAmpTurnCount = 450; %Check Value
TestTime = 2; % How long each aquisition is in seconds
TestTime = round(TestTime*fDrive)/fDrive; %ensuring an even number of periods
Results.Magnetometry.Parameters.TestTime = TestTime;
NumAverages = 2;
Results.Magnetometry.Parameters.NumAverages = NumAverages;

            TargetDrivemT = 2; %This is just a target, the actual value is measured after acquisition
            
            
TargetDriveCurrent = TargetDrivemT/Results.Magnetometry.Parameters.Drive_mTPerAmp;
DriveAmpGain = 10;
FilterConfigSpiceFile = 'MPS_V0_25kHzConfig.txt'; %3800Hz, 24.3kHz
% FilterConfigSpiceFile = 'MPS_V0_40kHzConfig.txt'; %23kHz 44.8kHz

DriveFiltImpedance = 1/(SpiceTFData2Mag(FilterConfigSpiceFile,fDrive));
Results.Magnetometry.Parameters.DriveAmp_Volts = DriveFiltImpedance*TargetDriveCurrent/DriveAmpGain;
MagDriveAmp = Results.Magnetometry.Parameters.DriveAmp_Volts; %Just abbreviating the variable name;

BiasGain = db2mag(27); %Measured into 8 Ohms resistive load
BiasImpedance = 4.7;%Ohms
TargetBiasFieldmT = 50;
TargetBiasCurrent =TargetBiasFieldmT/Results.Magnetometry.Parameters.Bias_mTPerAmp ; %Amps
Results.Magnetometry.Parameters.BiasAmp_Volts = TargetBiasCurrent*BiasImpedance/BiasGain;
MagBiasAmp = Results.Magnetometry.Parameters.BiasAmp_Volts;
%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Relaxometry  %%%%%%%
Results.Relaxometry.Parameters = Results.Magnetometry.Parameters;

                TargetDrivemT = 15;%This is just a target, the actual value is measured after acquisition
                
TargetDriveCurrent = TargetDrivemT/Results.Relaxometry.Parameters.Drive_mTPerAmp;
DriveAmpGain = 10;
% FilterConfigSpiceFile = 'MPS_V0_25kHzConfig.txt';
DriveFiltImpedance = 1/(SpiceTFData2Mag(FilterConfigSpiceFile,fDrive));
Results.Relaxometry.Parameters.DriveAmp_Volts = DriveFiltImpedance*TargetDriveCurrent/DriveAmpGain;
RelaxDriveAmp = Results.Relaxometry.Parameters.DriveAmp_Volts; %Just abbreviating the variable name;

BiasGain = db2mag(27); %Measured into 8 Ohms resistive load
BiasImpedance = 4.7;%Ohms
TargetBiasFieldmT = 50;
TargetBiasCurrent =TargetBiasFieldmT/Results.Magnetometry.Parameters.Bias_mTPerAmp ; %Amps
Results.Relaxometry.Parameters.BiasAmp_Volts = TargetBiasCurrent*BiasImpedance/BiasGain;
RelaxBiasAmp = Results.Relaxometry.Parameters.BiasAmp_Volts;
%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%% Spectroscopy %%%%%%%
Results.Spectroscopy.Parameters  = Results.Magnetometry.Parameters;

% TargetDrivemT = 5;%This is just a target, the actual value is measured after acquisition
TargetDriveCurrent = TargetDrivemT/Results.Spectroscopy.Parameters.Drive_mTPerAmp;
DriveAmpGain = 10;
% FilterConfigSpiceFile = 'MPS_V0_25kHzConfig.txt';
DriveFiltImpedance = 1/(SpiceTFData2Mag(FilterConfigSpiceFile,fDrive));
Results.Spectroscopy.Parameters.DriveAmp_Volts = DriveFiltImpedance*TargetDriveCurrent/DriveAmpGain;
SpecDriveAmp = Results.Spectroscopy.Parameters.DriveAmp_Volts; %Just abbreviating the variable name;

disp('Parameters Defined')


%%%%%%%% OVERWRITE PARAMETERS WITH SAVED DATA %%%%%%%
Overwrite = input('Do you want to overwrite with saved parameters (1=Yes or 0=No)');

if Overwrite==1
    load('StandardParams.mat')
    fBias = Results.Magnetometry.Parameters.fBias;
    fs = Results.Magnetometry.Parameters.fs;
    fsInterp  = Results.Magnetometry.Parameters.fsInterp;
    fDrive = Results.Magnetometry.Parameters.fDrive;
    NumAverages = Results.Magnetometry.Parameters.NumAverages;
    TestTime = Results.Magnetometry.Parameters.TestTime;
    
    
    MagBiasAmp = Results.Magnetometry.Parameters.BiasAmp_Volts;
    MagDriveAmp = Results.Magnetometry.Parameters.DriveAmp_Volts;
    
    RelaxBiasAmp = Results.Relaxometry.Parameters.BiasAmp_Volts;
    RelaxDriveAmp = Results.Relaxometry.Parameters.DriveAmp_Volts;
    
    SpecDriveAmp =  Results.Spectroscopy.Parameters.DriveAmp_Volts;
    
    disp('Parameters overwritten')
end




d  = daq.getDevices;
devID = d(1).ID;
s = daq.createSession('ni');





PTime = .1;%Pause time between phases -- can be used to lower duty cycle if there is heating issues

AO0 = addAnalogOutputChannel(s,devID,'ao0','Voltage');
AO1 = addAnalogOutputChannel(s,devID,'ao1','Voltage');

Ch1 = addAnalogInputChannel(s,devID,'ai1','Voltage');
Ch1.TerminalConfig = 'SingleEnded';

s.Rate = fs; %These lines try to set the sampling rate to the target sampling rate, fs...
%But often times the DAQ can't sample at that exact value so
%it selects a nearby value. This value is then pulled and
%stored for future use
fs = s.Rate;
Results.Magnetometry.Parameters.fs = fs;
Results.Relaxometry.Parameters.fs = fs;
Results.Spectroscopy.Parameters.fs = fs;

if fs==fsInterp
    InterpNeeded=0;%if the sampling rate is already correct, no interpolation is needed
else
    InterpNeeded = 1;
end

InterpNeeded=1;
disp('NIDAQ Configured')


a = arduino('COM4','Nano3'); %Modify this line to suit your board/port
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

PointsPerBiasPeriod = fsInterp/fBias;
BiasPeriods_Crop = 2;
PointsToCrop = BiasPeriods_Crop*PointsPerBiasPeriod+1;

disp('Arduino Configured')


FindBulbPosition = 0; %If this is a 1 the system will search for the ideal position for the bulb, otherwise it will use the previously defined value


%% Run N points to position sample

% This pulses the sample in 200 steps and then goes slowly in while
% recording and sets the position with max signal to be the location which
% data should be recorded at


if FindBulbPosition == 1
    
    writeDigitalPin(a,EnablePin,0)
    writeDigitalPin(a,DirPin,1)
    %back to position 0
    ButtonStatus = readDigitalPin(a,ButtonPin);
    while ButtonStatus==1&&TESTMODE==0
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
        data = SendData(s,MagDriveAmp,0,fs,.2, fBias, fDrive);
        if InterpNeeded==1
            data = ResampleData(data,fs,fsInterp,fDrive);
        end
        [F0Mag_Tmp,~]=FourierAmplitude_2(data(:,1),fsInterp,fDrive,1);
        F0Mag(i) = F0Mag_Tmp(1);
        
        figure(2),plot(i,F0Mag(i),'rd','LineWidth',3)
        hold on
        
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
        
        
    end
    writeDigitalPin(a,EnablePin,1)
    
    [AmplitudeMax, BulbLocation]=max(F0Mag);
    BulbLocation=BulbLocation+200;
end
%% Acquire data with sample in
%back to position 0


removeChannel(s,3); %Removing the Drive Current signal channel to limit the number of input signals and maximize sampling rate
Ch1 = addAnalogInputChannel(s,devID,'ai1','Voltage');% Adding Bias current sense
Ch1.TerminalConfig = 'SingleEnded';
LoopFigNum = 10;


for LoopNum=1:NumAverages %The number of times the "magnetometry" procedure will be repeated. i.e. how many times the sample goes in and out
    disp('Starting Run')
    
    
    
    writeDigitalPin(a,EnablePin,0) %Enables the motor
    writeDigitalPin(a,DirPin,1); %Tells the motor to move out
    ButtonStatus = readDigitalPin(a,ButtonPin);% Checks if it is already home
    while ButtonStatus==1&&TESTMODE==0 %while it isnt home, keep moving backwards
        ButtonStatus = readDigitalPin(a,ButtonPin);
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    disp('Motor Home')
    pause(PTime); %optional pause
    %move to sample position
    writeDigitalPin(a,DirPin,0);%change direction so it goes it.
    for j=1:BulbLocation %for the number of steps to takes to get to the right locations
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,EnablePin,1) %Disable motor while sending/Rx data
    disp('Sample In')
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%% SAMPLE IN %%%%%%%%%%%%%%%%%%
    
    pause(PTime);%optional pause
    MagData_Sample_TMP = SendData(s,MagDriveAmp,MagBiasAmp,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
    MagData_Sample_TMP = ResampleData(MagData_Sample_TMP,fs,fsInterp,fDrive);
    MagData_Sample(:,LoopNum) = MagData_Sample_TMP(PointsToCrop:end);
    clear MagData_Sample_TMP
    
    RelaxData_Sample_TMP = SendData(s,RelaxDriveAmp,RelaxBiasAmp,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
    RelaxData_Sample_TMP = ResampleData(RelaxData_Sample_TMP,fs,fsInterp,fDrive);
    RelaxData_Sample(:,LoopNum) = RelaxData_Sample_TMP(PointsToCrop:end);
    
    clear RelaxData_Sample_TMP
    
    SpecData_Sample_TMP = SendData(s,SpecDriveAmp,0,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
    SpecData_Sample_TMP = ResampleData(SpecData_Sample_TMP,fs,fsInterp,fDrive);
    SpecData_Sample(:,LoopNum) = SpecData_Sample_TMP(PointsToCrop:end);
    
    clear SpecData_Sample_TMP
    
    
    disp('Sample in data collected')
    
    NumBiasPeriods = round(length(MagData_Sample(:,LoopNum))/PointsPerBiasPeriod);
    ExtraPoints = mod(length(MagData_Sample(:,LoopNum)),NumBiasPeriods);
    
    
    pause(PTime);
    MagData_NoDrive_TMP = SendData(s,0,MagBiasAmp,fs,TestTime, fBias, fDrive); %Acquire data with the drive coil off to account for bias coil inducing signal
    MagData_NoDrive_TMP = ResampleData(MagData_NoDrive_TMP,fs,fsInterp,fDrive);
    MagData_NoDrive(:,LoopNum) = MagData_NoDrive_TMP(PointsToCrop:end);
    clear MagData_NoDrive_TMP
    
    RelaxData_NoDrive_TMP = SendData(s,0,RelaxBiasAmp,fs,TestTime, fBias, fDrive); %Acquire data with the drive coil off to account for bias coil inducing signal
    RelaxData_NoDrive_TMP = ResampleData(RelaxData_NoDrive_TMP,fs,fsInterp,fDrive);
    RelaxData_NoDrive(:,LoopNum) = RelaxData_NoDrive_TMP(PointsToCrop:end);
    clear RelaxData_NoDrive_TMP
    
    disp('Sample in (no drive field) data collected')
    
    %Acquire data with sample out
    %back to position 0
    writeDigitalPin(a,EnablePin,0)
    writeDigitalPin(a,DirPin,1);
    ButtonStatus = readDigitalPin(a,ButtonPin);
    while ButtonStatus==1&&TESTMODE==0
        ButtonStatus = readDigitalPin(a,ButtonPin);
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,EnablePin,1)
    pause(PTime);
    
    disp('Sample out, motor home')
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%% SAMPLE OUT %%%%%%%%%%%%%%%%%%%%
    
    MagData_NoBias_TMP = SendData(s,MagDriveAmp,0,fs,TestTime, fBias, fDrive);
    MagData_NoBias_TMP = ResampleData(MagData_NoBias_TMP,fs,fsInterp,fDrive);
    MagData_NoBias(:,LoopNum) = MagData_NoBias_TMP(PointsToCrop:end);
    clear MagData_NoBias_TMP
    
    RelaxData_NoBias_TMP = SendData(s,RelaxDriveAmp,0,fs,TestTime, fBias, fDrive);
    RelaxData_NoBias_TMP = ResampleData(RelaxData_NoBias_TMP,fs,fsInterp,fDrive);
    RelaxData_NoBias(:,LoopNum) = RelaxData_NoBias_TMP(PointsToCrop:end);
    clear RelaxData_NoBias_TMP
    
    SpecData_NoBias_TMP = SendData(s,SpecDriveAmp,0,fs,TestTime, fBias, fDrive);
    SpecData_NoBias_TMP = ResampleData(SpecData_NoBias_TMP,fs,fsInterp,fDrive);
    SpecData_NoBias(:,LoopNum) = SpecData_NoBias_TMP(PointsToCrop:end);
    clear SpecData_NoBias_TMP
    
    writeDigitalPin(a,EnablePin,0)
    writeDigitalPin(a,DirPin,0)
    for j=1:10
        writeDigitalPin(a,Step,1);
        writeDigitalPin(a,Step,0);
    end
    writeDigitalPin(a,EnablePin,1)
    
    
    %Subtract data with and without sample
    MagSubtractedData(:,LoopNum) = MagData_Sample(:,LoopNum)-MagData_NoDrive(:,LoopNum)-MagData_NoBias(:,LoopNum);
    RelaxSubtractedData(:,LoopNum) = RelaxData_Sample(:,LoopNum)-RelaxData_NoDrive(:,LoopNum)-RelaxData_NoBias(:,LoopNum);
    SpecSubtractedData(:,LoopNum) = SpecData_Sample(:,LoopNum)-SpecData_NoBias(:,LoopNum);
    
    
    
    MagData_Reshape = reshape(MagSubtractedData(1:end-ExtraPoints,LoopNum),PointsPerBiasPeriod,NumBiasPeriods)';
    RelaxData_Reshape = reshape(RelaxSubtractedData(1:end-ExtraPoints,LoopNum),PointsPerBiasPeriod,NumBiasPeriods)';
    SpecData_Reshape = reshape(SpecSubtractedData(1:end-ExtraPoints,LoopNum),PointsPerBiasPeriod,NumBiasPeriods)';
    
    
    MagAverage_Signaldata(:,LoopNum) = mean(MagData_Reshape,1);
    RelxAverage_Signaldata(:,LoopNum) = mean(RelaxData_Reshape,1);
    SpecAverage_Signaldata(:,LoopNum) = mean(SpecData_Reshape,1);
    
    
    norm_average_data=(MagAverage_Signaldata(:,LoopNum)-mean(MagAverage_Signaldata(:,LoopNum)))/max(abs(MagAverage_Signaldata(:,LoopNum)-mean(MagAverage_Signaldata(:,LoopNum))));%normalizing
    
    tBiasPeriod = 1/fsInterp:1/fsInterp:1/fBias;
    figure(LoopFigNum),plot(tBiasPeriod,norm_average_data, 'b')
    title(['Data from trial number ' num2str(LoopNum)])
    xlabel('Time [s]')
    legend('Signal','Location','northwest')
    disp(num2str(LoopNum))
end
%%
clear  norm_average_data
clear MagData_NoDrive RelaxData_NoDrive





Magdata_BiasField_SampleOut_TMP = SendData(s,0,MagBiasAmp,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
Magdata_BiasField_SampleOut_TMP = ResampleData(Magdata_BiasField_SampleOut_TMP,fs,fsInterp,fDrive);
Magdata_BiasField_SampleOut = Magdata_BiasField_SampleOut_TMP(PointsToCrop:end);
clear Magdata_BiasField_SampleOut_TMP

Relaxdata_BiasField_SampleOut_TMP = SendData(s,0,RelaxBiasAmp,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
Relaxdata_BiasField_SampleOut_TMP = ResampleData(Relaxdata_BiasField_SampleOut_TMP,fs,fsInterp,fDrive);
Relaxdata_BiasField_SampleOut = Relaxdata_BiasField_SampleOut_TMP(PointsToCrop:end);
clear Relaxdata_BiasField_SampleOut_TMP


Results.Magnetometry.RawData.RawSignal =  repmat(mean(MagAverage_Signaldata,2),2,1);
Results.Relaxometry.RawData.RawSignal =  repmat(mean(RelxAverage_Signaldata,2),2,1);
Results.Spectroscopy.RawData.RawSignal =  repmat(mean(SpecAverage_Signaldata,2),2,1);


norm_SignalData=(Results.Magnetometry.RawData.RawSignal-mean(Results.Magnetometry.RawData.RawSignal))/max(abs(Results.Magnetometry.RawData.RawSignal-mean(Results.Magnetometry.RawData.RawSignal)));


%%%%%%%%%%%%%%%%% DRIVE CURRENT SENSE & Analysis %%%%%%%%%%%%%%%%%%%%%%


removeChannel(s,3); %Removing the signal channel to limit the number of input signals and maximize sampling rate
Ch1 = addAnalogInputChannel(s,devID,'ai3','Voltage');% Adding drive current sense
Ch1.TerminalConfig = 'SingleEnded';

MagData_Drive_IMon = SendData(s,MagDriveAmp,0,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
MagData_Drive_IMon = ResampleData(MagData_Drive_IMon,fs,fsInterp,fDrive);
MagData_Drive_IMon = MagData_Drive_IMon(PointsToCrop:end);
MagDriveIMon_Reshape = reshape(MagData_Drive_IMon(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
MagAaverage_Drivedata= mean(MagDriveIMon_Reshape,1);
Results.Magnetometry.RawData.RawDriveImon  = MagAaverage_Drivedata-mean(MagAaverage_Drivedata);

clear MagDriveIMon_Reshape data_Drive_IMon_SmoothTmp MagAaverage_Drivedata

MagData_Drive_IMon_SmoothTmp = smooth(MagData_Drive_IMon,5);
MagData_Drive_IMon_SmoothTmp = MagData_Drive_IMon_SmoothTmp-mean(MagData_Drive_IMon_SmoothTmp);
MagDriveSmoothTmp = smooth(mean(MagData_NoBias,2),5);
MagDriveSmoothTmp = MagDriveSmoothTmp-mean(MagDriveSmoothTmp);
MagDrive_IMon_InPhase = MagDriveSmoothTmp/max(MagDriveSmoothTmp)*max(MagData_Drive_IMon_SmoothTmp);
Results.Magnetometry.Parameters.DriveAmp_mT = ...
    Results.Magnetometry.Parameters.Drive_mTPerAmp*(max(MagData_Drive_IMon_SmoothTmp)/Results.Magnetometry.Parameters.DriveImonVoltsPerAmp); %(mT/Amp)*[Volts/(Volts/Amp)] = (mT/Amp)*[Amps*Volts/(Volts)]

MagDrive_IMon_InPhase_RS_TMP = reshape(MagDrive_IMon_InPhase(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';

MagDrive_IMon_InPhase_OnePeriod = mean(MagDrive_IMon_InPhase_RS_TMP,1);
Results.Magnetometry.ProcessedData.DriveField = repmat(MagDrive_IMon_InPhase_OnePeriod(:),2,1);

clear MagDriveSmoothTmp MagData_Drive_IMon_SmoothTmp MagDrive_IMon_InPhase_RS_TMP MagDrive_IMon_InPhase_OnePeriod
clear MagData_NoBias


RelaxData_Drive_IMon = SendData(s,RelaxDriveAmp,0,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
RelaxData_Drive_IMon = ResampleData(RelaxData_Drive_IMon,fs,fsInterp,fDrive);
RelaxData_Drive_IMon = RelaxData_Drive_IMon(PointsToCrop:end);
RelaxDriveIMon_Reshape = reshape(RelaxData_Drive_IMon(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
RelaxAverage_Drivedata= mean(RelaxDriveIMon_Reshape,1);
Results.Relaxometry.RawData.RawDriveImon  = RelaxAverage_Drivedata-mean(RelaxAverage_Drivedata);


clear RelaxDriveIMon_Reshape RelaxAaverage_Drivedata

RelaxData_Drive_IMon_SmoothTmp = smooth(RelaxData_Drive_IMon,5);
RelaxData_Drive_IMon_SmoothTmp = RelaxData_Drive_IMon_SmoothTmp-mean(RelaxData_Drive_IMon_SmoothTmp);

RelaxDriveSmoothTmp = smooth(mean(RelaxData_NoBias,2),5);
RelaxDriveSmoothTmp = RelaxDriveSmoothTmp-mean(RelaxDriveSmoothTmp);
RelaxDrive_IMon_InPhase = RelaxDriveSmoothTmp/max(RelaxDriveSmoothTmp);
Results.Relaxometry.Parameters.DriveAmp_mT = ...
    Results.Relaxometry.Parameters.Drive_mTPerAmp*(max(RelaxData_Drive_IMon_SmoothTmp)/Results.Relaxometry.Parameters.DriveImonVoltsPerAmp); %mT/Amp*(Volts/(Volts/Amp))

clear    RelaxData_Drive_IMon_SmoothTmp   RelaxDriveSmoothTmp   RelaxData_NoBias

RelaxDrive_IMon_InPhase_RS_TMP = reshape(RelaxDrive_IMon_InPhase(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';

RelaxDrive_IMon_InPhase_OnePeriod = mean(RelaxDrive_IMon_InPhase_RS_TMP,1)*Results.Relaxometry.Parameters.DriveAmp_mT; %Units of mT
Results.Relaxometry.ProcessedData.DriveField = repmat(RelaxDrive_IMon_InPhase_OnePeriod(:),2,1);

clear RelaxDrive_IMon_InPhase_RS_TMP   RelaxDrive_IMon_InPhase




SpecData_Drive_IMon = SendData(s,SpecDriveAmp,0,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
SpecData_Drive_IMon = ResampleData(SpecData_Drive_IMon,fs,fsInterp,fDrive);
SpecData_Drive_IMon = SpecData_Drive_IMon(PointsToCrop:end);
SpecDriveIMon_Reshape = reshape(SpecData_Drive_IMon(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
SpecAverage_Drivedata= mean(SpecDriveIMon_Reshape,1);
Results.Spectroscopy.RawData.RawDriveImon  = SpecAverage_Drivedata-mean(SpecAverage_Drivedata);


clear SpecDriveIMon_Reshape SpecAaverage_Drivedata

SpecData_Drive_IMon_SmoothTmp = smooth(SpecData_Drive_IMon,5);
SpecData_Drive_IMon_SmoothTmp = SpecData_Drive_IMon_SmoothTmp-mean(SpecData_Drive_IMon_SmoothTmp);

SpecDriveSmoothTmp = smooth(mean(SpecData_NoBias,2),5);
SpecDriveSmoothTmp = SpecDriveSmoothTmp-mean(SpecDriveSmoothTmp);
SpecDrive_IMon_InPhase = SpecDriveSmoothTmp/max(SpecDriveSmoothTmp);
Results.Spectroscopy.Parameters.DriveAmp_mT = ...
    Results.Spectroscopy.Parameters.Drive_mTPerAmp*(max(SpecData_Drive_IMon_SmoothTmp)/Results.Spectroscopy.Parameters.DriveImonVoltsPerAmp); %mT/Amp*(Volts/(Volts/Amp))

clear    SpecData_Drive_IMon_SmoothTmp   SpecDriveSmoothTmp   RelaxData_NoBias

SpecDrive_IMon_InPhase_RS_TMP = reshape(SpecDrive_IMon_InPhase(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';

SpecDrive_IMon_InPhase_OnePeriod = mean(SpecDrive_IMon_InPhase_RS_TMP,1)*Results.Spectroscopy.Parameters.DriveAmp_mT; %Units of mT
Results.Spectroscopy.ProcessedData.DriveField = repmat(SpecDrive_IMon_InPhase_OnePeriod(:),2,1);

clear SpecDrive_IMon_InPhase_RS_TMP   SpecDrive_IMon_InPhase





removeChannel(s,3); %Removing the Drive Current signal channel to limit the number of input signals and maximize sampling rate







%%%%%%%%%%%%%%% BIAS CURRENT SENSE %%%%%%%%%%%%%


Ch1 = addAnalogInputChannel(s,devID,'ai2','Voltage');% Adding Bias current sense
Ch1.TerminalConfig = 'SingleEnded';

MagData_Bias_IMon = SendData(s,0,MagBiasAmp,fs,TestTime, fBias, fDrive);%acquire data, with bias field and drive field
MagData_Bias_IMon = ResampleData(MagData_Bias_IMon,fs,fsInterp,fDrive);
MagData_Bias_IMon = MagData_Bias_IMon(PointsToCrop:end);
MagBiasIMon_Reshape = reshape(MagData_Bias_IMon(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
MagAverage_Biasdata = mean(MagBiasIMon_Reshape,1);
MagAverage_Biasdata = MagAverage_Biasdata-mean(MagAverage_Biasdata);
Results.Magnetometry.RawData.RawBiasImon  = MagAverage_Biasdata;
MagNorm_BiasData= MagAverage_Biasdata/max(MagAverage_Biasdata);


clear  MagBiasIMon_Reshape  MagAverage_Biasdata


MagData_Bias_IMon_Smooth= smooth(MagData_Bias_IMon,PointsPerBiasPeriod/25); %
Bias_IMon_InPhase_RS_TMP = reshape(MagData_Bias_IMon_Smooth(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';

MagBias_IMon_InPhase_OnePeriod = mean(Bias_IMon_InPhase_RS_TMP,1);
MagBias_IMon_InPhase_OnePeriod = MagBias_IMon_InPhase_OnePeriod-mean(MagBias_IMon_InPhase_OnePeriod);
Results.Magnetometry.ProcessedData.BiasField = repmat(MagBias_IMon_InPhase_OnePeriod(:),2,1);
Results.Magnetometry.Parameters.BiasAmp_mT = ...
    Results.Magnetometry.Parameters.Bias_mTPerAmp*(max(MagBias_IMon_InPhase_OnePeriod)/Results.Magnetometry.Parameters.BiasImonVoltsPerAmp); %mT/Amp(Volts/(Volts/Amp))
clear MagData_Bias_IMon_Smooth   MagData_Bias_IMon    Bias_IMon_InPhase_RS_TMP     MagBias_IMon_InPhase_OnePeriod

Results.Magnetometry.ProcessedData.BiasField  = circshift(Results.Magnetometry.ProcessedData.BiasField ,1100);



RelaxData_Bias_IMon = SendData(s,0,RelaxBiasAmp,fs,TestTime, fBias, fDrive);%acquire data, with bias field
RelaxData_Bias_IMon = ResampleData(RelaxData_Bias_IMon,fs,fsInterp,fDrive);
RelaxData_Bias_IMon = RelaxData_Bias_IMon(PointsToCrop:end);
RelaxBiasIMon_Reshape = reshape(RelaxData_Bias_IMon(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';
RelaxAverage_Biasdata = mean(RelaxBiasIMon_Reshape,1);
RelaxAverage_Biasdata = RelaxAverage_Biasdata-mean(RelaxAverage_Biasdata);
Results.Relaxometry.RawData.RawBiasImon  = RelaxAverage_Biasdata;
Relaxnorm_BiasData= RelaxAverage_Biasdata/max(RelaxAverage_Biasdata);



RelaxData_Bias_IMon_Smooth= smooth(RelaxData_Bias_IMon,PointsPerBiasPeriod/25);
Bias_IMon_InPhase_RS_TMP = reshape(RelaxData_Bias_IMon_Smooth(1:end-ExtraPoints),PointsPerBiasPeriod,NumBiasPeriods)';

RelaxBias_IMon_InPhase_OnePeriod = mean(Bias_IMon_InPhase_RS_TMP,1);
RelaxBias_IMon_InPhase_OnePeriod = RelaxBias_IMon_InPhase_OnePeriod-mean(RelaxBias_IMon_InPhase_OnePeriod);
Results.Relaxometry.ProcessedData.BiasField = repmat(RelaxBias_IMon_InPhase_OnePeriod(:),2,1);
Results.Relaxometry.Parameters.BiasAmp_mT = ...
    Results.Relaxometry.Parameters.Bias_mTPerAmp*(max(RelaxBias_IMon_InPhase_OnePeriod)/Results.Relaxometry.Parameters.BiasImonVoltsPerAmp); %mT/Amp(Volts/(Volts/Amp))
clear RelaxData_Bias_IMon_Smooth    Bias_IMon_InPhase_RS_TMP    RelaxBias_IMon_InPhase_OnePeriod


Results.Relaxometry.ProcessedData.BiasField  = circshift(Results.Relaxometry.ProcessedData.BiasField ,1100);
Results.Relaxometry.ProcessedData.BiasField = Results.Relaxometry.ProcessedData.BiasField/max(abs(Results.Relaxometry.ProcessedData.BiasField));
Results.Relaxometry.ProcessedData.BiasField = Results.Relaxometry.ProcessedData.BiasField*Results.Relaxometry.Parameters.BiasAmp_mT;





%%

%plot normalized averaged data
% figure,plot(tBiasPeriod,norm_SignalData, 'b')
% hold on
% plot(tBiasPeriod,MagNorm_BiasData, 'r')
% title(SPION_Info.Name)
% xlabel('Time [s]')
% legend('measured Rx voltage (normalized and background subtracted)','measured Bias current (Hall, normalized)','Location','northwest')
% ylim([-1 1])
% disp('Data Acquisition Done')

Results.Magnetometry.RawData.TimeVec = 0:1/fsInterp:(length(Results.Magnetometry.RawData.RawSignal)-1)/fsInterp;
tMag = Results.Magnetometry.RawData.TimeVec;

PointsPerDrivePrd = Results.Magnetometry.Parameters.fsInterp/Results.Magnetometry.Parameters.fDrive;
[MagOutputs,MagParams]=Magnetometry_V1(SPION_Info,Results.Magnetometry.Parameters,Results.Magnetometry.RawData.RawSignal(:),Results.Magnetometry.ProcessedData.BiasField(:),PointsPerDrivePrd*2,'-');

Results.Magnetometry.Output.BiasFieldPlot = MagOutputs.BiasFieldPlot*1000 ;
Results.Magnetometry.Output.Susceptibility = MagOutputs.Susceptibility;
Results.Magnetometry.Output.Magnetization = MagOutputs.Magnetization;
Results.Magnetometry.Output.MagParams = MagParams;
Results.Magnetometry.Output.SaturationMag = max(Results.Magnetometry.Output.Magnetization);
clear MagOutputs MagParams
%% Relaxometry Analysis

TotalField =Results.Relaxometry.ProcessedData.DriveField +Results.Relaxometry.ProcessedData.BiasField;
Results.Relaxometry.ProcessedData.Startpoint=min([find(TotalField==max(TotalField)) find(TotalField==min(TotalField))]);
Startpoint = Results.Relaxometry.ProcessedData.Startpoint;
RelaxSignalData_OneBiasPeriod = repmat(Results.Relaxometry.RawData.RawSignal(:),2,1);

PlotLims = 60; %The extent of the plot x axis in mT
InterpTF = 0;
InterpFactor  = 1;
% Relaxometry_V0(Data_Sig,BiasSig,Fd,fs,InterpTF,InterpFactor,Conc,PlotLims)

[RelaxOutputs,RelaxColors] = Relaxometry_V0(RelaxSignalData_OneBiasPeriod(Startpoint:Startpoint+PointsPerBiasPeriod/2),TotalField(Startpoint:Startpoint+PointsPerBiasPeriod/2),fDrive,fsInterp,InterpTF,InterpFactor,SPION_Info.Concentration,PlotLims);

Results.Relaxometry.Output.MaxSig_Bucket = RelaxOutputs.MaxSig_Bucket;
Results.Relaxometry.Output.MinSig_Bucket= RelaxOutputs.MinSig_Bucket;
Results.Relaxometry.Output.RMag_Output = RelaxOutputs.RMag_Output;
Results.Relaxometry.Output.LMag_Output = RelaxOutputs.LMag_Output;
Results.Relaxometry.Output.MaxSigBias_Bucket = RelaxOutputs.MaxSigBias_Bucket;
Results.Relaxometry.Output.MinSigBias_Bucket = RelaxOutputs.MinSigBias_Bucket;
Results.Relaxometry.Output.VelCorrectedSig = RelaxOutputs.VelCorrectedSig;
Results.Relaxometry.Output.RelaxColors = RelaxColors;
Results.Relaxometry.Output.FWHM_MaxData = RelaxOutputs.FWHM_MaxData;
Results.Relaxometry.Output.FWHM_MinData = RelaxOutputs.FWHM_MinData;
Results.Relaxometry.Output.MaxDeviation_MaxSig = RelaxOutputs.MaxDeviation_MaxSig;
Results.Relaxometry.Output.MaxDeviation_MinSig = RelaxOutputs.MaxDeviation_MinSig;
%% Spectroscopy Analysis

Results.Spectroscopy.ProcessedData.SpecDataFFT = fft(SpecSubtractedData);
Results.Spectroscopy.ProcessedData.SpecDataL = length(SpecSubtractedData);
L = Results.Spectroscopy.ProcessedData.SpecDataL;
FFTMag2S = abs(Results.Spectroscopy.ProcessedData.SpecDataFFT/L);
Results.Spectroscopy.ProcessedData.FFTMag1S = FFTMag2S(1:round(L/2))*2;
Results.Spectroscopy.ProcessedData.FFTMag1S = Results.Spectroscopy.ProcessedData.FFTMag1S(:); %making into a column

Results.Spectroscopy.ProcessedData.FFTPhase = angle(Results.Spectroscopy.ProcessedData.SpecDataFFT(:));
Results.Spectroscopy.ProcessedData.FFTPhase = Results.Spectroscopy.ProcessedData.FFTPhase(1:round(L/2));

Results.Spectroscopy.ProcessedData.fVector = fsInterp*(0:(L/2-1))/L;
Results.Spectroscopy.ProcessedData.fVector =Results.Spectroscopy.ProcessedData.fVector(:); %making into a column
fVec = Results.Spectroscopy.ProcessedData.fVector;
F1Mag = Results.Spectroscopy.ProcessedData.FFTMag1S(fVec==fDrive);
F3Mag = Results.Spectroscopy.ProcessedData.FFTMag1S(fVec==fDrive*3);

Results.Spectroscopy.Output.NonlinearityIndex = F1Mag/F3Mag;
figure,semilogy(fVec/fDrive,Results.Spectroscopy.ProcessedData.FFTMag1S)

clear FFTMag2S


%% Plotting and Exporting
TmpStr = fieldnames(Results.Spectroscopy.Parameters);
if not(strcmp(TmpStr{end},'DriveAmp_mT'))
    Results.Spectroscopy.Parameters.DriveAmp_mT = Results.Relaxometry.Parameters.DriveAmp_mT;
end
[CompositeFig] = MPS_Composite_Fig_V1(SPION_Info,UserData,Results,'b');

if StartTic==1
    Results.TotalExperimentTime = toc;
else
    Results.TotalExperimentTime = 0;
end
StartTic=0;
clear TmpStr

ExportData_V1(SPION_Info,UserData,Results,CompositeFig)

Results.Relaxometry.Output.FWHM_MaxData
Results.Relaxometry.Output.MaxDeviation_MaxSig

%%
function [data] = SendData(s,DriveAmp,BiasAmp,fs,PulseTime, fBias, fDrive)

timepts = 0:1/fs:PulseTime;

DriveFunk = @(t) DriveAmp* sin(2*pi*fDrive*t);
DriveData = DriveFunk(timepts);

BiasFunk = @(t)BiasAmp*sin(2*pi*fBias*t);
BiasData = BiasFunk(timepts);

queueOutputData(s,[[DriveData 0]',[BiasData 0]'])
data = startForeground(s);
data = data(1:end-2,:);


end




