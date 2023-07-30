function necog_amplitudeanalysis(pp, task, path)

%% 3. Amplitude analysis
% This script extracts the amplitude values for seen and unseen
% trials for each participant and task.
% Mirror data contains collapsed left and right stimulus presentation data.
% First cell contains fourier complex values
% (trials x channels x frequencies x time points).
% Second cell contains trial labels (1 = seen, 2 = unseen).


% Predefine variables
seendata = cell(1,length(pp));
unseendata = cell(1,length(pp));

it = 1; % Iteration counter

for s = pp % Participants loop

    disp(['Subject ' num2str(it) '/' num2str(length(pp))])
    cd ([path.main '\preprocdata\Sub' num2str(s)])

    % Load mirrored data
    load([task '_mirrordata.mat'])

    slabel = find(mirrordata.trialinfo==1); % Seen trials
    ulabel = find(mirrordata.trialinfo==2); % Unseen trials

    % Extract the amplitude AVERAGES for seen and unseen trials.
    seen_amplitude   = squeeze(mean(abs(mirrordata.fourierspctrm(slabel,:,:,:))));
    unseen_amplitude = squeeze(mean(abs(mirrordata.fourierspctrm(ulabel,:,:,:))));

    % Fieldtrip format
    seendata{it} = mirrordata;
    seendata{it} = rmfield(seendata{it}, 'fourierspctrm');
    seendata{it}.powspctrm = seen_amplitude;
    seendata{it} = rmfield(seendata{it}, 'trialinfo');
    seendata{it}.dimord = 'chan_freq_time';

    unseendata{it} = mirrordata;
    unseendata{it} = rmfield(unseendata{it}, 'fourierspctrm');
    unseendata{it}.powspctrm = unseen_amplitude;
    unseendata{it} = rmfield(unseendata{it}, 'trialinfo');
    unseendata{it}.dimord = 'chan_freq_time';

    it = it+1;

end % end of participant loop

%% Statistics
cfg = [];
cfg.channel          = 'all';
cfg.latency          = 'all';
cfg.frequency        = 'all';

cfg.statistic        = 'ft_statfun_depsamplesT';
cfg.alpha            = .05;
cfg.tail             = 0; % two-tails
cfg.correcttail      = 'alpha'; % sets alpha = 0.025
cfg.ivar             = 1;
cfg.uvar             = 2;

cfg.method           = 'montecarlo';
cfg.design           = [ones(1, length(seendata)) ones(1, length(unseendata)) * 2; 1:length(seendata) 1:length(unseendata)];

cfg_neighb.method    = 'distance';
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, seendata{1});

cfg.correctm         = 'cluster';
cfg.numrandomization = 1000; % number of permutations
cfg.clusterthreshold = 'nonparametric_common';
cfg.clusteralpha     = 0.05;

cfg.clusterstatistic = 'wcm';
cfg.minnbchan        = 4;
cfg.clustertail      = 0;

[amplitude_stat] = ft_freqstatistics(cfg, seendata{:}, unseendata{:});

amplitude_poscluster = [];
amplitude_negcluster = [];

% grab the first positive and first negative clusters
if isfield(amplitude_stat, 'posclusterslabelmat')
amplitude_poscluster = amplitude_stat.posclusterslabelmat == 1;
end
if isfield(amplitude_stat, 'negclusterslabelmat')
amplitude_negcluster = amplitude_stat.negclusterslabelmat == 1;
end


%% Save data
cd([path.main '\results\'])
save([task '_amplitude_data'], 'seendata', 'unseendata', 'amplitude_stat', 'amplitude_poscluster', 'amplitude_negcluster')

end
