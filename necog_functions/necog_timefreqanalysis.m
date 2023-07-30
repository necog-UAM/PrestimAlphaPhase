function necog_timefreqanalysis(sub, task, path)

%% 1. Time-frequency decomposition (SFFT)
% This script computes a time-frequency representation of the already preprocessed
% data when the stimulus was presented on the left or the right hemifield, for each
% participant and task independently.
% Short-time Fast Fourier Transform (SFFT) is used.
% After decomposition, data are redifined accordingly to the prestimulus 
% time window (from -0.4 to -0.05 s)

% sub      = s;
% task     = t;
% rawpath  = p.rawpath;   
% datapath = p.datapath; 

%%

        warning('off') % Supress warnings
        cd ([path.main '\preprocdata\Sub' num2str(sub)])

        % Load preprocessed data (contains left and right stimulus presentation)
        load([task '_cleandata.mat']) 

        % Define the window size of STFFT adjusting number of cycles per 
        % frequency: from 2  (lowest fequency) to 7 cycles (largest
        % frequency), increasing logarithmically.
        
        frex = exp([.7:.2:3.6]); % Define logarithmic frequencies  (from 2 to 30 hz)        
        range_cycles = [2 7]; 
        nCycles = logspace(log10(range_cycles(1)),log10(range_cycles(end)),length(frex)); 
        
        % Time-frequency decomposition - STFFT
        cfg              = [];
        cfg.method       = 'mtmconvol'; % STFFT
        cfg.foi          = frex;
        cfg.toi          = left_data.time{1}(1):.02:left_data.time{1}(end); % Steps of 20 ms
        cfg.channel      = {'all'};
        cfg.taper        = 'hanning';
        cfg.output       = 'fourier'; % Complex values to extract amplitude and phase
        cfg.t_ftimwin    = nCycles./cfg.foi; % Window width was adjusted to number of cycles per frequency
        cfg.keeptrials   = 'yes'; 

        timefreq_left    = ft_freqanalysis(cfg, left_data);
        timefreq_right   = ft_freqanalysis(cfg, right_data);

        % Cut time from 0.4 to 0.05 ms before stimulus presentation
        t1 = dsearchn(timefreq_left.time', -0.4);
        t2 = dsearchn(timefreq_left.time', -0.05);
        
        timefreq_left.time = timefreq_left.time(t1:t2);
        timefreq_left.fourierspctrm = timefreq_left.fourierspctrm(:,:,:,t1:t2);
        timefreq_right.time = timefreq_right.time(t1:t2);
        timefreq_right.fourierspctrm = timefreq_right.fourierspctrm(:,:,:,t1:t2);

        save([task '_timefreqdata'], 'timefreq_left', 'timefreq_right')
        

end
%% End of script

