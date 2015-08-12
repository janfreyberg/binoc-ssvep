figure;
hold on;

% title('Amplitude');
stimfreqs = [28.8, 36];
group_symbols = {'v', 'o'};
group_colors = {[83 148 255]/255, [255 117 117]/255};

for group = 1:2;
    for trialTypes = 1:2;
    
    x = ones(size(amp_average{group}(:, trialTypes))) * stimfreqs(trialTypes) -1.5 +group;
    
%     scatter( x, amp_average{group}(:, trialTypes), group_symbols{group}, 'MarkerEdgeColor', [0.6 0.6 0.6] );
    
    x = stimfreqs(trialTypes) -.75 +group/2;
    h(group) = errorbar(mean(x), mean(amp_average{group}(:, trialTypes)), sem(amp_average{group}(:, trialTypes)),...
        'LineWidth', 2, 'Color', group_colors{group}, 'Marker', 'o', 'MarkerFaceColor', group_colors{group} );
    
    end
end

legend(h, {'CON', 'ASC'});
ylabel('Amplitude ( microvolt ^2 )', 'FontSize', 14);
xlabel('Frequency of Stimulation', 'FontSize', 14);
xlim([24.8 40]);
ylim([0, 0.2]);
set(gca, 'XTick', [28.8, 36]);