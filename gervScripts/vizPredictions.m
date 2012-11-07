%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  This function assists with visualizing the predictions                
% It takes as input a frequency, block, and sentence stimulus to compare the
% actual audio to the predicted audio.
%   INPUTS:
%           freq                : specified frequency
%           testBlock           : block to test
%           stim                : sentence to test against
%           numStims            : how many sentences are there total?
%           templates           : pointer to a cell array with templates
%           predictions         : pointer to a cell array with predictions
%           zFlag               : a flag to decide if we zscore first
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function a = vizPredictions(freq, testBlock, stim, numStims, templates, predictions, zFlag)

figure(1); clf; 
colNum = 0; 
for l = 1:numStims
    subplot(2, 1, 1); hold on; 
    audTemp = templates{l}(:, freq);
    if zFlag == 1
        audTemp = zscore(audTemp);  % Z-score the templates as well
    end
    
    plot(audTemp, 'col', [0 colNum colNum])

    
    subplot(2, 1, 2); hold on; 
    sentence = predictions{stim};
    block = sentence(sentence(:, 1)==testBlock, :);
    predFreq = block(:, freq + 1);
    predFreq(isnan(predFreq)) = [];
    if zFlag == 1
        predFreq = zscore(predFreq);
    end
    
    plot(predFreq, 'col', [0 colNum colNum])
    xlim([0 length(audTemp)]);
    colNum = colNum + (1 / numStims);
end