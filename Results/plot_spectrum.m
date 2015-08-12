figure;
hold on;

% title('Amplitude');
stimfreqs = [28.8, 36];
group_symbols = {'v', 'o'};
group_colors = {[83 148 255]/255, [255 117 117]/255};



    
    
    
    
for group = 1:2;
    %         subplot(2, 1, iFreq);
    ylabel('Amplitude ( microvolt ^2 )', 'FontSize', 14);
%     ylim([0, 0.1]);
    xlim([24.8 40]);
    hold on;
    
    x = freqs.freq;
    
    y = squeeze( mean(spec_average{group}(:, 1, :), 1 ) )';
    
    h(group) = plot(x, y, 'LineWidth', 1, 'Color', group_colors{group});
    
    %         x_fill(2:2:2*numel(x)) = x;
    %         x_fill(1:2:2*numel(x)-1) = x;
    %         y_fill(2:2:2*numel(y)) = y-squeeze( nansem(spec_average{group}(:, trialTypes, :), 1 ) )';
    %         y_fill(1:2:2*numel(y)-1) = y+squeeze( nansem(spec_average{group}(:, trialTypes, :), 1 ) )';
    x_fill = [x, fliplr(x)];
    y_fill = [y-squeeze( nansem(spec_average{group}(:, 1, :), 1 ) )', fliplr(y+squeeze( nansem(spec_average{group}(:, 1, :), 1 ) )')];
    
    fill( x_fill, y_fill, group_colors{group}, 'FaceAlpha', 0.2, 'EdgeColor', 'none' );
    
end
legend(h, {'CON', 'ASC'});




xlabel('Frequency', 'FontSize', 14);

% set(gca, 'XTick', [28.8, 36]);