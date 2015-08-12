%% Analyse Binoc with FFT
clearvars;
clc;
load('buttons_freqs.mat');
if exist('E:\Documents\Recorded Data\EEG Feb 2015', 'dir') % location on desktop
    file_directory = 'E:\Documents\Recorded Data\EEG Feb 2015';
elseif exist('D:\Recorded Data', 'dir') % location on laptop
    file_directory = 'D:\Recorded Data';
else
    error('please provide directory where file is stored');
end

%% File Names
filenames{1} = dir([file_directory, '\*CTR*BinSSVEP.bdf']);
filenames{2} = dir([file_directory, '\*ASC*BinSSVEP.bdf']);
n{1} = size(filenames{1}, 1);
n{2} = size(filenames{2}, 1);

%% Analysis Variables
trial_dur = 12;
discard_start = 0.5; % how much time should be cut off at beginning
electrodes = [27, 29, 30, 64];
% electrodes = 1:64;
stimulation_frequencies = [28.8, 36];

group_freqs = cell(2, max([n{1}, n{2}]));

% Start parallel pool
% if isempty(gcp('nocreate'))
%     try
%         parpool(4);
%     catch par_comp_err
%         warning(par_comp_err.message);
%     end
% end


for group = 1:2
for subject = 1:n{group}
%% Trial Definition
    fileID = fullfile(file_directory, filenames{group}(subject).name);
    official_ID = str2double(fileID(end-16:end-13));
    cfg_trldef = [];
    cfg_trldef.dataset = fileID;
    cfg_trldef.trialdef.eventtype = 'STATUS';
    cfg_trldef.trialfun = 'ft_trialfun_general';
    cfg_trldef.trialdef.prestim = -discard_start;
    cfg_trldef.trialdef.poststim = trial_dur; %actual length of trial 12 s
    cfg_trldef.trialdef.eventvalue = 201:216;

    try
        cfg_trldef = ft_definetrial(cfg_trldef);
    catch define_trial_error
        cfg_trldef.trialdef.eventvalue
        cfg_trldef.dataset
        rethrow(define_trial_error);
    end

    cfg_trldef.trl = remove_overlaps(cfg_trldef); % this script removes overlapping trials in case triggers got confused

%% Preprocessing

cfg_preproc = cfg_trldef;
cfg_preproc.channel = 1:64;
cfg_preproc.continuous = 'yes';
cfg_preproc.demean    = 'yes';
cfg_preproc.detrend = 'no';
cfg_preproc.reref = 'yes';
cfg_preproc.refchannel = 1:64;


all_data = ft_preprocessing(cfg_preproc);

%% FFT
cfg_fft = [];
cfg_fft.continuous = 'yes';
cfg_fft.output = 'pow';
cfg_fft.method = 'mtmfft';
cfg_fft.foilim = [24.8, 40];
cfg_fft.tapsmofrq = 0.25;
cfg_fft.channel = electrodes;

freqs = ft_freqanalysis(cfg_fft, all_data);
group_freqs{group, subject} = freqs;

%% SSVEP Statistics
for iFreq = 1:2
    
    stimfreq = stimulation_frequencies(iFreq);
    
    signal = freqs.freq<=stimfreq + 0.14 & freqs.freq>=stimfreq - 0.14;
    noise = ~signal & (freqs.freq<=stimfreq + 4 & freqs.freq>=stimfreq - 4);
    
    snr{iFreq} = max(freqs.powspctrm(:, signal), [], 2) ./ mean(freqs.powspctrm(:, noise), 2);
    
    snr_electrodes{group}(subject, iFreq, :) = snr{iFreq};
    
    
    
    snr_average{group}(subject, iFreq) = mean(snr{iFreq});
end

%% Compute the size of the SSVEP

for iFreq = 1:2
    
    stimfreq = stimulation_frequencies(iFreq);
    
    signal = freqs.freq<=stimfreq + 0.14 & freqs.freq>=stimfreq - 0.14;
    
    amps = max(freqs.powspctrm(:, signal), [], 2);
    
    amp_average{group}(subject, iFreq) = mean(amps);
    
end

%% Plot the average spectrum for each group
        
    amps = mean(freqs.powspctrm(:, :), 1);
    
    spec_average{group}(subject, 1, :) = amps;
    



end % End of participant loop
end % End of group loop












