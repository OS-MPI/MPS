function [FPickAmp] = FourierAnalyze_v2(Data,Fs,F0,DiscSamples,FPick)
%DiscSamples is the number of discrete samples per FT analysis
plotFT(Data(:,1),Fs,F0,3,'b',1,0);
SamplesPerPeriod=Fs/F0;
DiscSamples = 2*(DiscSamples-mod(DiscSamples,SamplesPerPeriod));
Count = 0;
for i=1:length(Data)-DiscSamples-1
    Count  =Count+1;
    [F2Amp(:,Count),FPhase1(Count)]=plotFT(Data(i:i+DiscSamples-1,1),Fs,F0,2,'b',0,0);
    [FPickAmp(:,Count),FPhase2(Count)]=plotFT(Data(i:i+DiscSamples-1,1),Fs,F0,FPick,'b',0,0);
    MeanBias(Count) = mean(Data(i:i+DiscSamples-1,2));
    
end
% figure,plot(MeanBias,FPickAmp,'b')
% hold on
% plot(MeanBias,F2Amp,'r')
% figure,plot(FPickAmp)

end


% function [F3Amp,F3Phase,f,P1] = plotFT(Signal,Fs,F0,C,PlotOn,PhaseOn)
function [FAmp,FPhase] = plotFT(Signal,Fs,F0,Fselect,C,PlotOn,PhaseOn)

%This function takes the signal, returns F3 amp and phase and plots it 

T = length(Signal)/Fs;             % Sampling period
L = length(Signal);             % Length of signal
Y_signal = fft(Signal);
P2 = abs(Y_signal/L);
P1 = P2(1:L/2+1);
YPhase = angle(Y_signal(1:L/2+1));
YPhase(P1<.00000001)=0;
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;
if PlotOn==1
    figure(94),semilogy(f,P1)
    hold on
    title('Single-Sided Amplitude Spectrum of X(t)')
    xlabel('f (Hz)')
    ylabel('|P1(f)|')
end
FAmp = P1(f/F0==Fselect);
FPhase = YPhase(f/F0==Fselect);
if isempty(FAmp)
    FAmp=P1(abs(f/F0-Fselect)==min(abs(f/F0-Fselect)));
    FPhase=YPhase(abs(f/F0-Fselect)==min(abs(f/F0-Fselect)));
end
if PhaseOn==1
    %     figure(7),plot(f,YPhase)
    %     hold on
    t = 0:dt:3-dt;
    Recon = ifft(Y_signal);
    ReconMinusf3 = Recon(1:3000)-FAmp*sin(2*pi*3*t+FPhase);
%     
    figure(8),plot(t,Recon(1:3000),'b',t,ReconMinusf3,'r')
%     hold on
%     plot(ReconMinusf3,'r')
    xlim([0 3])
    ylim([-.05 .05])
end


end
