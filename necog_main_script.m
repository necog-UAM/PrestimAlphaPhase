clear all, close all

script_path = fileparts(matlab.desktop.editor.getActiveFilename); %get path of current editor
cd(fullfile(script_path,'..')); % get the main path

p.main   = pwd(); % main path
p.files   = [p.main '\Files'];
p.scripts = [p.main '\Scripts'];

addpath(p.files) % Add folder with essential files
addpath(genpath(p.scripts)) % Add folder with functions

addpath('') % Add FieldTrip path here.

% Names of the 3 tasks
tasks = {'nocue', 'noninformative', 'informative'};

for t = 1:length(tasks) % task loop
    disp(['Starting task: ' tasks{t} '.......'])

    % Define participants for each task (pp)
    if t == 1
        pp = [1 4:7 9:18 20:23 25:34]; % pp task l
    elseif t == 2
        pp = [4:7 9:13 16:25 27:35]; % pp task 2
    elseif t == 3
        pp = [2:7 9:13 16:25 27:36]; % pp task 3
    end

    %% 1. Behavior analysis, save results in the results folder
    necog_behavioranalysis(pp, tasks{t}, p)

    %% 2. Timefrequency decomposition and collapse data to ipsi contra, save in preproc folder
    it = 1; % Iteration counter
    for s = pp % Participant loop
        disp(['Subject ' num2str(it) '/' num2str(length(pp))])
        necog_timefreqanalysis(s, tasks{t}, p)
        necog_collapsedata(s,tasks{t},p)
        it = it+1;
    end

    %% 3. Analyze amplitude and phase group statistics and save results in the results folder
    necog_amplitudeanalysis(pp, tasks{t}, p)
    necog_phaseanalysis(pp, tasks{t}, p, 1000) % Last parameter is number of permutations

end
    
    %% 4. Generate the figures from the paper and save them in figures folder
    necog_createfigures(p, tasks)











