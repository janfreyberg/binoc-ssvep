%% Clear everything and establish where data is
clearvars;
clc;
load('buttons_freqs.mat');
if exist('E:\Documents\Recorded Data\EEG Feb 2015', 'dir') % location on desktop
    file_directory = 'E:\Documents\Recorded Data\EEG Feb 2015';
elseif exist('D:\Recorded Data', 'dir') % location on laptop
    file_directory = 'D:\Recorded Data';
elseif exist('C:\EEG Data\mit-data', 'dir')
    file_directory = 'C:\EEG Data\mit-data';
else
    error('please provide directory where file is stored');
end

%% File Names
% filenames{1} = dir([file_directory, '\*CTR*BinSSVEP.bdf']);
% filenames{2} = dir([file_directory, '\*ASC*BinSSVEP.bdf']);
% n{1} = size(filenames{1}, 1);
% n{2} = size(filenames{2}, 1);

n{1} = 1;
filenames{1}(1).name = 'cw_1_020916_.bdf';

%% Analysis Variables
trial_dur = 12;
discard_start = 0.5; % how much time should be cut off at beginning
electrodes = [27, 29];
% electrodes = 1:32;



% group_freqs = cell(2, max([n{1}, n{2}]));

stimulation_frequencies = [5, 8.5];
% harmonic_frequencies = [stimulation_frequencies*2];
% subharmonic_frequencies = [stimulation_frequencies/2];


%% Practice Analysis with one subject
fileID = fullfile(file_directory, filenames{1}(1).name);

% Trial Definition
cfg_trldef.dataset = fileID;
cfg_trldef.trialdef.eventtype = 'STATUS';
cfg_trldef.trialfun = 'ft_trialfun_general';
cfg_trldef.trialdef.prestim = -discard_start;
cfg_trldef.trialdef.poststim = trial_dur;
cfg_trldef.trialdef.eventvalue = 201:216;
cfg_trldef = ft_definetrial(cfg_trldef);
cfg_trldef.trl = remove_overlaps(cfg_trldef);

% Pre-processing
cfg_preproc = cfg_trldef;

cfg_preproc.channel = 1:32;

cfg_preproc.continuous = 'yes';
cfg_preproc.demean = 'yes';
cfg_preproc.detrend = 'yes';
cfg_preproc.reref = 'no';
% cfg_preproc.refchannel = 1:64;
% cfg_preproc.refchannel = {'01', 'Oz', 'Iz', 'POz'};
cfg_preproc.refchannel = 1:32;

cfg_preproc.bpfilter = 'yes'; % bandpass filter?
cfg_preproc.bpfreq = [2 70]; % bandpass frequencies

cfg_preproc.bsfilter = 'yes'; % bandstop filter?
cfg_preproc.bsfreq = [59 61]; % bandstop frequencies


all_data = ft_preprocessing(cfg_preproc);

% Re-sample if recording was >1024 kHz
% if all_data.fsample > 1024
% cfg_resample.resamplefs = 1024;
% cfg_resample.detrend    = 'no';
% cfg_resample.feedback   = 'no';
% all_data = ft_resampledata(cfg_resample, data);
% end

%% Percept Definition
% Find all Percept Starts
cfg_percdef.dataset = fileID;
cfg_percdef.trialdef.eventtype = 'STATUS';
cfg_percdef.trialfun = 'ft_trialfun_general';
cfg_percdef.trialdef.prestim = 0;
cfg_percdef.trialdef.poststim = 0;
cfg_percdef.trialdef.eventvalue = 1:10;
cfg_percdef = ft_definetrial(cfg_percdef);

for iTrial = 1:16
    
    trial_start = cfg_trldef.trl(iTrial, 1);
    trial_end = cfg_trldef.trl(iTrial, 2);
    
    currPercepts = (cfg_percdef.trl(:, 1) >= trial_start) & (cfg_percdef.trl(:, 1) <= trial_end);
    
    percepts(iTrial).trl = cfg_percdef.trl(currPercepts, :);
    
    percepts(iTrial).type = dec2bin(cfg_percdef.trl(currPercepts, 4)-1) - '0';
    
    percepts(iTrial).start = cfg_percdef.trl(currPercepts, 1);
    
    percepts(iTrial).duration = [percepts(iTrial).start(2:end); trial_end] - percepts(iTrial).start;
    
    percepts(iTrial).start = (percepts(iTrial).start-trial_start) /all_data.fsample;
    
    percepts(iTrial).duration = percepts(iTrial).duration /all_data.fsample;
    
end


%% RLS Analysis
rls_data = all_data;
single_rls(1) = all_data;
single_rls(2) = all_data;
msglength = 0;
for iTrial = 1:16;
    
    fprintf(repmat('\b',1,msglength));
    msg = sprintf('Running RLS - Processing Trial No %d\n', iTrial);
    fprintf(msg);
    msglength = numel(msg);
    
colours = {[83 148 255]/255, [255 117 117]/255};
rls_data.trial{iTrial} = zeros(size(rls_data.trial{iTrial}));

