%%===================Effort allocation task===================
%Script for Effort cost paradigm -30/05/2017-
%EffortAllocation_task13.m ordered and commented by Monja

%author: Monja P. Neuser, Vanessa Teckentrup, Nils B. Kroemer

%input via XBox USB-Controller

%Jitter/condition files prepared for n=99
%========================================================

%%Further information

%frequency estimation with exponential weighting
%https://de.mathworks.com/help/dsp/ug/sliding-window-method-and-exponential-weighting-method.html


%% Preparation

% Clear workspace
close all;
clear all; 
sca;

Screen('Preference', 'SkipSyncTests', 2);
load('GripForceSpec.mat')



%% Settings

% Run mode settings (fMRI or behavioral)
do_fmri_flag = 0; %will include trigger

if do_fmri_flag == 1
    dummy_volumes = 2; %will have to be set according to the sequence
    keyTrigger=KbName('5%');
    keyTrigger2=KbName('5');
    keyQuit=KbName('q');
    keyResp=KbName('1');
    keyResp2=KbName('1!');
    count_trigger = 0;
    win_phase_counter = 1; % Logs onsets of phases above threshold
    rest_phase_counter = 1; % Logs onsets of phases below threshold
    
    flip_flag_horizontal = 1;
    flip_flag_vertical = 0;
    
else
    
    flip_flag_horizontal = 0;
    flip_flag_vertical = 0;
    
end

% Basic screen setup 
    setup.screenNum = max(Screen('Screens')); %secondary monitor if there is one connected
    setup.fullscreen = 1; %if 0 -> will create a small window ideal for debugging, set =1 for Experiment

% Basic gamepad settings
    do_gamepad = 1; %do not set to 0, this is not implemented yet
    xbox_buffer = zeros(1,50); %will buffer the history of 50 button press status

        
   
%%Console input
% entrered by experimenter when experiment starts

%Before Experiment starts, get input from the MATLAB console
subj.runLABEL=input('Study ID [1 für Training / 2 für Experiment]: ','s');
subj.subjectID=input('Subject ID [2-stellig]: ','s');
subj.sessionID=input('Session ID [1/2]: ','s');


%Convert inputs
%Convert runLABEL (numeric) input to label (string)
if strcmp(subj.runLABEL, '1')
    subj.runLABEL = 'training';
    subj.studyID = 'TUE001'; %Prefix of tVNS project
    subj.study_part_ID = 'S5';
else
    subj.runLABEL = 'grEAT'; %Label can be study specific
    subj.studyID = 'TUE001'; %Prefix of tVNS project
    subj.study_part_ID = 'S5';
end


%Convert ID inputs to integers
subj.run = str2double(subj.runLABEL); %converts Run ID to integer
subj.num = str2double(subj.subjectID); %converts Subject ID to integer
subj.sess = str2double(subj.sessionID); %converts Session ID to integer


    
    
%% Load Conditions
%  Randomization of task parameters (difficulty, reward domain, reward
%  magnitude) is stored in separate condition files 'cond_runLABEL_subjID'.
%  [Condition files can be produced by running shuffle_conditions_effort.m] 

    % Load conditions for training run
    if  strcmp(subj.runLABEL, 'training')

        cond_filename = sprintf('%s\\conditions\\EAT-cond-Training_%s_%s_%s_R1', pwd, subj.studyID, subj.subjectID, subj.study_part_ID);
        
        % Load dummy maximum frequency value (=5.5) for calibration
        maxfreq_filename = sprintf('%s\\data\\dummy_freq_estimate', pwd);


    % Load conditions for experiment run
    elseif strcmp(subj.runLABEL, 'grEAT')

        cond_filename = sprintf('%s\\conditions\\EAT-cond-Experiment_%s_%s_%s_R1', pwd, subj.studyID, subj.subjectID, subj.study_part_ID);

        % Load maximum frequency (always from Session 1, runLABEL==training)
        maxfreq_searchname = [[pwd '\data\grEATPilot_Training_' subj.studyID '_'  subj.subjectID '_' subj.study_part_ID] '*'];
        maxfreq_searchname = dir(maxfreq_searchname);
        maxfreq_filename = sprintf('%s\\data\\%s', pwd, maxfreq_searchname.name);

    end

    
load(maxfreq_filename, 'input');
load(cond_filename);

  
%% Load graphics for counter and instruction graphics

%load regular images for behavioral task
if do_fmri_flag == 0 || strcmp(subj.runLABEL, 'training')
    [img_coin.winCounter, img_coin.map, img_coin.alpha] = imread('singlecoin.jpg');
    [img_cookie.winCounter, img_cookie.map, img_cookie.alpha] = imread('singlecookie_choc.jpg');

    [img.incentive_coins1, img.map, img.alpha] = imread('incentive_coins1.jpg');
    [img.incentive_coins10, img.map, img.alpha] = imread('incentive_coins10_2.jpg');

    [img.incentive_cookies1, img.map, img.alpha] = imread('incentive_cookies_choc1.jpg');
    [img.incentive_cookies10, img.map, img.alpha] = imread('incentive_cookies_choc10_2.jpg');
    
else %load mirrored images for fmri experiment
    [img_coin.winCounter, img_coin.map, img_coin.alpha] = imread('singlecoinM.jpg');
    [img_cookie.winCounter, img_cookie.map, img_cookie.alpha] = imread('singlecookie_chocM.jpg');

    [img.incentive_coins1, img.map, img.alpha] = imread('incentive_coins1M.jpg');
    [img.incentive_coins10, img.map, img.alpha] = imread('incentive_coins10_2M.jpg');

    [img.incentive_cookies1, img.map, img.alpha] = imread('incentive_cookies_choc1.jpg');
    [img.incentive_cookies10, img.map, img.alpha] = imread('incentive_cookies_choc10_2M.jpg');
end

%%if preferred: loading regular (vanilla colored) cookies
%[img_cookie.winCounter, img_cookie.map, img_cookie.alpha] = imread('singlecookie.jpg');
%[img.incentive_cookies1, img.map, img.alpha] = imread('incentive_cookies1.jpg');
%[img.incentive_cookies10, img.map, img.alpha] = imread('incentive_cookies10.jpg');



%% Load jitter vectors for ball onset
ball_jitter_filename = sprintf('%s\\jitters\\DelayJitter_mu_2_max_12_trials_64.mat', pwd);
fix_jitter_filename = sprintf('%s\\jitters\\DelayJitter_mu_3_max_12_trials_64.mat', pwd);
    
load(ball_jitter_filename);
ball_jitter = Shuffle(DelayJitter);
load(fix_jitter_filename);
fix_jitter = Shuffle(DelayJitter);



%% Setup PTB with some default values
PsychDefaultSetup(1); %unifies key names on all operating systems


