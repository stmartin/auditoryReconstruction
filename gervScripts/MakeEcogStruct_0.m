%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This function creates the initial ecog structure that we will use later
% for STRF fitting.  It is called as a function in a main "analysis
% control" script.
%       Inputs:
%          subjPath                    : the path to subject folder.  This
%                                        folder should have in it a
%                                        file called "subjInfo.mat" that
%                                        stores values of interest for
%                                        assignment in this script
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ecog = MakeEcogStruct_0(subjPath)


%clear all
addpath('/home/knight/bpasley/matlab');

load([subjPath 'subjInfo.mat']); % S.M. only one subjIndo.mat => should have one subjInfo per subject

dataDir = subjInfo.dataDir;
saveDir = subjInfo.saveDir;

% Specify a file that Schalk has provided which gives relevant variables
%varFile = 
cd(dataDir)

% Define subjects to analyze here
subjectList = [33];

% Define reference and ground for all the files we'll analyze.  These
% should come in two value pairs [ref ground] w/ 'nSubjs' pairs.
refground = {subjInfo.refGround};

% How many ECoG channels per subject?  Only necessary if no data file for
% them already
nChans = subjInfo.nChans;  % This is 98 for Sub31. 
micChan = subjInfo.micChan; % This is if we need to hard code a mic chan

for k = 1:length(subjectList)
    clear ecog
    
    % Initialized I/O File Locations
    subj = subjectList(k);
    dataDirSubj = [dataDir 'subject_' num2str(subj) '/'];
    saveDirSubj = [saveDir 'subject_' num2str(subj) '/'];
    disp(['Running subject ' num2str(subj) '...']);
    
    cd(dataDirSubj);
    fname = dir('*.dat');
    tmp = zeros(size(fname));
    
    % ignore segmented P0 files if present, just load full data set into
    % memory
    disp('Removing partial files');
    for i=1:length(fname)
        if isempty(findstr('P0',fname(i).name))
            tmp(i)=1;
        end
    end
    
    % Remove the components of fname that correspond to partial datasets
    fname(~logical(tmp)) = [];
    
    % Schalk data sometimes has a SUBJECTXX_vars.mat file that contains
    % useful parameters for each subject.  If it exists, load it here.
    % If not, then load variables manually
    ecog.refground = refground{k};
    if exist('varFile')
        disp(['Loading Schalk data variables...']);
        load(fullfile(dataDirSubj, ['AMC0' num2str(subj) '_brain.mat']))
        ecog.goodchannels = good_channels;
        ecog.goodchannels = setdiff(ecog.goodchannels, ecog.refground);
        mic = micChan;
    else 
        disp(['WARNING: No variables file given.  Assuming hard-coded variables...']);
        ecog.nChans = nChans(k); % S.M. error need non-cell array
        ecog.goodchannels = [1:ecog.nChans];
        nChanBlocks = ecog.nChans / 16;
        mic = micChan; % Custom micchan specified above
    end
  
    %% create ecog data structure, cycle through all data sets in fname
    for b=1:length(fname)   
        disp(['Running file ' fname(b).name]);
        [ gdat, states, parameters ] = load_bcidat(fname(b).name, '-calibrated');
        ecog.chanssz = size(gdat, 2);
        ecog.audio = gdat(:, mic);
        clear tmp
        tmp(:, ecog.goodchannels) = gdat(:, ecog.goodchannels);
        ecog.data = [tmp];
        ecog.audioFs = parameters.SamplingRate.NumericValue;
        ecog.dataFs = parameters.SamplingRate.NumericValue;
        ecog.name=['GV' num2str(subj) '_Ticker' ];s
        
        % Resample audio to 16000Hz
        if ecog.audioFs ~= 16000
            ecog.audio = resampleHz(ecog.audio, ecog.audioFs, 16000);
            ecog.audioFs = 16000;
        end
        ecog.data=resampleHz(ecog.data,ecog.dataFs,1000);
        ecog.dataFs=1000;
        
        % lengths of data and sound vector should be approx equal
        datLength = length(ecog.data) ./ 1000;
        soundLength = length(ecog.audio) ./ 16000;
        
        %% Saving Files
        saveFileName = ['origGVPhrases_S' num2str(subj) '_B' num2str(b)];
        disp(['Data and sound vector length: ' num2str(datLength) ' ' num2str(soundLength)]);
        disp(['Filename: ' saveFileName]);
        fprintf(['Saving to: ' saveDirSubj '\n\n']);
        save(fullfile(saveDirSubj, saveFileName), 'ecog');
        
        % Now remove big fields so we conserve memory
        ecog = rmfield(ecog, {'data' 'audio' 'audioFs' 'dataFs' 'name'});
    end
end


