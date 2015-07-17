function find_offset()
% global pxsize frameWidth fixWidth ycen xcen scr l_key u_key d_key r_key esc_key stimRect fixLines fixPoint;
offset = pxsize;
found = 0;
% Firstly, present white & black circles to avoid merging and find
% the spot where they meet!
        while 1
            if found == 0;
            %% Move stimuli close until they meet
            stimRect{1} = [xcen-offset-pxsize/2, ycen-pxsize/2, xcen-offset+pxsize/2, ycen+pxsize/2];
            stimRect{2} = [xcen+offset-pxsize/2, ycen-pxsize/2, xcen+offset+pxsize/2, ycen+pxsize/2];
            fixPoint{1} = [xcen-offset, ycen];
            fixPoint{2} = [xcen+offset, ycen];
            
            
                        
            Screen('FrameRect', scr, [255,0;255,0;255,0], [stimRect{1}', stimRect{2}'], frameWidth);
            Screen('DrawLines', scr, fixLines, fixWidth, 255, fixPoint{1});
            Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{2});
            Screen('Flip', scr);
            
            WaitSecs(0.2);
            
            [~, keyCode] = KbWait;
            
            if keyCode(u_key)
                offset = offset + 10;
            elseif keyCode(d_key)
                offset = offset - 10;
            elseif keyCode(l_key)
                offset = offset + 2;
            elseif keyCode(r_key)
                offset = offset - 2;
            elseif keyCode(ent_key)
                offset = offset + pxsize/2 + frameWidth;
                found = 1;
            elseif keyCode(esc_key)
                error('You interrupted the script!');
            end
            if offset < pxsize
                offset = pxsize;
            end
            
            elseif found == 1
            %% Once jump is made, merge stimuli
            stimRect{1} = [xcen-offset-pxsize/2, ycen-pxsize/2, xcen-offset+pxsize/2, ycen+pxsize/2];
            stimRect{2} = [xcen+offset-pxsize/2, ycen-pxsize/2, xcen+offset+pxsize/2, ycen+pxsize/2];
            frameRect{1} = stimRect{1} + [-frameWidth, -frameWidth, +frameWidth, +frameWidth];
            frameRect{2} = stimRect{2} + [-frameWidth, -frameWidth, +frameWidth, +frameWidth];
            fixPoint{1} = [xcen-offset, ycen];
            fixPoint{2} = [xcen+offset, ycen];
            
            [newX, ~] = Screen('DrawText', scr, 'A', xcen-offset-pxsize/3, ycen-pxsize/3, [255 0 0]);
            width = newX - (xcen-offset-pxsize/3); height = Screen('TextSize', scr);
            Screen('DrawText', scr, 'B', xcen-offset+pxsize/3-width, ycen-pxsize/3, [0 255 0]);
            Screen('DrawText', scr, 'C', xcen-offset-pxsize/3, ycen+pxsize/3-height-2, [0 0 255]);
            Screen('DrawText', scr, 'D', xcen-offset+pxsize/3-width, ycen+pxsize/3-height-2, [0 255 255]);
            
            Screen('DrawText', scr, 'A', xcen+offset-pxsize/3, ycen-pxsize/3, [255 0 0]);
            Screen('DrawText', scr, 'B', xcen+offset+pxsize/3-width, ycen-pxsize/3, [0 255 0]);
            Screen('DrawText', scr, 'C', xcen+offset-pxsize/3, ycen+pxsize/3-height-2, [0 0 255]);
            Screen('DrawText', scr, 'D', xcen+offset+pxsize/3-width, ycen+pxsize/3-height-2, [0 255 255]);
            
            Screen('FrameRect', scr, 0, [stimRect{1}', stimRect{2}'], frameWidth);
            Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{1});
            Screen('DrawLines', scr, fixLines, fixWidth, 0, fixPoint{2});
            Screen('Flip', scr);
            
            WaitSecs(0.2);
            
            [~, keyCode] = KbWait;
            
            if keyCode(u_key)
                offset = offset + 10;
            elseif keyCode(d_key)
                offset = offset - 10;
            elseif keyCode(l_key)
                offset = offset + 2;
            elseif keyCode(r_key)
                offset = offset - 2;
            elseif keyCode(ent_key)
                break;
            elseif keyCode(esc_key)
                offset = pxsize;
                found = 0; % you can return to first step by pressing esc
            end

            end
        end
end