function necog_createfigures(path, tasks)

% This script generates the figures presented in the paper.


%% 1. Behavior
cd([path.main '\results\'])

    load nocue_behaviour_results.mat
    pcntl_catch(:,1) = catch_t .* 100 ./ (catch_t + catch_errors);
    pcntl_hits(:,1) = obj_hits .* 100 ./ (obj_hits + obj_errors);
    load noninformative_behaviour_results.mat
    pcntl_catch(:,2) = catch_t .* 100 ./ (catch_t + catch_errors);
    pcntl_hits(:,2) = obj_hits .* 100 ./ (obj_hits + obj_errors);
    load informative_behaviour_results.mat
    pcntl_catch(:,3) = catch_t .* 100 ./ (catch_t + catch_errors);
    pcntl_hits(:,3) = obj_hits .* 100 ./ (obj_hits + obj_errors);

% Figure 1
figure,
violinplot(pcntl_catch(:,1:3)/100,'ViolinColor')
ylabel('% correct rejections');
ylim([.40 1.05])
yticks([.50 1])
yline(.50, ':')
xticklabels({'No-cue','Non-Informative','Informative'})
title('% correct rejections')

cd([path.main '\figures\'])
savefig(gcf,['Correct rejections'])

% Figure 2
figure,
violinplot(pcntl_hits(:,1:3)/100)
ylabel('% correct responses');
ylim([.40 1.05])
yticks([.50 1])
yline(.50, ':')
xticklabels({'No-cue','Non-Informative','Informative'})

cd([path.main '\figures\'])
savefig(gcf,['Correct responses'])


%% 2. Electrophysiology: Amplitude and phase clusters

cd([path.main '\results\'])

for t = 1:length(tasks) % task loop

    load([tasks{t} '_amplitude_data.mat']) % Load amplitude data
    load([tasks{t} '_phase_data.mat']) % Load POS data

    % Seen - Unseen amplitude
    cfg = [];
    seendata_avg                   = ft_freqgrandaverage(cfg,seendata{:});
    unseendata_avg                 = ft_freqgrandaverage(cfg,unseendata{:});
    amplitude_difference           = seendata_avg; % fieldtrip structure
    amplitude_difference.powspctrm = seendata_avg.powspctrm - unseendata_avg.powspctrm;
    
    % Real - Permuted POS
    empirical_POS_avg        = ft_freqgrandaverage(cfg,empirical_POS{:});
    permuted_POS_avg         = ft_freqgrandaverage(cfg,permuted_POS{:});
    POS_difference           = empirical_POS_avg; % fieldtrip structure
    POS_difference.powspctrm = empirical_POS_avg.powspctrm - permuted_POS_avg.powspctrm;

    values   = {'amplitude', 'POS'};
    clusters = {'poscluster', 'negcluster'};

    for v = 1:length(values) % Loop through amplitude and POS
        for c = 1:length(clusters) % Loop through positive and negative clusters

            data_cluster = eval([values{v} '_' clusters{c}]); %

            % Find time points included in the cluster
            tpcluster = find(squeeze(sum(sum(data_cluster,1),2)))';
            it = 1; % Iteration counter
            figure
            for tp = tpcluster % Create a topography for each time point within the cluster
                if it > 12
                    it=1;
                    figure
                end

                temp_cluster = data_cluster(:,:,tp);

                %Find channels and frequencies included in the cluster for each time point
                [chcluster, freqcluster] = find(temp_cluster);
                chcluster = unique(chcluster);
                freqcluster = unique(freqcluster);

                plotcluster = eval([values{v} '_difference']);
                plotcluster.powspctrm = plotcluster.powspctrm(:,freqcluster,tp);
                plotcluster.time = plotcluster.time(tp);
                plotcluster.freq = plotcluster.freq(freqcluster);

                subplot(3,4,it)
                cfg                  = [];
                cfg.layout           = 'biosemi128_1005.lay';
                cfg.parameter        = 'powspctrm';
                cfg.marker           = 'off';
                cfg.highlight        = 'on';
                cfg.highlightsymbol  = '.';
                cfg.highlightchannel = chcluster;
                cfg.highlightcolor   = [0 0 0];
                cfg.figure           = 'gca';
                cfg.highlightsize    = 7;
                ft_topoplotTFR(cfg,plotcluster)

                title([num2str(round(plotcluster.time,2)) ' ms; '])
                sgtitle([ tasks{t} ' ' eval("[tasks{t} ' ' values{v} ' ' clusters{c}]") '  p = ' num2str(round(eval([values{v} '_stat.' clusters{c} 's(1).prob']),3))])

                it = it+1;
            end % Time point loop
                cd([path.main '\figures\'])
                saveas(gcf,[tasks{t} '_' values{v} ' ' clusters{c}],'fig')
        end % Positive negative clusters loop
    end % Amplitude or phase loop
end % Task loop

end % end of function








