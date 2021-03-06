%%%% This script pulls behavioral data from raw ECoG files and incorporates
%%%% them into pre-existing ECoG analysis files.
addpath('~/Dropbox/DataSync/knightLab/choldgraf/matlab/gervScripts/bciFiles/');

%% Parameters
subNum = 31; subStr = num2str(subNum);
blockNum = 4; blockStr = num2str(blockNum);
numElectrodes = 98; % How many electrodes are actually recording brain activity?

%% Load the data
% Load the raw data
rawDir = ['/home/knight/holdgraf/data/gerwinSchalk/rawData/subject_' subStr '/'];
rawFile = ['ECOGS001R0' blockStr '.dat'];
[gdat states parameters] = load_bcidat([rawDir rawFile]);

% Load the processed ecog structure
procDir = ['/home/knight/holdgraf/data/gerwinSchalk/subjData/subject_' subStr '/'];
procFile = ['a2GVPhrases_S31_B' blockStr '.mat'];
load([procDir procFile], 'ecog');
brainData = ecog.data{1}(:, 1:numElectrodes);

% Load the spectrogram file that Brian created
audioDir = ['/home/knight/holdgraf/data/gerwinSchalk/subjData/subject_' subStr '/'];
audioFile = ['subject_31stim.freq32.origGVPhrases_S31_B' blockStr '.mat'];
load([audioDir audioFile], 'speech');
audioData = speech.s;
audioData = audioData(1:length(brainData), :);

%% Massage the data
% Need to make the stimulus code vector work well with the brain data
% Calculate how much we need to resample the stimcodes
samplingScale = parameters.SamplingRate.NumericValue / ecog.dataFs;

% stims 21-30 are when people should be thinking/speaking the sentence
stimVec = [21:30]; % Indices of the stimulus codes of interest
stimCodes = states.StimulusCode;
stimCodes = downsample(stimCodes, 96); % Downsample stimCodes to match brain data
stimCodes = stimCodes(1:length(brainData));

%% Do the Merging
% Go through the ecog.data structure, pull out the timeseries that
% correspond to certain sentences, and concatenate each stimuli's values into 
% into an N x D stimulus matrix with another vector of indices that marks the start
% and end of each stimulus.
pastStim = 'NA';
countVec = ones(1, length(stimVec));
nonStim = 0;
countVec = zeros(length(brainData), 1);
ecogMerge = {};


%% Stim pulling
% Now iterate through the stim codes we want, 
% pull out the brain activity related with those stims, 
% and mark when the blocks end/begin 

stimCells = {};
audioCells = {};
for i = 1:length(stimVec)
    stimCode = stimVec(i);
    pullIdxs = find(stimCodes == stimCode);
    brainDataPull = [pullIdxs brainData(pullIdxs, :)];
    audioDataPull = [pullIdxs audioData(pullIdxs, :)];
    
    % Now iterate through the indices for that stimulus, if the jump in idx
    % is >1, it means that we have a new block, so mark it.
    newIdxs = zeros(length(brainDataPull), 1);
    count = 1;
    for  j = 2:length(brainDataPull)
        diff = brainDataPull(j, 1) - brainDataPull(j-1, 1);
        if diff > 1
            count = count + 1;
        else
            
        end
        
        newIdxs(j, 1) = count;
    end
    % Now overwrite the pull idxs with our block idxs
    newIdxs(1, 1) = 1; % Set first number to 1 since we skip it
    brainDataPull(:, 1) = newIdxs;
    audioDataPull(:, 1) = newIdxs;
    stimCells{stimCode - 20} = brainDataPull;
    audioCells{stimCode - 20} = audioDataPull;
end

% Now, ecog.stimCells will have nStim cells, each with a matrix that is 
% datapts x electrodes, with the first column being a vector of indices
ecog.stimBrainData = stimCells;
ecog.stimAudioData = audioCells;

%% Save
save([procDir 'a2GVPhrases_S31_B' blockStr '_merged.mat'], 'ecog')