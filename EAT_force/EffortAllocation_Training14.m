%%===================Effort allocation Training=============
% Script needed for EffortAllocation_task14
% Commented and sorted by Monja, 19.10.2018
%
% author: Monja P. Neuser, Vanessa Teckentrup, Nils B. Kroemer
%
% input via XBox USB-Controller

%%==========================================================


    
%%=====================================================
%%   Determine individual maximum Frequency (2x10secs)    
%%=====================================================

%% Clear data vectors / initialize start values
%  This section is mirrored to the preparation in the actual experiment
%  script

 % (Initializing) variables
    restforce = getfield(GripForceSpec, 'restforce'); %normal holding force
    maxpossibleforce = getfield(GripForceSpec, 'maxpossibleforce'); %limit of GFD
    delta_pos_force = restforce - maxpossibleforce; 
    ForceMat = restforce; %current force. Starts at restforce to start ball at bottom
    ForceTime = []; %matrix that saves force over time
    LowerBoundBar = setup.ScrHeight - Tube.offset - Ball.width; %height at which the bar starts when ForceMat = restforce
    UpperBoundBar = Tube.height; %heighest allowed position of bar
    
    max_Boundary_yposition = LowerBoundBar; % location where bar starts
    i_step = 1; %loops through each iteration of the while loop (to place time stamps)

    % Prepare output struct to determine maximal force across training
    i_collectMax = 1; 
    collectMax.maxForce = nan(1,2);  %stores maxForce of 2 practice trials
    collectMax.values_per_trial = [];
    % collectMax.values_per_trial_t100 = []; %Matrix of output values / timepoint referenced (every 100ms)

    % Initialize exponential weighting
    t_button = 0; %still used in buffering routine         
    
    
%% Starting Protocol

% Introcudction
text = ['Auf dem Bildschirm werden Sie gleich ein nach oben geöffnetes Gefäß sehen mit einem blauen Ball darin. Wenn Sie Druck auf den Griff in Ihrer Hand ausüben, bewegt sich der Ball nach oben. Je fester Sie drücken, desto höher steigt der Ball. \nSie haben jetzt zweimal 10 Sekunden Zeit, um den Ball so hoch wie möglich steigen zu lassen.\nDie höchste erreichte Position wird mit einer blauen Linie angezeigt.'];
            Screen('TextSize',w,32);
            Screen('TextFont',w,'Arial');
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', (setup.ScrHeight/5), color.black, 60, [], [], 1.2);
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
            Screen('Flip',w);


%wait for a mouse click to continue
GetClicks(setup.screenNum);

% Procedure contains 2 trials of 10secs to collect individual maxForce

