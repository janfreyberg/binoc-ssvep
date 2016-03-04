    %% Plot based on buttons
    % whole percept
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    hold on;
    group_colours = {[83 148 255]/255, [255 117 117]/255};
    linespec_dom{1} = '--ko'; linespec_dom{2} = ':kv';
    linespec_sup{1} = '--ro'; linespec_sup{2} = ':rv';
    linespec_mix{1} = '--mo'; linespec_mix{2} = '--mv';
    
    x = [1, 2, 3];
    
    for group = 1:1
        
    y(1) = nanmean(postWhole_dom_av{group}(~remove_subject{group}));
    y(2) = nanmean(postWhole_mix_av{group}(~remove_subject{group}));
    y(3) = nanmean(postWhole_sup_av{group}(~remove_subject{group}));
    
    e(1) = nansem(postWhole_dom_av{group}(~remove_subject{group}));
    e(2) = nansem(postWhole_mix_av{group}(~remove_subject{group}));
    e(3) = nansem(postWhole_sup_av{group}(~remove_subject{group}));
    
%     h(group) = errorbar(x([1 3]), y([1 3]), e([1 3]), 'Color', group_colours{group}, 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});
    h(group) = errorbar(x, y, e, 'Color', group_colours{group}, 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});
    
    
    
    % Add horizontal Line
    end
     
    suptitle('Power During Percepts');
    ylabel('Ratio to Trial Average', 'FontSize', 15);
    set(gca, 'XTick', [1 3], 'xticklabel', {'Frequency Dominant', 'Frequency Suppressed'});
    xlim([0 4]);
    plot(get(gca,'xlim'), [1 1], 'Color', 'k');
legend(h, {'CON', 'ASC'});