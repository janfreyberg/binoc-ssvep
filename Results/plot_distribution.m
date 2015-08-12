figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};

for group = 1:2
    
    samples_concat = [];
    
    for subject = 1:n{group}
        
        samples_concat = [samples_concat, all_samples{group, subject}(1, :), all_samples{group, subject}(2, :)];
        logtrans_kurtosis{group}(subject, 1) = kurtosis(log10( [all_samples{group, subject}(1, :), all_samples{group, subject}(2, :)] ));
%         [f(subject, 1:100) = 
        
    end
    
    pts = linspace(-0.5, 0.5, 200);
    
    % transform
%     samples_concat = 1./(samples_concat);
%     samples_concat = sqrt(samples_concat);
    samples_concat = log10(samples_concat);
    
    disp(kurtosis(samples_concat));

    [mu, sigma] = normfit(samples_concat);
    
    [f{group}, xi] = ksdensity(samples_concat);
    
    plot(xi, f{group}, 'LineWidth', 2, 'Color', group_colours{group});
    
    plot(xi, normpdf(xi, mu, sigma), 'LineWidth', 2, 'Color', group_colours{group}, 'LineStyle', '--');
    
%     y = nanmean(logtrans_kurtosis{group}(~remove_subject{group}));
%     e = nansem(logtrans_kurtosis{group}(~remove_subject{group}));
%     
%     h(group) = errorbar(x(group), y, e, 'Color', group_colours{group},...
%         'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});
    
    
    
end