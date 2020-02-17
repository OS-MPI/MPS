function [FAmp,FPhase] = FourierAmplitude_2(Data,Fs,F0,~)
%DiscSamples is the number of discrete samples per FT analysis
Data = Data(1:end-mod(length(Data),Fs/(F0)));
if mod(length(Data),2)==1
    Data = Data(1:end-Fs/F0);
end
[FAmp,FPhase]=plotFT(Data,Fs,F0,1,'b',0,0);

end


% function [F3Amp,F3Phase,f,P1] = plotFT(Signal,Fs,F0,C,PlotOn,PhaseOn)
function [FAmp,FPhase] = plotFT(Signal,Fs,F0,Fselect,C,PlotOn,PhaseOn)
if mod(length(Signal),2)==1
    Signal = Signal(1:end-1,:);
end
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
% disp(num2str(f(2)-f(1)))
if PlotOn==1
    figure,semilogy(f,P1,C)
    hold on
    title('Single-Sided Amplitude Spectrum of X(t)')
    xlabel('f (Hz)')
    ylabel('|P1(f)|')
end
FAmp = [P1(f/F0==Fselect) P1(f/F0==Fselect*3) P1(f/F0==Fselect*5)];
FPhase =  [YPhase(f/F0==Fselect)  YPhase(f/F0==Fselect*3)  YPhase(f/F0==Fselect*5)];
if isempty(FAmp)
    FAmp=mean(P1(abs(f/F0-Fselect)==min(abs(f/F0-Fselect))));
    FPhase=min(YPhase(abs(f/F0-Fselect)==min(abs(f/F0-Fselect))));
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
