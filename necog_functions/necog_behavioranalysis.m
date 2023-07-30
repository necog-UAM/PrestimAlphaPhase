function necog_behavioranalysis(pp, task, path)

%% 2. Behavior analysis
%Blablabla

ct = 1;
contrast = [];
catch_t = nan(31,1);
catch_errors = nan(31,1);
obj_hits = nan(31,1);
obj_errors = nan(31,1);

for s = pp

    cd ([path.main '\preprocdata\Sub' num2str(s)])
    load([task '_responses.mat']) % Load behavioral responses

    % % 3 factors: hemifield

    %% 1) Contrast

    %idx for seen and unseen
    seenL   =  left_resp == 1;
    unseenL =  left_resp == 0;
    seenR   =  right_resp == 1;
    unseenR =  right_resp == 0;

    contrast(ct,1) = mean(left_stim_contrast(unseenL));
    contrast(ct,2) = mean(left_stim_contrast(seenL));
    contrast(ct,3) = mean(right_stim_contrast(unseenR));
    contrast(ct,4) = mean(right_stim_contrast(seenR));

    %% 2) Correct rejections (catch trials)

    trials = [];
    catch_trials = [];
    if strcmp(task, 'nocue')
        trials(:,1) = trigger(:,2);
        trials(:,2) = trigger(:,1);
    else
        trials(:,1) = trigger(:,3);
        trials(:,2) = trigger(:,2);
    end

    ct2 = 1;
    for tr = 1:length(trials)
        if trials(tr,2) > 30 && trials(tr,2) < 100 % catch trial
            catch_trials(ct2,1) = trials(tr,1);
            ct2 = ct2 + 1;
        end
    end

    c = zeros(length(catch_trials),1);
    c(catch_trials==124) = 1;

    catch_errors(ct) = nansum(c); % hits
    catch_t(ct) = length(c) - catch_errors(ct,1); % errors

    %% 3) Objective response (seen trials)

    trials = [];
    if strcmp(task, 'nocue')
        trials(:,1) = trigger(:,2);
        trials(:,3) = trigger(:,1);
    else
        trials(:,1) = trigger(:,3);
        trials(:,3) = trigger(:,2);
    end
    trials(:,2) = discrimination_response(:,2);

    ct2 = 1;
    for tr = 1:length(trials)
        if isnan(trials(tr,2)) == 0 % objective question trial
            if trials(tr,1) == 124 % seen trial
                if ~strcmp(task, 'noninformative')
                    if trials(tr,3) < 30 % no catch trial
                        hit_trials(ct2) = trials(tr,2);
                        ct2 = ct2 + 1;
                    end
                else
                    if trials(tr,3) > 100 % no catch trial
                        hit_trials(ct2) = trials(tr,2);
                        ct2 = ct2 + 1;
                    end
                end
            end
        end
    end

    obj_hits(ct) = nansum(hit_trials); % hits
    obj_errors(ct) = length(hit_trials) - obj_hits(ct,1); % errors

        ct = ct+1;

end

%% Save behavior results
cd([path.main '\results\'])
save([task '_behaviour_results'], 'contrast', 'catch_t', 'catch_errors', 'obj_hits','obj_errors')

end





