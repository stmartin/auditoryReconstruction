% Runs the STRFLab code on data generated from ECoG
clear all;

%% Define parameters for fitting
nLags = 10; %% How many time lags do we use?
useGPU = 0; %% Do we use GPU acceleration?
numElectrodes = 109;  %% How many iterations for this process?  (should be total num of electrodes)
numSpecBands = 32;

% Forward/Reverse switch
strfDirection = 'rev'; % Either 'for' or 'rev'.  rev takes electrodes as input and an audio spectrogram as output

CC = [];
weightMat = [];
biasMat = [];
strfTrainedMat = [];

%% Specify File Input/Output Directories
outFilename = ['strf_globDat_B2B3_' strfDirection];
rootDir = '/home/knight/smartin/subjData/subject_33/';
savePath = [rootDir 'regressions/'];

% Specify ecog and audio files to use for model fitting
audioFile = {[rootDir 'stim.freq32.B3.mat'], [rootDir 'stim.freq32.B2.mat']};
ecogFile = {[rootDir 'highGamma_ecogB3.mat'], [rootDir 'highGamma_ecogB2.mat']};

predictFileList = {'highGamma_ecogB5.mat' 'highGamma_ecogB4.mat' 'highGamma_ecogB6.mat'};
predictAudioFileList = {'stim.freq32.B5.mat' 'stim.freq32.B4.mat' 'stim.freq32.B6.mat'};
strfArray = {};

[resp audio assign] = strf_initializeData(ecogFile, audioFile); %% concatenate all ecog
% and audio files respectively and 

%% Now run the STRF fitting
% Note that the number of models to fit depends on whether you're fitting
% to electrode responses, or to auditory stimuli.

% This allows you to access the global variable created by strfData
global globDat

if strfDirection == 'rev'
    numModels = numSpecBands;
elseif strfDirection == 'for'
    numModels = numElectrodes;
end

% Fit input/output according to a decoding/encoding model
[fitIdx inData outData rev] = strf_initializeDirection(audio, resp, strfDirection, numModels);

