function [] = ExportData_V0(Name,Concentration,Particles,RepeatTests,Type,AcqTime,fs,Drive,Bias,Data,f,FTMagnitude,FTPhase)
NameSame_Orig = ['DataTemp/' Name];
%A simple function to save data in a consistent manner

Params = {'Acquision Type'
    'Particles'
    'Concentration'
    'Sampling Rate'
    'Number of Test Averages'
    'Length of each acquision'
    'Drive Amplifier'
    'Drive Amp Volts'
    'Drive Amp mT'
    'Drive Frequency'
    'Drive Power Supply Name'
    'Bias Amplifier'
    'Bias Amp Volts'
    'Bias Amp mT'
    'Bias Frequency'};
Vals = {Type
    Particles
    num2str(Concentration)
    num2str(fs)
    num2str(RepeatTests)
    num2str(AcqTime)
    Drive.Name
    Drive.Volts
    Drive.mT
    Drive.Freq
    Drive.PowerSupplyName
    Bias.Name
    Bias.Volts
    Bias.mT
    Bias.Freq};

BasicData = table(Params,Vals);
i = 0;
NameSame_New = NameSame_Orig;
if exist([NameSame_Orig,'.txt'])==2
    while exist([NameSame_New,'.txt'])==2
        NameSame_New = strcat(NameSame_Orig,num2str(i));
        i = i+1;
    end
end
writetable(BasicData,[NameSame_New,'.txt'])

    
save(NameSame_New)


