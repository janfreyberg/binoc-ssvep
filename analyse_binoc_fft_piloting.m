%% Analyse Binoc with FFT
clearvars;
clc;
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

n{1} = 1;
filenames{1}(1).name = 'jl_1_100216.bdf';
repair_electrodes = {'TP7', 'P9'};

%% Analysis Variables
trial_dur = 12;
discard_start = 0.5; % how much time should be cut off at beginning
% electrodes = [27, 29, 64];
electrodes = [1:32];

stimulation_frequencies = [85/2, 85/3];




for group = 1:1
for subject = 1:n{group}
%% Update the progress bar, load psychometric data
    clc; fprintf('Processing: Group %2.0f of 2, Subject %2.0f of %2.0f\n', group, subject, n{group});
    
    fileID = fullfile(file_directory, filenames{group}(subject).name);
    
    
%% Trial Definition
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


%% Preprocessing

cfg_preproc = cfg_trldef;
cfg_preproc.channel = 1:32;
cfg_preproc.continuous = 'yes';
cfg_preproc.demean    = 'yes';
cfg_preproc.detrend = 'no';
cfg_preproc.reref = 'no';
cfg_preproc.refchannel = 'all';
cfg_preproc.refmethod = 'median';

cfg_preproc.hpfilter = 'yes';
cfg_preproc.hpfreq = 2;

all_data = ft_preprocessing(cfg_preproc);

%% Channel Repair



%% FFT
cfg_fft = [];
cfg_fft.continuous = 'yes';
cfg_fft.output = 'pow';
cfg_fft.method = 'mtmfft';
cfg_fft.foilim = [0, 50];
cfg_fft.tapsmofrq = 0.09;
cfg_fft.channel = electrodes;
cfg_fft.keeptrials = 'no';

freqs = ft_freqanalysis(cfg_fft, all_data);


%% Plot the spectrum

figure;
for iTrial = 1:1;
    
%     subplot(4, 4, iTrial);
    
    plot(freqs.freq, squeeze( freqs.powspctrm(:, :) ));
    
    for iElec = electrodes
        text(35, freqs.powspctrm(iElec, 116), freqs.label(iElec));
    end
    
%     gridxy([5, 12]);
    
%     xlim([3, 10]);
%     ylim([0, 15]);
    
%     gridxy(stimulation_frequencies);
end

%% Plot Spatial Extent
figure;
cfg_plot = [];
cfg_plot.parameter = 'powspctrm';
cfg_plot.xlim = [stimulation_frequencies(2)-0.5, stimulation_frequencies(2)+0.5];
cfg_plot.layout = 'biosemi64.lay';

ft_topoplotTFR(cfg_plot, freqs);



end % End of participant loop
end % End of group loop








