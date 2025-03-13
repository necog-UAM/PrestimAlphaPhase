%% Trial randomization of the experiment
%
% This script generates the sequence of trials for the three near-threshold 
% visual detection tasks used in Melcón at al. 2004: 
%
%      1. No-cue task
%      2. Noninformative cue task (50% validity)
%      3. Informative cue task (100% validity). 
% 
% The variable 'parameters' is saved in each participant folder with the 
% experimental block randomization. Additionally, an extra variable is 
% saved in the folder "subject0" to be used in the pre-task calibration 
% block (same randomization for all participant).
%
% For more details, see:
%               Melcón, M., Stern, E., Kessel, D., Arana, L., Poch, C., 
%               Campo, P., & Capilla, A. (2024). Perception of 
%               near‐threshold visual stimuli is influenced by prestimulus 
%               alpha‐band amplitude but not by alpha phase. 
%               Psychophysiology, 61(5), e14525.
%
%
% Authors: María Melcón and Almudena Capilla, Universidad Autónoma de Madrid, July, 2021


%% 1. Trial randomization for no-cue task
clear all
path = ''; % DEFINE THE PATH WITH PARTICIPANT FOLDERS!
cd (path) 


% ---------- % --------- PRE-TASK CALIBRATION --------- % ---------- %
% define variables
Ntrial = 20; % number of trials
subj    = 0;  % participant 0, for pre-task block
parameters = zeros(Ntrial,3); %colunms: fixation; Gabor location/orientation; Gabor - subjetive question ISI

% 1.- Fixation (800-1200ms)
fixation = rand(Ntrial,1)*0.4 + 0.8;

% Gabor location/orientation
left(1:5,1)  = 11; % left vertical Gabor
left(6:10,1) = 12; % left horizontal Gabor

right(1:5,1)  = 21; % right vertical Gabor
right(6:10,1) = 22; % right horizontal Gabor

% merge both variables
location = [left; right];
% randomize
a = rand(20,1);
location = [location,a];
location = sortrows(location,2);
location = location(:,1);

% 3.- Gabor - Subjective question ISI (250-350ms)
isi2 = rand(Ntrial,1)*0.1 + 0.25; %250-350 ms

% save data
% Include data in parameters variable
parameters(:,1) = fixation;
parameters(:,2) = location;
parameters(:,3) = isi2;

cd ([path '\subj' num2str(subj)])
save nocuetask_aleatorization parameters
cd ..

% ---------- % --------- EXPERIMENTAL TASK --------- % ---------- %
%participants
Ntrial = 400;

for subj = 1:2
    
    parameters = zeros(Ntrial,3); %colunms: fixation; Gabor; Gabor - subjetive question ISI
    
    % 1.- Fixation (800-1200ms)
    fixation = rand(Ntrial,1)*0.4 + 0.8;
    
    % 2.- Location
    left(1:90,1)    = 11; % left vertical Gabor
    left(91:180,1)  = 12; % left horizontal Gabor
    left(181:200,1) = 31; % no Gabor - 10%
    
    right(1:90,1)    = 21; % right vertical Gabor
    right(91:180,1)  = 22; % right horizontal Gabor
    right(181:200,1) = 32; % no Gabor - 10%
    
    % merge both variables
    location = [left; right];
    % randomize
    a = rand(400,1);
    location = [location,a];
    location = sortrows(location,2);
    location = location(:,1);
    
    % 3.- Gabor - Subjective question ISI (250-350ms)
    isi2 = rand(Ntrial,1)*0.1 + 0.25; %250-350 ms
    
    % save data
    % Include data in parameters variable
    parameters(:,1) = fixation;
    parameters(:,2) = location;
    parameters(:,3) = isi2;

    % create folder for each subject
    mkdir(['suj' num2str(subj)])

    cd ([path '\subj' num2str(subj)])
    save nocuetask_aleatorization parameters
    cd .. 

end

%% 2. Trial randomization for noninformative cue task
path = ''; % DEFINE THE PATH WITH PARTICIPANT FOLDERS!
cd (path) 

