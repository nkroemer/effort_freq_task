%%===================Effort allocation task===================
%Script for Effort cost paradigm -30/05/2017-
%author: Monja P. Neuser, Vanessa Teckentrup, Nils B. Kroemer

%frequency estimation with exponential weighting
%https://de.mathworks.com/help/dsp/ug/sliding-window-method-and-exponential-weighting-method.html

%input via XBox USB-Controller

% WISHLIST: 
%-Instructions: Weiter-Button 
%-z-axis of controller button
%- Randomize conditions (incentives)
%- VAS between trials
%========================================================

%% Preparation

% Clear workspace
close all;
clear all; 
sca;

Screen('Preference', 'SkipSyncTests', 2);
load('JoystickSpecification.mat')

% Change settings
% Basic screen setup 
setup.screenNum = max(Screen('Screens')); %secondary monitor if there is one connected
setup.fullscreen = 0; %if 0 -> will create a small window ideal for debugging, set =1 for Experiment

do_gamepad = 1; %do not set to 0, this is not implemented yet
xbox_buffer = zeros(1,50); %will buffer the history of 50 button press status

do_training = 0;
%If skipping training: need Dummy Input = 6



%%get input from the MATLAB console
subj.studyID=input('Study ID: ','s');
subj.subjectID=input('Subject ID: ','s');
subj.sessionID=input('Session ID: ','s');
subj.sess = str2double(subj.sessionID); %converts Session ID to integer
subj.num = str2double(subj.subjectID); %converts Subject ID to integer


%Load Conditions
%for individual rand conditions:
    %cond_filename = sprintf('%s\\conditions\\cond_%02d', pwd, subj.num);
%for training purposes
    cond_filename = sprintf('%s\\conditions\\cond_exp_75-85', pwd);
load(cond_filename);

            
% Setup PTB with some default values
PsychDefaultSetup(1); %unifies key names on all operating systems

% Seed the random number generator.
rand('seed', sum(100 * clock)); %old MATLAB way




% Define colors
color.white = WhiteIndex(setup.screenNum); %with intensity value for white on second screen
color.grey = color.white / 2;
color.black = BlackIndex(setup.screenNum);
color.red = [255 0 0];
color.green = [0 139 0]; %dark green
color.green2 = [0 238 0]; %bright green
color.darkblue = [0 0 139];
color.royalblue = [65 105 225]; %light blue, above threshold
color.gold = [255,215,0];
color.scale_anchors = [205 201 201];

% Define the keyboard keys that are listened for. 
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
end;
%[w, wRect] = Screen('OpenWindow', setup.screenNum, grey, [], 32, 2);

% Get the center coordinates
[setup.xCen, setup.yCen] = RectCenter(wRect);

% Flip to clear
Screen('Flip', w);

% Query the frame duration                                       Wofür?
setup.ifi = Screen('GetFlipInterval', w);

% Query the maximum priority level - optional
setup.topPriorityLevel = MaxPriority(w);




%Setup ovrlay screen
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



% Stimulus settings

%Draw Thermometer
%rescale screen_height to scale_height
Tube.width = round(setup.ScrWidth * .20);
Tube.offset = round((setup.ScrHeight - (setup.ScrHeight * .95)) * .35);
Tube.height = round(Tube.offset+setup.ScrHeight/4);

Ball.width = round(setup.ScrWidth * .12);

%Reward details
Coin.width = round(setup.ScrWidth * .15);



%Drawing parameters 
output.resp = 0; %Updated by exponential weighting
    freq_interval=1; % Frequency estimation interval 1 sec

    maxfreq_estimate = 5; % numerator of narmalising factor. Should be updated after task piloting
    input.maxFrequency = 5; %Dummy for MaxFreq estimation, updated before trial start if do_training==1 
    input.percentFrequency = 85; %Dummy for MaxFreq estimation, updated before trial start with values from condition sheet

draw_frequency_normalize = maxfreq_estimate/input.maxFrequency; %
draw_frequency_factor = 60 * draw_frequency_normalize; %value (50) freely chosen to have a nice ball movement using the full screen
 

