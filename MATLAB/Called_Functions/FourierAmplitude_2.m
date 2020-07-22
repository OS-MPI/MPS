function [FAmp,FPhase] = FourierAmplitude_2(Data,Fs,F0,~)
%Perhaps a bad name, but this function picks the amplitude and phase of the
%first, third, and fifth harmonic (for now-- can easily add others later
%versions).


%DiscSamples is the number of discrete samples per FT analysis
Data = Data(1:end-mod(length(Data),Fs/(F0))); %Crops the data such that there is an integer number of drive periods

if mod(length(Data),2)==1 % Makes sure that there is an even number of drive samples
    Data = Data(1:end-Fs/F0);
end
[FAmp,FPhase]=plotFT(Data,Fs,F0);

end


function [FAmp,FPhase] = plotFT(Signal,Fs,F0)
if mod(length(Signal),2)==1
    Signal = Signal(1:end-1,:);
end
%This function takes the signal, returns F1 amp and phase and plots it 

L = length(Signal);             % Length of signal
Y_signal = fft(Signal);
P2 = abs(Y_signal/L);
P1 = P2(1:L/2+1);
YPhase = angle(Y_signal(1:L/2+1));
YPhase(P1<.00000001)=0;
P1(2:end-1) = 2*P1(2:end-1);
f = Fs*(0:(L/2))/L;

% disp(num2str(f(2)-f(1))) %this would display the bandwidth of each
% frequency band in the FT

FAmp = [P1(f/F0==1) P1(f/F0==3) P1(f/F0==5)]; %Right now it selects only the first, 3rd and 5th harmonic... needs to be all of them (next version)


FPhase =  [YPhase(f/F0==1)  YPhase(f/F0==3)  YPhase(f/F0==5)];

if isempty(FAmp)
    FAmp=mean(P1(abs(f/F0-F0)==min(abs(f/F0-F0))));
    FPhase=min(YPhase(abs(f/F0-F0)==min(abs(f/F0-F0))));
end



end