% Define colors
color.white = WhiteIndex(setup.screenNum); %with intensity value for white on second screen
color.grey = color.white / 2;
color.black = BlackIndex(setup.screenNum);
color.red = [255 0 0];
color.darkblue = [0 0 139];
color.royalblue = [65 105 225]; %light blue, above threshold
color.gold = [255,215,0];
color.scale_anchors = [205 201 201];


% Define the keyboard keys that are listened for.
% Actually not needed for the task
keys.escape = KbName('ESCAPE');%returns the keycode of the indicated key.
keys.resp = KbName('Space');
keys.left = KbName('LeftArrow');
keys.right = KbName('RightArrow');
keys.down = KbName('DownArrow');



% Open the screen
if setup.fullscreen ~= 1   %if fullscreen = 0, small window opens
    [w,wRect] = Screen('OpenWindow',setup.screenNum,color.white,[0 0 800 600]);
else
    [w,wRect] = Screen('OpenWindow',setup.screenNum,color.white, []);
end

% Get the center coordinates
[setup.xCen, setup.yCen] = RectCenter(wRect);

% Flip to clear
Screen('Flip', w);

% Query the frame duration
setup.ifi = Screen('GetFlipInterval', w);

% Query the maximum priority level - optional
setup.topPriorityLevel = MaxPriority(w);


% Setup overlay screen
effort_scr = Screen('OpenOffscreenwindow',w,color.white);
Screen('TextSize',effort_scr,16);
Screen('TextFont',effort_scr,'Arial');

setup.ScrWidth = wRect(3) - wRect(1);
setup.ScrHeight = wRect(4) - wRect(2);

% Key Press settings    
KbQueueCreate();
KbQueueFlush(); 
KbQueueStart();
[b,c] = KbQueueCheck;

% Initialize counter
count_joy = 1; %Indexes Joystick position
count_jitter = 1; %Not used in the script



%% Stimulus settings

% Prepare incentive textures
stim.incentive_coins1 = Screen('MakeTexture', w, img.incentive_coins1);
stim.incentive_coins10 = Screen('MakeTexture', w, img.incentive_coins10);
stim.incentive_cookies1 = Screen('MakeTexture', w, img.incentive_cookies1);
stim.incentive_cookies10 = Screen('MakeTexture', w, img.incentive_cookies10);

% Draw Elements proportional to screen dimensions (screen_height to
% scale_height)

    % Drawing parameters for Thermometer (Tube)
    Tube.width = round(setup.ScrWidth * .20);
    Tube.offset = round((setup.ScrHeight - (setup.ScrHeight * .95)) * .35);
    Tube.height = round(Tube.offset+setup.ScrHeight/4);

    % Drawing parameters for Ball
    Ball.width = round(setup.ScrWidth * .06);

    % Drawing parameters for Reward details
    Coin.width = round(setup.ScrWidth * .15);



% Parameters to draw ball movement force
    
    restforce = getfield(GripForceSpec, 'restforce'); %Resting force of the Grip Device
    maxpossibleforce = getfield(GripForceSpec, 'maxpossibleforce');
    ForceMat = restforce; %Ball initially at bottom is here realized by making the initial force equal to the resting force
    delta_pos_force = restforce - maxpossibleforce;
    ForceTime = [];
    LowerBoundBar = setup.ScrHeight - Tube.offset - Ball.width;
    UpperBoundBar = Tube.height;

    
% Template for "continue with mouse click" display    
text_Cont = ['Weiter mit Mausklick.'];

%%=========================================================================
%%    Training block
%     ("Training" includes only 2 trials of 10sec, "pushing the limit"
%      to determine individual maximum frequency)
%
%      "Practice trials" instead use the same EffortAllocation_task14.m script
%%=========================================================================


% Initialize task start
if strcmp(subj.runLABEL, 'training') 

    %Instruction text                                               
    text = ['Willkommen. \n\nDies ist ein einfaches Spiel, bei dem Sie um Geld und einen Snack spielen.\nSie können sich zunächst mit den Funktionen vertraut machen und ein bisschen üben. Das eigentliche Spiel wird dann zu einem späteren Zeitpunkt starten.'];
    Screen('TextSize',w,32);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', (setup.ScrHeight/5), color.black, 60, [], [], 1.2);
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
    Screen('Flip',w);

    GetClicks(setup.screenNum);
      


% for skipping: set do_training = 0;  (WARNING: Training is used to obtain
% maximum frequency estimation at session 1)
    do_training = 1;

% Call Training script

    if do_training == 1
     
     input.maxForce = [];
     
     EffortAllocation_Training14
   
    end

end




%%=========================================================
%%    1 Trial effort    
% Procedure as used in experiment and during practice trials
% Show moving ball proportional to button press frequency
%%=========================================================

%% Settings for individual participant

%  Load VAS-jitters
if strcmp(subj.runLABEL, 'training') 
    
    jitter_filename = sprintf('%s\\jitters\\DelayJitter_mu_0.70_max_4_trials_16.mat', pwd);
    
else
    
    jitter_filename = sprintf('%s\\jitters\\DelayJitter_mu_0.70_max_4_trials_96.mat', pwd);
    
end
    
load(jitter_filename);
jitter = Shuffle(DelayJitter);



%% Initialize drawing and output variables for trial

% Initialise exponential weighting
forget_fact = 0.6;
prev_weight_fact = 0;
prev_movingAvrg = 0;
t_button = 0;
current_input = 0; 
Avrg_value = 0;
frequency_estimate=0;
draw_frequency = 0;%This is the relevant output, also used to determine ball height

collect_freq.t_button_interval  = []; %stores current_input (t2-t1)
collect_freq.avrg               = []; %stores weighted interval value of a click

i_resp = 1;
i_phantom = 1;

t_button_vec = [nan];
frequency_vector = [nan]; %stores weighted interval value of a click

i_step = 1;
t_vector = [];


% Initialize output structure
output.t_button = []; % stores clicks: timestamps of button presses
output.t_button_referenced = []; % referenced to trial start (t_trial_onset)
output.frequency_button = [];
output.values_per_trial = []; % Matrix of output values Button press referenced
output.values_per_trial_t100 = []; % Matrix of output values / timepoint referenced (every 100ms)
output.t_100 = []; % Timestamp every 100ms
output.frequency_t100 = []; % Tracks frequency every 100 ms


% Initialize parameters for payout calculation
flag = 0; %1 if frequency exceeds MaxFrequency
exceed_onset = 0; %Time point of ball exceeding threshold

t_payout = [nan; nan]; %collects all t1/t2 in one trial
i_payout_onset = 1;

output.t_payout = []; %collects all t1/t2 across all trials
output.payout_per_trial = 0;
output.t_payout_calories = 0;

