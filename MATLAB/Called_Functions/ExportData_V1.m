function [] = ExportData_V1(SPION_Info,UserData,Results)
% This function should take in the essential data from one of the analysis
% scripts and export it with a LaTeX document which can then be saved as a
% PDF.


DateToday = date;
Name = [SPION_Info.Name,'_',DateToday ];
Name(Name=='-')='_';
eval([Name,'.SPION_Info','=SPION_Info'])
eval([Name,'.UserData','=UserData'])
eval([Name,'.Results','=Results'])

Name_Orig = ['DataTemp/' DateToday,'/' Name];
%A simple function to save data in a consistent manner

Params = {'Particle Name'
    'Particle Manufacturer'
    'SPION Lot'
    'SPION Mfg. Date'
    'SPION Core Size'
    'SPION Hydrodynamic Diameter'
    'Concentration'
    'Sample Volume'
    'SPION Coating'
    'Notes'
    'User Name'
    'User Location'
    };
Vals = {
    SPION_Info.Name
    SPION_Info.Manufacturer
    SPION_Info.Lot
    SPION_Info.DateMade
    num2str(SPION_Info.CoreSize)
    num2str(SPION_Info.HydroSize)
    num2str(SPION_Info.Concentration)
    num2str(SPION_Info.Volume)
    SPION_Info.Coating
    SPION_Info.Notes
    UserData.Name
    UserData.Location
    };

BasicData = table(Params,Vals);
i = 0;
Name_New = Name_Orig;
if exist([Name_Orig])==7
    while exist([Name_New])==7
        Name_New = strcat(Name_Orig,'_',num2str(i));
        i = i+1;
    end
end
ExportFileName = [Name_New,'.tex'];
mkdir(Name_New)
writetable(BasicData,[Name_New,'/',Name,'.txt'])

%% Magnetometry
MagFig = figure('Units','Inches','Position',[1 1 7.5 5]);
subplot(2,1,1)
plot(Results.Magnetometry.Output.BiasFieldPlot,Results.Magnetometry.Output.Susceptibility)
xlabel('External Magnetic Field [mT]')
ylabel('dM/dH')
title({SPION_Info.Name;date})

subplot(2,1,2)
plot(Results.Magnetometry.Output.BiasFieldPlot(2:end),Results.Magnetometry.Output.Magnetization)
xlabel('External Magnetic Field [mT]')
ylabel('Magnetization')
MagnetometryPath = [Name,'_MagFig.png'];
print(MagFig,[Name_New,'/',MagnetometryPath],'-dpng')

MagParams = {'Sampling Freq.'
    'Interpolated Freq.'
    'Drive Freq.'
    'Bias Freq.'
    'Bias Waveform Shape'
    'Bias Amplitude (mT)'
    'Bias Amplitude (Volts)'
    'Bias Amplifier Name'
    'Bias Current Monitor Volts Per Amp'
    'Bias Field mT per Amp'
    'Drive Amplitude (mT)'
    'Drive Amplitude (Volts)'
    'Drive Amplifier Name'
    'Drive Current Monitor Volts Per Amp'
    'Drive Field mT per Amp'
    'Power Supply Name'
    'Pre-Amplifier Name'
    'Pre-Amplifier Gain'
    'Test Time'
    'Number of Averages'};
MagVals = {num2str(Results.Magnetometry.Parameters.fs)
    num2str(Results.Magnetometry.Parameters.fsInterp)
    num2str(Results.Magnetometry.Parameters.fDrive)
    num2str(Results.Magnetometry.Parameters.fBias)
    Results.Magnetometry.Parameters.BiasWaveShape
    num2str(Results.Magnetometry.Parameters.BiasAmp_mT)
    num2str(Results.Magnetometry.Parameters.BiasAmp_Volts)
    Results.Magnetometry.Parameters.BiasAmp_AmpName
    num2str(Results.Magnetometry.Parameters.BiasImonVoltsPerAmp)
    num2str(Results.Magnetometry.Parameters.Bias_mTPerAmp)
    num2str(Results.Magnetometry.Parameters.DriveAmp_mT)
    num2str(Results.Magnetometry.Parameters.DriveAmp_Volts)
    Results.Magnetometry.Parameters.DriveAmp_AmpName
    num2str(Results.Magnetometry.Parameters.DriveImonVoltsPerAmp)
    num2str(Results.Magnetometry.Parameters.Drive_mTPerAmp)
    Results.Magnetometry.Parameters.PowerSupplyName
    Results.Magnetometry.Parameters.PreAmpName
    num2str(Results.Magnetometry.Parameters.PreAmpGain)
    num2str(Results.Magnetometry.Parameters.TestTime)
    num2str(Results.Magnetometry.Parameters.NumAverages)};

