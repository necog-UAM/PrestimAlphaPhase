function necog_collapsedata(sub, task, path)

%% 2. Collapse data
% This script transforms right stimulus data into a mirrored version.
% This way, ipsilateral activity is represented in left channels in both
% conditions (left and right stimulus), while contralateral activity is
% displayed in right channels. Finally, both conditions are collapsed into
% a single file.ls

load inverse_elec.mat % Located in essential files folder.

cd ([path.main '\preprocdata\Sub' num2str(sub)])
load([task '_timefreqdata.mat']) % Load time-frequency data (left and right hemifield)

%%
right = zeros(size(timefreq_right.fourierspctrm)); % Predefine variable
% Allocate ipsilateral data to left channels and contralateral data
% to right channels (mirrored version)
for elec = 1:55
    right(:,find(order==LH(elec)),:,:) = right(:,find(order==LH(elec)),:,:) + timefreq_right.fourierspctrm(:,LH(elec),:,:);
    right(:,find(order==RH(elec)),:,:) = right(:,find(order==RH(elec)),:,:) + timefreq_right.fourierspctrm(:,RH(elec),:,:);
end
right(:,midch,:,:) = timefreq_right.fourierspctrm(:,midch,:,:) + right(:,midch,:,:); % channel of the middle line

% Collapse left and right variables in a single cell (trials x label)
mirrordata = timefreq_left;
mirrordata = rmfield(mirrordata, 'cumtapcnt');
mirrordata.fourierspctrm = cat(1,timefreq_left.fourierspctrm, right);
mirrordata.trialinfo =  cat(1,timefreq_left.trialinfo(:,4), timefreq_right.trialinfo(:,4) );

% save
save([task '_mirrordata'], 'mirrordata')
clear mirrordata

end

%% End of script