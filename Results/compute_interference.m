ratiopow = im_to_fun_ratio;

for group = 1:2;
    for subject = 1:n{group}        
        if ratiopow{group}(subject, 1) > 1
            ratiopow{group}(subject, 1) = NaN;
        end
        
    end
end

figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};
linespec_dom{1} = '--ko'; linespec_dom{2} = ':kv';
linespec_sup{1} = '--ro'; linespec_sup{2} = ':rv';
linespec_mix{1} = '--mo'; linespec_mix{2} = '--mv';

for group = 1:2
    clear y e
    
    y(1) = nanmean(ratiopow{group});
    
    e(1) = nansem(ratiopow{group});
    
    errorbar(group, y, e, 'Color', group_colours{group}, 'LineWidth', 2, 'Marker', 'o', 'MarkerFaceColor', group_colours{group});
    
end

