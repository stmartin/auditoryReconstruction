%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function initializes the STRF files to be used in model fitting.  It
% takes as input the paths to folders with audio and ecog files, then
% concatenates them for STRF fitting.  This is useful if you have multiple
% blocks for model training.
%
%		input:
%			ecogFile				: Path to the location of the input preprocessed Ecog activity
%			audioFile				: Path to the location of the input audio spectrogram, split into frequency bands
%           numElectrodes           : The number of electrodes we have.  This lets us know which columns=electrodes
%          
%           
%           
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [resp audio assign] = strf_initializeData(ecogFile, audioFile)

resp = [];
audio = [];

%% Concatenate all files in the input/audio folders into one large block for model training.
disp(['Analyzing ' num2str(length(ecogFile)) ' files']);
for i = 1:length(ecogFile)
    
    % Load ECoG data
    load(ecogFile{i});
    disp('Loading ECoG data...');
    ecogData = ecog.data;
    resp = [resp; ecogData(ecog.selectedChannels,:)']; % select only the good channels

    % Load audio data
    load(audioFile{i});
    disp('Loading audio data...');
    
    audio = [audio; speech.s]; 
end

assert(size(resp, 1) == size(audio, 1), 'Number of trials does not match between audio and ECoG data');
%assert(numElectrodes == size(resp, 2), 'Variable numElectrodes does not equal the num of columns in resp matrix');

% This sets an arbitrary assignment at 7 second intervals (data is sampled
% at 100 Hz, so 700 Hz corresponds to 7 seconds
if exist('assign') == 0
    fprintf('WARNING: No trial assignment given, segregating data into 7 sec chunks\n\n');
    assign = zeros(size(resp,1),1);
    i = 1;
    j = 700;
    k = 1;
    while j < size(resp,1)
        assign(i:j) = k;
        i = i + 700;
        j = j + 700;
        k = k + 1;
    end
    assign(assign == 0) = k + 1;
end