% Payout display (Counter visible during trial)
win_coins = nan;
win_cookies = nan;
payout.diff = [nan nan]';
payout.counter = 0;
payout.win = 0;

% Trial counter CHANGE TO 30 IN EXPERIMENT
trial_length = 2; %seconds

% Force variables
ForceMat = restforce;
ForceTime = [];


%% Screen elements

%Text before Trial-Block
if strcmp(subj.runLABEL, 'training') 
    text = ['Jetzt üben Sie die eigentliche Aufgabe: \nDie Linie wird sich nun nicht mehr mit dem Ball bewegen.\n\nVersuchen Sie mithilfe von Druck den Ball nach oben und über eine rote Linie zu bewegen. Sie können Punkte gewinnen für jede volle Sekunde, die der Ball über der roten Linie bleibt. Sie können erkennen, dass Sie etwas gewinnen, wenn der Ball seine Farbe zu hellblau ändert.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum);
        
elseif do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training') 
    
    text = ['Wir beginnen nun mit dem Spiel, das Sie vorhin geübt haben. Zur Erinnerung: Dies ist ein einfaches Spiel, bei dem Sie um Geld und einen Snack spielen.\n\nVersuchen Sie mithilfe von Druck den Ball nach oben und über eine rote Linie zu bewegen. Sie können Punkte gewinnen für jede volle Sekunde, die der Ball über der roten Linie bleibt. Sie können erkennen, dass Sie etwas gewinnen, wenn der Ball seine Farbe zu hellblau ändert.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, flip_flag_horizontal, flip_flag_vertical, 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, flip_flag_horizontal, flip_flag_vertical, 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum);
        
else     
        text = ['Wir beginnen nun mit dem Spiel, das Sie vorhin geübt haben. Zur Erinnerung: Dies ist ein einfaches Spiel, bei dem Sie um Geld und einen Snack spielen.\n\nVersuchen Sie mithilfe von Druck den Ball nach oben und über eine rote Linie zu bewegen. Sie können Punkte gewinnen für jede volle Sekunde, die der Ball über der roten Linie bleibt. Sie können erkennen, dass Sie etwas gewinnen, wenn der Ball seine Farbe zu hellblau ändert.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum);

      text = ['Der Unterschied zur Übung vorhin ist, dass Sie nicht in jedem Durchgang wissen werden, wo die Linie genau liegt. In der Hälfte der Durchgänge sehen Sie stattdessen einen roten Bereich. Die Linie, die der Ball übersteigen muss um Punkte zu gewinnen, liegt irgendwo in diesem Bereich. Wenn Sie den Ball also komplett über diesen Bereich bewegen, sammeln Sie auf jeden Fall Essens- oder Geld-Punkte. In diesen Durchgängen ändert der Ball seine Farbe nicht. \n\n Wie zuvor sehen Sie jedoch nach dem Durchgang, wie viele Punkte Sie gesammelt haben. Dann wird Ihnen auch die tatsächliche Position der Linie angezeigt.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum);
end   


% Text blocks for Task Instruction

if do_fmri_flag == 0 || strcmp(subj.runLABEL, 'training') 

    text = ['Sie können in den einzelnen Durchgängen unterschiedliche Gewinne erhalten. Sie spielen dabei sowohl für Geld als auch für Kalorien, die Sie im Anschluss an die Aufgabe für einen Snack eintauschen können. Was die aktuelle Belohnung ist, bleibt für einen Durchgang von 24 Sekunden konstant und wird Ihnen mit Hilfe von Bildern angezeigt.'];
    Screen('TextSize',w,32);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
    Screen('Flip',w);
    GetClicks(setup.screenNum);   

    
    
    % Load and show incentives


    text_coins1 = ['1 Geld-Punkt pro Sekunde'];
    text_coins10 = ['10 Geld-Punkte pro Sekunde'];
    text_cookies1 = ['1 Essens-Punkt pro Sekunde'];
    text_cookies10 = ['10 Essens-Punkte pro Sekunde'];


        text_instr =  ['In manchen Durchgängen können Sie Geld-Punkte gewinnen. Im Anschluss an die Aufgabe bekommen Sie den entsprechenden Geldbetrag ausgezahlt.\n\nFolgende Bedingungen gibt es:'];
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_instr, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        
        Screen('DrawTexture', w, stim.incentive_coins1,[], [(setup.xCen*0.7) ((setup.ScrHeight/5)*2.9-Coin.width*0.6) (setup.xCen*0.7+Coin.width*0.6) ((setup.ScrHeight/5)*2.9)])
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_coins1, setup.xCen, ((setup.ScrHeight/5)*3.2-Coin.width/2), color.black,40, [], [], 1.2);
        
        Screen('DrawTexture', w, stim.incentive_coins10,[], [(setup.xCen*0.7) ((setup.ScrHeight/5)*3.9-Coin.width*0.6) (setup.xCen*0.7+Coin.width*0.6) ((setup.ScrHeight/5)*3.9)])
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_coins10, setup.xCen, ((setup.ScrHeight/5)*4.2-Coin.width/2), color.black,40, [], [], 1.2);
        

        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        time.img = Screen('Flip', w);    
        
        GetClicks(setup.screenNum);         
        
    text_instr =  ['In manchen Durchgängen können Sie Kalorien gewinnen. Im Anschluss an die Aufgabe bekommen Sie den entsprechenden Gegenwert als Snack augegeben. \n\nFolgende Bedingungen gibt es:'];
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_instr, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);   
        
        Screen('DrawTexture', w, stim.incentive_cookies1,[], [(setup.xCen*0.7) ((setup.ScrHeight/5)*2.9-Coin.width*0.6) (setup.xCen*0.7+Coin.width*0.6) ((setup.ScrHeight/5)*2.9)])
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_cookies1, setup.xCen, ((setup.ScrHeight/5)*3.2-Coin.width/2), color.black,40, [], [], 1.2);
        
        Screen('DrawTexture', w, stim.incentive_cookies10,[], [(setup.xCen*0.7) ((setup.ScrHeight/5)*3.9-Coin.width*0.6) (setup.xCen*0.7+Coin.width*0.6) ((setup.ScrHeight/5)*3.9)])
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_cookies10, setup.xCen, ((setup.ScrHeight/5)*4.2-Coin.width/2), color.black,40, [], [], 1.2);

        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2); 
        time.img = Screen('Flip', w);    
        
        GetClicks(setup.screenNum); 

    text = ['Die Umrechnung der Punkte richtet sich nach folgendem Kurs:  \n10 Geld-Punkte entsprechen 1 cent.\n\n10 Essens-Punkte entsprechen 1 kcal.\n\nIm Anschluss an die Aufgabe können Sie die Geldpunkte in einen entsprechenden Geldbetrag eintauschen und für die Essens-Punkte einen entsprechenden Snack erhalten.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum); 
if strcmp(subj.runLABEL, 'training')
    text = ['Im Verlaufe des Experiments wird es unterschiedliche Schwierigkeitsstufen geben. Es wird also nicht immer möglich sein, den Ball die ganze Zeit über vollständig über der Linie zu halten. Eine Möglichkeit damit umzugehen ist, auch während eines Durchgangs Pausen zu machen, um danach wieder stärkeren Druck ausüben zu können.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum); 
else
        text = ['Zur Erinnerung: Im Verlaufe des Experiments wird es unterschiedliche Schwierigkeitsstufen geben. Es wird also nicht immer möglich sein, den Ball die ganze Zeit über vollständig über der Linie zu halten. Eine Möglichkeit damit umzugehen ist, auch während eines Durchgangs Pausen zu machen, um danach wieder stärkeren Druck ausüben zu können.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum); 
end
%      if strcmp(subj.runLABEL, 'training') && do_fmri_flag == 0
% 
%         text = ['Nach jedem Durchgang werden Ihnen nacheinander zwei Fragen angezeigt:\n\n' char(39) 'Wie stark haben Sie sich in diesem Durchgang verausgabt?' char(39) ' \n ' char(39) 'Wie sehr wollten Sie die Belohnung in diesem Durchgang erhalten?' char(39) '\n\nSie können zum Antworten den Regler auf einer Skala (überhaupt nicht - sehr) verschieben. Nutzen Sie dazu bitte den linken Joystick auf dem Controller. Ihre Antwort müssen Sie dann mit der grünen A-Taste auf dem Controller bestätigen.\nBitte beachten Sie, dass Sie für die Antworten nur eine begrenzte Zeit zur Verfügung haben. Überlegen Sie deshalb nicht zu lange, sondern antworten Sie spontan. Es gibt dabei kein ' char(39) 'Richtig' char(39) ' oder ' char(39) 'Falsch' char(39) '.'];
%             Screen('TextSize',w,32);
%             Screen('TextFont',w,'Arial');
%             [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
%             [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
%             Screen('Flip',w);
%             GetClicks(setup.screenNum); 
% 
%      end
    
    if strcmp(subj.runLABEL, 'training') 

        text = ['Die nun folgende Übungsphase wird ca. 5 Minuten dauern.\nSollten Sie noch Fragen haben, können Sie diese jetzt stellen.\nWenn Sie sich bereit fühlen, können wir jetzt mit dem Experiment beginnen.'];

    elseif strcmp(subj.runLABEL, 'grEAT') 

        text = ['Das gesamte Experiment wird ca. 40 Minuten dauern.\nSollten Sie noch Fragen haben, können Sie diese jetzt stellen.\nWenn Sie sich bereit fühlen, können wir jetzt mit dem Experiment beginnen.'];

    end
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', (setup.ScrHeight/5), color.black, 60, [], [], 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum);
    
elseif do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
    
    text = ['Das gesamte Experiment wird ca. 20 Minuten dauern.\nSollten Sie noch Fragen haben, können Sie diese jetzt stellen.\nWenn Sie sich bereit fühlen, können wir jetzt mit dem Experiment beginnen.'];

    Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', (setup.ScrHeight/5), color.black, 60, flip_flag_horizontal, flip_flag_vertical, 1.2);
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, flip_flag_horizontal, flip_flag_vertical, 1.2);
        Screen('Flip',w);
        GetClicks(setup.screenNum);
        
end



    
%% Experimental procedure
%Listen for triggers
if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
    
    % Show empty screen while waiting for trigger
    Screen('FillRect',w);
    Screen('Flip',w);
    
    timestamps.on_trigger_loop = GetSecs;
    %KbQueueCreate();
    KbQueueFlush(); 
	KbQueueStart(); 
	%[ons_resp, starttime] = Screen('Flip', w, []);
    [b,c] = KbQueueCheck;
    
    while c(keyQuit) == 0
        [b,c] = KbQueueCheck;
        if c(keyTrigger) || c(keyTrigger2) > 0
            count_trigger = count_trigger + 1;
            timestamps.trigger.all(count_trigger,1) = GetSecs;
            if count_trigger > dummy_volumes
                timestamps.trigger.fin = GetSecs;
                break
            end
        end
    end
end   

% if do_fmri_flag == 0
% 
%     timestamps.trigger.fin = GetSecs;
% end
    
KbQueueFlush();
timestamps.exp_on = GetSecs;

%  Loop while entries in the conditions file left
for i_trial = 1:length(conditions) %condition file determines repetitions
    
  
    if do_fmri_flag == 0
        
        % Break?
        % After half of the trials enable short break
        if i_trial == ((length(conditions)/2) + 1) 

                text = ['Sie haben jetzt die Hälfte geschafft. Sie können eine kleine Pause machen und sich lockern.'];          


            Screen('TextSize',w,32);
            Screen('TextFont',w,'Arial');
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
            Screen('Flip',w);
            GetClicks(setup.screenNum);  

        end
        
    end
    
    
    
    % Fixation cross
    
    if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training') 
        
        % Show fixation cross 
        fix = ['+'];
        Screen('TextSize',w,64);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.black,80);
        [time.fix, starttime] = Screen('Flip', w);

        timestamps.onsets.fix(i_trial,1) = starttime - timestamps.trigger.fin;

        WaitSecs(2 + fix_jitter(i_trial,1)); %Show screen for 2s plus jitter value (drawn from exponential distribution with mean of 3 and max = 12)
        
    elseif do_fmri_flag == 1 && strcmp(subj.runLABEL, 'training') 
        
        % Show fixation cross
        fix = ['+'];
        Screen('TextSize',w,64);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.black,80);
        [time.fix, starttime] = Screen('Flip', w);

        WaitSecs(2);
            
    else
    
        % Manual trigger together with NEMOS tVN-Stimulation
          fix = ['+'];
          Screen('TextSize',w,64);
          Screen('TextFont',w,'Arial');
          [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.black,80);
          [time.fix, starttime] = Screen('Flip', w);

         % Wait for experimenter input 
         %WaitSecs(2 + fix_jitter(i_trial,1));
         WaitSecs(2);
     
    end
     
     
     
    
    % Preparation before actual Trial start

    % Update Conditions trialwise
    input.percentFrequency = input.maxFrequency * (conditions(i_trial, 1) * 0.01); % 75% or 85% in training, interval in experiment
    input.incentive = conditions(i_trial, 2); %1 = Money, 2 = Food
    input.value = conditions(i_trial, 3); % 1 or 10
    if strcmp(subj.runLABEL, 'training')
        input.uncertainty = 0;
    else
        input.uncertainty = conditions(i_trial, 4);
    end 
    
    % FORCE Update Conditions trialwise
    
    input.percentForce = restforce - ((restforce - input.maxForce )* (conditions(i_trial,1) * 0.01)); % 75 or 85%
    LowerBoundBar = setup.ScrHeight - Tube.offset; %bottom of ball and bar if delta_pos_force = 0
    UpperBoundBar = Tube.height + Ball.width; %location of bar when maxpossibleforce = input.maxForce
    maxpossibleforce = input.maxForce; %update so that the uncertainty box appears in the same location, irrespective of the individual max force
    delta_pos_force = restforce - maxpossibleforce;
    %Threshold position for obtaining reward in this trail
    Threshold.yposition = ((((LowerBoundBar - UpperBoundBar)/delta_pos_force) * input.percentForce + UpperBoundBar - (maxpossibleforce * (LowerBoundBar - UpperBoundBar)/delta_pos_force)));
    
    % FORCE Updates to draw uncertainty box
    ForceLow = restforce - ((restforce - input.maxForce) * 0.6); %60 percent of maxForce, used to draw uncertainty box
    LwrBndUncertain = ((((LowerBoundBar - UpperBoundBar)/delta_pos_force) * ForceLow + UpperBoundBar - (maxpossibleforce * (LowerBoundBar - UpperBoundBar)/delta_pos_force))); %bottom y coordinate of uncertainty box
    ForceHigh = restforce - ((restforce - input.maxForce) * 0.95); %95 percent of maxForce, used to draw uncertainty box
    UpprBndUncertain = ((((LowerBoundBar - UpperBoundBar)/delta_pos_force) * ForceHigh + UpperBoundBar - (maxpossibleforce * (LowerBoundBar - UpperBoundBar)/delta_pos_force))); %top y coordinate of uncertainty box
    
    % Prepare graphical display with corresponding reward items 
    
    % load incentive & counter icon
        if input.incentive == 1 && input.value == 1
            incentive = stim.incentive_coins1;
            img.winCounter = img_coin.winCounter;
            img.map = img_coin.map;
            img.alpha = img_coin.alpha;
        elseif input.incentive == 1 && input.value == 10
            incentive = stim.incentive_coins10;
            img.winCounter = img_coin.winCounter;
            img.map = img_coin.map;
            img.alpha = img_coin.alpha;
        elseif input.incentive == 2 && input.value == 1
            incentive = stim.incentive_cookies1;
            img.winCounter = img_cookie.winCounter;
            img.map = img_cookie.map;
            img.alpha = img_cookie.alpha;
        elseif input.incentive == 2 && input.value == 10
            incentive = stim.incentive_cookies10;
            img.winCounter = img_cookie.winCounter;
            img.map = img_cookie.map;
            img.alpha = img_cookie.alpha;
        end
 
    % load single-coin/single-cookie picture for Counter

    stim.winCounter = Screen('MakeTexture', w, img.winCounter);

    % Show reward type and difficulty before start of force input
    Screen('DrawTexture', w, incentive,[], [((setup.xCen-Tube.width)-Coin.width) (setup.ScrHeight/4) (setup.xCen-Tube.width) (setup.ScrHeight/4+Coin.width)]); 
    
    % Draw Tube
    Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), Tube.height, (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6);
    Screen('DrawLine',effort_scr,color.black,(setup.xCen+Tube.width/2), Tube.height, (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
    Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);

    Screen('DrawTexture', effort_scr, incentive,[], [((setup.xCen-Tube.width)-Coin.width) (setup.ScrHeight/4) (setup.xCen-Tube.width) (setup.ScrHeight/4+Coin.width)]);
    Screen('CopyWindow',effort_scr,w);

    % Draw Max% line
    if input.uncertainty == 0 
        Screen('DrawLine',w,color.red,(setup.xCen-Tube.width/2), Threshold.yposition, (setup.xCen+Tube.width/2), Threshold.yposition,3);
    
        [time.img, starttime] = Screen('Flip', w);
    
        if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
            timestamps.onsets.condition_preview(i_trial,1) = starttime - timestamps.trigger.fin;
        end
    
        if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training') 
            WaitSecs(2 + ball_jitter(i_trial,1)); %Show screen for 2s plus jitter value (drawn from exponential distribution with mean of 2 and max = 12)
        else
            WaitSecs(2);
        end
    else %uncertainty condition in experiment, draw uncertainty box
        box.position = [(setup.xCen-Tube.width/2), UpprBndUncertain, (setup.xCen+Tube.width/2), LwrBndUncertain];
        Screen('FillRect',w,color.red,box.position);
        
        [time.img, starttime] = Screen('Flip', w);
    
        if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
            timestamps.onsets.condition_preview(i_trial,1) = starttime - timestamps.trigger.fin;
        end
    
        if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training') 
            WaitSecs(2 + ball_jitter(i_trial,1)); %Show screen for 2s plus jitter value (drawn from exponential distribution with mean of 2 and max = 12)
        else
            WaitSecs(2);
        end
    end 
        
 
%% Actual trial start (recordstart time)
    
t_trial_onset = GetSecs;
t_buttonN_1 = t_trial_onset;

if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
    timestamps.onsets.effort_trial_start(i_trial,1) = t_trial_onset - timestamps.trigger.fin;
end
    
   
% Loop during 30 sec duration (trial length)
while (trial_length > (GetSecs - t_trial_onset))    

   % Draw graphical display

      % Draw Tube
        Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), Tube.height, (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6);
        Screen('DrawLine',effort_scr,color.black,(setup.xCen+Tube.width/2), Tube.height, (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
        Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);

        Screen('DrawTexture', effort_scr, incentive,[], [((setup.xCen-Tube.width)-Coin.width) (setup.ScrHeight/4) (setup.xCen-Tube.width) (setup.ScrHeight/4+Coin.width)]);
        Screen('CopyWindow',effort_scr,w);

      % Draw Max% line or uncertainty box
      if input.uncertainty == 0 
        Screen('DrawLine',w,color.red,(setup.xCen-Tube.width/2), Threshold.yposition, (setup.xCen+Tube.width/2), Threshold.yposition,3);
      else
        Screen('FillRect',w,color.red,box.position);
      end

      % Show incentive counter
      if strcmp(subj.runLABEL, 'training')
        if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
              Screen('DrawTexture', w, stim.winCounter,[], [(setup.xCen*1.7-(size(img.winCounter,2)*0.3)) (setup.ScrHeight/6-(size(img.winCounter,1)*0.3)) (setup.xCen*1.7) (setup.ScrHeight/6)]);
        else
            Screen('DrawTexture', w, stim.winCounter,[], [(setup.xCen*1.5-(size(img.winCounter,2)*0.3)) (setup.ScrHeight/6-(size(img.winCounter,1)*0.3)) (setup.xCen*1.5) (setup.ScrHeight/6)]);
        end
      
            text = [' x ' num2str(payout.win, '%02i')];
                   Screen('TextSize',w,56);
                    Screen('TextFont',w,'Arial');
                if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
                    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, setup.xCen*1.5, (setup.ScrHeight/6), color.black, [], flip_flag_horizontal, flip_flag_vertical);
                else
                    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, setup.xCen*1.5, (setup.ScrHeight/6), color.black);
                end
      end

    % Track Ball position and translate into payout
    
     if ForceMat < restforce
        
        Ball_yposition = ((((LowerBoundBar - UpperBoundBar)/delta_pos_force) * ForceMat + UpperBoundBar - (maxpossibleforce * (LowerBoundBar - UpperBoundBar)/delta_pos_force)));
    
     else
         Ball_yposition = (setup.ScrHeight-Tube.offset);
        
     end

        Ball.position = [(setup.xCen-Ball.width/2) (Ball_yposition-Ball.width) (setup.xCen+Ball.width/2) (Ball_yposition)];

        
        % Ball above threshold
        % -> change color, start increasing scoreÖpw
        if (Ball.position(1,4) < Threshold.yposition)  
            if input.uncertainty == 0
                Ball.color = color.royalblue;
            else
                Ball.color = color.darkblue;
            end

            if (flag == 0) % Mark "crossing the threshold"

                flag = 1;                    
                exceed_onset = GetSecs;
                t_payout(1,i_payout_onset) = exceed_onset;
                
                if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
                    timestamps.onsets.win_phase(i_trial,win_phase_counter) = exceed_onset - timestamps.trigger.fin;
                    win_phase_counter = win_phase_counter + 1;
                end

            end

            % Calculate payoff for exceed_Threshold:
                % If ball above threshold, need phantom value to update
                % reward counter
                t_payout(3,i_payout_onset) = GetSecs;

                payout.diff = t_payout(3,1:end) - t_payout(1,1:end);
                payout.counter = nansum(payout.diff);

                % Payout: counter only for seconds, exchange rate computed
                % internally

                % if input.value == 1
                   payout.win = floor(payout.counter); 
                % elseif input.value == 10
                %   payout.win = (floor(payout.counter) * 10);
                % end



        % Ball below threshold: 
        % -> change color, stop increasing score 
        else       

             Ball.color = color.darkblue;

             if (flag == 1) % Mark "crossing the threshold"

                 flag = 0;
                 exceed_offset = GetSecs;
                 t_payout(2,i_payout_onset) = exceed_offset;

                 i_payout_onset = i_payout_onset + 1;
                 
                 if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
                    timestamps.onsets.rest_phase(i_trial,rest_phase_counter) = exceed_offset - timestamps.trigger.fin;
                    rest_phase_counter = rest_phase_counter + 1;
                 end

             end  

            % No payoff for this condition

        end  

            Screen('FillOval',w,Ball.color,Ball.position);
            Screen('Flip', w);




    % Gamepad query to compute button press frequency

        [b,c] = KbQueueCheck;  

        % Conditional input
        if do_gamepad == 1 % If experiment is run with GamePad

            % Continuously log position and time of the button for the right index
            % finger -> Joystick.Z
            [Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(GripForceSpec);

            % Getting values from Grip Force Device -> Joystick.Y
                ForceMat = Joystick.Y;
                ForceTime = [ForceTime, Joystick.Y];
            % Store for timestamps and actual frequency every 100ms
                t_step = GetSecs;
                t_vector(1,i_step) = t_step - t_trial_onset;
                i_step = i_step + 1;
            
            %Buffer routine
            for buffer_i = 2:50 %buffer_size

            joy.pos_Z(count_joy,i_trial) = Joystick.Z;
            joy.time_log(count_joy,i_trial) = GetSecs - t_trial_onset;
            count_joy = count_joy + 1;

                if Joystick.Z < 200
                    Joystick.RI_button = 1;
                else
                    Joystick.RI_button = 0;
                end

                xbox_buffer(buffer_i) = Joystick.RI_button; %Joystick.Button(1);

                if xbox_buffer(buffer_i)==1 && xbox_buffer(buffer_i-1)==0
                    count_joystick = 1;

                    %Stores time stamp of BP
                    t_button = GetSecs; 

                else
                    count_joystick = 0;
                end

                if buffer_i == 50
                    buffer_i = 2;
                    xbox_buffer(1)=xbox_buffer(50);
                end

            end

        end

end
            
    
% End of trial
    
count_joy = 1;

end_of_trial = GetSecs;

if (flag == 1)

    t_payout(2,i_payout_onset) =  end_of_trial;
end

    

% Calculate payoff for exceed_Threshold

exc_thresh_this_trial = t_payout(2,1:end)-t_payout(1,1:end);
   

% Calculate win for this trial according to reward at stake
if input.incentive == 1 && input.value == 1
    win_coins = floor(nansum(exc_thresh_this_trial));
elseif input.incentive == 2 && input.value == 1
    win_cookies = floor(nansum(exc_thresh_this_trial));    
elseif input.incentive == 1 && input.value == 10
    win_coins = floor(nansum(exc_thresh_this_trial)) * 10;
elseif input.incentive == 2 && input.value == 10
    win_cookies = floor(nansum(exc_thresh_this_trial)) * 10;
end


% Store reward in output struct
output.t_payout = [output.t_payout, t_payout(1:2,1:end)];   
output.payout_per_trial(1,i_trial) = win_coins;
output.payout_per_trial(2,i_trial) = win_cookies;
output.payout_per_trial(3,i_trial) = input.incentive;
output.payout_per_trial(4,i_trial) = input.value;




%%                At the end of each trial
%%==============call feedback===================   

%If no VAS: Show feedback
%effort_feedback
timer_onset_feedback = GetSecs;

if do_fmri_flag == 1 && strcmp(subj.runLABEL, 'grEAT')
    
    timestamps.onsets.feedback(i_trial,1) = timer_onset_feedback - timestamps.trigger.fin;
    
    if i_trial < length(conditions)

        i_timer = 1;

        while i_timer <= 3

            while i_timer > GetSecs - timer_onset_feedback

                if input.incentive == 1 % money
                    text = ['Sehr gut!\n\nGewinn:   ' num2str(win_coins) '   Geld-Punkt(e). \n\n\n\n' num2str(4 - i_timer) '    Sekunden bis zur nächsten Runde.'];
                elseif input.incentive == 2 % food
                    text = ['Sehr gut!\n\nGewinn:   ' num2str(win_cookies) '   Essens-Punkt(e). \n\n\n\n' num2str(4 - i_timer) '    Sekunden bis zur nächsten Runde.'];
                end

                    Screen('TextSize',w,32);
                    Screen('TextFont',w,'Arial');
                    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40, flip_flag_horizontal, flip_flag_vertical);
                    Screen('Flip',w);
            end

            i_timer = i_timer + 1;
        end

    end

