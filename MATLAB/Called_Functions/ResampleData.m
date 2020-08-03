function [DataInterp,tNew] = ResampleData(DataOrig,fsOrig,fsNew,fDrive)
% This function takes in a data vector or matrix where the time vector is
% the column direction at one sampling rate and resamples it at a different
% sampling rate. If the DataOrig is a matrix it will treat each column
% independently.

L = size(DataOrig,1);
tOrig = linspace(0,(L-1)/fsOrig,L);
tOrig = tOrig(:);

if nargin()==4
    LNew = round(tOrig(end)*fDrive)/fDrive*fsNew;
    tNew = linspace(0,tOrig(end),LNew);
    tNew = tNew(:);
else
    tNew = linspace(0,tOrig(end),L*fsNew/fsOrig);
    tNew = tNew(:);
    if(mod(length(tNew),2)==1);tNew(end) = [];end %ensuring there is an even number of points
end



DataInterp = zeros(size(tNew,1),size(DataOrig,2));
for i = 1:size(DataOrig,2)
    DataInterp(:,i) = interp1(tOrig,DataOrig(:,i),tNew,'spline');
end