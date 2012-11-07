%%% This code takes a STRF structure as well as a set of brain activity,
%%% and outputs auditory predictions to be compared with 10 templates
clear all;

% Load the STRF file that we've already got
strfDir = '/home/knight/holdgraf/data/gerwinSchalk/subjData/subject_31/regressions/';
strfFile = 'GV31_B2B3_rev.mat';
load([strfDir strfFile], 'predictions');
strfArray = predictions.strfArray;

% Load the file for brain activity that we'd like to use for predictions
numElecs = 98; % specify specific number of electrodes to use
dataDir = '/home/knight/holdgraf/data/gerwinSchalk/subjData/subject_31/';
dataFile = 'a2GVPhrases_S31_B4.mat';
load([dataDir dataFile]);
brainData = ecog.data{1}(:, 1:numElecs);

% Initialize STRF data with brain activity as stimulus.  All we care about
% is the stimulus, not the response, since we're predicting
global globDat;
strfData(brainData, brainData);

% Run the prediction for each model that is in strfArray
predictMat = zeros(length(brainData), length(strfArray));
for i = 1:length(strfArray)
    strf = strfArray{i};
    [strf preds] = strfFwd(strf, [1:length(brainData)]);
    predictMat(:, i) = preds;
end