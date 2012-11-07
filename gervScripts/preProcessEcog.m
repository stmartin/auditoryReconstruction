% This is a control file for preprocessing and running STRF fitting.  It
% is currently under construction, and should ultimately be the main
% control point for ECoG preprocessing and STRF fitting.  
subjPath = ['/home/knight/holdgraf/data/gerwinSchalk/subjData/subject_33/'];

% First, make the ecog structure
ecog = makeEcogStruct_0(subjPath);  % finished
ecog = preprocessEcogStruct_1(ecog);
ecog = processEcogStruct_2(ecog);
audio = createSpeechRepresentations_5; 

% STRF Fitting
ecog = strfCode; % This outputs a strfData object with all strfs in it

% Use this object to make predictions given these models
predictions = predictStrf;

% Given that we have predictions, now need to slice up these and the
% behavioral data from Gerv's original files for comparison 
% (split by sentence type).
splitPredictions = splitFromSplitStimuli;