MagParamsData = table(MagParams,MagVals);
writetable(MagParamsData,[Name_New,'/',Name,'MagParams.txt']);



%% Relaxometry (still need to update from the prev. version)
RelaxFig = figure('Units','Inches','Position',[1 1 7.5 5]);
subplot(2,1,2)
plot(RelaxOutputs.MaxSigBias_Bucket,RelaxOutputs.MaxSig_Bucket/max(RelaxOutputs.MaxSig_Bucket),'Color',RelaxColors.RProfileColor,'LineWidth',2)
hold on
plot(RelaxOutputs.MinSigBias_Bucket,abs(RelaxOutputs.MinSig_Bucket/max(abs(RelaxOutputs.MinSig_Bucket))),'Color',RelaxColors.LProfileColor,'LineWidth',2)

legend('Right scanning','Left scannning')

subplot(2,1,1)
plot(RelaxOutputs.MaxSigBias_Bucket,RelaxOutputs.RMag_Output,'Color',RelaxColors.RProfileColor,'LineWidth',2)
hold on
plot(RelaxOutputs.MaxSigBias_Bucket,RelaxOutputs.LMag_Output,'Color',RelaxColors.LProfileColor,'LineWidth',2)
legend('Right scanning','Left scannning')


RelaxometryPath = [Name,'_RelaxFig.png'];
print(RelaxFig,[Name_New,'/',RelaxometryPath],'-dpng')
%% Spectroscopy (still need to update from the prev. version)

figure(12),semilogy(f,Mag,'k','LineWidth',0.5)
hold on
semilogy(f(mod(f,fDrive)==0 & f~= 0), FTMagnitude(mod(f,fDrive)==0 & f~= 0),'bo','LineWidth',2)
semilogy(f(mod(f,fDrive*2)==0 & f~= 0), FTMagnitude(mod(f,fDrive*2)==0 & f~= 0),'ro','LineWidth',2)
xlabel('Frequency')
ylabel('Spectral Amplitude')


%% General Fig
figure(SaveFig)
savefig([Name_New,'/',Name])
print(SaveFig,[Name_New,'/',Name,'.png'],'-dpng')
clear SaveFig
save([Name_New,'/',Name],Name)



%% Compiling all the information into a LaTeX doxument
OpeningText = '\\documentclass{article}\n\\usepackage[utf8]{inputenc}\n\\usepackage{graphicx}\n\\title{ADD TITLE}\n\\date{\\today}\n\\begin{document}\n';
EndText = '\n\\end{document}';
TextStr = '\\section{Acquisition Parameters}\n\\begin{itemize}';
for i = 1:height(BasicData)
    
    TextStr = [TextStr,'\t\\item{\\textbf{',BasicData.Params{i},'}:',BasicData.Vals{i} ,'}\n'];
    
end
TextStr = [TextStr,'\\end{itemize}\n'];
TextStr = [TextStr,'\n\\section{Magnetometry}\n\n\\begin{itemize}'];
for i = 1:height(MagParamsData)
    
    TextStr = [TextStr,'\\textbf{',MagParamsData.MagParams{i},'}:',MagParamsData.MagVals{i} ,'\n'];
    
end
TextStr = [TextStr,'\\end{itemize}\n'];    
MagnetometryCaption = 'TestCaption for Mag';
[TextStr] = FigText(TextStr,MagnetometryPath,MagnetometryCaption);

TextStr = [TextStr,'\n\\section{Relaxometry}\n\\begin{itemize}'];
[TextStr] = FigText(TextStr,RelaxometryPath,RelaxometryCaption);


TextStr = [TextStr,'\\end{itemize}\n'];

TextStr = [TextStr,'\n\\section{Spectroscopy}\n\\begin{itemize}'];
[TextStr] = FigText(TextStr,SpectroscopyPath,SpectroscopyCaption);

TextStr = [TextStr,'\\end{itemize}\n'];

FileID = fopen(ExportFileName,'w');
fprintf(FileID,[OpeningText TextStr EndText]);
fclose(FileID);
end


function [TextStr] = FigText(TextStr,Path,Caption)

TextStr = [TextStr,'\\begin{figure}[h] \n \\centering \n \\includegraphics[width=0.9\\textwidth]{',Path,'}\n \\caption{', Caption,'}\n \\end{figure}'];

end




% 'Sampling Rate'
%     'Number of Test Averages'
%     'Length of each acquision'
%     'Drive Amplifier'
%     'Drive Amp Volts'
%     'Drive Amp mT'
%     'Drive Frequency'
%     'Drive Power Supply Name'
%     'Bias Amplifier'
%     'Bias Amp Volts'
%     'Bias Amp mT'
%     'Bias Frequency'
