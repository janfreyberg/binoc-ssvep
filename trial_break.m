function trial_break(break_time, invoking_function)
global pxsize frameWidth ycen xcen fixWidth scr l_key u_key d_key r_key esc_key stimRect fixLines fixPoint frameRect;
KbQueueStart;
for lapsedTime = 0:break_time
    if strcmp(invoking_function, 'binocular_ssvep')
        for k = 1:2;
            DrawFormattedText(scr, ['Break for ' num2str(break_time-lapsedTime)], 'center', 'center', 0, [], [], [], [], [], stimRect{k});
            Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
%             Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
        end
    elseif strcmp(invoking_function, 'monocular_ssvep.m')
        
    end
Screen('Flip', scr);
[~, pressed] = KbQueueCheck;

if pressed(esc_key)
    error('Interrupted in the break');
end

WaitSecs(1);

end


if strcmp(invoking_function, 'binocular_ssvep')
    for k = 1:2
        Screen('FrameRect', scr, 0, frameRect{k}, frameWidth);
        Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{k});
    end
    Screen('Flip', scr);
    KbWait;
    WaitSecs(2);
end


KbQueueStop;