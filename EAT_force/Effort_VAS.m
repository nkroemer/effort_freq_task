%%===================VAS horizontal===================
%customized visual analogue scales (0-100)
%Answer with Joystick (USB Xbox-360 Controller)
%
%Modified by Monja Neuser
%   to be used in effort allocation task
%Coded by: Nils Kroemer modified from mood_VAS (coded by Ying Lee) and BDM task (coded by Jean Liu)

%Update coded with: Matlab R2014a using Psychtoolbox 3.0.11
%========================================================
% Define colors
color.white = WhiteIndex(setup.screenNum); %with intensity value for white on second screen
color.grey = color.white / 2;
color.black = BlackIndex(setup.screenNum);
color.red = [255 0 0];
color.scale_anchors = color.black;


%% Start rating:
feedback_delay = 1; % specifies the duration that the confirmed rating will be displayed on the screen
%max_dur_rating = 4; %Previously fixed, variable for State ratings and
%Experiment
max_dur_rating = VAS_rating_duration;
%VAS_time_limit = 1; %set 0 f�r state ratings, 1 for experiment
wait_rest = 0;

%and initialize jitter counter
%count_jitter = 1;


% Fixation cross
[Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(JoystickSpecification);
x_mid = JoystickSpecification.Max / 2;


loop_start = GetSecs;
while (Joystick.X < x_mid * 0.85) || (Joystick.X > x_mid * 1.15)
   
    fix_color = color.red;
    
    fix = ['+'];
    Screen('TextSize',w,64);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', fix_color,80);
    time.fix = Screen('Flip', w);
    
    [Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(JoystickSpecification);

end
    loop_duration = GetSecs - loop_start;
    wait_rest = wait_rest - loop_duration;
    
    fix_color = color.black;

    fix = ['+'];
    Screen('TextSize',w,64);
    Screen('TextFont',w,'Arial');
    [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, fix, 'center', 'center', fix_color,80);
    time.fix = Screen('Flip', w);
   
    iti_jitter = 0.3+jitter(count_jitter);
    
    if  (VAS_time_limit == 1) && (wait_rest > 0)
        
        iti_jitter = iti_jitter+wait_rest;
    end
    
    WaitSecs(iti_jitter);

count_jitter = count_jitter + 1;

%--- Start trial---
%for i=1:length(questionlist{1,1}); %number of questions
t_scale_trigger = GetSecs; 

    trial.runstart = GetSecs; %Time run starts
    
    %--- Prepare off-screen windows---
    
    %rating window (4s)
    rating_scr = Screen('OpenOffscreenwindow',w,color.white);
    text_freerating = [trial.question]; %free rating
    
    Screen('TextSize',effort_scr,14);
    Screen('TextFont',effort_scr,'Arial');
    anchor_1 = ['�berhaupt nicht'];
    %anchor_4 = ['Neutral'];
    anchor_7 = ['Sehr'];
  
    
 %%Questions   
    if  strcmp(trial.question,'wanted')
        text_question = ['Wie sehr wollten Sie die Belohnung in diesem Durchgang erhalten?'];
    elseif strcmp(trial.question,'exhausted')
        text_question = ['Wie stark haben Sie sich in diesem Durchgang verausgabt?'];
    else %e.g. strcmp(trial.question,'hungry')
        %text_question = strcat({'Wie '}, trial.question,  ' f�hlen Sie sich im Moment?');
        text_question = ['Wie ' trial.question  ' f�hlen Sie sich im Moment?'];
     
    end;
    
    %rescale wh to scale_height
    Scale_width = round(setup.ScrWidth * .50);
    %Scale_width = round(ww * .75);
    Scale_offset = round((setup.ScrHeight - (setup.ScrHeight * .95)) * .75);
    %Scale_offset = round((wh - (wh * .95)) * .75);
    
    DrawFormattedText(rating_scr, text_question, 'center', (Scale_offset+setup.ScrHeight/2 - 150), color.scale_anchors,40,[],[],2);
    DrawFormattedText(rating_scr, [anchor_1], (setup.ScrWidth/2-Scale_width/2 - 65), (Scale_offset+setup.ScrHeight/2 + 40), color.scale_anchors,80);
    %DrawFormattedText(rating_scr, [anchor_4], 'center', (Scale_offset+wh/2 + 30), [205 201 201],80);
    DrawFormattedText(rating_scr, [anchor_7], (setup.ScrWidth/2+Scale_width/2 - 35), (Scale_offset+setup.ScrHeight/2 + 40), color.scale_anchors,80);
    
    % horizontal scale element
    Screen('DrawLine',rating_scr,color.scale_anchors,(setup.ScrWidth/2-Scale_width/2), (Scale_offset+setup.ScrHeight/2), (setup.ScrWidth/2+Scale_width/2), (Scale_offset+setup.ScrHeight/2),3)
  
   
    % vertical scale elements
    Screen('DrawLine',rating_scr,color.scale_anchors,(setup.ScrWidth/2-Scale_width/2), (Scale_offset+setup.ScrHeight/2 - 20), (setup.ScrWidth/2-Scale_width/2), (Scale_offset+setup.ScrHeight/2 + 20),3)
    %Screen('DrawLine',rating_scr,[250 250 250],(ww/2), (Scale_offset+wh/2 - 15), (ww/2), (Scale_offset+wh/2 + 15),3)
    Screen('DrawLine',rating_scr,color.scale_anchors,(setup.ScrWidth/2+Scale_width/2), (Scale_offset+setup.ScrHeight/2 - 20), (setup.ScrWidth/2+Scale_width/2), (Scale_offset+setup.ScrHeight/2 + 20),3)
    
    %--- Start display for trial---
    
    %rating window
    Screen('CopyWindow',rating_scr,w);
    Screen('Flip',w);
    
    
    %----Mouse response----
    
    %Move cursor to mean position
    X = round(setup.ScrWidth/2);
    Y = round(Scale_offset + setup.ScrHeight/2); %Fix y coordinate
    Slider_x_pos = X;
    SetMouse(X,Y);
    %scale_joy_x = ww*1.1/JoystickSpecification.Max;
    %scale_joy_y = wh*1.1/JoystickSpecification.Max;
    scale_joy_x = setup.ScrWidth*0.7/JoystickSpecification.Max;
    scale_joy_y = setup.ScrHeight*0.7/JoystickSpecification.Max;
    
    %Put slider on the screen
    Screen('CopyWindow',rating_scr,w)
    
    Screen('DrawLine',w,[250 0 0], Slider_x_pos, Y-10, Slider_x_pos, Y+ 10, 5)
                
    Screen('Flip',w);
    
    %Loop and track mouse such that rating slider moves according to mouse position (edited from MouseTraceDemo)
    sampleTime = 0.01;
    startTime = GetSecs;
    nextTime = startTime+sampleTime;
    flag_resp = 0;
    
    %[mouseX, mouseY, mousebuttons] = GetMouse(screenNumber); %Find out coordinates of current mouse position
    [Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(JoystickSpecification);
    offset_x = X - round(Joystick.X * scale_joy_x);
    proj_x = round(Joystick.X * scale_joy_x) + offset_x;
    
    while (GetSecs - t_scale_trigger) < max_dur_rating && flag_resp == 0 %mousebuttons(1)~=1 
        
        if (GetSecs > nextTime) %Sample every 0.01 seconds
            %[mouseX, mouseY, mousebuttons] = GetMouse(screenNumber); %Find out coordinates of current mouse position
            [Joystick.X, Joystick.Y, Joystick.Z, Joystick.Button] = WinJoystickMex(JoystickSpecification);
            proj_x = round(Joystick.X * scale_joy_x) + offset_x;
            
            if Joystick.Button(1) == 1
                flag_resp = 1;
                t_button = GetSecs;
            end
            
%             for buffer_i = 2:250 %buffer_size
%                 xbox_buffer(buffer_i) = Joystick.Button(1);
%                 if xbox_buffer(buffer_i)==1 && xbox_buffer(buffer_i-1)==0
%                     flag_resp = 1;
%                     t_button = GetSecs;
%                 else
%                     flag_resp = 0;
%                 end
%                 if buffer_i == 50
%                     buffer_i = 2;
%                     xbox_buffer(1)=xbox_buffer(250);
%                 end
            
                if flag_resp==1 %Terminate and record rating on left mouseclick
                    
                    t_rating_ref = t_button - startTime;
                                        
                    rating = ((Slider_x_pos - (setup.ScrWidth/2-Scale_width/2))/ Scale_width)*100; %rescaling of scale_width independent of screen resolution [0-100]
                    rating_label = text_freerating;
                    rating_subm = 1;
                    

                elseif (proj_x ~= Slider_x_pos) %Update screen if participant has scrolled up or down
                    Screen('CopyWindow',rating_scr,w);
                    Slider_x_pos = (proj_x);

                    %restrict range of slider to defined scale
                    if Slider_x_pos < (setup.ScrWidth/2 - Scale_width/2)
                        Slider_x_pos = (setup.ScrWidth/2 - Scale_width/2);
                    elseif Slider_x_pos > (setup.ScrWidth/2 + Scale_width/2)
                        Slider_x_pos = (setup.ScrWidth/2 + Scale_width/2);
                    end

                    Screen('DrawLine',w,[250 0 0],Slider_x_pos, Y - 10, Slider_x_pos, Y + 10,5)

                    Screen('Flip',w);
                end
            %end
            nextTime = nextTime+sampleTime;
        end
    end
    
     if flag_resp==0 %Terminate without click
                    
            rating = ((Slider_x_pos - (setup.ScrWidth/2-Scale_width/2))/ Scale_width)*100; %rescaling of scale_width independent of screen resolution [0-100]
            rating_label = text_freerating;
            rating_subm = 0;
       
            t_rating_ref = GetSecs - startTime;
     end
     wait_rest = max_dur_rating - t_rating_ref;
     WaitSecs(feedback_delay); %Show screen for 1s post-mouseclick
     

%end