% ---------- % --------- PRE-TASK CALIBRATION --------- % ---------- %

% define variables
Ntrial = 20;  % number of trials
subj    = 0;  % participant 0, for pre-task block
parameters = zeros(Ntrial,5); %colunms: fixation; cue-Gabor ISI; location; Gabor; Gabor - subjetive question ISI

% 1.- Fixation (800-1200ms)
fixation = rand(Ntrial,1)*0.4 + 0.8;

% 2.- Cue- Gabor ISI (500-800 ms)
isi = rand(Ntrial,1)*0.3 + 0.5; 

% 3 y 4.- Cue location (100% valid) and Gabor location/orientation
left         = ones(10,1); % location: 1 = left
left(1:2,2)  = 101; % left cue - left vertical Gabor
left(3:5,2)  = 102; % left cue - left horizontal Gabor
left(6:7,2)  = 111; % left cue - right vertical Gabor
left(8:10,2) = 112; % left cue - right horizontal Gabor

right         = ones(10,1)*2; % location: 2 = right
right(1:2,2)  = 103; % right cue - left vertical Gabor
right(3:5,2)  = 104; % right cue - left horizontal Gabor
right(6:7,2)  = 113; % right cue - right vertical Gabor
right(8:10,2) = 114; % right cue - right horizontal Gabor

% merge both variables
location = [left; right];
% randomize
a = rand(20,1);
location = [location,a];
location = sortrows(location,3);
location = location(:,1:2);

% 5.- Gabor - Subjective question ISI (250-350ms)
isi2 = rand(Ntrial,1)*0.1 + 0.25; 

% save data
% Include data in parameters variable
parameters(:,1) = fixation;
parameters(:,2) = location(:,1);
parameters(:,3) = isi;
parameters(:,4) = location(:,2);
parameters(:,5) = isi2;

cd ([path '\subj' num2str(subj)])
save noninformativetask_aleatorization  parameters

cd ..

% ---------- % --------- EXPERIMENTAL TASK --------- % ---------- %
%participants
Ntrial = 400; % number of trials in experimental block
Nsubj  = 30;  % number of participants

for subj = 1:Nsubj
    
    parameters = zeros(Ntrial,5); %fixation; ISI cue-gabor; cue location; Gabor location/orientation; ISI gabor - subjetive task
    
    % 1.- Fixation (800-1200ms)
   fixation = rand(Ntrial,1)*0.4 + 0.8; 
    
    % 2.- Cue- Gabor ISI (500-800 ms)
    isi = rand(Ntrial,1)*0.3 + 0.5;
    
    % 3 y 4.- Cue location (100% valid) and Gabor location/orientation
    left            = ones(200,1); % location: 1 = left
    left(1:45,2)    = 101; % left cue - left vertical Gabor
    left(46:90,2)   = 102; % left cue - left horizontal Gabor
    left(91:135,2)  = 111; % left cue - right vertical Gabor
    left(136:180,2) = 112; % left cue - right horizontal Gabor
    left(181:200,2) = 98;  % left cue - no Gabor - 10%
    
    right            = ones(200,1)*2; % location: 1 = left
    right(1:45,2)    = 103; % right cue - left vertical Gabor
    right(46:90,2)   = 104; % right cue - left horizontal Gabor
    right(91:135,2)  = 113; % right cue - right vertical Gabor
    right(136:180,2) = 114; % right cue - right horizontal Gabor
    right(181:200,2) = 99;  % right cue - no Gabor - 10%
    
    % merge both variables
    location = [left; right];
    % randomize
    a        = rand(400,1);
    location = [location,a];
    location = sortrows(location,3);
    location = location(:,1:2);
    
    % 5.- Gabor - Subjective question ISI (250-350ms)
    isi2 = rand(Ntrial,1)*0.1 + 0.25;
    
    % save data
    % Include data in parameters variable
    parameters(:,1) = fixation;
    parameters(:,2) = location(:,1);
    parameters(:,3) = isi;
    parameters(:,4) = location(:,2);
    parameters(:,5) = isi2;
    
    cd ([path '\subj' num2str(subj)])
    save noninformativetask_aleatorization parameters
    cd ..
    
