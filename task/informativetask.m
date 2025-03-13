%
% informativetask() - this function uses Psychtoolbox to control stimulus 
%             presentation and behavioral data collection during one of the  
%             near-threshold visual detection tasks used in Melcón at al.  
%             2004, specifically, an informative cue task (100% validity).  
%             Each trial starts with a variable fixation window, where two  
%             boxes outlined in light gray are placed at the lower left and  
%             right sides of a central cross. After a 100% valid cue, a  
%             Gabor stimulus is presented at peri-threshold contrast during  
%             50ms, whose orientation is equally likely to be either  
%             vertical or horizontal (no stimulus is presented in 10% of  
%             trials). Participants are asked about two aspects related to  
%             the Gabor. First, a subjective question: Have you seen the  
%             Gabor stimulus? Response: yes or no. Then, an objective  
%             question in 15% of randomly selected trials: What was the  
%             Gabor stimulus orientation? Response: horizontal or vertical.  
%             In both question displays the two response alternatives  
%             (yes/no, horizontal/vertical) appeared randomly on the right  
%             and the left. Responses are collected from a numerical  
%             keyboard during unlimited time. The stimulus contrast is  
%             calculated on a trial-by-trial basis.
%             There is a pre-task calibration, whose goal is to find an 
%             initial perceptual threshold individualized per each 
%             participant and also serves as a practice session. The 
%             structre is identical to that of the main task, but with no 
%             objective question. The pre-task calibration finishes when
%             the percentage of seen responses is in the range between 30% 
%             and 70%. If performance is out of that range, a new 
%             calibration series starts, where the contrasts are adjusted 
%             according to the previous responses (increasing the values 
%             for <30% unseen responses and decreasing the values for >70% 
%             unseen responses).    
%             For more details, see:
%               Melcón, M., Stern, E., Kessel, D., Arana, L., Poch, C., 
%               Campo, P., & Capilla, A. (2024). Perception of 
%               near‐threshold visual stimuli is influenced by prestimulus 
%               alpha‐band amplitude but not by alpha phase. 
%               Psychophysiology, 61(5), e14525.
% 
% Use as
%   >> informativetask(subj,eeg,tc,runt)
%
% Input Arguments
%   subj - participant numerical code matching the participant folder where
%          the file with the experimental conditions (parameters) is 
%          storaged
%   eeg  - initialize and send EEG triggers
%          0 = no EEG triggers; 1 = send EEG triggers
%   tc   - provide timing control by presenting brightness changes in the 
%          lower right corner of the screen at the same time than the 
%          stimulus onset that can be detected by a photodiode 
%          0 = no timing control; 1 = timing control
%   runt - determines the part of the task that is presented
%          0 = run pre-task calibration; 1 = run both pre-task calibration 
%          and experimental task
%
% Ouput  - the file valid_responses.mat is saved in the participant folder
%          containing the following variables
%
%   trigger                 - trial number x 4 matrix, where the columns 
%                             are 1) cue condition: left-1 or right-2, 
%                             2) gabor condition: left vertical-11, left 
%                             horizontal-12, right vertical-21, right 
%                             horizontal-22, 3) subjective task response:
%                             seen-124, unseen-125, 4) objective task: 
%                             vertical-121, horizontal-122
%   response_key            - vector with pressed key in the subjective 
%                             task per trial
%   response_time           - vector with reaction times for the subjective
%                             task
%   left_resp               - responses for the subjective task when Gabor
%                             is presented in the left hemifield
%   right_resp              - responses for the subjective task when Gabor
%                             is presented in the right hemifield
%   discrimination_response - trial number x 2 matrix with the reseponses 
%                             for the objective task, where the columns are
%                             1) Gabor orientation reported: vertical-121,
%                             horizontal-122, 2) Hits: incorrect
%                             response-0, correct response-1
%   discrimination_time     - vector with reaction times for the objective
%                             task
%   left_threshold          - stimulus threshold calculated on each trial 
%                             during subjective task when Gabor is 
%                             presented in the left hemifield 
%   right_threshold         - stimulus threshold calculated on each trial 
%                             during subjective task when Gabor is 
%                             presented in the right hemifield 
%   right_stim_contrast     - contrast of the Gabor presented on each
%                             trial in the right hemifield: threshold + 
%                             sigma x random scalar drawn from the standard 
%                             normal distribution
%   left_stim_contrast      - contrast of the Gabor presented on each
%                             trial in the left hemifield: threshold + 
%                             sigma x random scalar drawn from the standard 
%                             normal distribution
%
% Example:
% informativetask(25,1,1,1)
%
% Authors: María Melcón and Almudena Capilla, Universidad Autónoma de Madrid, July, 2021
%


