function [freq28, freq36] = average_across_timebins(freqs, ~, start_times, durations)
%% [freq28, freq36] = average_across_timebins(freqs, electrodes, start_times, durations  )
n_bins = numel(start_times);

if n_bins == 0
    freq28 = [];
    freq36 = [];
    return
end

%% Normalisation
% DECIDE WHAT TO USE



baseline = freqs.time > -3 & freqs.time < 0;
trialtime = freqs.time > 0.5 & freqs.time < 12;

for iElec = 1:size(freqs.powspctrm, 1)
    for iFreq = 1:size(freqs.powspctrm, 2)
%         freqs.powspctrm(iElec, iFreq, :) = freqs.powspctrm(iElec, iFreq, :)-nanmean( freqs.powspctrm(iElec, iFreq, baseline));
        freqs.powspctrm(iElec, iFreq, :) = freqs.powspctrm(iElec, iFreq, :)/nanmean( freqs.powspctrm(iElec, iFreq, trialtime) );
    end
end

% Average across electrodes
temp_powspctrm = nanmean( freqs.powspctrm(:, :, :), 1 );

% Decide what time-segment of the trial to use for normalisation
% this ignores the first second for obvious reasons
% time_index = freqs.time > 0.5 & freqs.time < 12;




% Take SD of this new average across time & mean
% powspctrm_mu_28 = nanmean( temp_powspctrm(1, 1, time_index) );
% powspctrm_sd_28 = nanstd( temp_powspctrm(1, 1, time_index) );
% powspctrm_mu_36 = nanmean( temp_powspctrm(1, 2, time_index) );
% powspctrm_sd_36 = nanstd( temp_powspctrm(1, 2, time_index) );


% Make a normalised power spectrum
% Z-Score transform
% norm_powspctrm(1, 1, :) = (temp_powspctrm(1, 1, :) - powspctrm_mu_28) / (powspctrm_sd_28);
% norm_powspctrm(1, 2, :) = (temp_powspctrm(1, 2, :) - powspctrm_mu_36) / (powspctrm_sd_36);

% Simply divide by the trial mean
% norm_powspctrm(1, 1, :) = temp_powspctrm(1, 1, :) / (powspctrm_mu_28);
% norm_powspctrm(1, 2, :) = temp_powspctrm(1, 2, :) / (powspctrm_mu_36);

% No normalisation at all
% norm_powspctrm(1, 1, :) = temp_powspctrm(1, 1, :);
% norm_powspctrm(1, 2, :) = temp_powspctrm(1, 2, :);


%% Slicing
freq28 = [];
freq36 = [];

for timeSlice = 1:n_bins
    
    t_0 = min([start_times(timeSlice), start_times(timeSlice) + durations(timeSlice)]);
    t_end = max([start_times(timeSlice), start_times(timeSlice) + durations(timeSlice)]);
    
    % %%%%%%%%%%%%%%%%%%
    % Frequency 28
    % %%%%%%%%%%%%%%%%%%
        % cut out relevant sample
        samples = ...
            mean(temp_powspctrm(1, 1, (freqs.time > t_0 & freqs.time < t_end)), 1);
%         samples = ...
%             padarray(samples, [0, 0, 20-size(samples, 3)], NaN, 'post');

        % reshape
        freq28 = [freq28, mean((permute(samples, [1, 3, 2])), 2)];

    % %%%%%%%%%%%%%%%%%%
    % Frequency 36
    % %%%%%%%%%%%%%%%%%%
        % cut out relevant sample
        samples = ...
            mean(temp_powspctrm(1, 2, (freqs.time > t_0 & freqs.time < t_end)), 1);
%         samples = ...
%             padarray(samples, [0, 0, 20-size(samples, 3)], NaN, 'post');


        % reshape
        freq36 = [freq36, mean((permute(samples, [1, 3, 2])), 2)];

end
end
