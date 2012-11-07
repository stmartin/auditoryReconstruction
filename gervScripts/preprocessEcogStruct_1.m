clear all
% Add paths for analysis
addpath(genpath('~/Dropbox/DataSync/knightLab/choldgraf/matlab/gervScripts'));
addpath(genpath_exclude('/home/knight/bpasley/matlab/toolbox', 'jacket'));
addpath('/home/knight/bpasley/matlab');

basedir = '/home/knight/holdgraf/data/gerwinSchalk/subjData/';
saveDir = '/home/knight/holdgraf/data/gerwinSchalk/subjData/';
cd([basedir '/subject_31'])

%  set regular expression of all files you want to preprocess
flist=dir('origGVPhrases*');

% if you want to use parallel computing toolbox:
if matlabpool('size') < 2
    matlabpool open 8
end

disp(['Processing ' num2str(size(flist, 1)) ' files:']);
for item = [1:length(flist)]
    disp(flist(item).name);
end

% assign reference and ground channels for each data set to be processed. RefGround channels can differ for each case
% (each index of the cell array is the ref/ground pair for each different data set 
% in flist
refground={[]};
 
for k=1:length(flist)
    
    load(flist(k).name)
    disp(['Processing file ' flist(k).name]);
    clear CARchans

    % data is recorded on subgrids, 16 channels each, do CAR on each
    % separately
    maxChan = max(ecog.goodchannels);
    if maxChan > 64
        CARchans={1:16,17:32,33:48,49:64,65:80,81:96,97:maxChan};
    else
        CARchans={1:maxChan};
    end
    
    disp('Common Average Reference...')
    for c=1:size(ecog.data, 2)
        % Sets the noise within channels to the average of non-noisy
        % timepoints
        badidx = find(abs(myzscore(ecog.data(:, c))) > 5);
        goodidx = find(abs(myzscore(ecog.data(:, c))) <= 5);
        ecog.data(badidx, c) = mean(ecog.data(goodidx, c));
    end
    
    disp(['Detrending data...'])
    ecog.data = locdetrend(double(ecog.data), ecog.dataFs, [5 1]);
    %badidx=find(abs(myzscore(ecog.data))>10);
    %ecog.data(badidx)=0;
    p = var(ecog.data);
    badchans = find(myzscore(p)>5);
    
    disp(['Removing bad channels...']);
    ecog.goodchannels = setdiff(ecog.goodchannels, badchans);
    ecog.data = double(eg_CAR(ecog, CARchans));
    
    disp('Removing 60Hz line noise...')
    ecog.data=single(eg_rmlinenoise(ecog, 60));
    ecog.audioFs=16000;
    
    if ecog.audioFs ~= 16000
        disp(['Audio sample rate is ' num2str(ecog.audioFs) '.  Resampling to 16000Hz'])
        ecog.audio = resample16khz(ecog.audio,ecog.audioFs);
        ecog.audioFs = 16000;
    end
    soundLength = length(ecog.data) ./ 1000;
    datLength = length(ecog.audio) ./ 16000;
    disp(['Data and sound vector length: ' num2str(datLength) ' ' num2str(soundLength)]);
  
    saveName = ['CAR_' flist(k).name '_B' num2str(k)];
    fprintf(['Saving to directory: ' saveDir]);
    fprintf(['Filename: ' saveName '\n\n']);
    save([saveDir '/subject_31/' saveName],'ecog')
end