elseif strcmp(subj.runLABEL, 'training')

    if i_trial < length(conditions)

        i_timer = 1;

        while i_timer <= 3

            while i_timer > GetSecs - timer_onset_feedback
                

                if input.incentive == 1 % money
                    text = ['Sehr gut!\n\nGewinn:   ' num2str(win_coins) '   Geld-Punkt(e). \n\n\n\n' num2str(4 - i_timer) '    Sekunden bis zur nächsten Runde.'];
                elseif input.incentive == 2 % food
                    text = ['Sehr gut!\n\nGewinn:   ' num2str(win_cookies) '   Essens-Punkt(e). \n\n\n\n' num2str(4 - i_timer) '    Sekunden bis zur nächsten Runde.'];
                end

                    Screen('TextSize',w,32);
                    Screen('TextFont',w,'Arial');
                    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
                    Screen('Flip',w);
            end

            i_timer = i_timer + 1;
        end

    end
    
elseif do_fmri_flag == 0 && strcmp(subj.runLABEL, 'grEAT') 
     if i_trial < length(conditions)

        i_timer = 1;

        while i_timer <= 3

            while i_timer > GetSecs - timer_onset_feedback
                

                if input.incentive == 1 % money
                    text = ['Sehr gut!\n\nGewinn:   ' num2str(win_coins) '   Geld-Punkt(e). \n\n\n' num2str(4 - i_timer) '    Sekunden bis zur nächsten Runde.'];
                elseif input.incentive == 2 % food
                    text = ['Sehr gut!\n\nGewinn:   ' num2str(win_cookies) '   Essens-Punkt(e). \n\n\n' num2str(4 - i_timer) '    Sekunden bis zur nächsten Runde.'];
                end
                    % Draw Text
                    Screen('TextSize',w,32);
                    Screen('TextFont',w,'Arial');
                    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center',(setup.ScrHeight/10), color.black,40);
                    % Draw Tube
                    Screen('DrawLine',w,color.black,(setup.xCen-Tube.width/2), Tube.height, (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6);
                    Screen('DrawLine',w,color.black,(setup.xCen+Tube.width/2), Tube.height, (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
                    Screen('DrawLine',w,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
                    % Draw Threshold line
                    Screen('DrawLine',w,color.red,(setup.xCen-Tube.width/2), Threshold.yposition, (setup.xCen+Tube.width/2), Threshold.yposition,3);
                    Screen('Flip',w);
                   
            end

            i_timer = i_timer + 1;
        end
    end
end



%%=====only for training (session 1): update individual max Frequency====
if strcmp(subj.runLABEL, 'training') && (subj.sess ==1)
    
    if length(frequency_vector) == 0

        collectMax.next = nan;
        
    else
        
        collectMax.next = max(frequency_vector);
        
    end 
    
        collectMax.maxFreq(1,i_collectMax) = collectMax.next;
        i_collectMax = i_collectMax + 1;
    
end

% Equivalent for Force, as a control that maxForce in the practice might be
% higher (corresponding to a lower number) in the training.

if strcmp(subj.runLABEL, 'training') && (subj.sess ==1)

        collectMax.maxForce(1,i_collectMax) = min(ForceTime);
        i_collectMax = i_collectMax + 1;
    
end


%%=======Prepare Output=========================
%Reference t_Button to trial_start 
t_ref_vector = t_vector - t_trial_onset;


%Copy Output Values into Output Matrix
if do_fmri_flag == 0 && strcmp(subj.runLABEL, 'grEAT')
output.values_per_trial = [output.values_per_trial, [ones(1,length(ForceTime)) * subj.num ; ...  %Subj_ID
                           ones(1,length(ForceTime)) * input.maxForce; ...                       %MaxForce
                           ones(1,length(ForceTime)) * i_trial ;  ...                            %Trial_ID
                           ones(1,length(ForceTime)) * conditions(i_trial, 1); ...               %Difficulty in %
                           (1:length(ForceTime)) ; ...                                           %t_Button ID
                           t_ref_vector ; ...                                                    %time referenced to trial start
                           ForceTime ; ...                                                       %Frequency at t_Button
                           ones(1,length(ForceTime)) * conditions(i_trial,2); ...                %Cond.incentive 1= Money, 2= Food
                           ones(1,length(ForceTime)) * conditions(i_trial,3);   ...              %Cond.value 1 / 10 per Sec
                           ones(1,length(ForceTime)) * conditions(i_trial,4); ...                %Certain or Uncertain
                           ones(1,length(ForceTime)) * output.payout_per_trial(1,i_trial); ...   %payout: Money
                           ones(1,length(ForceTime)) * output.payout_per_trial(2,i_trial)]]; ...   %payout: Food
                           
elseif do_fmri_flag == 0 && strcmp(subj.runLABEL, 'training')
output.values_per_trial = [output.values_per_trial, [ones(1,length(ForceTime)) * subj.num ; ...  %Subj_ID
                           ones(1,length(ForceTime)) * input.maxForce; ...                       %MaxForce
                           ones(1,length(ForceTime)) * i_trial ;  ...                            %Trial_ID
                           ones(1,length(ForceTime)) * conditions(i_trial, 1); ...               %Difficulty in %
                           (1:length(ForceTime)) ; ...                                           %t_Button ID
                           t_ref_vector ; ...                                                    %time referenced to trial start
                           ForceTime ; ...                                                       %Frequency at t_Button
                           ones(1,length(ForceTime)) * conditions(i_trial,2); ...                %Cond.incentive 1= Money, 2= Food
                           ones(1,length(ForceTime)) * conditions(i_trial,3);   ...              %Cond.value 1 / 10 per Sec
                           ones(1,length(ForceTime)) * output.payout_per_trial(1,i_trial); ...   %payout: Money
                           ones(1,length(ForceTime)) * output.payout_per_trial(2,i_trial)]]; ...   %payout: Food

elseif do_fmri_flag == 1 && strcmp(subj.runLABEL, 'grEAT')
output.values_per_trial = [output.values_per_trial, [ones(1,length(ForceTime)) * subj.num ; ...  %Subj_ID
                           ones(1,length(ForceTime)) * input.maxForce; ...                       %MaxForce
                           ones(1,length(ForceTime)) * i_trial ; ...                             %Trial_ID
                           ones(1,length(ForceTime)) * conditions(i_trial, 1); ...               %Difficulty in %
                           (1:length(ForceTime)) ; ...                                           %t_Button ID
                           t_ref_vector ; ...                                                    %time referenced to trial start
                           ForceTime ; ...                                                       %Frequency at t_Button
                           ones(1,length(ForceTime)) * conditions(i_trial,2); ...                %Cond.incentive 1= Money, 2= Food
                           ones(1,length(ForceTime)) * conditions(i_trial,3);   ...              %Cond.value 1 / 10 per Sec
                           ones(1,length(ForceTime)) * conditions(i_trial,4); ...                %Certain or Uncertain
                           ones(1,length(ForceTime)) * output.payout_per_trial(1,i_trial); ...   %payout: Money
                           ones(1,length(ForceTime)) * output.payout_per_trial(2,i_trial)]];       %payout: Food
 
else
output.values_per_trial = [output.values_per_trial, [ones(1,length(ForceTime)) * subj.num ; ...  %Subj_ID
                           ones(1,length(ForceTime)) * input.maxForce; ...                       %MaxForce
                           ones(1,length(ForceTime)) * i_trial ; ...                             %Trial_ID
                           ones(1,length(ForceTime)) * conditions(i_trial, 1); ...               %Difficulty in %
                           (1:length(ForceTime)) ; ...                                           %t_Button ID
                           t_ref_vector ; ...                                                    %time referenced to trial start
                           ForceTime ; ...                                                       %Frequency at t_Button
                           ones(1,length(ForceTime)) * conditions(i_trial,2); ...                %Cond.incentive 1= Money, 2= Food
                           ones(1,length(ForceTime)) * conditions(i_trial,3);   ...              %Cond.value 1 / 10 per Sec
                           ones(1,length(ForceTime)) * output.payout_per_trial(1,i_trial); ...   %payout: Money
                           ones(1,length(ForceTime)) * output.payout_per_trial(2,i_trial)]];       %payout: Food   
    
end
    
    
    
% Create & Save temporary output data
output.filename = sprintf('%s\\data\\effort_%s_%s_%s_s%s_temp', pwd, subj.studyID, subj.runLABEL, subj.subjectID, subj.sessionID);
%save([output.filename '.mat'], 'output', 'subj', 'input', 'joy', 'conditions', 'jitter')
save([output.filename '.mat'], 'output', 'subj', 'input', 'joy', 'conditions')
    




%% Clear Variables to initiate new trial

t_payout = [nan; nan];
i_payout_onset = 1;
i_payout_offset = 1;

t_trial_onset = nan;
t_buttonN_1 = 0;
t_button = 0;

draw_frequency = 0; %resets ball position
input.percentFrequency = 0;

current_input = 0;
current_weight_fact = 0;
Avrg_value = 0;
frequency_estimate = 0;
prev_weight_fact = 0; 
prev_movingAvrg = 0;


collect_freq.avrg = [];
collect_freq.t_button_interval = [];


phantom_current_input = 0;

Estimate_Avrg_value = 0;
phantom.freq = 0;

phantom.avrg = [];
phantom.t_button_interval = [];
phantom.frequency = []; 

exc_thresh_this_trial = 0;
payout.win = 0;
win_coins = nan;
win_cookies = nan;
i_phantom = 1;

i_resp = 1;
count_joystick = 0;

i_step = 1;
t_vector = [];

flag = 0;
end_of_trial = 0;

if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
    win_phase_counter = 1;
    rest_phase_counter = 1;
end

ForceMat = restforce;
ForceTime = [];


end



%% After the last trial

% Update maxFrequency based on highest value during practice trials

if strcmp(subj.runLABEL, 'training') 
    
    %input.maxFrequency = max(collectMax.maxFreq);
    collectMax.maxForce = collectMax.maxForce(collectMax.maxForce ~= 0);
    input.maxForce = min(input.maxForce, min(collectMax.maxForce));
    
end


% Prepare feedback

   % Compute win
   win_sum_coins = floor(nansum(output.payout_per_trial(1,3:end)));
   win_sum_cookies = floor(nansum(output.payout_per_trial(2,3:end)));
       
   % Show win 
   if strcmp(subj.runLABEL, 'training') 

        text = ['Die Übung ist nun zu Ende. Im richtigen Spiel hätten Sie \n' num2str(win_sum_coins) ' Geld-Punkte und\n' num2str(win_sum_cookies) ' Essens-Punkte gewonnen.\n\nDie maximal ausgeübte Kraft beträgt: ' num2str(input.maxForce) '.' ];

   elseif strcmp(subj.runLABEL, 'grEAT') 

        text = ['Das Spiel ist nun zu Ende.\n Sie gewinnen ' num2str(win_sum_coins) ' Punkte in Euro.\nSie gewinnen ' num2str(win_sum_cookies) ' Punkte in Kcal. \n\nVielen Dank für die Teilnahme!'];

   end

        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training') 
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, flip_flag_horizontal, flip_flag_vertical, 1.2);
        else
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', setup.ScrHeight/5, color.black,60, [], [], 1.2);
        end
        Screen('Flip',w);
        if strcmp(subj.runLABEL, 'training')
           WaitSecs(10);
        else
           WaitSecs(30);
        end


KbQueueRelease();
           




%% Create Output Format

%  Suj_ID  /  Trial_ID  /  difficulty(%) / t_Button_Index  /  t_Button(ref_to_trialStart  /
%  Frequency_at_t_Button / VAS_exhaustion / VAS_wanting
output.values_per_trial_flipped = output.values_per_trial';
output.values_per_trial_t100_flipped = output.values_per_trial_t100';

% Store output
output.time = datetime;

if strcmp(subj.runLABEL, 'training')
    output.filename = sprintf('grEATPilot_Training_%s_%s_%s_R%s_%s', subj.studyID, subj.subjectID, subj.study_part_ID,subj.sessionID, datestr(now, 'yymmdd_HHMM'));
else
    output.filename = sprintf('grEATPilot_%s_%s_%s_R%s_%s', subj.studyID, subj.subjectID, subj.study_part_ID,subj.sessionID, datestr(now, 'yymmdd_HHMM'));
end

if do_fmri_flag == 1 && ~strcmp(subj.runLABEL, 'training')
    save(fullfile('data', [output.filename '.mat']), 'output', 'subj', 'input', 'joy', 'conditions', 'ball_jitter','fix_jitter','timestamps');
else
save(fullfile('data', [output.filename '.mat']), 'output', 'subj', 'input', 'joy', 'conditions', 'jitter');
end
save(fullfile('Backup', [output.filename datestr(now,'_yymmdd_HHMM') '.mat']));




temp.filename = sprintf('%s\\data\\effort_%s_%s_%s_s%s_temp', pwd, subj.studyID, subj.runLABEL, subj.subjectID, subj.sessionID);
delete([temp.filename '.mat']);

%GetClicks(setup.screenNum);
Screen('CloseAll');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%