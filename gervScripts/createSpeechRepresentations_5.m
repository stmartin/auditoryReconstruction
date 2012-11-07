% This script takes an audio file as input and turns it into a 
% spectrogram of frequency bands It creates a structure called "speech" 
% that contains values for what kind of spectrogram it is ('name'), what 
% the frequency cutoffs are ('d'), and the actual values of the 
% spectrogram ('s').


clear all
cd '/home/knight/smartin/subjData/subject_011/';
addpath('/home/knight/smartin/matlab/toolbox/nsl/');

saveDir = '/home/knight/smartin/subjData/subject_011/';
flist=dir('CAR_ecogB*.mat');
%flist=dir('a2*');

% SDO Defines a switch between different audio profiles
% 1    freq32
% 2    rate32
% 3    scale32
% 4    freq128
% 5    rate12
% 6    scale5
% 7    stacked32
% 8    stacked  (5+6+32 = 43 dims)
% 9    full32   (32^3 = 32768 dims)
% 10   full     (5x12x32 = 1920 dims)
% 11   freq32u  (normalized to unitseq)
% 12   rate32u
% 13   scale32u
% 14   ratescale32
% 15   ratescale
sdo=zeros(1,17);
sdo([1])=1;

length(flist)
for k = 1:length(flist)
   % load([/home/knight/bpasley/data/' flist(k).name]);
    load(flist(k).name);
    [num2str(k) flist(k).name]
    if sdo(1) == 1
        disp('s1')
        loadload
        paras = [10 10 -2 0]; %[frame_length time_const non_lin_factor shift]
        ecog.audio(isnan(ecog.audio)) = 0;
        ycoch  = wav2aud(double(unitseq(double(ecog.audio))), paras);
        %speech.fs=ecog.audioFs* (length(ycoch)/length(ecog.audio))
        clear ecog;
        % ycoch, 1 is lowest freq, end is highest freq
        speech.s = ycoch;
        
        clear ycoch
        tmp = 440 * 2 .^ ((-31:97) / 24);
        speech.d = tmp(1:end-1);
        speech.name = 'freq128';
        audspect128 = speech.s; 
        f128 = speech.d;
   %     save([/home1/knight/bpasley/data2/datafiles/stim.' speech.name '.' flist(k).name(2:end)], 'speech');
        speech.s = [];
        speech.s = double(resample(double(audspect128'), 1, 4))';
        speech.d = resample(speech.d, 1, 4);
        speech.name = 'freq32';
        
        save([saveDir 'stim.' speech.name '.' flist(k).name(5:end)], 'speech');
        audspect32 = speech.s;
        f32 = speech.d;
        size(speech.s) / 100
        
        clear speech
    end
    
    if sdo(2)==1
        disp('s2')
        loadload
        paras=[10 10 -2 0 0 0 1];
        rv =  [ 1:32  ];
        sv = linspace(0.1,8,32);
        [rtf stf]=aud2tfbp(double(audspect128),rv,sv,100,24,1,1);
        %   size(stf)
        speech.s=squeeze(abs(mean(stf,3)))'; clear stf
        speech.d=sv;
        speech.name='scale32';
        save([saveDir 'stim.' speech.name '.' flist(k).name(2:end)],'speech');
        scale32=speech.s;
        clear speech
        %   size(rtf)
        speech.s=squeeze(abs(mean(rtf,3)))'; clear rtf
        speech.d=rv;
        speech.name='rate32';
        save([saveDir 'stim.' speech.name '.' flist(k).name(2:end)],'speech');
        rate32=speech.s;
        clear speech
        speech.s=[audspect32 rate32 scale32];
        speech.d=[f32 ;rv ;sv]';
        speech.name='stacked32';
        save([saveDir 'stim.' speech.name '.' flist(k).name(2:end)],'speech');
        
        %
        %
        %         speech.s=unitseq(scale32);
        %         speech.d=sv;
        %         speech.name='scale32u';
        %         save([/home/knight/bpasley/data/speechstim/stim.' speech.name '.' flist(k).name(5:end)],'speech');
        %         clear speech
        %         speech.s=unitseq(rate32); clear rtf
        %         speech.d=rv;
        %         speech.name='rate32u';
        %         save([/home/knight/bpasley/data/speechstim/stim.' speech.name '.' flist(k).name(5:end)],'speech');
        %         clear speech
        %         speech.s=unitseq(audspect32);
        %         speech.d=f32;
        %         speech.name='freq32u';
        %         save([/home/knight/bpasley/data/speechstim/stim.' speech.name '.' flist(k).name(5:end)],'speech');
        clear speech rate32 scale32
    end
    
    
    if sdo(3)==1
        disp('s3')
        loadload
        paras=[10 10 -2 0 0 0 1];
        rv =  [ 1 2 4 8 16 32 ];
        sv = [0.5 1 2 4 8];
        [rtf stf]=aud2tfbp(double(audspect128),rv,sv,100,24,1,1);
        %  size(stf)
        speech.s=squeeze(abs(mean(stf,3)))'; clear stf
        speech.d=sv;
        speech.name='scale5';
        save([saveDir 'stim.' speech.name '.' flist(k).name(5:end)],'speech');
        scale5=speech.s;
        clear speech
        %  size(rtf)
        speech.s=squeeze(abs(mean(rtf,3)))'; clear stf
        speech.d=rv;
        speech.name='rate12';
        save([saveDir 'stim.' speech.name '.' flist(k).name(5:end)],'speech');
        rate12=speech.s;
        clear speech
        
        speech.s=[audspect32 rate12 scale5];
        speech.d{1}=f32;speech.d{2}=rv;speech.d{3}=sv;
        speech.name='stacked';
        save([saveDir 'stim.' speech.name '.' flist(k).name(5:end)],'speech');
        clear speech rate12 scale5 audspect32
    end
    
    if sdo(4)==1
        disp('s4')
        loadload
        paras=[10 10 -2 0 0 0 1];
        rv =  [ 1 2 4 8 16 32 ];
        sv = [0.5 1 2 4 8];
        speech.s=aud2corm(double(audspect128),paras,rv,sv,'tmp.cor');
        nsamps=size(speech.s,3);
        speech.s=permute( reshape( single( resample( double( permute( speech.s,[4 1 2 3] ) ) ,1,4 ) ) ,32, 5, 12,nsamps),[4 2 3 1]);
        speech.d{1}=f32;speech.d{2}=rv;speech.d{3}=sv;
        speech.name='full';
        save([saveDir 'stim.' speech.name '.' flist(k).name(2:end)],'speech');
        clear speech
    end
    
    
    if sdo(14)==1
        disp('s14')
        loadload
        paras=[10 10 -2 0];
        ycoch  = wav2aud(double(unitseq(ecog.audio)), paras);
        clear ecog;
        
        paras=[10 10 -2 0 0 0 1];
        rv =  [ 1:32  ];
        sv = linspace(0.1,8,32);
        disp('s14a')
        
        speech.s=aud2cormrs(double(ycoch),paras,rv,sv,'tmp.cor');
        speech.d{1}=rv;speech.d{2}=sv;
        speech.name='ratescale32';
        size(speech.s)
        save([saveDir 'stim.' speech.name '.' flist(k).name(5:end)],'speech');
        clear speech
    end
    
    if sdo(15)==1
        disp('s15')
        loadload
        paras=[10 10 -2 0];
        ycoch  = wav2aud(double(unitseq(ecog.audio)), paras);
        clear ecog;
        
        paras=[10 10 -2 0 0 0 1];
        rv =  [ 1 2 4 8 16 32  ];
        sv = [0.5 1 2 4 8];
        disp('s15a')
        
        speech.s=aud2cormrs(double(ycoch),paras,rv,sv,'tmp.cor');
        speech.d{1}=rv;speech.d{2}=sv;
        speech.name='ratescale';
        size(speech.s)
        save([saveDir 'stim.' speech.name '.' flist(k).name(5:end)],'speech');
        clear speech
    end
    if sdo(16)==1
        disp('s16')
        load('/home/knight/bpasley/data/TIMIT/TIMIT_phn')
        uphone=nominal(uniquePHall);
        
        speech.s=zeros(length(ecog.data{1}),length(uphone));
        
        
        for a=1:length(uphone)
            a
            ui=find(ismember(ecog.TIMIT.ph,uphone(a))==1);
            for b=1:length(ui)
                bi=floor(100*ecog.TIMIT.ph_events(ui(b),1)):floor(100*ecog.TIMIT.ph_events(ui(b),2));
                speech.s(bi,a)=1;
            end
        end
        %     speech.d{1}=rv;speech.d{2}=sv;
        speech.name='phone';
        size(speech.s)
        save([saveDir 'stim.' speech.name '.' flist(k).name(2:end)],'speech');
        clear speech
        
        
    end
    
    if sdo(17)==1
        disp('s17')
        load('/home/knight/bpasley/data/TIMIT/TIMIT_phn')
        uphone=nominal(uniquePHall);
        X=zeros(length(ecog.data{1}),length(uphone));
%        speech.s=zeros(length(ecog.data{1}),length(uphone));
        for a=1:length(uphone)
            a
            ui=find(ismember(ecog.TIMIT.ph,uphone(a))==1);
            for b=1:length(ui)
                bi=floor(100*ecog.TIMIT.ph_events(ui(b),1)):floor(100*ecog.TIMIT.ph_events(ui(b),2));
                X(bi,a)=1;
            end
        end
        %     speech.d{1}=rv;speech.d{2}=sv;
        speech.name='phone2ndOrder';
        nlags=50;
        n=length(uphone);
        nt=length(ecog.data{1});
        
        i2=zeros(nt,n*n,nlags,'single');
 
        for k0=1:nlags
        for ii=nlags+1:nt
           xx=single(X(ii,:)'*X(ii-k0,:));   
           i2(ii,:,k0)=xx(:);
        end
        end
        i3=[];
        for k0=1:nlags
            i3=[i3;squeeze(i2(:,:,k0))];
        end
        
        
        
        size(speech.s)
        save([saveDir 'stim.' speech.name '.' flist(k).name(2:end)],'speech');
        clear speech
        
        
    end
    
    
end