function informativetask(subj,eeg,tc,runt)

try

    % ------ % ------ LOAD DATA AND PREPARE EXPERIMENT % ------ % ------ % 
    
    % define paths 
    taskpath=''; % ADD PATH WITH TASK FILES!
    pppath=['\subj' num2str(subj)]; % ADD PATH WITH PARTICIPANT FILES!
    cd (taskpath)

    Nptrials = 20;  % number of trials in the pre-task calibration
    Ntrial   = 400; % number of trials in the experimental block

    % Create output arrays 
    response_key            = cell(Ntrial,1);
    response_time           = nan(Ntrial,1);
    discrimination_response = nan(Ntrial,2);
    discrimination_time     = nan(Ntrial,1);
    trigger        = nan(Ntrial,4); % columns: cue - gabor - subjective task response - objective task response
    % counters to present the objective question in the same percentage
    % across conditions
    ct_leftunseen  = 15; 
    ct_leftseen    = 15;
    ct_rightunseen = 15;
    ct_rightseen   = 15;
    
    % define spatial parameters of the screen
    x1 = 1366; % screen size
    y1 = 768;  % screen size
    distx = 124; % distance to center of quadrants
    disty = 25;  % distance to center of quadrants
    size_stim = 152 ; % size of stimuli 
    size_cue1 = [0 0 162 162];
    size_cue2 = [0 0 150 150];
    
    % load images
    instructions    = imread('instruction_valid.tif');
    fixation        = imread('fixation.tif');
    answer1         = imread('answer1.tif');
    answer2         = imread('answer2.tif');
    discrimination1 = imread('discrimination1.tif');
    discrimination2 = imread('discrimination2.tif');
    ppbreak         = imread('break.tif');
    black           = imread('black_background.jpg');
    white           = imread('white_background.tif');
      
    % Inicialize USB-LPT1 if EEG is to be recorded
    % create a USB245 persistent interface object
    if eeg == 1
        clear USB245;                 % delete any previous copies of USB245 from the MATLAB workspace
        device = USB245();            % fetch handle to persistent USB245 interface object
        % initialize the interface and UM245R device to the default I/O configuration
        status = USB245(device,255);  % initialization success indicated by status=0
        status = USB245(device, 1, 0);
    end
    
    % Open window
    screens = Screen('Screens');
    screenNumber = max(screens);
    
    full_rect = 1; % 1 = full screen
    if full_rect == 0
        myRect = CenterRect([0 0 600 600], Screen('Rect',screenNumber)); % debug
    elseif full_rect == 1
        myRect = []; 
    end
    Screen('Preference', 'SkipSyncTests', 1);
    [w w2] = Screen('OpenWindow',screenNumber,[],myRect);
    HideCursor
    [screenXpixels, screenYpixels] = Screen('WindowSize', w);
    [x0, y0] = RectCenter(w2);
    
    % Define Gabor location for each hemifield
    coord(1,:) = [ x0-distx-size_stim   y0+disty   x0-distx  y0+disty+size_stim  ] ;
    coord(2,:) = [ x0+distx    y0+disty   x0+distx+size_stim  y0+disty+size_stim  ] ;
    dif = (coord(1,3)-coord(1,1))/2;
    
    % load textures
    txt_fixation = Screen('MakeTexture',w,fixation);
    txt_a1       = Screen('MakeTexture',w,answer1);
    txt_a2       = Screen('MakeTexture',w,answer2);
    txt_disc1    = Screen('MakeTexture',w,discrimination1);
    txt_disc2    = Screen('MakeTexture',w,discrimination2);
    txt_black    = Screen('MakeTexture',w,black);
    txt_white    = Screen('MakeTexture',w,white);
    

    % ---------- % --------- PRE-TASK CALIBRATION --------- % ---------- %

    % calibration parameters:
    % inferior/superior threshold and steps size
    inf_thr  = .017;
    step_thr = 0.002;
    sup_thr  = .035;

    sigma = 0.004;     % stimulus variability around threshold
    thr_range_left  = (inf_thr:step_thr:sup_thr)'; % initial contrast range for each hemifield
    thr_range_right = (inf_thr:step_thr:sup_thr)';
    
    % randomize initial contrast values for each hemifield
    r = rand(10,1);
    left_thr = [thr_range_left, r];
    left_thr = sortrows(left_thr,2);
    left_thr = left_thr(:,1);
    
    r = rand(10,1);
    right_thr = [thr_range_right, r];
    right_thr = sortrows(right_thr,2);
    right_thr = right_thr(:,1);
    
    % variables for number of seen trials
    left_seen = 0;
    right_seen = 0;
    
    % instructions
    txt = Screen('MakeTexture',w,instructions);
    Screen ('DrawTexture',w,txt,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
    Screen ('Flip',w);
    KbWait
    
    while left_seen < 3 || left_seen > 7 || right_seen < 3 || right_seen > 7 % while the percentage of unseen trials is a small or big
       
        % announce practice block
        Screen ('FillRect',w,127);
        Screen('TextFont', w , 'Helvetica')
        Screen('TextSize', w, 25);
        Screen('DrawText', w , 'Bloque de prueba', x0*830/960 , 510*y0/540 , [10 10 10]) % 'Practice block'
        Screen('Flip', w);
        WaitSecs (2)
        
        Screen ('FillRect',w,127);
        Screen('TextFont', w , 'Helvetica')
        Screen('TextSize', w, 25);
        Screen('DrawText', w , 'Pulsa una tecla cuando estes preparad@', x0*651/960 , 510*y0/540 , [10 10 10]) % 'Press any key when you are ready'
        % photodiode
        if tc == 1
            Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]);
        end
        Screen('Flip', w);
        KbWait
        
        % variables to grab info:
        % to grab each trial answer (seen = 1 or unseen = 0)
        left_resp  = [];      
        right_resp = [];
        % to grab estimated threshold per each trial
        left_threshold = [];       
        right_threshold = [];
        % to grab the exact contrast value used in each trial
        left_stim_contrast = [];    
        right_stim_contrast = [];
        
        % counters for each hemifield
        ct_l = 1;
        ct_r = 1;
        
        % load trial randomization
        cd ('') % ADD THE PATH OF THE EXPERIMENTAL CONDITIONS!
        load informativetask_aleatorization
        
        % start trial presentation for pre-task calibration block
        for trl = 1:Nptrials

            % 1. Fixation window (800-1200ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]); 
            end

            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(parameters(trl,1))
            
            % 2. Cue onset (200ms)
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_black,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]);
            end

            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            
            % cue
            cue_out = CenterRectOnPointd(size_cue1, coord(parameters(trl,2),1)+dif, coord(parameters(trl,2),2)+dif); 
            color_out = [255 255 255];
            
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, color_out, cue_out);
            Screen('FillRect', w, colori_left, cuei_left);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(0.2)
            
            % grab cue condition to send EEG trigger
            trg = parameters(trl,2);

            % send EEG trigger
            if eeg == 1
                status = USB245( device, 1, trg );
                WaitSecs(0.010)
                status = USB245( device, 1, 0 );
            end
            % grab trigger for posterior sanity check if needed
            trigger(trl,1) = parameters(trl,2);
            
            % 3. Cue - Gabor interstimulus interval (500-800ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]); 
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(parameters(trl,3))
            
            % 4. Gabor (50ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_black,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]); 
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            % grab gabor presence/location 
            s  = num2str(parameters(trl,4));
            ix = str2double(s(1));
            
            % Gabor presentation
            if ix == 3 % no Gabor - 10%

                numb_img = (fx_Gabor_patch_A(0,0)+1).*127;

            elseif ix == 1 % Gabor presented in the left hemifield

                lstim_tr = left_thr(ct_l) + sigma.*randn(1); % add variability to Gabor contrast 
                if rem(parameters(trl,4),2) > 0 % Vertically orientated
                    numb_img = (fx_Gabor_patch_A(lstim_tr,0)+1).*127;
                elseif rem(parameters(trl,4),2) == 0 % Horizontally oriented
                    numb_img = (fx_Gabor_patch_A(lstim_tr,90)+1).*127;
                end
                txt=Screen('MakeTexture',w,(numb_img));
                Screen('DrawTexture',w,txt,[0 0 1000 1000],[coord(ix,1) coord(ix,2) coord(ix,3)  coord(ix,4)]);

            elseif ix == 2 % Gabor presented in the right hemifield

                rstim_tr = right_thr(ct_r) + sigma.*randn(1); % add variability to Gabor contrast 
                if rem(parameters(trl,4),2) > 0 % Vertically orientated
                    numb_img = (fx_Gabor_patch_A(rstim_tr,0)+1).*127;
                elseif rem(parameters(trl,4),2) == 0 % Horizontally oriented
                    numb_img = (fx_Gabor_patch_A(rstim_tr,90)+1).*127;
                end
                txt=Screen('MakeTexture',w,(numb_img));
                Screen('DrawTexture',w,txt,[0 0 1000 1000],[coord(ix,1) coord(ix,2) coord(ix,3)  coord(ix,4)]);

            end
            
            Priority([2]);
            Screen('Flip',w);
            WaitSecs(.03)
                        
            % grab Gabor condition to send EEG trigger
            trg = parameters(trl,4);
            % send EEG trigger
            if eeg == 1
                status = USB245( device, 1, trg );
                WaitSecs(0.010)
                status = USB245( device, 1, 0 );
            end
            % grab trigger for posterior sanity check if needed
            trigger(trl,2) = parameters(trl,4);
            
            % 5. Gabor - Subjective question ISI (250-350ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]); 
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(parameters(trl,5)) 
            
            % 6. Subjective task (Have you seen the Gabor? Yes/No)
            ans_scr = rand(1); % randomize the location (left/right) of answer options (Yes/No) on the screen
            % present answer options
            if ans_scr > 0.5 % Yes - Left hemifield; No - Right hemifield
                Screen ('DrawTexture',w,txt_a1,[0 0 4000 2250],[0 0 x1 y1]);
            else % Yes - Right hemifield; No - Left hemifield
                Screen ('DrawTexture',w,txt_a2,[0 0 4000 2250],[0 0 x1 y1]);
            end
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]);
            end
            Screen ('Flip',w);
            KbWait
            
            % detect response
            FlushEvents('keyDown');
            t1     = GetSecs; % grab time point
            time   = 0; % response time
            cont_r = 0; % response index
            resp   = 1; % response for calibration update
            trg    = [];
            while time < 0.3
                % update response time
                t2   = GetSecs;
                time = t2-t1;
                [keyIsDown,timeStamp,keyCode] = KbCheck;
                
                if (keyIsDown) && cont_r == 0 
                    key = KbName(find(keyCode));
                    % grab subjective response (seen/unseen)
                    if ans_scr > 0.5 % accordingly with Yes/No location on the screen
                        if strcmp(key,'4')
                            trigger(trl,3) = 124; %seen
                            trg = 124;
                        elseif strcmp(key,'6')
                            trigger(trl,3) = 125; %unseen
                            trg = 125;
                        end
                    else
                        if strcmp(key,'4')
                            trigger(trl,3) = 125; %unseen
                            trg = 125;
                        elseif strcmp(key,'6')
                            trigger(trl,3) = 124; %seen
                            trg = 124;
                        end
                    end
                    % send EEG trigger with subjective response
                    if eeg == 1
                        status = USB245( device, 1, trg );
                        WaitSecs(0.010)
                        status = USB245( device, 1, 0 );
                    end
                    
                    % grab behavioural responses for posterior sanitiy
                    % check (key and  time)
                    response_key{trl}  = key;
                    response_time(trl) = time;

                    % update response variable for calibration update
                    if trg == 124
                        resp = 1; % seen
                    elseif trg == 125
                        resp = 0; % unseen
                    end
                    cont_r = 1; % update response index to break while loop
                end
            end
            
            % grab response, threshold and contrast
            if ix == 1 % gabor in left hemifield
                left_resp = [left_resp resp];
                left_threshold (length(left_resp)) = left_thr(ct_l);
                left_stim_contrast(length(left_resp)) = lstim_tr;
                ct_l = ct_l + 1; % update counter
                
            elseif ix == 2 % gabor in right hemifield
                right_resp = [right_resp resp];
                right_threshold (length(right_resp)) = right_thr(ct_r);
                right_stim_contrast(length(right_resp)) = rstim_tr;
                ct_r = ct_r + 1; % update counter
                
            end
        end
        
        % Calculate unseen Gabors after pre-task calibration run
        left_seen  = (Nptrials./2)-sum(left_resp);
        right_seen = (Nptrials./2)-sum(right_resp);
        
        % keep adjusting initial Gabor contrast range 
        if left_seen > 7 % if more than 7 trials are seen in left hemifield, reduce range of that hemifield
            
            thr_range_left = (thr_range_left(Nptrials./4):step_thr:thr_range_left(end)+step_thr*4)';
            r = rand(Nptrials./2,1);
            left_thr = [thr_range_left, r];
            left_thr = sortrows(left_thr,2);
            left_thr = left_thr(:,1);
            
        elseif left_seen < 3 % if less than 3 trials are unseen in left hemifield, increase range of that hemifield
            
            thr_range_left = (thr_range_left(1)-step_thr*5:step_thr:thr_range_left(Nptrials./4))';
            r = rand(Nptrials./2,1);
            left_thr = [thr_range_left, r];
            left_thr = sortrows(left_thr,2);
            left_thr = left_thr(:,1);
            
        elseif right_seen > 7 % if more than 7 trials are seen in right hemifield, reduce range of that hemifield
            
            thr_range_right = (thr_range_right(Nptrials./4):step_thr:thr_range_right(end)+step_thr*4)';
            r = rand(Nptrials./2,1);
            right_thr = [thr_range_right, r];
            right_thr = sortrows(right_thr,2);
            right_thr = right_thr(:,1);
            
        elseif right_seen < 3 % if less than 3 trials are unseen in right hemifield, increase range of that hemifield
            
            thr_range_right = (thr_range_right(1)-step_thr*5:step_thr:thr_range_right(Nptrials./4))';
            r = rand(Nptrials./2,1);
            right_thr = [thr_range_right, r];
            right_thr = sortrows(right_thr,2);
            right_thr = right_thr(:,1);
            
        end
        
    end
    

    % ---------- % --------- EXPERIMENTAL TASK --------- % ---------- %

    % Use estimated threshold to start experimental task
    left_thr  = sortrows(left_threshold);
    left_thr  = left_thr(left_seen);
    right_thr = sortrows(right_threshold);
    right_thr = right_thr(right_seen);
    
    % calibration parameters
    sigma = 0.001;     % stimulus variability around threshold (reduced)
    thr_step = 0.001;  % step size (reduced)
    
    % announces the start of the experimental block
    Screen ('FillRect',w,127);
    Screen('TextFont', w , 'Helvetica')
    Screen('TextSize', w, 25);
    Screen('DrawText', w , 'Bloque experimental', x0*830/960 , 510*y0/540 , [10 10 10]) % 'Experimental block'
    Screen('Flip', w);
    WaitSecs (2)
    
    Screen ('FillRect',w,127);
    Screen('TextFont', w , 'Helvetica')
    Screen('TextSize', w, 25);
    Screen('DrawText', w , 'Pulsa una tecla cuando estes preparad@', x0*651/960 , 510*y0/540 , [10 10 10]) % 'Press any key when you are ready'
    Screen('Flip', w);
    KbWait
    
    % Create arrays
    response_key         = cell(Ntrial,1);
    response_time        = nan(Ntrial,1);
    discrimination_response = nan(Ntrial,2);
    discrimination_time     = nan(Ntrial,1);
    trigger = nan(Ntrial,3); % cue - gabor - subjective task - objective task
    % counters to present the objective question in the same percentage
    % across conditions
    ct_leftunseen  = 15;
    ct_leftseen    = 15;
    ct_rightunseen = 15;
    ct_rightseen   = 15;
    
    % load trial randomization for the participant
    cd (pppath)
    load informativetask_aleatorization
    
    if runt == 0 % if only initial calibration is requiered, close screen
        Screen('CloseAll');
    elseif runt == 1 % run whole task
        for trl=1:Ntrial
            
            % 1. Fixation window (800-1200ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]);
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(parameters(trl,1))
            
            % 2. Cue onset (200ms)
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_black,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]); %gris claro
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            
            % cue
            cue_out   = CenterRectOnPointd(size_cue1, coord(parameters(trl,2),1)+dif, coord(parameters(trl,2),2)+dif);
            color_out = [255 255 255];
            
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, color_out, cue_out);
            Screen('FillRect', w, colori_left, cuei_left);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(0.2)
            
            % grab cue condition to send EEG trigger
            trg = parameters(trl,2);
            
            % send EEG trigger
            if eeg == 1
                status = USB245( device, 1, trg );
                WaitSecs(0.010)
                status = USB245( device, 1, 0 );
            end
            % grab trigger for posterior sanity check if needed
            trigger(trl,1) = parameters(trl,2);
            
            % 3. Cue - Gabor interstimuluis interval (500-800ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]);
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(parameters(trl,3))
            
            % 4. Gabor (50ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_black,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]); %gris claro
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            % grab Gabor presence/location 
            s = num2str(parameters(trl,4));
            ix = str2double(s(1));
            
            % Gabor presentation
            if ix == 3 % no Gabor - 10%

                numb_img = (fx_Gabor_patch_A(0,0)+1).*127;

            elseif ix == 1 % Gabor presented in the left hemifield

                lstim_tr = left_thr + sigma.*randn(1); % add variability to gabor contrast 
                if rem(parameters(trl,4),2) > 0 % Vertically oriented
                    numb_img = (fx_Gabor_patch_A(lstim_tr,0)+1).*127;
                elseif rem(parameters(trl,4),2) == 0 % Horizontally oriented
                    numb_img = (fx_Gabor_patch_A(lstim_tr,90)+1).*127;
                end
                txt = Screen('MakeTexture',w,(numb_img));
                Screen('DrawTexture',w,txt,[0 0 1000 1000],[coord(ix,1) coord(ix,2) coord(ix,3)  coord(ix,4)]);

            elseif ix == 2 % Gabor presented in the right hemifield

                rstim_tr = right_thr + sigma.*randn(1) ; % add variability to gabor contrast 
                if rem(parameters(trl,4),2) > 0 % Vertically oriented
                    numb_img = (fx_Gabor_patch_A(rstim_tr,0)+1).*127;
                elseif rem(parameters(trl,4),2) == 0 % Horizontally oriented
                    numb_img = (fx_Gabor_patch_A(rstim_tr,90)+1).*127;
                end
                txt = Screen('MakeTexture',w,(numb_img));
                Screen('DrawTexture',w,txt,[0 0 1000 1000],[coord(ix,1) coord(ix,2) coord(ix,3)  coord(ix,4)]);

            end
            
            Priority([2]);
            Screen('Flip',w);
            WaitSecs(.03)
            
            % grab Gabor condition to send EEG trigger
            trg = parameters(trl,4);
            % send EEG trigger
            if eeg == 1
                status = USB245( device, 1, trg );
                WaitSecs(0.010)
                status = USB245( device, 1, 0 );
            end
            % grab trigger for posterior sanity check if needed
            trigger(trl,2) = parameters(trl,4);
            
            % 5. Gabor - Subjective question ISI (250-350ms)
            % fixation
            Screen('DrawTexture',w,txt_fixation,[0 0 4000 2250],[0 0 x0*2+1 y0*2]);
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]);
            end
            
            % present a box outlined in light gray in each hemifield
            cueo_left   = CenterRectOnPointd(size_cue1, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            coloro_left = [130 130 130];
            cuei_left   = CenterRectOnPointd(size_cue2, coord(2,1)+.5+dif, coord(2,2)+.5+dif);
            colori_left = [127 127 127];
            Screen('FillRect', w, coloro_left, cueo_left);
            Screen('FillRect', w, colori_left, cuei_left);
            
            cueo_right   = CenterRectOnPointd(size_cue1, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            coloro_right = [130 130 130];
            cuei_right   = CenterRectOnPointd(size_cue2, coord(1,1)+.5+dif, coord(1,2)+.5+dif);
            colori_right = [127 127 127];
            Screen('FillRect', w, coloro_right, cueo_right);
            Screen('FillRect', w, colori_right, cuei_right);
            
            Screen('Flip',w);
            WaitSecs(parameters(trl,5))
            
            % 6. Subjective task (Have you seen the Gabor? Yes/No)
            ans_scr = rand(1); % randomize the location (left/right) of answer options (Yes/No) on the screen
            % present answer options
            if ans_scr > 0.5 % Yes - Left hemifield; No - Right hemifield
                Screen ('DrawTexture',w,txt_a1,[0 0 4000 2250],[0 0 x1 y1]);
            else % Yes - Right hemifield; No - Left hemifield
                Screen ('DrawTexture',w,txt_a2,[0 0 4000 2250],[0 0 x1 y1]);
            end
            % photodiode
            if tc == 1
                Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]); 
            end
            Screen ('Flip',w);
            KbWait
            
            % detect response
            FlushEvents('keyDown');
            t1     = GetSecs; % Grab time point
            time   = 0; % response time
            cont_r = 0; % response index
            trg    = [];
            while time < 0.15
                % update time response
                t2   = GetSecs;
                time = t2-t1;
                [keyIsDown,timeStamp,keyCode] = KbCheck;
                
                if (keyIsDown) && cont_r == 0 
                    key = KbName(find(keyCode));
                    % grab subjective response (seen/unseen)
                    if ans_scr > 0.5
                        if strcmp(key,'4')
                            trigger(trl,3) = 124; %seen
                            trg = 124;
                        elseif strcmp(key,'6')
                            trigger(trl,3) = 125; %unseen
                            trg = 125;
                        end
                    else
                        if strcmp(key,'4')
                            trigger(trl,3) = 125; %unseen
                            trg = 125;
                        elseif strcmp(key,'6')
                            trigger(trl,3) = 124; %seen
                            trg = 124;
                        end
                    end
                    % send EEG trigger with subjective response
                    if eeg==1
                        status=USB245( device, 1, trg );
                        WaitSecs(0.010)
                        status=USB245( device, 1, 0 );
                    end
                    
                    % grab behavioural responses for posterior sanitiy
                    % check (key and  time)
                    response_key{trl}  = key;
                    response_time(trl) = time;
                    
                    % update response variable for calibration update
                    if trg == 124
                        resp = 1; % seen
                    elseif trg == 125
                        resp = 0; % unseen
                    end
                    cont_r = 1; % update response index to break while loop
                end
            end
            
            % update contrast and grab threshold and contrast
            nresp = round(1 + (4-1).*rand(1)) ;   % random value to chcnumber of responses to check
            if ix == 1 % Gabor in left hemifield

                left_resp = [left_resp resp];
                if sum(left_resp(length(left_resp)-nresp+1:length(left_resp))) == nresp   % reduce contrast if all trials are seen
                    left_thr = left_thr-thr_step;
                elseif sum(left_resp(length(left_resp)-nresp+1:length(left_resp))) == 0   % increase contrast if all trials are unseen
                    left_thr = left_thr+thr_step;
                end
                left_threshold(length(left_resp))     = left_thr;
                left_stim_contrast(length(left_resp)) = lstim_tr;

            elseif ix == 2 % Gabor in right hemifield

                right_resp = [right_resp resp];
                if sum(right_resp(length(right_resp)-nresp+1:length(right_resp))) == nresp   % reduce contrast if all trials are seen
                    right_thr = right_thr-thr_step;
                elseif sum(right_resp(length(right_resp)-nresp+1:length(right_resp))) == 0   % increase contrast if all trials are unseen
                    right_thr = right_thr+thr_step;
                end
                right_threshold(length(right_resp))     = right_thr;
                right_stim_contrast(length(right_resp)) = rstim_tr;

            end
            
            % 6. Objective task - 15% (What was the Gabor orientation? Vertical/Horizontal)   
            if parameters(trl,4) > 10 && parameters(trl,4) < 13 && trigger(trl,3) == 124 &&...
               ct_leftseen > 0 && rand(1) < 0.15 || parameters(trl,4) > 10 &&...
               parameters(trl,4) < 13 && trigger(trl,3) == 125 && ct_leftunseen > 0 &&...
               rand(1) < 0.15 || parameters(trl,4) > 20 &&...
               parameters(trl,4) < 23 && trigger(trl,3) == 124 &&...
               ct_rightseen > 0 && rand(1) < 0.15 || parameters(trl,4) > 20 &&...
               parameters(trl,4) < 23 && trigger(trl,3) == 125 && ct_rightunseen > 0 && rand(1) < 0.15
                
                disc_scr = rand(1);
                if disc_scr > 0.5 % Vertical - Left hemifield; Horizontal - Right hemifield
                    Screen ('DrawTexture',w,txt_disc1,[0 0 4000 2250],[0 0 x1 y1]);
                else % Vertical - Right hemifield; Horizontal - Left hemifield
                    Screen ('DrawTexture',w,txt_disc2,[0 0 4000 2250],[0 0 x1 y1]);
                end
                % photidiode
                if tc == 1
                    Screen('DrawTexture',w,txt_white,[0 0 4000 2250],[1725*x0*2/1920 850*y0*2/1080 x0*2+1 y0*2]);
                end
                Screen ('Flip',w);
                WaitSecs(0.1)
                FlushEvents('keyDown');
                KbWait
                
                % answer
                t1     = GetSecs; % grab time point
                time   = 0; % response time
                cont_r = 0; % response index
                while time < 0.1
                    % update response time
                    t2   = GetSecs;
                    time = t2-t1;
                    [keyIsDown,timeStamp,keyCode] = KbCheck;
                    
                    if (keyIsDown) && cont_r == 0
                        key = KbName(find(keyCode));
                        % grab subjective response (vertical/horizontal)
                        if disc_scr > 0.5 % accordingly with Vertical/Horizontal location on the screen
                            if strcmp(key,'4')
                                trg = 121;                                
                                trigger(trl,4) = 121; %vertical
                                
                            elseif strcmp(key,'6')
                                trigger(trl,4) = 122; %horizontal
                                trg = 122;
                            end
                        else
                            if strcmp(key,'4')
                                trigger(trl,4) = 122; %horizontal
                                trg = 122;
                            elseif strcmp(key,'6')
                                trigger(trl,4) = 121; %vertical
                                trg = 121;
                            end
                        end
                        % send EEG trigger with subjective response
                        if eeg == 1
                            status = USB245( device, 1, trg );
                            WaitSecs(0.010)
                            status = USB245( device, 1, 0 );
                        end

                        % grab behavioural responses for posterior sanitiy check (key and time)
                        discrimination_response(trl) = trg;
                        if parameters(trl,4) == 11 && trg== 121 || parameters(trl,4) == 21 && trg== 121 ||...
                           parameters(trl,4) == 12 && trg== 122 || parameters(trl,4) == 22 && trg== 122
                            discrimination_response(trl,2) = 1;
                        else
                            discrimination_response(trl,2) = 0;
                        end
                        discrimination_time(trl) = time;
                        cont_r = 1; % update response index to break while loop
                    end
                    
                end
                
                % update counters for objective question
                if parameters(trl,4) > 10 &&  parameters(trl,4) < 13 && trigger(trl,3) == 125 % left_unseen
                    ct_leftunseen = ct_leftunseen-1;
                elseif parameters(trl,4) > 10 &&  parameters(trl,4) < 13 && trigger(trl,3) == 124 % left_seen
                    ct_leftseen = ct_leftseen-1;
                elseif parameters(trl,4) > 20 &&  parameters(trl,4) < 23 && trigger(trl,3) == 125 % right_unseen
                    ct_rightunseen = ct_rightunseen-1;
                elseif parameters(trl,4) > 20 &&  parameters(trl,4) < 23 && trigger(trl,3) == 124 % right_seen
                    ct_rightseen = ct_rightseen-1;
                end
            end
            
            if trl == 400 % if 400 trials, experiment is done
                Screen ('FillRect',w,127);
                Screen ('Flip',w);
                WaitSecs (1)
                
                Screen ('FillRect',w,127);
                Screen('TextFont', w , 'Helvetica')
                Screen('TextSize', w, 25);
                Screen('DrawText', w , 'Gracias por tu participacion', x0*668/960 , 510*y0/540 , [10 10 10]) %'Thank you for your participation'
                Screen('Flip', w);
                WaitSecs(4)
                
                % remove responses from pre-task calibration block/s
                right_resp          = right_resp(11:end);
                left_resp           = left_resp(11:end);
                right_stim_contrast = right_stim_contrast(11:end);
                right_threshold     = right_threshold(11:end);
                left_stim_contrast  = left_stim_contrast(11:end);
                left_threshold      = left_threshold(11:end);
                
                % save variables
                save valid_responses discrimination_response discrimination_time response_key right_resp left_resp response_time trigger right_threshold right_stim_contrast left_threshold left_stim_contrast
                
                Screen('CloseAll');
                
            elseif rem(trl,100) == 0 % give a break every 100 trials

                txt = Screen('MakeTexture',w,ppbreak);
                Screen ('DrawTexture',w,txt,[0 0 4000 2250],[0 0 x1 y1]);
                Screen ('Flip',w);
                WaitSecs(0.1)
                KbWait
                
            end
            
        end
        
    end
    
catch

    Screen('CloseAll');
    psychrethrow(psychlasterror);
end
cd ..

