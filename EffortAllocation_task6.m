%%===================Effort allocation task===================
%Script for Effort cost paradigm -15/05/2017-
%author: Monja P. Neuser, Vanessa Teckentrup, Nils B. Kroemer

%frequency estimation with exponential weighting
%https://de.mathworks.com/help/dsp/ug/sliding-window-method-and-exponential-weighting-method.html

% WISHLIST: 
%-Instructions: Weiter-Button 
%- Reward Counter
%-Power Mate Mouseclick
%-Complete Session
%========================================================

%% Preparation

% Clear workspace
close all;
clear all;
clearvars; 
sca;

%%get input from the MATLAB console
%subj.studyID=input('Study ID: ','s');
%subj.subjectID=input('Subject ID: ','s');
%subj.sessionID=input('Session ID: ','s');
%subj.sess = str2double(subj.sessionID); %converts Session ID to integer
%subj.num = str2double(subj.subjectID); %converts Subject ID to integer
            
% Setup PTB with some default values
PsychDefaultSetup(1); %unifies key names on all operating systems

% Seed the random number generator.
rand('seed', sum(100 * clock)); %old MATLAB way
%TO DO: Create condition file in advance with looped randomisation

% Basic screen setup 
setup.screenNum = max(Screen('Screens')); %secondary monitor if there is one connected
setup.fullscreen = 0; %will create a small window ideal for debugging

% Define colors
color.white = WhiteIndex(setup.screenNum); %with intensity value for white on second screen
color.grey = color.white / 2;
color.black = BlackIndex(setup.screenNum);
color.red = [255 0 0];
color.green = [0 139 0]; %dark green
color.green2 = [0 238 0]; %bright green
color.blue = [0 0 255];
color.gold = [255,215,0];

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



