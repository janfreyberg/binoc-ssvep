    %% Plot based on buttons
    % whole percept
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    hold on;
    group_colours = {[83 148 255]/255, [255 117 117]/255};
    linespec_dom{1} = '--ko'; linespec_dom{2} = ':kv';
    linespec_sup{1} = '--ro'; linespec_sup{2} = ':rv';
    linespec_mix{1} = '--mo'; linespec_mix{2} = '--mv';
    
    x = [0.8, 1, 1.2];
    
    for group = 1:2
        
    y(1) = nanmean(postOne_dom_av{group}(~remove_subject{group}));
    y(2) = nanmean(postOne_mix_av{group}(~remove_subject{group}));
    y(3) = nanmean(postOne_sup_av{group}(~remove_subject{group}));
    
    e(1) = nansem(postOne_dom_av{group}(~remove_subject{group}));
    e(2) = nansem(postOne_mix_av{group}(~remove_subject{group}));
    e(3) = nansem(postOne_sup_av{group}(~remove_subject{group}));
    
%     h(group) = errorbar(x([1 3]), y([1 3]), e([1 3]), 'Color', group_colours{group}, 'LineWidth', 2);
    h(group) = errorbar(x, y, e, 'Color', group_colours{group}, 'LineWidth', 2);
    
    
    
    % Add horizontal Line
    plot(get(gca,'xlim'), [1 1]);
    end
    legend(h, {'CON', 'ASC'}); 
    title('Freq Power Whole Spectrum', 'FontSize', 18);
