% timecourse over dom percept
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};

x = 1:10;

for group = 1:2
    
    y = nanmean(dom_bin_av{group}(~remove_subject{group}, :), 1);
    e = nansem(dom_bin_av{group}(~remove_subject{group}, :), 1);
    errorbar(x, y, e, 'Color', group_colours{group}, 'LineWidth', 2);
    
    y = nanmean(sup_bin_av{group}(~remove_subject{group}, :), 1);
    e = nansem(sup_bin_av{group}(~remove_subject{group}, :), 1);
    errorbar(x, y, e, 'Color', group_colours{group}, 'LineWidth', 2, 'LineStyle', '--');
    
%     errorbar(1:10, nanmean(dom_bin_av{group}(~remove_subject{group}, :), 1), nansem(dom_bin_av{group}(~remove_subject{group}, :), 1), linespec_dom{group});
%     errorbar(1:10, nanmean(sup_bin_av{group}(~remove_subject{group}, :), 1), nansem(sup_bin_av{group}(~remove_subject{group}, :), 1), linespec_sup{group});
    
end

% figure;
% hold on;
% 
% for group = 1:2
%     
%     errorbar(1:10, nanmean(dom_bin_av{group}(~remove_subject{group}, :), 1) - nanmean(sup_bin_av{group}(~remove_subject{group}, :), 1),...
%         nansem(dom_bin_av{group}(~remove_subject{group}, :) - sup_bin_av{group}(~remove_subject{group}, :), 1), linespec_dom{group});
% end

figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};

x = 1:10;

for group = 1:2
    
    y = nanmean(dom_bin_av{group} - sup_bin_av{group}, 1);
    e = nansem(dom_bin_av{group} - sup_bin_av{group}, 1);
%     errorbar(x, y, e, 'Color', group_colours{group}, 'LineWidth', 2);
    
    plot(x, y, 'Color', group_colours{group}, 'LineWidth', 2);
    
    fill_x = [x, fliplr(x)];
    fill_y = [y - e, fliplr( y + e )];
    
    fill( fill_x, fill_y, group_colours{group}, 'FaceAlpha', 0.2, 'EdgeColor', 'none' );
    
end