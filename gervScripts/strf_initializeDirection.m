%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Switch to determine whether we are doing forward or backwards regression.
% 'for' means that we are predicting electrode activity from the audio spectrogram,
% 'rev' means that we are predicting auditory spectrogram from electrodes.
%       Inputs:
%          audio                       : the audio spectrogram for fitting
%          resp                        : the ECoG response for fitting
%          strfDirection               : ['for', 'rev'] Are we fitting an
%                                           'for' = encoding model
%                                           'rev' = decoding model
%          numModels                   : the number of models we're fitting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fitIdx inData outData rev] = strf_initializeDirection(audio, resp, strfDirection, numModels)

if strfDirection == 'for'
    fitIdx = [1:numModels];
    inData = audio;
    outData = resp;
    rev = 1;
elseif strfDirection == 'rev'
    fitIdx = [1:numModels];
    inData = resp;
    outData = audio;
    rev = -1;
end