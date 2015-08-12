%% Behavioural result: Dominant and Mixed Percept Duration
figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};



for group = 1:2
    
    x = [0.9, 1.1];
    
    y = nanmean(difference_dom{group}(~remove_subject{group}));
    e = nansem(difference_dom{group}(~remove_subject{group}));
    
    errorbar(x(group), y, e, 'Color', group_colours{group},...
        'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});
    
    x = [1.9, 2.1];

    y = nanmean(difference_mix{group}(~remove_subject{group}));
    e = nansem(difference_mix{group}(~remove_subject{group}));
    
    h(group) = errorbar(x(group), y, e, 'Color', group_colours{group},...
        'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});
    
    
end

suptitle('Difference Between Frequencies');
set(gca, 'XTick', [1, 2], 'XTickLabel', {'Dominant Percepts', 'Mixed Percepts'});
xlim([0 3]);
ylabel('Ratio to Trial Average', 'FontSize', 15);
legend(h, {'CON', 'ASC'});