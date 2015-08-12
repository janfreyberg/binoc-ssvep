%% Behavioural result: Dominant and Mixed Percept Duration
figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};

x = [1, 2];

for group = 1:2
    subplot(1, 2, 1);
    hold on;
    y = nanmean(mean_mix{group}(~remove_subject{group}));
    e = nansem(mean_mix{group}(~remove_subject{group}));
    
    errorbar(group, y, e, 'Color', group_colours{group}, 'LineWidth', 2);
    
    subplot(1, 2, 2);
    hold on;
    y = nanmean(mean_dom{group}(~remove_subject{group}));
    e = nansem(mean_dom{group}(~remove_subject{group}));
    
    errorbar(group, y, e, 'Color', group_colours{group}, 'LineWidth', 2);
    
%     errorbar(0.8+group*0.1, nanmean(mean_mix{group}(~remove_subject{group})), nansem(mean_mix{group}(~remove_subject{group})), linespec_mix{group} );
%     scatter( 0.8+group*0.1*ones(size(mean_mix{group}(~remove_subject{group}))), mean_mix{group}(~remove_subject{group}) );
%     errorbar(1.8+group*0.1, nanmean(mean_dom{group}(~remove_subject{group})), nansem(mean_dom{group}(~remove_subject{group})), linespec_dom{group} );
%     scatter( 1.8+group*0.1*ones(size(mean_mix{group}(~remove_subject{group}))), mean_dom{group}(~remove_subject{group}) );
end
suptitle('Mixed / Dominant Durations');
