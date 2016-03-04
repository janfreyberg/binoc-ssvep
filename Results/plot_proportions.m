figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};
linespec_dom{1} = '--ko'; linespec_dom{2} = ':kv';
linespec_sup{1} = '--ro'; linespec_sup{2} = ':rv';
linespec_mix{1} = '--mo'; linespec_mix{2} = '--mv';


for group = 1:2

y(1) = nanmean(nanmean(domF_by_supF{group}, 2), 1);
% y(2) = nanmean(nanmean(mixF_by_mixF{group}, 2), 1);
y(2) = nanmean(nanmean(supF_by_domF{group}, 2), 1);

e(1) = nansem(nanmean(domF_by_supF{group}, 2), 1);
% e(2) = nansem(nanmean(mixF_by_mixF{group}, 2), 1);
e(2) = nansem(nanmean(supF_by_domF{group}, 2), 1);

% bar((group-1)/2+(1:numel(y)), y, 'FaceColor', group_colours{group});
h(group) = errorbar((group-1)/2+(1:numel(y)), y, e, 'Color', [0 0 0], 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});



% Add horizontal Line
end

suptitle('Power During Percepts');
ylabel('Ratio to Trial Average', 'FontSize', 15);
set(gca, 'XTick', [1 3], 'xticklabel', {'Frequency Dominant', 'Frequency Suppressed'});
%     xlim([0 5]);
%     ylim([1 1.2] .* ylim);
plot(get(gca,'xlim'), [1 1], 'Color', 'k');
legend(h, {'CON', 'ASC'});