function [Signal,M] = SignalSim_Experimental(X,MParticle,HLim,fs,fDrive,fSelect)

if fs<100e3;fs=100e3;end
fs = ceil(fs/fDrive)*fDrive; %ensuring the sampling rate is a multiple of the drive freq.

Ramp = HLim*(0:1/fs:1-1/fs); %ramp from 0 to limits of applied field
t = 0:1/fs:1-1/fs; %time vector
DriveField = sin(2*pi*fDrive*t).*Ramp;
M = ParticleInterp(X,MParticle,DriveField);
WindowSize = 1000;
HannWindow = 0.5*(1-cos(2*pi*linspace(0,1,WindowSize)));
Count = 0;
for i = round(WindowSize/2):WindowSize:length(t)-round(WindowSize/2)-1
    Count = Count+1;
    TestM = M(i-round(WindowSize/2)+1:i+round(WindowSize/2));
    TestM = TestM.*HannWindow;
    [Mag(:,Count), Phase(:,Count), f] = Fourier(TestM,fs);
    Harmonics = Mag(mod(f/fDrive,1)==0,Count);
    if nargin<6
        Signal(Count,1) = sum(Harmonics(2:end));
    else
        Signal(Count,1) = Harmonics(fSelect+1);
    end
    Signal(Count,2) = Ramp(i);%Amplitude at the cetner of FT

end

figure(85),semilogy(f/fDrive,Mag(:,end))
hold on
xlabel('F/Fdrive')
ylabel('Signal Amplitude')
figure(16),plot(Signal(:,2),Signal(:,1))
hold on
xlabel('Drive field Amplitude (mT)')
ylabel('Simulated Signal (Arb.Units)')

end


function [M] = ParticleInterp(X,MParticle,H)
MParticle(X(2:end)==X(1:end-1))=[];
X(X(2:end)==X(1:end-1))=[];

X(MParticle(2:end)==MParticle(1:end-1))=[];
MParticle(MParticle(2:end)==MParticle(1:end-1))=[];

M = interp1(X,MParticle,H,'spline');

end

function [Mag,Phase,f] = Fourier(M,Fs)

L = length(M);             % Length of signal
if mod(L,2)~=0
    M = M(1:end-1);
    L=L-1;
end
Y_signal = fft(M);
P2 = abs(Y_signal/L); 
Mag = P2(1:L/2+1); 
Phase = angle(Y_signal(1:L/2+1));
Phase(Mag<1e-6)=0;

f = Fs*(0:(L/2))/L; %Freq. vector

end