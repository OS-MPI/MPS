function [Amp] = SpiceTFData2Mag(FileName,FreqSample)
% This function takes in LTSpice data for the transfer function between a
% voltage source and a current (could be others things too) and selects the
% interpolated value at a specific frequency. To get the file you should go
% to your plot in LTSpice and go to File->Export Data as Text and then
% export it as a CARTESIAN not polar

% Example Data from the text file:
% Freq.	I(Ldrive)
% 1.00000000000000e+003	9.30446424313157e-004,3.32921433160558e-002
% 1.00230523807790e+003	9.35235428146482e-004,3.33780641983375e-002
% 1.00461579027840e+003	9.40051507073702e-004,3.34642515872294e-002


fid = fopen(FileName);
LTSpice_DataCell = textscan(fid,'%f %f %f','HeaderLines',1,'Delimiter',',');
fclose(fid);
LTSpice_Data = cell2mat(LTSpice_DataCell);
Mag = abs(LTSpice_Data(:,2)+1i*LTSpice_Data(:,3));
Freq = LTSpice_Data(:,1);
Amp = interp1(Freq,Mag,FreqSample);