% Fundamental Stimulation Frequency
for iFreq = stimulation_frequencies
    j = find(iFreq==stimulation_frequencies);
    cfg_rls.n_cycles = (trial_dur - discard_start) * iFreq;
    cfg_rls.stim_freq = iFreq;
    cfg_rls.channel = 22;
    
    [single_rls(j).trial{iTrial}, single_rls(j).amp{iTrial}] = rls_slave( cfg_rls, all_data.trial{iTrial} );
    
    rls_data.trial{iTrial} = rls_data.trial{iTrial} + single_rls(j).trial{iTrial};
end

% Smooth the Amplitude Estimate
% for j = 1:2
%     
%     bin_edges = single_rls(j).time{iTrial}(1):(5/1000):single_rls(j).time{iTrial}(end);
%     
%     for iBin = 2:numel(bin_edges)
%         
%         currBin = single_rls(j).time{iTrial} < bin_edges(iBin) & single_rls(j).time{iTrial} > bin_edges(iBin-1);
%         
%         single_rls(j).smooth_amp{iTrial}(:, iBin) = mean( single_rls(j).amp{iTrial}(:, currBin), 2 );
%         
%     end
%     single_rls(j).smooth_time{iTrial} = bin_edges(2:end);
% end
% 
% figure(1); hold on;
% plot(bin_edges, single_rls(1).smooth_amp{iTrial}, 'r');
% plot(bin_edges, single_rls(2).smooth_amp{iTrial}, 'g');


% % Harmonics
% for iFreq = harmonic_frequencies
%     
%     j = find(iFreq==harmonic_frequencies);
%     cfg_rls.n_cycles = (trial_dur - discard_start) * iFreq;
%     cfg_rls.stim_freq = iFreq;
%     cfg_rls.channel = 29;
%     
%     [single_rls_harm(j).trial{iTrial}, single_rls_harm(j).amp{iTrial}] = rls_slave( cfg_rls, all_data.trial{iTrial} );
% 
% end
% 
% % Sub-Harmonics
% for iFreq = subharmonic_frequencies
%     
%     j = find(iFreq==subharmonic_frequencies);
%     cfg_rls.n_cycles = (trial_dur - discard_start) * iFreq;
%     cfg_rls.stim_freq = iFreq;
%     cfg_rls.channel = 29;
%     
%     [single_rls_sub(j).trial{iTrial}, single_rls_sub(j).amp{iTrial}] = rls_slave( cfg_rls, all_data.trial{iTrial} );
% end

end


%% FFT Analysis
% compare the FFT amplitude between RLS estimate and raw data 
cfg_fft = [];
cfg_fft.continuous = 'yes';
cfg_fft.output = 'pow';
cfg_fft.method = 'mtmfft';
cfg_fft.keeptrials = 'no';
cfg_fft.foilim = [0 60];
cfg_fft.tapsmofrq = 0.09;
cfg_fft.channel = 1:32;

freqs_raw = ft_freqanalysis(cfg_fft, all_data);
freqs_rls = ft_freqanalysis(cfg_fft, rls_data);

figure;
for iTrial = 1:16
    subplot(4, 4, iTrial); hold on;
    plot(freqs_raw.freq, squeeze(mean(freqs_raw.powspctrm(iTrial, :, :), 2)), 'Color', colours{1});
    plot(freqs_rls.freq, squeeze(mean(freqs_rls.powspctrm(iTrial, :, :), 2)), 'Color', colours{2});
    ylim([0, 1]);
    xlim([0, max([10, stimulation_frequencies])+10]);
end

return;

figure; hold on;
for iTrial = 1:16;
    
    for iFreq = 1:2
        x = freqs_rls.powspctrm(iTrial, 1, find(freqs_rls.freq>stimulation_frequencies(iFreq), 1));
        y = mean( single_rls(iFreq).amp{iTrial}(1, :) );
        scatter(x, y, [], colours{iFreq});
    end
end

%% SNR

for iFreq = 1:2
    
    snr(iFreq, 1:32) = ...
        freqs_raw.powspctrm(iTrial, :, find(freqs_raw.freq>stimulation_frequencies(iFreq), 1))...
        ./median(freqs_raw.powspctrm(iTrial, :, (freqs_raw.freq>stimulation_frequencies(iFreq)-3 & freqs_raw.freq<stimulation_frequencies(iFreq)+3)), 3);
    
    
end

return;

figure;
for iElec = 1:32
    
    subplot(4, 8, iElec);
    plot(freqs_raw.freq, squeeze( mean(freqs_raw.powspctrm(:, iElec, :), 1)) );
    ylim([0, 1]);
    xlim([2, 10]);
    
end

return;

%% TFR Analysis
cfg_tfr = [];
cfg_tfr.channel = 29;
cfg_tfr.foi = [subharmonic_frequencies, stimulation_frequencies, harmonic_frequencies];
% cfg_tfr.foi = [21.61, 21.59]; %intermodulation freqs
cfg_tfr.toi = discard_start:0.05:12;
cfg_tfr.keeptrials = 'yes'; % this makes sure all trials are separate

cfg_tfr.method = 'mtmconvol';
cfg_tfr.taper = 'hanning';
cfg_tfr.t_ftimwin = 0.1 * ones(size(cfg_tfr.foi));