for model=fitIdx
    % Load Data
    disp(['Running model ' num2str(model)])
    disp('Loading Data...')
    
    trainStim = inData; % ecog high gamma [time x selectedChannels]
    trainResp = outData(:, model); % stimuli at a specific fz band [time x 1]
    
    % zScore all responses for equal variance and zero mean
    trainResp = zscore(trainResp); % if 'rev' => trainResp=audio stimulus representation
    trainStim = zscore(trainStim); % if 'rev' => trainStim=high gamma ecog
    
    % strfData loads the design matrix and response vector into globals
    % Convert stim/response to single precision points - cuts down on memory
    if useGPU
        disp('Using GPU acceleration')
        strfData(gsingle(trainStim), gsingle(trainResp), assign);
    else
        strfData(single(trainStim), single(trainResp), assign); %take stim and resp and set them as global variable
    end
    
    %******* WHY it set stim size [time x nSelectedChannels] and resp [time x 1]******

    %% Initialize STRFLab Options
    % Specify Cross-Validation
    options = resampJackknife;
    options.nResamp = 2;
    options.testFrac = 0.1;
    options.jackFrac = 0.1;
    
    % Specify Optimization Algorithm
    options.optimOpt =                  trnThreshGroupGradDescStepShrink;  % Using hybrid gradient descent/coordinate descent
    options.optimOpt.threshold =        .9;  % step using parameters >=90% of the max gradient
    options.optimOpt.thresholdGroup =   .5; % step using parameters >=50% of the max gradient in each delay group
    options.optimOpt.earlyStop =        1;
    options.optimOpt.nDispTruncate =    150;  %% Don't display the first N errors (this is because the error is really high at first)
    options.optimOpt.display =          -30;  %% Displays errors after N iterations (neg = figure window)
    options.optimOpt.stepSize =         .0001;
    options.optimOpt.errLastN =         -400; %% Stop if N iterations yeld error slope higher than errSlope
    options.optimOpt.errSlope=          -.01;
    options.optimOpt.is1D=              1;
    options.optimOpt.adaptive=          1;
    options.optimOpt.maxIter =          3000;
    

    %% Run the STRFLab Model Fitting
    % Initialize strf structure
    disp('Initializing STRF Structure...')
    lagIdxs = rev*[0:(nLags-1)]; % These index how many timelags and in which direction we use.
    strf = linInit(size(globDat.stim, 2), lagIdxs, 'linear', 0); % Rev determines whether we reverse the lags (for backwards model)
    % if 'rev'=> size(globalDat.stim,2)= nSelectedChannels
    % linInit create a generalized linear model
    strf.gidx = 1:size(trainStim, 2);% 
 
    if useGPU
        strf.w1 = gsingle(strf.w1);
        strf.b1 = gsingle(strf.b1);
    end
 
    % run the optimization (early stopping flag is true).  strfTrained is the newly fit model
    disp('Running optimization...')
    useIdx = [1:globDat.nSample];  % all samples are used 
    [strfTrained, optOptions, cvresult] = strfOpt(strf, useIdx, options); % build and save n times strf  (n=option.nResample)
    % cvresult are the index of the 10% of samples that are held out
 
    %% Model Validation
    % loop through all cross-validation folds and make a prediction for the model fitted to each fold
    disp('Running model validation...')
    preda=[]; respa=[]; totccResamp=[];
    
    for fold = 1:length(strfTrained)  % on the validation set
        [p1 pred pred2] = strfFwd(strfTrained(fold), cvresult{fold}); % strfFwd outputs the model prediction
        r2=globDat.resp(cvresult{fold});
        preda=[preda; pred(:)]; % prediction
        respa=[respa; r2(:)]; % auditory representation
    end
    
    % average model over all folds
    disp('Averaging Model...')
    strfAvg = strfTrained(1); % but we don't test the averaged model?!
    strfAvg.b1 = squeeze(mean(cat(2, strfTrained.b1), 2));
    strfAvg.w1 = squeeze(mean(cat(4, strfTrained.w1), 4));
    
    preda=preda(:);
    respa=respa(:);
    nonnanidx = find(~isnan(preda));   
    
    % Compute correlation between predicted and actual response
    CC{model} = corrcoef(preda(nonnanidx), respa(nonnanidx));
    ccVec = CC{model}(2,1);
    
    sprintf(['Correlation Coefficient is: ' num2str(CC{model}(2,1)) '\n\n'])
    

    
   %% COMMENTED OUT FOR FUTURE REMOVAL IF IT DOESN'T BREAK
    %%%%%%%%%%%%%% ANYTHING!!!!!!!!
%     % Now predict stimuli for another block of data
%     % Define files for prediction
%     disp(['Building reconstructed spectrogram for ' num2str(length(predictFileList)) ' files...']);
% 
%     % This creates a dataPts x models x predictions matrix of predictions
%     for f = [1:length(predictFileList)]
%         predAudioFile = load([rootDir predictAudioFileList{f}], 'speech');
%         predFile = load([rootDir predictFileList{f}], 'ecog');
%         predResp = predFile.ecog.data{1}(:, 1:numElectrodes);
%         if model == 1 
%             predictSpect{f} = zeros(length(predResp), numSpecBands); 
%         end
%         
%         predAudioData = predAudioFile.speech.s(:, model);
%         [audioPredict] = Resp, predAudioData);
%         predictSpect{f}(:, model) = audioPredict;
%     end
    strfArray{model} = strfAvg;
  
    % actual resp for the validation set and for the 32 models

end

strfData.strfArray = strfArray;
strfData.ccVec = ccVec;
strfData.trainFiles = ecogFile;
% strfData.predictSpect = predictSpect; POTENTIAL REMOVAL
% strfData.predictFileList = predictFileList; POTENTIAL REMOVAL
save([savePath outFilename], 'globDat', 'strfData')
