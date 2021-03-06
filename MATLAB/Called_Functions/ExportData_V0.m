function [] = ExportData_V0(Name,Concentration,Particles,RepeatTests,Type,AcqTime,fs,Drive,Bias,Data,RelaxOutputs,RelaxColors,f,FTMagnitude,FTPhase,SaveFig)
DateToday = date;

NameSame_Orig = ['DataTemp/' DateToday,'/' Name];
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
if exist([NameSame_Orig])==7
    while exist([NameSame_New])==7
        NameSame_New = strcat(NameSame_Orig,num2str(i));
        i = i+1;
    end
end
mkdir(NameSame_New)
writetable(BasicData,[NameSame_New,'/',Name,'.txt'])
% figure, subplot(2,1,1) 
% plot(Data.BiasFieldVector,Data.Susceptibility/max(Data.Susceptibility))
% xlabel('External Magnetic Field [T]')
% ylabel('dM/dH (Normalized)')
% title({Particles;date})
% 
%     subplot(2,1,2) 
% plot(Data.BiasFieldVector(2:end),Data.Magnetization/max(Data.Magnetization))
% xlabel('External Magnetic Field [T]')
% ylabel('Magnetization [a.u.]')
figure(SaveFig)
savefig([NameSame_New,'/',Name])
clear SaveFig
save([NameSame_New,'/',Name])