for i_collectMax = 1:2 
    
    % For show further instructions
    if (i_collectMax == 1)
        text = ['Bitte verändern Sie während des Versuchs Ihre Handhaltung nicht. \n\nVersuchen Sie in den nächsten 10 Sekunden den Ball so hoch steigen zu lassen, wie Sie können.'];
            Screen('TextSize',w,32);
            Screen('TextFont',w,'Arial');
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', (setup.ScrHeight/5), color.black, 60, [], [], 1.2);
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
            Screen('Flip',w);
            GetClicks(setup.screenNum);
    
    elseif (i_collectMax == 2)
        text = ['Das war schon sehr gut. Versuchen Sie jetzt, den Ball noch höher steigen zu lassen.'];
            Screen('TextSize',w,32);
            Screen('TextFont',w,'Arial');
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', (setup.ScrHeight/5), color.black, 60, [], [], 1.2);
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
            Screen('Flip',w);
            GetClicks(setup.screenNum);
    end

    
    % Show fixation cross at the beginning of each trial 
    fix = ['+'];
    Screen('TextSize',w,64);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', color.black,80);
    time.fix = Screen('Flip', w);

    WaitSecs(1); %Show screen for 1s
    

    % Actual traing trial star (recortstart time)
    t_collectMax_onset = GetSecs;

    % Loop during 10 sec duration (training trial length)
    while (10  > (GetSecs - t_collectMax_onset))    
    
       
        

         % Draw graphical display (reduced version without threshold)
        
         % Draw Tube
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), Tube.height, (setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen+Tube.width/2), Tube.height, (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('DrawLine',effort_scr,color.black,(setup.xCen-Tube.width/2), (setup.ScrHeight-Tube.offset), (setup.xCen+Tube.width/2), (setup.ScrHeight-Tube.offset),6);
            Screen('CopyWindow',effort_scr,w);
          
         % Draw upper bound blue line
         
         if ForceMat < restforce
        
              Boundary_yposition = ((LowerBoundBar - UpperBoundBar)/delta_pos_force) * ForceMat + UpperBoundBar - (maxpossibleforce * (LowerBoundBar - UpperBoundBar)/delta_pos_force);
    
         else
             
             Boundary_yposition = (setup.ScrHeight-Tube.offset-Ball.width);
        
         end
         
         % Boundary_yposition = ((setup.ScrHeight-Tube.offset-Ball.width)-TubeForceScale);
            max_Boundary_yposition = min(max_Boundary_yposition, Boundary_yposition);
            
            Screen('DrawLine',w,color.darkblue,(setup.xCen-Tube.width/2), max_Boundary_yposition, (setup.xCen+Tube.width/2), max_Boundary_yposition,3);

         % Draw Ball
            Ball.position = [(setup.xCen-Ball.width/2) (Boundary_yposition) (setup.xCen+Ball.width/2) (Boundary_yposition + Ball.width)];
            Ball.color = color.darkblue;
            Screen('FillOval',w,Ball.color,Ball.position);
            Screen('Flip', w);

            
    % Gamepad query to compute button press frequency            
            [b,c] = KbQueueCheck;      
            
            % Conditional input
            if do_gamepad == 1 %If experiment is run with GamePad
                
                % Continuously log position and time of the button for the right index
                % finger -> Joystick.Z
                [Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(GripForceSpec);
                
                % Getting values from Grip Force Device -> Joystick.Y
                ForceMat = Joystick.Y;
                
                % Saving force over time by adding the current ForceMat to ForceTime at every
                % step
                
                ForceTime = [ForceTime, Joystick.Y]; 
                
                 % Store for timestamps and actual frequency every 100ms
                t_step = GetSecs;
                t_vector(1,i_step) = t_step;
                i_step = i_step + 1;
                
                %end
                
            end        
    
    end

    
% End of trial    
    count_joy = 1;
    
   
    
    
%% Prepare Output

% Store MaxForce for each training trial in a vector, take the minimum, because lower values indicate
% higher forces.
% Will be complemented by practice trials to approximate 'real' MaxForce

collectMax.maxForce(1,i_collectMax) = min(ForceTime);
collectMax.maxForce = collectMax.maxForce(collectMax.maxForce ~= 0);
input.maxForce = min(collectMax.maxForce);

% Reference t_vector to collectMax_onset 
t_ref_vector = t_vector - t_collectMax_onset; 

% Copy Output Values into Output Matrix
% Name of struct = collectMax; to disentangle from practice trials (!different array size) 
collectMax.values_per_trial = [collectMax.values_per_trial, [ones(1,length(ForceTime)) * subj.num; ... %Subj_ID
                               ones(1,length(ForceTime)) * i_collectMax ; ...                         %Trial_ID
                               (1:length(ForceTime)) ; ...                                            %t_Button ID
                               t_ref_vector ; ...                                                       %time referenced to 10 second trial start
                               ForceTime ; ...                                                   %Force at t_Button
                               ones(1,length(ForceTime)) * collectMax.maxForce(1,i_collectMax)]];       %Maximum Force in 10seconds-trial

% Create & Save temporary output data
collectMax.filename = sprintf('%s\\data\\effort_%s_%s_s%s_temp', pwd, subj.studyID, subj.subjectID, subj.sessionID);
save([collectMax.filename '.mat'], 'collectMax', 'subj', 'input')
  

%% Clear Variables to initiate new trial

    i_resp = 1;

    i_step = 1;
    t_vector = [];
    count_joystick = 0;
    
    ForceMat = restforce;
    ForceTime = [];

    WaitSecs(1.5);
    
end



% Prepare Individual MaxForce as input for Trials
collectMax.maxForce = collectMax.maxForce(collectMax.maxForce ~= 0);
input.maxForce = min(collectMax.maxForce);


% 
% % CONTROL PRINT
% text = ['Sehr gut! Die Maximal-Frequenz bisher ist: ' num2str(input.maxForce)];
%         Screen('TextSize',w,32);
%         Screen('TextFont',w,'Arial');
%         [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', (setup.ScrHeight/5), color.black, 60, [], [], 1.2);
%         [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text_Cont, 'center', (setup.ScrHeight/5*4.7), color.black, 50, [], [], 1.2);
%         Screen('Flip',w);
%         GetClicks(setup.screenNum);





%%======================
%%End of TRAINING
%%======================