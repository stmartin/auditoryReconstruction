%function ecogPreprocessing(path, saveFileName)
% HOW TO MAKE THE VISUAL INSPECTION => MODIFY JOCHEM's SCRIPT to make a
% function too
% change the path (where the ecog strucutres are and where there will be
% save too)

path ='/home/knight/smartin/subjData/subject_010/'; 
cd(path)
saveFileName='ecogB';
fname = dir('ecogB*');
nbloc=length(fname);% CHANGE IN ORDER TO BE GENERALIZABLE
for i=1:nbloc
    display(['Preprocess bloc ' num2str(i)])
    filename=fname(i).name;
    load([path filename]);

    %% STEP 1: Down Sampling
    fs=1000; %modify if micChan not same Fs
    ecog=ecogDownsampleTS(ecog,fs);
    ecog.dataFs=fs;

    %% STEP 2: Remove Baseline

    %add nBaselineSamp to be able to use ecogBaselineCorrect
    ecog.nBaselineSamp=ecog.nSamp;
    ecog=ecogBaselineCorrect(ecog); 


    %% STEP 3: Filtering
    bandFreq= [0.5 200];
    ecog=ecogFilterTemporal(ecog,bandFreq,3); % band pass filter
    ecog=ecogFilterTemporal(ecog,[62 58; 122 118; 182 178],[3 3 3]); % notch filter


    % %% STEP 4: Artifact Rejection
    % % Use doPreprocessingArtfactRejection in Jochem's script->examples->preprocessing
    % ecog.badChannels= [31 65 66 67 68 69 70 71 72 80 81 83 84 85 87 88 89 90 91 93 94 95 96 97 98 100 103 106 108 109];
    % ecog=ecogDeselectBadChan(ecog);
    % 
    % %% STEP 5: Common Average Referencing 
    % ecog=ecogRemoveCommonAverageReference(ecog,'equal');
    % 
     %% STEP 6: Save
     saveFileName_i = [saveFileName num2str(i)];
     save(fullfile(path, saveFileName_i), 'ecog','-v7.3')
end
%%