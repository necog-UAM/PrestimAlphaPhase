function necog_phaseanalysis(pp, task, path,numbperm)

%% 4. Phase Opposition Sum (POS) calculation
%
% This script calculates an empirical and a null Phase Opposition Sum
% (POS, VanRullen, 2016) index between seen and unseen trials for each
% electrode, frequency, and time point and independently for each
% participant and task.
% POS index is based on the comparison of the inter-trial phase coherence
% (ITC, i.e., phase consistency) across trials between conditions.
% Specifically, POS is calculated according to the following formula:
%
%              POS = ITCseen + ITCunseen – 2ITCall
%
% where ITCseen and ITCunseen represent the ITC of each condition and
% ITCall is the overall ITC of all trials together, which serves as a
% baseline. This procedure yields values close to 0 when the two conditions
% do not have a strong ITC and also when their phases are clustered at
% approximately the same phase angles. On the contrary, a POS value of 1
% indicates a complete opposition between the phases of the two conditions.
%
% To calculate the null POS, a null POS distribution was first estimated:
% seen and unseen trials were shuffled over 10,000 iterations. Then, ITCs
% and POS were calculated. Eventually, the POS values of this null
% distribution were averaged resulting.

warning('This script can take long to run with high number of permutations (>100)')

% Predefine variables
empirical_POS = cell(1, length(pp));
permuted_POS = cell(1, length(pp));

it = 1; % Iteration counter

for s = pp % Participants loop

    disp(['Subject ' num2str(it) '/' num2str(length(pp))])
    cd ([path.main '\preprocdata\Sub' num2str(s)])

    % Load mirrored data
    load([task '_mirrordata.mat'])

    slabel = find(mirrordata.trialinfo==1); % Seen trials
    ulabel = find(mirrordata.trialinfo==2); % Unseen trials

    % Select seen and unseen trials.
    seen_phase   = squeeze(mirrordata.fourierspctrm(slabel,:,:,:));
    unseen_phase = squeeze(mirrordata.fourierspctrm(ulabel,:,:,:));

    %% b. Calculate empirical POS

    % Identify the lowest number of trials between both conditions
    % (seen and unseen)
    trls_seen = length(slabel);
    trls_unseen = length(ulabel);
    min_trls = min([trls_seen, trls_unseen]);

    % Predefine variables
    balanced_seen_phase = zeros(min_trls, length(mirrordata.label),length(mirrordata.freq), length(mirrordata.time));
    balanced_unseen_phase = zeros(min_trls, length(mirrordata.label),length(mirrordata.freq), length(mirrordata.time));

    % Randomly grab trials up to min_trls
    pseen   = randperm(trls_seen);
    punseen = randperm(trls_unseen);
    balanced_seen_phase   = seen_phase(pseen(1:min_trls),:,:,:);
    balanced_unseen_phase = unseen_phase(punseen(1:min_trls),:,:,:);
    balanced_all_phase    = [balanced_seen_phase;balanced_unseen_phase];

    % Calculate Inter Trial Phase Coherence (ITC)
    seen_ITPC   = squeeze(abs(mean(balanced_seen_phase   ./  abs(balanced_seen_phase))));
    unseen_ITPC = squeeze(abs(mean(balanced_unseen_phase ./  abs(balanced_unseen_phase))));
    all_ITPC    = squeeze(abs(mean(balanced_all_phase    ./  abs(balanced_all_phase))));

    % Calculate empirical POS
    emp_POS = (seen_ITPC + unseen_ITPC) - 2*all_ITPC;

    %% c. Compute the permuted POS

    nperm = numbperm; % Number of permutations

    % Predefine variable
    perm_POS = zeros(length(mirrordata.label), length(mirrordata.freq), length(mirrordata.time));

    for perm = 1:nperm % Permutation loop
        disp(['Progress: Permutation ' num2str(perm) '/' num2str(nperm)])

        % Calculate permuted ITCs shuffling seen and unseen labels
        p = randperm(size(balanced_all_phase,1)); % variable with randomized trials
        seen_ITPC   = squeeze(abs(mean(balanced_all_phase(p(1:min_trls),:,:,:)     ./  abs(balanced_all_phase(p(1:min_trls),:,:,:))))); % grab first half of trials for seen
        unseen_ITPC = squeeze(abs(mean(balanced_all_phase(p(min_trls+1:end),:,:,:) ./  abs(balanced_all_phase(p(min_trls+1:end),:,:,:))))); % grab second half of trials for seen

        % Calculate permuted POS
        perm_POS = perm_POS + ( (seen_ITPC + unseen_ITPC) - 2*all_ITPC );

    end % end of permutation loop

    perm_POS = perm_POS ./ nperm; % Average permutations

    % Fieldtrip format
    empirical_POS{it} = mirrordata;
    empirical_POS{it} = rmfield(empirical_POS{it}, 'fourierspctrm');
    empirical_POS{it}.powspctrm = emp_POS;
    empirical_POS{it} = rmfield(empirical_POS{it}, 'trialinfo');
    empirical_POS{it}.dimord = 'chan_freq_time';


    permuted_POS{it} = mirrordata;
    permuted_POS{it} = rmfield(permuted_POS{it}, 'fourierspctrm');
    permuted_POS{it}.powspctrm = perm_POS;
    permuted_POS{it} = rmfield(permuted_POS{it}, 'trialinfo');
    permuted_POS{it}.dimord = 'chan_freq_time';

    it = it+1; % Increase iteration counter

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
cfg.design           = [ones(1, length(empirical_POS)) ones(1, length(permuted_POS)) * 2; 1:length(empirical_POS) 1:length(permuted_POS)];

cfg_neighb.method    = 'distance';
cfg.neighbours       = ft_prepare_neighbours(cfg_neighb, empirical_POS{1});

cfg.correctm         = 'cluster';
cfg.numrandomization = 1000; % number of permutations
cfg.clusterthreshold = 'nonparametric_common';
cfg.clusteralpha     = 0.05;

cfg.clusterstatistic = 'wcm';
cfg.minnbchan        = 4;
cfg.clustertail      = 0;

[POS_stat]       = ft_freqstatistics(cfg, empirical_POS{:}, permuted_POS{:});

POS_poscluster = [];
POS_negcluster = [];

% grab the first positive and first negative clusters
if isfield(POS_stat, 'posclusterslabelmat')
POS_poscluster = POS_stat.posclusterslabelmat == 1;
end
if isfield(POS_stat, 'negclusterslabelmat')
POS_negcluster = POS_stat.negclusterslabelmat == 1;
end

%% Save data
cd([path.main '\results\'])
save([task '_phase_data'], 'empirical_POS', 'permuted_POS', 'POS_stat', 'POS_poscluster', 'POS_negcluster')

end

