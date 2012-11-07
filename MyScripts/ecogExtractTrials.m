function Ecog=ecogExtractTrials(ecog, nClass)
% This function extract the different trials that are not outliers and 
% gather them in their corresponding class of the Ecog structure. By
% outliers, we mean the trials that are longer or shorter (time frame) than
% the whisker of a traditional boxplot
% 
% INPUT 
% ecog:     an ecog structure
%
% OUTPUT
% Ecog:     an Ecog structure containing the extracted trials gathered in
%           their respectiv class. Each trial is an ecog structure.
%
% Example:  Ecog=ecogExtractTrials(ecog, nclass);


%% Extract the indexes of the interval edges
for i=21:1:30
   Class=['Class' num2str(i-20)];
   idx=find(ecog.triggerTS==i); 
   edge=[1 (find(diff(idx)>1)+1); find(diff(idx)>1) size(idx,2)]'; % build a matrix of nTrialsx2 with the the indexes of the 2 respective edges of the interval
   Trigg.(Class)=idx(edge); 
   Length=Trigg.(Class)(:,2)-Trigg.(Class)(:,1);
   
   %% Remove Outliers
   boxplot(Length);
   h=findobj(gcf,'tag','Outliers');
   yc=get(h,'YData');
   idxOutliers=[];
    if ~isnan(yc);
         for j=1:numel(unique(yc))
             idxOutliers(j,:)=find(Length==yc(j));
         end
    end
   Trigg.(Class)=removerows(Trigg.(Class), idxOutliers);
end

%% Extract the intervals of the trials and attribute them to their corresponding class field
baselineDurMs=0;
sampDur=ecog.sampDur;
Ecog.nClass=nClass;

for j=1:nClass
    Class=['Class' num2str(j)];
    Ecog.(Class).nTrial=size(Trigg.(Class),1);
    for i=1:size(Trigg.(Class),1)
        Trial=['Trial' num2str(i)];
        Ecog.(Class).(Trial)= ecogRaw2Ecog(ecog.data(:,Trigg.(Class)(i,1):Trigg.(Class)(i,2)),baselineDurMs,sampDur,[]);
        Ecog.(Class).(Trial).badChannels=ecog.badChannels;
        Ecog.(Class).(Trial)=ecogDeselectBadChan(Ecog.(Class).(Trial));
    end
end


% for i=21:1:30
%    idx=find(ecog.triggerTS==i); 
%    edge=[1 (find(diff(idx)>1)+1); find(diff(idx)>1) size(idx,2)]'; % build a matrix of nTrialsx2 with the the indexes of the 2 respective edges of the interval
%    Trigg(:,:,i-20)=idx(edge); 
% end
% 
% baselineDurMs=0;
% sampDur=ecog.sampDur;
% nTrial=10;
% nClass=10;
% 
% for j=1:nClass
%     ecogClass=['Class' num2str(j)];
%     for i=1:nTrial
%         ecogTrial=['Trial' num2str(i)];
%         Ecog.(ecogClass).(ecogTrial)= ecogRaw2Ecog(ecog.data(:,Trigg(i,1,j):Trigg(i,2,j)),baselineDurMs,sampDur,[]);
%         Ecog.(ecogClass).(ecogTrial).badChannels=ecog.badChannels;
%         Ecog.(ecogClass).(ecogTrial)=ecogDeselectBadChan(Ecog.(ecogClass).(ecogTrial));
%     end
% end

