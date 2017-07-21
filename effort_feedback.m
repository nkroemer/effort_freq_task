%For all trials except the last, show pause screen with 10secs timer
if i_trial < length(conditions)
   
    timer_onset = GetSecs;
    i_timer = 1;
    
    while i_timer <= 5
        
        while i_timer > GetSecs - timer_onset
          
            text = ['Well done!\nYou win   ' num2str(win) '   points in this run. \n\n' num2str(i_trial)  '  Trials completed.\n\n' num2str(6 - i_timer) '    Seconds until next trial'];
                Screen('TextSize',w,32);
                Screen('TextFont',w,'Arial');
                [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
                Screen('Flip',w);
        end
    
        i_timer = i_timer + 1;
    end

%After last trial, compute total win
elseif i_trial == length(conditions)
    
       text = ['Well done!\nYou win   ' num2str(win) '   points in this run.'];
            Screen('TextSize',w,32);
            Screen('TextFont',w,'Arial');
            [pos.text.x,pos.text.y,pos.text.bbox] = DrawFormattedText(w, text, 'center', 'center', color.black,40);
            Screen('Flip',w);
            WaitSecs (3);
                

        
end