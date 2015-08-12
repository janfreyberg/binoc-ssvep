cfg_topoSNR = [];
cfg_topoSNR.parameter = 'avg';
cfg_topoSNR.layout = 'biosemi64.lay';
cfg_topoSNR.zlim = [0 7];
cfg_topoSNR.commentpos = 'lefttop';
cfg_topoSNR.colorbar = 'EastOutside';

group_names = {'CON', 'ASC'};
trial_names = {'28.8 Hz', '36.0 Hz'};
figure;

for group = 1:2;
    
    
    for iFreq = 1:2;
        cfg_topoSNR.comment = trial_names{iFreq};
        subplot(2, 2, group + 2*(iFreq-1));
        set(gcf, 'Color', 'w');
        
        data_temp_topoSNR = [];
        data_temp_topoSNR.dimord = 'chan_time';
        data_temp_topoSNR.avg = nanmean(snr_electrodes{group}(:, iFreq, 1:64), 1);
        data_temp_topoSNR.avg = squeeze(permute(data_temp_topoSNR.avg, [3, 2, 1]));
        data_temp_topoSNR.avg = cat(3, data_temp_topoSNR.avg, data_temp_topoSNR.avg);
        data_temp_topoSNR.label = freqs.label;
        data_temp_topoSNR.var = zeros(size(data_temp_topoSNR.avg));
        data_temp_topoSNR.time = [0, 1];
        
        ft_topoplotER(cfg_topoSNR, data_temp_topoSNR);
        hold on;
        
        if iFreq == 1
            title(group_names{group}, 'FontSize', 18);
        end
        
    end
%     suptitle(group_names{group});
end

load('colormap_topoplots.mat');

colormap(cmap);

% plot2svg('binoc-topo-SNR.svg');