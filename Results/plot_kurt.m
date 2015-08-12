%% Behavioural result: Dominant and Mixed Percept Duration
figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};



for group = 1:2
    
    for subject = 1:n{group}
        
        logtrans_kurtosis{group}(subject, 1) = ...
            mean([ kurtosis(log10( [all_samples{group, subject}(1, :) ])), kurtosis(log10(all_samples{group, subject}(2, :))) ]);
        
    end
    
    x = [1, 2];
    
    y = nanmean(logtrans_kurtosis{group}(~remove_subject{group}));
    e = nansem(logtrans_kurtosis{group}(~remove_subject{group}));
    
    h(group) = errorbar(x(group), y, e, 'Color', group_colours{group},...
        'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});
    
    
    
end

suptitle('Difference Between Frequencies');
% set(gca, 'XTick', [1, 2], 'XTickLabel', {'Dominant Percepts', 'Mixed Percepts'});
xlim([0 3]);
ylabel('Ratio to Trial Average', 'FontSize', 15);
legend(h, {'CON', 'ASC'});