end

%% 3. Trial randomization for informative cue task
clear all
path = ''; % DEFINE THE PATH WITH PARTICIPANT FOLDERS!
cd (path) 

% ---------- % --------- PRE-TASK CALIBRATION --------- % ---------- %
% define variables
Ntrial = 20; % number of trials
subj    = 0;  % participant 0, for pre-task block
parameters = zeros(Ntrial,5); %colunms: fixation; cue-Gabor ISI; location; Gabor; Gabor - subjetive question ISI

% 1.- Fixation (800-1200ms)
fixation = rand(Ntrial,1)*0.4 + 0.8;

% 2.- Cue- Gabor ISI (500-800 ms)
isi = rand(Ntrial,1)*0.3 + 0.5; 

% 3 y 4.- Cue location (100% valid) and Gabor location/orientation
left = ones(10,1); % location: 1 = left
left(1:5,2)  = 11; % vertical
left(6:10,2) = 12; % horizontal

right = ones(10,1)*2; % location: 2 = right
right(1:5,2)  = 21; % vertical
right(6:10,2) = 22; % horizontal

% merge both variables
location = [left; right];
% randomize
a = rand(20,1);
location = [location,a];
location = sortrows(location,3);
location = location(:,1:2);

% 5.- Gabor - Subjective question ISI (250-350ms)
isi2 = rand(Ntrial,1)*0.1 + 0.25;

% Include data in parameters variable
parameters(:,1) = fixation;
parameters(:,2) = location(:,1);
parameters(:,3) = isi;
parameters(:,4) = location(:,2);
parameters(:,5) = isi2;

% create folder for subjet 0 (pre-task calibration block)
mkdir(['suj' num2str(suj)]) 
% save randomization
cd ([path '\subj' num2str(subj)])
save informativetask_aleatorization parameters

cd ..

% ---------- % --------- EXPERIMENTAL TASK --------- % ---------- %

Ntrial = 400; % number of trials in experimental block
Nsubj  = 30;  % number of participants

for subj = 1:Nsubj
    
    parameters = zeros(Ntrial,5); %fixation; ISI cue-gabor; cue location; Gabor location/orientation; ISI gabor - subjetive task
    
    % 1.- Fixation (800-1200ms)
    fixation = rand(Ntrial,1)*0.4 + 0.8;
    
    % 2.- Cue- Gabor ISI (500-800 ms)
    isi = rand(Ntrial,1)*0.3 + 0.5; 
    
    % 3 y 4.- Cue location (100% valid) and Gabor location/orientation
    left            = ones(200,1);
    left(1:90,2)    = 11; % left cue - vertical Gabor
    left(91:180,2)  = 12; % left cue - horizontal Gabor
    left(181:200,2) = 31; % left cue - no Gabor - 10%
    
    right            = ones(200,1)*2;
    right(1:90,2)    = 21; % right cue - vertical Gabor
    right(91:180,2)  = 22; % right cue - vertical Gabor
    right(181:200,2) = 32; % right cue - no Gabor - 10%
    
    % merge both variables
    location = [left; right]; 
    % randomize
    a = rand(400,1);
    location = [location,a];
    location = sortrows(location,3);
    location = location(:,1:2);
    
    % 5.- Gabor - Subjective question ISI (250-350ms)
    isi2 = rand(Ntrial,1)*0.1 + 0.25;
    

    % save data
    % Include data in parameters variable
    parameters(:,1) = fixation;
    parameters(:,2) = location(:,1);
    parameters(:,3) = isi;
    parameters(:,4) = location(:,2);
    parameters(:,5) = isi2;
    
    cd ([path '\subj' num2str(subj)])
    save informativetask_aleatorization parameters

    cd .. 

end