%%Instruction text                                               
%text = ['Willkommen. \n\n In dieser Aufgabe soll es um den Zusammenhang von Belohnung und Aufwand gehen. Lesen Sie bitte die folgenden Instruktionen aufmerksam durch. \n\n Weiter mit Leertaste.'];
%Screen('TextSize',w,32);
%Screen('TextFont',w,'Arial');
%[pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
%Screen('Flip',w);

%Wait for Key - - Turn Page???
%wait for a mouse click to continue
%GetClicks(setup.screenNum);



% Query the maximum priority level - optional
setup.topPriorityLevel = MaxPriority(w);



%%Draw Incentive coin (1 sec)
incentive.value1 = '1 cent';
incentive.value10 = '10 cent';
incentive.color10 = color.gold;

%Setup ovrlay screen
effort_scr = Screen('OpenOffscreenwindow',w,color.white);
Screen('TextSize',effort_scr,16);
Screen('TextFont',effort_scr,'Arial');

setup.ScrWidth = wRect(3) - wRect(1);
setup.ScrHeight = wRect(4) - wRect(2);

Coin.width = round(setup.ScrWidth * .15);
%Coin.offset = round((setup.ScrHeight - (setup.ScrHeight * .95)) * .15);

%%Draw Thermometer
%rescale screen_height to scale_height
Tube.width = round(setup.ScrWidth * .20);
Tube.offset = round((setup.ScrHeight - (setup.ScrHeight * .95)) * .35);

Ball.width = round(setup.ScrWidth * .16);
Ball.offset = round((setup.ScrHeight - (setup.ScrHeight * .95)) * .35);

KbQueueCreate();
KbQueueFlush(); 
KbQueueStart();
[b,c] = KbQueueCheck;
draw_frequency_factor = 50;
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   Determine maximum Frequency (2x10secs)    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Initiate response routine
output.resp = 0;

freq_interval=1; % Frequency estimation interval 1 sec

% collectMax.freq=0;
% collectMax.clicks = nan(1,400); % stores clicks: timestamp
% collectMax.clickinterval = nan(1,400); %stores current_input (t2-t1)
% collectMax.avrg = nan(1,400); %stores weighted interval value of a click
% collectMax.frequency = nan(1,400); %stores weighted interval value of a click
% collectMax_index = 1;
% collectMax_trialCount = 1;
% collectMax.maxFreq = nan(1,3); %stores maxFreq of 2 practice trials
% 
% %Initialise exponential weighting
% forget_fact = 0.8;
% prev_weight_fact = 0;
% prev_movingAvrg = 0;
% key_timestamp = 0;
% current_input = 0; 
% Avrg_value = 0;
%  
% draw_frequency = 0;
% 
% 
% %%Starting Protocol
% 
% text = ['Start...\n\nMausklick für Weiter.'];
% Screen('TextSize',w,32);
% Screen('TextFont',w,'Arial');
% [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
% Screen('Flip',w);
% 
% %wait for a mouse click to continue
% GetClicks(setup.screenNum);
% 
% 
% while (collectMax_trialCount < 3) %2 trials of 10secs to collect valid maxFreq
%     
%     
%     if (collectMax_trialCount == 1)
%         text = ['Drücken Sie bitte in den nächsten 10 Sekunden so schnell Sie können die Leertaste.\n\nWeiter mit Mausklick.'];
%         Screen('TextSize',w,32);
%         Screen('TextFont',w,'Arial');
%         [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
%         Screen('Flip',w);
%     
%     elseif (collectMax_trialCount == 2)
%         text = ['Das war schon sehr gut. Versuchen Sie das noch zu steigern. \n\nWeiter mit Mausklick.'];
%         Screen('TextSize',w,32);
%         Screen('TextFont',w,'Arial');
%         [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
%         Screen('Flip',w);
%     end
%     
%     WaitSecs(1.5);
%     GetClicks(setup.screenNum);
% 
%     fix = ['+'];
%     Screen('TextSize',w,64);
%     Screen('TextFont',w,'Arial');
%     [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.black,80);
%     time.fix = Screen('Flip', w);
% 
%     WaitSecs(1); %Show screen for 1s
%         
%     collectMax_time.onset = GetSecs;
%     key_timestampN_1 = collectMax_time.onset;
% 
%     
%     while ((10*collectMax_trialCount) > (GetSecs-collectMax_time.onset))       %Trial-length 10sec
%      % Draw Tube
%             Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (Tube.offset+setup.ScrHeight/3), (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6)
%             Screen('DrawLine',effort_scr,color.black,(setup.xCen+Tube.width/2), (Tube.offset+setup.ScrHeight/3), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6)
%             Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6)
%     
%      %      Screen('DrawTexture', effort_scr, stim.coin10,[], [0 0 Coin.width Coin.width*.84]);
%            
%      % Draw Ball
%             Screen('CopyWindow',effort_scr,w); 
%             Ball.position = [(setup.xCen-Ball.width/2) (setup.ScrHeight-Tube.offset-Ball.width)-(draw_frequency*draw_frequency_factor) (setup.xCen+Ball.width/2) (setup.ScrHeight-Tube.offset)-(draw_frequency*draw_frequency_factor)];    
%             Screen('FillOval',w,color.green,Ball.position);
% 
%             Screen('Flip', w);
% 
%             [b,c] = KbQueueCheck;      
% 
% 
%              if c(keys.resp) > 0
%                      key_timestamp = GetSecs;   %b papameter does not work!
%                      
%                      if (key_timestamp > (collectMax_time.onset + 0.1)); %if keypress starts during fixation phase, the initial interval might be too short. Frequency estimation the n becomes skewed
%                          current_input = key_timestamp - key_timestampN_1;
% 
%                         %Exponential weightended Average of RT for frequency estimation
%                         current_weight_fact = forget_fact * prev_weight_fact + 1;
%                         Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * current_input);
%                         collectMax.freq = freq_interval/Avrg_value;
% 
%                         %Refresh values in output vector
%                         prev_weight_fact = current_weight_fact; 
%                         prev_movingAvrg = Avrg_value;
%                         key_timestampN_1 = key_timestamp;
%                             collectMax.clicks(1,collectMax_index) = key_timestamp;
%                             collectMax.avrg(1,collectMax_index) = Avrg_value;
%                             collectMax.clickinterval(1,collectMax_index) = current_input;
%                             collectMax.frequency(1,collectMax_index) = collectMax.freq;
%                             draw_frequency = collectMax.freq; %updates Ball height
%                             collectMax_index = collectMax_index + 1;
%                      end
%              
%             elseif (GetSecs - key_timestampN_1) > (1.5 * Avrg_value) && (collectMax_index > 1);
%                 
%                     phantom_current_input = GetSecs - key_timestampN_1;
%                 
%                     current_weight_fact = forget_fact * prev_weight_fact + 1;
%                     Estimate_Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * phantom_current_input);
%                     phantom.freq = freq_interval/Estimate_Avrg_value;  
%                 
%                     %Refresh values in phantom output vector
%                     prev_weight_fact = current_weight_fact; 
%                     prev_movingAvrg = Estimate_Avrg_value;
%                         %NOT% key_timestampN_1 = key_timestamp; Last key press remains unchanged 
%                         %output.clicks(1,output_index) = key_timestamp;
%     %                 phantom.avrg(1,i_phantom) = Avrg_value;
%     %                 phantom.clickinterval(1,i_phantom) = current_input;
%     %                 phantom.frequency(1,i_phantom) = phantom.freq; 
%                     draw_frequency = phantom.freq;  %updates Ball height
%     %               i_phantom = i_phantom + 1;
%     %                 
%             end
%        
%              collectMax.maxFreq(1,collectMax_trialCount) = max(collectMax.frequency(1:collectMax_index));
%     end
%      collectMax_trialCount = collectMax_trialCount + 1;
%      
%     WaitSecs(1.5);
% end
% 
% input.maxFrequency = max(collectMax.maxFreq(1:collectMax_trialCount));
% 
% %CONTROL PRINT - delete!
% text = ['Klasse!\n\nMaximale Frequenz: ' num2str(input.maxFrequency) '\n\nWeiter mit Mausklick'];
% Screen('TextSize',w,32);
% Screen('TextFont',w,'Arial');
% [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
% Screen('Flip',w);
% 
%                                           
% GetClicks(setup.screenNum);


%%%%%%%%%%%%%%%%%%%%%%%%%%
%%    1 Trial effort    %%
%%%%%%%%%%%%%%%%%%%%%%%%%%

%When Skipping MaxEstimation
input.maxFrequency = 6;


%Reset values

%Initialise exponential weighting
forget_fact = 0.8;
prev_weight_fact = 0;
prev_movingAvrg = 0;
key_timestamp = 0;
current_input = 0; 
Avrg_value = 0;
 
% Effort-Reward Threshold
input.percent70Frequency = input.maxFrequency * 0.7;

output.freq=0;
output.clicks = nan(1,200); % stores clicks: timestamp
output.clickinterval = nan(1,200); %stores current_input (t2-t1)
output.avrg = nan(1,200); %stores weighted interval value of a click
output.frequency = nan(1,200); %stores weighted interval value of a click
i_collect_freq = 1;
i_phantom = 1;

%Payout calculation
flag = 0; %1 if frequency exceeds MaxFrequency
output.payout = nan(2,200); %[t1=exceeding_onset ; t2=exceeding_offset ; Dt=t2-t1]
i_payout_onset = 1;
output.payout_money = nan(1,200);
output.payout_calories = 0;

trials_per_run_counter = 1;
trials_per_session = 1; %Determines repetitions of 30secs run


draw_frequency = 0; %combines output.frequency and phantom frequency to smoothen ball position

text = ['Main experiment \n\nWeiter mit Mausklick'];
[pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
Screen('Flip',w);
    
GetClicks(setup.screenNum);
WaitSecs(1.5);


%% Built trialwise
while trials_per_run_counter < (trials_per_session+1) %trials per run starts with 1!
    
    fix = ['+'];
    Screen('TextSize',w,64);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.black,80);
    time.fix = Screen('Flip', w);

    WaitSecs(1); %Show screen for 1s

    % load and show Coin
    [img.incentive_coins10, img.map, img.alpha] = imread('incentive_coins10.jpg');
    stim.incentive_coins10 = Screen('MakeTexture', w, img.incentive_coins10); %ggf Hintergrund transparent machen
    % [img.incentive_sweets2, img.map, img.alpha] = imread('incentive_sweets2.jpg');
    % stim.incentive_sweets2 = Screen('MakeTexture', w, img.incentive_sweets2); %ggf Hintergrund transparent machen
    Screen('DrawTexture', w, stim.incentive_coins10,[], [((setup.xCen-Tube.width/2)-Coin.width-10) (setup.ScrHeight/2-Coin.width) (setup.xCen-Tube.width/2-10) (setup.ScrHeight/2)]);
    time.img = Screen('Flip', w);

    WaitSecs(1); %Show screen for 1s

    trial_time.onset = GetSecs;
    key_timestampN_1 = trial_time.onset;

    while (30 > (GetSecs-trial_time.onset))       %Trial-length 30sec

          % Draw Tube
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (Tube.offset+setup.ScrHeight/3), (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen+Tube.width/2), (Tube.offset+setup.ScrHeight/3), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
          % Draw 70% line
            Threshold.yposition = (setup.ScrHeight-Tube.offset-(input.percent70Frequency*draw_frequency_factor));
            Screen('DrawLine',effort_scr,color.red,(setup.xCen-Tube.width/2), Threshold.yposition, (setup.xCen+Tube.width/2), Threshold.yposition,3);

            Screen('DrawTexture', effort_scr, stim.incentive_coins10,[], [((setup.xCen-Tube.width/2)-Coin.width-10) (setup.ScrHeight/2-Coin.width) (setup.xCen-Tube.width/2-10) (setup.ScrHeight/2)]);
            Screen('CopyWindow',effort_scr,w);
          
          % Draw Ball
            Ball.position = [(setup.xCen-Ball.width/2) ((setup.ScrHeight-Tube.offset-Ball.width)-(draw_frequency*draw_frequency_factor)) (setup.xCen+Ball.width/2) ((setup.ScrHeight-Tube.offset)-(draw_frequency*draw_frequency_factor))];

            if (Ball.position(1,4) < Threshold.yposition) %Ball above threshold
                
                Ball.color = color.green2;
                
%                 if (flag == 1)
%                     continue
                    
                if (flag == 0)
                    
                    flag = 1;                    
                    exceed_onset = GetSecs;
                    output.payout(1,i_payout_onset) = exceed_onset;
                
                end    
                    
            else    %Ball below threshold    
                
                 Ball.color = color.green;
                 
%                  if (flag == 0)
%                      continue
                     
                 if (flag == 1)
                     
                     flag = 0;
                     exceed_offset = GetSecs;
                     output.payout(2,i_payout_onset) = exceed_offset;
                     
                     i_payout_onset = i_payout_onset + 1;
                     
                 end    
                
            end  
            
                Screen('FillOval',w,Ball.color,Ball.position);
                Screen('Flip', w);
                
           
            [b,c] = KbQueueCheck;      


             if c(keys.resp) > 0
                     key_timestamp = GetSecs;   %b papameter does not work!
                     
                     if (key_timestamp > (trial_time.onset + 0.1))
                         current_input = key_timestamp - key_timestampN_1;

                        %Exponential weightended Average of RT for frequency estimation
                        current_weight_fact = forget_fact * prev_weight_fact + 1;
                        Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * current_input);
                        output.freq = freq_interval/Avrg_value;


                        %Refresh values in output vector
                        prev_weight_fact = current_weight_fact; 
                        prev_movingAvrg = Avrg_value;
                        key_timestampN_1 = key_timestamp;
                            output.clicks(1,i_collect_freq) = key_timestamp;
                            output.avrg(1,i_collect_freq) = Avrg_value;
                            output.clickinterval(1,i_collect_freq) = current_input;
                            output.frequency(1,i_collect_freq) = output.freq;
                            draw_frequency = output.freq; %updates Ball height
                            i_collect_freq = i_collect_freq + 1;
                            
                     end

             elseif (GetSecs - key_timestampN_1) > (1.5 * Avrg_value) && (i_collect_freq > 1);

                    phantom_current_input = GetSecs - key_timestampN_1;

                    current_weight_fact = forget_fact * prev_weight_fact + 1;
                    Estimate_Avrg_value = (1-(1/current_weight_fact)) * prev_movingAvrg + ((1/current_weight_fact) * phantom_current_input);
                    phantom.freq = freq_interval/Estimate_Avrg_value;


                    %Refresh values in phantom output vector
                    prev_weight_fact = current_weight_fact; 
                    prev_movingAvrg = Estimate_Avrg_value;
                   % key_timestampN_1 = key_timestamp; %Not necessary for phantom count, Last key press remains unchanged 
                       % output.clicks(1,output_index) = key_timestamp;
                        phantom.avrg(1,i_phantom) = Avrg_value;
                        phantom.clickinterval(1,i_phantom) = current_input;
                        phantom.frequency(1,i_phantom) = phantom.freq; 
                        draw_frequency = phantom.freq;  %updates Ball height
                        i_phantom = i_phantom + 1;

             end
               
    end 
    end_of_trial = GetSecs;
    
    if (flag == 1)
        
        output.payout(2,i_payout_onset) =  end_of_trial;
    end
    
    
    % Calculate payouff for run
    output.payout_money = diff(output.payout);
    win = nansum(output.payout_money);
    
         
 trials_per_run_counter = trials_per_run_counter + 1;
end


text = ['Well done!\nYou win for ' num2str(win) ' seconds in this run'];
[pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
Screen('Flip',w);

WaitSecs(1.5);
GetClicks(setup.screenNum);

KbQueueRelease();

% Screen('TextSize',w,64);
% Screen('TextFont',w,'Arial');
% [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.white,80);
% time.fix = Screen('Flip', w);


%%Outputs:
%plot_frequency = plot(output.frequency)
%plot_money = plot(output.payout_money)

output.clicks(isnan(output.clicks)) = [];
output.frequency(isnan(output.frequency)) = [];

output.clicks_referenced = output.clicks - trial_time.onset;
output.freq_over_time = [output.clicks_referenced ; output.frequency];

ts = timeseries(output.freq_over_time(end,:), output.freq_over_time(1,:));
plot(ts)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%TO DO
%Initiate Max_Freq
%Place white Line (Limit) at y=Max_Freq

%Count secs exceeding Max_Freq
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%