%Instruction text                                               
text = ['Welcome. \n\n This is a simple game where you can gain delicious rewards. \n\n Continue with Mouse Click.'];
Screen('TextSize',w,32);
Screen('TextFont',w,'Arial');
[pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
Screen('Flip',w);

GetClicks(setup.screenNum);

if do_training == 1
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   Determine maximum Frequency (2x10secs)    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

collectMax.freq=0;
collectMax.clicks = nan(1,300); % stores clicks: timestamp
collectMax.clickinterval = nan(1,300); %stores current_input (t2-t1)
collectMax.avrg = nan(1,300); %stores weighted interval value of a click
collectMax.frequency = nan(1,300); %stores weighted interval value of a click
collectMax_index = 1;
collectMax_trialCount = 1;
collectMax.maxFreq = nan(1,2); %stores maxFreq of 2 practice trials

%Initialise exponential weighting
forget_fact = 0.6;
prev_weight_fact = 0;
prev_movingAvrg = 0;
t_button = 0;
current_input = 0; 
Avrg_value = 0;
draw_frequency = 0; %Ball position dependent on output/phantom frequency, initially ball at bottom
 
max_Boundary_yposition = ((setup.ScrHeight-Tube.offset-Ball.width)-(draw_frequency * draw_frequency_factor));

%%Starting Protocol

text = ['On the Screen you will see a vertical tube with a blue ball in it. By pressing the upper right Button on the Controller with your index finger you can move the ball. The faster you press, the higher it moves.\nYou have 2x10 secondes to push a blue line as high as you can. \nContinue with Mouse Click.'];
Screen('TextSize',w,32);
Screen('TextFont',w,'Arial');
[pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
Screen('Flip',w);

%wait for a mouse click to continue
GetClicks(setup.screenNum);


while (collectMax_trialCount < 3) %2 trials of 10secs to collect valid maxFreq
    
    
    if (collectMax_trialCount == 1)
        text = ['In the next 10 seconds try to push the boundary as high as you can.\n\nContinue with Mouse Click.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
        Screen('Flip',w);
    
    elseif (collectMax_trialCount == 2)
        text = ['That was a very good start. Now try to push it even further.\n\nContinue with Mouse Click.'];
        Screen('TextSize',w,32);
        Screen('TextFont',w,'Arial');
        [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
        Screen('Flip',w);
    end
    
    WaitSecs(1.5);
    GetClicks(setup.screenNum);

    fix = ['+'];
    Screen('TextSize',w,64);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.black,80);
    time.fix = Screen('Flip', w);

    WaitSecs(1); %Show screen for 1s
    
    draw_frequency = 0; %Ball position dependent on output/phantom frequency, initially ball at bottom
    
    t_collectMax_onset = GetSecs;
    t_buttonN_1 = t_collectMax_onset;

    
    while ((10 * collectMax_trialCount) > (GetSecs - t_collectMax_onset))       %Trial-length 10sec
    % Draw Tube
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), Tube.height, (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen+Tube.width/2), Tube.height, (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('CopyWindow',effort_scr,w);
          
            %Draw upper bound blue line
            Boundary_yposition = ((setup.ScrHeight-Tube.offset-Ball.width)-(draw_frequency * draw_frequency_factor));
            max_Boundary_yposition = min(max_Boundary_yposition, Boundary_yposition);
            
            Screen('DrawLine',w,color.darkblue,(setup.xCen-Tube.width/2), max_Boundary_yposition, (setup.xCen+Tube.width/2), max_Boundary_yposition,3);

          % Draw Ball
            Ball.position = [(setup.xCen-Ball.width/2) ((setup.ScrHeight-Tube.offset-Ball.width)-(draw_frequency * draw_frequency_factor)) (setup.xCen+Ball.width/2) ((setup.ScrHeight-Tube.offset)-(draw_frequency * draw_frequency_factor))];
            Ball.color = color.darkblue;
            Screen('FillOval',w,Ball.color,Ball.position);
            Screen('Flip', w);

            
            
            [b,c] = KbQueueCheck;      


 
            %If experiment is run with GamePad
            if do_gamepad == 1
                [Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(JoystickSpecification);
                
                %Buffer routine
                for buffer_i = 2:50 %buffer_size
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
 
 
        %Frequency estimation based on Button Press            
        if c(keys.resp) > 0 || count_joystick == 1
            % resp=resp+1;
%              if c(keys.resp) > 0
%                  
%                 t_button = c(keys.resp);
                     
                     if (t_button > (t_collectMax_onset + 0.1)); %if keypress starts during fixation phase, the initial interval might be too short. Frequency estimation the n becomes skewed
                         current_input = t_button - t_buttonN_1;

                        %Exponential weightended Average of RT for frequency estimation
                        current_weight_fact = forget_fact * prev_weight_fact + 1;
                        Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * current_input);
                        collectMax.freq = freq_interval/Avrg_value;

                        %Refresh values in output vector
                        prev_weight_fact = current_weight_fact; 
                        prev_movingAvrg = Avrg_value;
                        t_buttonN_1 = t_button;
                            collectMax.clicks(1,collectMax_index) = t_button;
                            collectMax.avrg(1,collectMax_index) = Avrg_value;
                            collectMax.clickinterval(1,collectMax_index) = current_input;
                            collectMax.frequency(1,collectMax_index) = collectMax.freq;
                            draw_frequency = collectMax.freq; %updates Ball height
                            collectMax_index = collectMax_index + 1;
                     end
             
            elseif (GetSecs - t_buttonN_1) > (1.5 * Avrg_value) && (collectMax_index > 1);
                
                    phantom_current_input = GetSecs - t_buttonN_1;
                
                    current_weight_fact = forget_fact * prev_weight_fact + 1;
                    Estimate_Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * phantom_current_input);
                    phantom.freq = freq_interval/Estimate_Avrg_value;  
                
                    %Refresh values in phantom output vector
                    prev_weight_fact = current_weight_fact; 
                    prev_movingAvrg = Estimate_Avrg_value;
                        %NOT% t_buttonN_1 = t_button; Last key press remains unchanged 
                        %output.t_button(1,output_index) = t_button;
    %                 phantom.avrg(1,i_phantom) = Avrg_value;
    %                 phantom.t_button_interval(1,i_phantom) = current_input;
    %                 phantom.frequency(1,i_phantom) = phantom.freq; 
                    draw_frequency = phantom.freq;  %updates Ball height
    %               i_phantom = i_phantom + 1;
    %                 
        end
                end
            end
            
    %Store MaxFrequencie for each training trial
    collectMax.maxFreq(1,collectMax_trialCount) = max(collectMax.frequency(1:collectMax_index));
    end
    
     collectMax_trialCount = collectMax_trialCount + 1;
     
    WaitSecs(1.5);
end


% Individual MaxFrequency for experiment
input.maxFrequency = max(collectMax.maxFreq);



%CONTROL PRINT - delete!
text = ['Excellent!\n\nYour maximum frequency is: ' num2str(input.maxFrequency) '\n\nContinue with Mouse Click.'];
Screen('TextSize',w,32);
Screen('TextFont',w,'Arial');
[pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
Screen('Flip',w);

                                          
GetClicks(setup.screenNum);
end 

%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    1 Trial effort    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%Reset values

%Initialise exponential weighting
forget_fact = 0.6;
prev_weight_fact = 0;
prev_movingAvrg = 0;
t_button = 0;
current_input = 0; 
Avrg_value = 0;
 
frequency_estimate=0;
collect_freq.t_button_interval  = []; %stores current_input (t2-t1)
collect_freq.avrg               = []; %stores weighted interval value of a click


t_button_vector = [];
frequency_vector = []; %stores weighted interval value of a click
output.t_button = []; % stores clicks: timestamp
output.t_button_referenced = []; %referenced to t_trial_onset
output.frequency = [];
output.values_per_trial = []; %Matrix of output values

i_resp = 1;
i_phantom = 1;

%Payout calculation
flag = 0; %1 if frequency exceeds MaxFrequency
exceed_onset = 0;
i_payout_onset = 1;
t_payout = [nan nan nan]';
output.t_payout = [nan nan]'; %collects all t1/t2 across all trials
output.payout_per_trial = 0;
output.t_payout_calories = 0;

%Payout display (Counter visible during trial)
payout.diff = [nan nan]';
payout.counter = 0;
payout.win = 0;

trial_length = 5;
i_trial = 1;

%Text before Trial-Block

text = ['Main experiment: \n\n\nIn the main experiment the line will not move with the ball. \nBy pressing the button try to lift the ball as in the training. You can now win points for every second you keep the ball above a fix red line. You know when you are winning when the ball changes its color to a lighter blue. \n\nContinue with Mouse Click.'];
    Screen('TextSize',w,32);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
    Screen('Flip',w);
    GetClicks(setup.screenNum);

text = ['The experiment will take 25 minutes. After every 8 minutes you may take a short break. \nIf you have any questions, do not hesitate to ask.\nIf you feel ready, you can start with the experiment. \n\nContinue with Mouse Click.'];
    Screen('TextSize',w,32);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
    Screen('Flip',w);
    GetClicks(setup.screenNum);


%% Experimental procedure
%  Loop while conditions pending

while i_trial <= length(conditions) %Condition sheet determines repetitions
    
    input.percentFrequency = input.maxFrequency * (conditions(i_trial) * 0.01);
    
        
%     text = ['Schwierigkeit in dieser Runde: ' num2str(conditions(i_trial)) ' %' ];
%     screen('TextSize',w,32);
%     Screen('TextFont',w,'Arial');
%     [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black, 40);
%     Screen('Flip',w);
%     WaitSecs(1);
    
    % load and show incentive
    [img.incentive_coins10, img.map, img.alpha] = imread('incentive_coins10.jpg');
    stim.incentive_coins10 = Screen('MakeTexture', w, img.incentive_coins10); %ggf Hintergrund transparent machen
    Screen('DrawTexture', w, stim.incentive_coins10,[], [((setup.xCen-Tube.width)-Coin.width) (setup.ScrHeight/4) (setup.xCen-Tube.width) (setup.ScrHeight/4+Coin.width)])
    time.img = Screen('Flip', w);

    % load single-coin picture for Counter
    [img.winCounter, img.map, img.alpha] = imread('singlecoin.jpg');
    stim.winCounter = Screen('MakeTexture', w, img.winCounter);
    
    WaitSecs(1); %Show screen for 1s
    
    draw_frequency = 0; %resets ball position

    
    t_trial_onset = GetSecs;
    t_buttonN_1 = t_trial_onset;

    while (trial_length > (GetSecs-t_trial_onset))       %Trial-length 5sec

          % Draw Tube
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), Tube.height, (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen+Tube.width/2), Tube.height, (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
          
            Screen('DrawTexture', effort_scr, stim.incentive_coins10,[], [((setup.xCen-Tube.width)-Coin.width) (setup.ScrHeight/4) (setup.xCen-Tube.width) (setup.ScrHeight/4+Coin.width)]);
            Screen('CopyWindow',effort_scr,w);
          
          % Draw Max% line
            Threshold.yposition = (setup.ScrHeight-Tube.offset-(input.percentFrequency * draw_frequency_factor));
            Screen('DrawLine',w,color.red,(setup.xCen-Tube.width/2), Threshold.yposition, (setup.xCen+Tube.width/2), Threshold.yposition,3);

          % Show incentive counter
            Screen('DrawTexture', w, stim.winCounter,[], [(setup.xCen*1.5-(size(img.winCounter,2)*0.6)) (setup.ScrHeight/6-(size(img.winCounter,1)*0.6)) (setup.xCen*1.5) (setup.ScrHeight/6)]);
     
            text = ['x' num2str(payout.win, '%02i')];
                   Screen('TextSize',w,56);
                   Screen('TextFont',w,'Arial');
                   [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, setup.xCen*1.5, (setup.ScrHeight/6), color.black);
            
            
            
          % Draw Ball
            Ball.position = [(setup.xCen-Ball.width/2) ((setup.ScrHeight-Tube.offset-Ball.width)-(draw_frequency * draw_frequency_factor)) (setup.xCen+Ball.width/2) ((setup.ScrHeight-Tube.offset)-(draw_frequency * draw_frequency_factor))];

            if (Ball.position(1,4) < Threshold.yposition) %Ball above threshold 
                
                Ball.color = color.royalblue;
                
%                 if (flag == 1)
%                     continue
                    
                if (flag == 0)
                    
                    flag = 1;                    
                    exceed_onset = GetSecs;
                    t_payout(1,i_payout_onset) = exceed_onset;
                                   
                end
                
                % Calculate payoff for exceed_Threshold:
                %If ball above threshold, need phantom value to update
                %reward counter
                t_payout(3,i_payout_onset) = GetSecs;

                payout.diff = t_payout(3,1:end) - t_payout(1,1:end);
                payout.counter = nansum(payout.diff); 
                payout.win = floor(payout.counter); 

                    
            else    %Ball below threshold    
                
                 Ball.color = color.darkblue;
                 
%                  if (flag == 0)
%                      continue
                     
                 if (flag == 1)
                     
                     flag = 0;
                     exceed_offset = GetSecs;
                     t_payout(2,i_payout_onset) = exceed_offset;
                     
                     i_payout_onset = i_payout_onset + 1;
                                       
                 end  
                 
                 %For last trial
               
                % Calculate payoff for exceed_Threshold:
                %If ball above threshold, need phantom value to update
                %reward counter
%                 payout.diff = t_payout(2,1:end) - t_payout(1,1:end);
%                 payout.counter = nansum(payout.diff); 
%                 payout.win = floor(payout.counter);
                
            end  
            
                Screen('FillOval',w,Ball.color,Ball.position);
                Screen('Flip', w);
             
                
             
                
                       
            [b,c] = KbQueueCheck;  
            
            
            %If experiment is run with GamePad
            if do_gamepad == 1
                [Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(JoystickSpecification);
                
                %Buffer routine
                for buffer_i = 2:50 %buffer_size
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

        %Frequency estimation based on Button Press            
        if c(keys.resp) > 0 || count_joystick == 1
            % resp=resp+1;
%              if c(keys.resp) > 0
%                  
%                 t_button = c(keys.resp);
                                
                if (t_button > (t_trial_onset + 0.1)) %Prevents too fast button press at the beginning
                    
                    t_button_vector(1,i_resp) = t_button;
                      
                    %Exponential weightended Average of RT for frequency estimation
                    current_input = t_button - t_buttonN_1;
                    current_weight_fact = forget_fact * prev_weight_fact + 1;
                    Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * current_input);
                    frequency_estimate = freq_interval/Avrg_value;
                    
                    frequency_vector(1,i_resp) = frequency_estimate;
                    
                    %update Ball height
                    draw_frequency = frequency_estimate; 

                    
                    %Refresh values
                    prev_weight_fact = current_weight_fact; 
                    prev_movingAvrg = Avrg_value;
                    t_buttonN_1 = t_button;

                    collect_freq.avrg(1,i_resp) = Avrg_value;
                    collect_freq.t_button_interval(1,i_resp) = current_input;

                    i_resp = i_resp + 1;
                    count_joystick = 0;

                end

             
             %if no button press happened: Freqency should decrease slowly based on phantom estimates   
             elseif (GetSecs - t_buttonN_1) > (1.5 * Avrg_value) && (i_resp > 1);

                    phantom_current_input = GetSecs - t_buttonN_1;
                    current_weight_fact = forget_fact * prev_weight_fact + 1;
                    Estimate_Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * phantom_current_input);
                    phantom.freq = freq_interval/Estimate_Avrg_value;
                    
                    %update Ball height
                    draw_frequency = phantom.freq; 

                    %Refresh values in phantom output vector
                    prev_weight_fact = current_weight_fact; 
                    prev_movingAvrg = Estimate_Avrg_value;
                   % t_buttonN_1 = t_button; %Not necessary for phantom count, Last key press remains unchanged 
                       % output.t_button(1,output_index) = t_button;
                        phantom.avrg(1,i_phantom) = Avrg_value;
                        phantom.t_button_interval(1,i_phantom) = current_input;
                        phantom.frequency(1,i_phantom) = phantom.freq; 
                        
                        
                        i_phantom = i_phantom + 1;

            end
               
         
          
                end
         
            end
            
         
            
    end
            
                    
    end_of_trial = GetSecs;
    
    if (flag == 1)
        
        t_payout(2,i_payout_onset) =  end_of_trial;
    end
    
 % Calculate payoff for exceed_Threshold
payout_this_trial = t_payout(2,1:end)-t_payout(1,1:end);
output.t_payout = [output.t_payout, t_payout(1:2,1:end)];   


% Calculate win for this trial
win = floor(nansum(payout_this_trial));
output.payout_per_trial(i_trial) = win;



%%==============call VAS_exhaustion_wanting===================

t_scale_trigger = GetSecs;
trial.question = 'wanted';

VAS_exhaustion_wanting

 
    
%%==============call feedback===================   

%If no VAS: Show feedback
%effort_feedback

         
   %Reference t_Butto to trial_start 
   t_button_referenced_vector = t_button_vector - t_trial_onset; %References every key press to trial onset

   
   %Copy Output Values into Output Matrix
    output.values_per_trial = [output.values_per_trial, [ones(1,length(frequency_vector)) * subj.num ; ones(1,length(frequency_vector)) * i_trial ; [1:length(frequency_vector)] ; t_button_referenced_vector ; frequency_vector ; ones(1,length(frequency_vector)) * output.rating_wanting(i_trial)]]; %ADD IDs    
    
    output.t_button = [output.t_button, t_button_vector];
        t_button_vector = [];
    
    output.frequency = [output.frequency, frequency_vector];
        frequency_vector = [];
    
    output.t_button_referenced = [output.t_button_referenced, t_button_referenced_vector];
        t_button_referenced_vector = [];

    %Clear Variables
    t_payout = [];
    i_payout_onset = 1;
    i_payout_offset = 1;
    
    t_trial_onset = GetSecs;
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

                        
    i_phantom = 1;

    i_resp = 1;
    count_joystick = 0;
    
    flag = 0;
    end_of_trial = 0;
    i_trial = i_trial + 1;
end


       win_sum = floor(nansum(output.payout_per_trial));
       
        text = ['Great. You finished this this experiment.\n In total you win ' num2str(win_sum) ' points.\n\nThank you for participating!'];
            Screen('TextSize',w,32);
            Screen('TextFont',w,'Arial');
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
            Screen('Flip',w);
            WaitSecs(1.5);
            GetClicks(setup.screenNum);



KbQueueRelease();
           




% Create Output Format
%  Suj_ID  /  Trial_ID  /  t_Button_Index  /  t_Button  /
%  Frequency_at_t_Button / VAS_wanting
output.values_per_trial_flipped = output.values_per_trial';


%%Outputs:
%plot_frequency = plot(output.)
%plot_money = plot(output.payout_per_trial)


%%Plot time series
%freq_over_time = [output.t_button_referenced ; output.frequency];
 
%ts = timeseries(freq_over_time(end,:), freq_over_time(1,:));
%plot(ts)


%%Store output
output.time = datetime;
output.filename = sprintf('%s\\data\\effort_%s_%s_%s_%s', pwd, subj.studyID, subj.subjectID, subj.sessionID, datestr(now, 'yymmdd_HHMM'));

save([output.filename '.mat'], 'output', 'subj', 'input')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%