figure;
hold on;
group_colours = {[83 148 255]/255, [255 117 117]/255};

for group = 1:2
    
    x = postOne_mix_av{group};
    y = mean_mix{group};
    
    scatter( x, y, 'Marker', 'o', 'MarkerFaceColor', group_colours{group}, 'MarkerEdgeColor', group_colours{group} );
    
end