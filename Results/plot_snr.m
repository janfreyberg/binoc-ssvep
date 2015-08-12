figure;
hold on;

% title('Signal-To-Noise Ratio', 'FontSize', 18);
stimfreqs = [28.8, 36];
group_symbols = {'v', 'o'};
group_colors = {[83 148 255]/255, [255 117 117]/255};

for group = 1:2;
    for trialTypes = 1:2;
    
    
    x = stimfreqs(trialTypes) -.75 +group/2;
    h(group) = errorbar(mean(x), mean(snr_average{group}(:, trialTypes)), sem(snr_average{group}(:, trialTypes)),...
        'LineWidth', 2, 'Color', group_colors{group}, 'Marker', 'o', 'MarkerFaceColor', group_colors{group} );
    
    end
end

legend(h, {'CON', 'ASC'});
ylabel('Signal-To-Noise Ratio', 'FontSize', 14);
xlabel('Frequency of Stimulation', 'FontSize', 14);
xlim([24.8 40]);
set(gca, 'XTick', [28.8, 36]);