% cfg_tfr.method = 'wavelet';
% cfg_tfr.width = 16;


tfr_raw = ft_freqanalysis(cfg_tfr, all_data);
tfr_rls = ft_freqanalysis(cfg_tfr, rls_data);

for iFreq = 1:2
    tfr_single_freq{iFreq} = ft_freqanalysis(cfg_tfr, single_rls(iFreq));
end

%% Some Plotting

% figure; 
% subplot(3, 1, 1); hold on;
% x = tfr_raw.time;
% y1 = squeeze(tfr_raw.powspctrm(1, 1, :));
% y2 = squeeze(tfr_raw.powspctrm(1, 2, :));
% plot(x, y1, 'Color', colours{1});
% plot(x, y2, 'Color', colours{2});
% 
% 
% subplot(3, 1, 2); hold on;
% x = tfr_rls.time;
% y1 = squeeze(tfr_rls.powspctrm(1, 1, :));
% y2 = squeeze(tfr_rls.powspctrm(1, 2, :));
% plot(x, y1, 'Color', colours{1});
% plot(x, y2, 'Color', colours{2});
% 
% subplot(3, 1, 3); hold on;
% x = tfr_single_freq{1}.time;
% y1 = squeeze(tfr_single_freq{1}.powspctrm(1, 1, :));
% y2 = squeeze(tfr_single_freq{2}.powspctrm(1, 2, :));
% plot(x, y1, 'Color', colours{1});
% plot(x, y2, 'Color', colours{2});

% figure;
% hold on;
% for iTrial = 1:16
%     subplot(4, 4, iTrial); hold on;
%     includeTime = tfr_single_freq{1}.time > 0.5;
%     x = squeeze(tfr_single_freq{1}.powspctrm(iTrial, 1, 1, includeTime));
%     y = squeeze(tfr_single_freq{2}.powspctrm(iTrial, 1, 2, includeTime));
%     scatter(x, y);
%     lsline;
% end
% 
% figure;
% hold on;
% for iTrial = 1:16
%     subplot(4, 4, iTrial); hold on;
%     
% %     includeTime = single_rls(j).smooth_time{iTrial} > 1;
%     
%     x = squeeze(single_rls(1).amp{iTrial}(29, :));
%     
% %     y = squeeze(single_rls(2).smooth_amp{iTrial}(29, includeTime));
%     
%     y = single_rls_sub(1).amp{iTrial}(29, :);
%     
%     scatter(x, y);
%     lsline;
% end




%% Amplitude during Percepts

cfg_trl_tfr = [];
figure;

for iTrial = 1:16
    
    % Left Trials
    left_index = percepts(iTrial).type(:, 1) & ~( percepts(iTrial).type(:, 2) | percepts(iTrial).type(:, 3) );
    right_index = percepts(iTrial).type(:, 3) & ~( percepts(iTrial).type(:, 2) | percepts(iTrial).type(:, 1) );
    mid_index = ~( left_index | right_index );
    
    % Empty the time point logicals
    left_time_points = false(size(single_rls(1).time{iTrial}));
    right_time_points = false(size(single_rls(1).time{iTrial}));
    mid_time_points = false(size(single_rls(1).time{iTrial}));
    
    % Go through each type of percept and index the time points within them
    for t = find(left_index)';
        left_time_points = single_rls(1).time{iTrial} >= percepts(iTrial).start(t) & ...
                            single_rls(1).time{iTrial} < percepts(iTrial).start(t) + percepts(iTrial).duration(t) | ...
                            left_time_points;
    end
    for t = find(right_index)';
        right_time_points = single_rls(1).time{iTrial} >= percepts(iTrial).start(t) & ...
                            single_rls(1).time{iTrial} < percepts(iTrial).start(t) + percepts(iTrial).duration(t) | ...
                            right_time_points;
    end
    for t = find(mid_index)';
        mid_time_points = single_rls(1).time{iTrial} >= percepts(iTrial).start(t) & ...
                            single_rls(1).time{iTrial} < percepts(iTrial).start(t) + percepts(iTrial).duration(t) | ...
                            mid_time_points;
    end
    
    % On a trial-by-trial basis, was A or B higher or lower during LEFT or
    % RIGHT
    amp_28_left = mean( single_rls(1).amp{iTrial}(29, left_time_points) ) - mean(single_rls(1).amp{iTrial}(29, :));
    amp_28_right = mean( single_rls(1).amp{iTrial}(29, right_time_points) ) - mean(single_rls(1).amp{iTrial}(29, :));
    amp_36_left = mean( single_rls(2).amp{iTrial}(29, left_time_points) ) - mean(single_rls(2).amp{iTrial}(29, :));
    amp_36_right = mean( single_rls(2).amp{iTrial}(29, right_time_points) ) - mean(single_rls(2).amp{iTrial}(29, :));
    
    subplot(4, 4, iTrial); hold on;
    plot([1, 2], [amp_28_left, amp_28_right], 'Color', colours{1});
    plot([1, 2], [amp_36_left, amp_36_right], 'Color', colours{2});
    
    
end

