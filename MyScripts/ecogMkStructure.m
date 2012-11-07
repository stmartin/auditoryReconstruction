%function ecogMkStructure(path, saveFileName)
%% CREATE AN ECOG-STRUCTURE (THE BASIC DATA STRUCTURE) OF THE WHOLE RECORDED TIMESERIES 
% change the path and and savepath and saveFileName. Prior to using this
% script, you should create a subjInfo structure

path='/home/knight/smartin/subjData/subject_33/';
savepath ='/home/knight/smartin/subjData/subject_33/';
saveFileName='ecogB';
%addpath(path);
cd(path);
subj=33;

load([path 'subjInfo.mat']); % subjInfo has to be created manually
fname = dir('ECOGS001R0*.dat');
nbloc=length(fname);

for i=1:nbloc
    filename=fname(i).name;
    display(['load data bloc ' num2str(i)]);

    %% load the data with BCI2000
    [ signal, states, parameters, total_samples, file_samples] = load_bcidat([path filename]);
    nChan = subjInfo.nChans;
    ecog.data = signal(:,1:nChan)'; 

    %% create a basic ecog structure
    display(['create ecog structure bloc ' num2str(i)]);
    baselineDurMs = 0;
    sampDur = 1000/parameters.SamplingRate.NumericValue;
    ecog = ecogRaw2Ecog(ecog.data, baselineDurMs, sampDur, []); % Jochem's function

    %% add subjInfo
    ecog.audio = signal(:,subjInfo.micChan); 
    ecog.audioFs = parameters.SamplingRate.NumericValue; 
    ecog.dataFs=parameters.SamplingRate.NumericValue; 
    ecog.audio=resampleHz(ecog.audio,ecog.audioFs, 16000); % up sampling of the audio 
    % channel to be able to compute a speech representation ranging from 0-7'000 Hz
    ecog.audioFs=16000;
    ecog.name=['GV' num2str(subj) '_Ticker' ]; % *useless? might at some point be used in Brian's script*

    %% add trigger 
    ecog.triggerTS=states.StimulusCode;

    saveFileName_i = [saveFileName num2str(i)];
    save(fullfile(savepath, saveFileName_i), 'ecog','-v7.3')
end









