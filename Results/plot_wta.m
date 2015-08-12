%% Behavioural result: Dominant and Mixed Percept Duration
figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};

x = [1, 2];

for group = 1:2
    
    hold on;
    y = nanmean(wta{group}(~remove_subject{group}));
    e = nansem(wta{group}(~remove_subject{group}));
    
    errorbar(group, y, e, 'Color', group_colours{group}, 'LineWidth', 2);
    
    
    
end
title('Winner Takes All');
