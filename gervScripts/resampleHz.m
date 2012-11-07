function a = resampleHz(a,fs,rate)
% a = audio
% fs = fs
% rate = whatever hz

t = 0: 1/rate : (size(a,1) / fs - 1/rate);
told = 0:1/fs:(size(a,1)/fs-1/fs);
ats = timeseries(a,told);
ats = resample(ats,t);
a = squeeze(ats.Data);
