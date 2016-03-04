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
electrodes = [27, 29, 64];
% electrodes = 1:64;

stimulation_frequencies = [28.8, 36];
% intermodulation_frequencies = [21.6, 43.2];
intermodulation_frequencies = 21.6;


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
%% Update the progress bar, load psychometric data
    clc; fprintf('Processing: Group %2.0f of 2, Subject %2.0f of %2.0f\n', group, subject, n{group});
    
    fileID = fullfile(file_directory, filenames{group}(subject).name);
    psychometric_fileID = [fileID(1:end-13), '.mat'];
    official_ID = str2double(fileID(end-16:end-13));
    try
        psycho_data = load(psychometric_fileID);
        aq{group}(subject, 1) = psycho_data.AQ;
    catch
        aq{group}(subject, 1) = NaN;
    end
    
    
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

    cfg_trldef.trl = remove_overlaps(cfg_trldef); % this script removes overlapping trials in case triggers got confused

%% Preprocessing

cfg_preproc = cfg_trldef;
cfg_preproc.channel = 1:64;
cfg_preproc.continuous = 'yes';
cfg_preproc.demean    = 'yes';
cfg_preproc.detrend = 'no';
cfg_preproc.reref = 'yes';
cfg_preproc.refchannel = 1:64;
% cfg_preproc.refchannel = [27 28 64 30];

all_data = ft_preprocessing(cfg_preproc);

%% FFT
cfg_fft = [];
cfg_fft.continuous = 'yes';
cfg_fft.output = 'pow';
cfg_fft.method = 'mtmfft';
cfg_fft.foilim = [19.8, 45];
cfg_fft.tapsmofrq = 0.25;
cfg_fft.channel = electrodes;

freqs = ft_freqanalysis(cfg_fft, all_data);
group_freqs{group, subject} = freqs;

%% SSVEP Statistics
for iFreq = 1:2
    
    stimfreq = stimulation_frequencies(iFreq);
    
    signal = freqs.freq<=stimfreq + 0.14 & freqs.freq>=stimfreq - 0.14;
    both_signals = freqs.freq<=stimulation_frequencies(1) + 0.14 & freqs.freq>=stimulation_frequencies(1) - 0.14 &...
                    freqs.freq<=stimulation_frequencies(2) + 0.14 & freqs.freq>=stimulation_frequencies(2) - 0.14;
    
    noise = ~both_signals & (freqs.freq<=max(cfg_fft.foilim) & freqs.freq>=min(cfg_fft.foilim));
    
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

%% Calculate The Power in Intermodulation frequency

for iFreq = 1:numel(intermodulation_frequencies)
    
    imFreq = intermodulation_frequencies(iFreq);
    
    signal = freqs.freq<=imFreq + 0.14 & freqs.freq>=imFreq - 0.14;
    
    noise = ~signal & freqs.freq<=imFreq + 1 & freqs.freq>=imFreq - 1;
    
    amp_by_elec = max(freqs.powspctrm(:, signal), [], 2);
    
    im_average{group}(subject, iFreq) = mean(amp_by_elec);
    
    im_snr{group}(subject, iFreq) = mean(max(freqs.powspctrm(:, signal), [], 2) ./ mean(freqs.powspctrm(:, noise), 2));
    
    im_snr_ratio{group}(subject, iFreq) = im_snr{group}(subject, iFreq) / mean(snr_average{group}(subject, iFreq));
end

im_to_fun_ratio{group}(subject, 1) = mean(im_average{group}(subject, :), 2) ./ mean(amp_average{group}(subject, :), 2);


%% Calculate the average spectrum for each group
        
    amps = mean(freqs.powspctrm(:, :), 1);
    
    spec_average{group}(subject, 1, :) = amps;
    

end % End of participant loop
end % End of group loop

return;

%% Analyse The Data Behaviourally
for group = 1:2
for subject = 1:n{group}

    %% Definition of Trials
    fileID = fullfile(file_directory, filenames{group}(subject).name);
    official_ID = str2double(fileID(end-16:end-13));
    cfg = [];
    cfg.dataset = fileID;
    cfg.channel = electrodes;
    cfg.trialdef.eventtype = 'STATUS';
    cfg.trialfun = 'ft_trialfun_general';
    cfg.trialdef.prestim = 3.5;
    cfg.trialdef.poststim = 12.5; %actual length of trial 12 s
    
        cfg.trialdef.eventvalue = 201:216;

        try
            cfg = ft_definetrial(cfg);
        catch define_trial_error
            cfg.trialdef.eventvalue
            cfg.dataset
            rethrow(define_trial_error);
        end
        
        cfg.trl = remove_overlaps(cfg); % this script removes overlapping trials
        samplefreq = abs(cfg.trl(1, 3)) / cfg.trialdef.prestim;
        offset = abs(cfg.trl(1, 3));
        
    for eventvalue = 201:216
        
        cfg_trial = cfg;
        cfg_trial.trl = cfg.trl( cfg.trl(:,4)==eventvalue, : );
        trial_starts(eventvalue-200) = cfg_trial.trl(1, 1) - cfg_trial.trl(1, 3);
%         trial_data{eventvalue-200} = ft_preprocessing(cfg_trial);
        
    end
    
    %% Behavioural Analysis (from triggers)
    button_data = cell(1, 16);
    load('buttons_freqs.mat', 'buttons_freqs');
    
    % Extract the relevant sequence
    cfg_buttons = [];
    cfg_buttons.dataset = fileID;
    cfg_buttons.trialdef.eventvalue = 1:8;
    cfg_buttons.trialdef.eventtype = 'STATUS';
    cfg_buttons.trialfun = 'ft_trialfun_general';
    try
        cfg_buttons = ft_definetrial(cfg_buttons);
        remove_subject{group}(subject) = 0;
    catch button_define_error
        warning(button_define_error.message);
        remove_subject{group}(subject) = 1;
        continue
    end
    
    % Now analyse trial by trial
    for trialNo = 1:16
        trl_start = trial_starts(trialNo);
        trl_end = trl_start + samplefreq*trial_dur;
        
        button_data{trialNo} = cfg_buttons.trl( cfg_buttons.trl(:, 1) > trl_start & cfg_buttons.trl(:, 1) < trl_end, : );
        if size(button_data{trialNo}, 1) < 1
            break % if no buttons were pressed, this trial needs to be skipped
        end
        
        % convert the second column to real time values (in secs, relative
        % to trial onset)
        button_data{trialNo}(:, 2) = (button_data{trialNo}(:, 2) - trl_start)/samplefreq;
        
        percepts(trialNo).start = button_data{trialNo}(:, 2);
        percepts(trialNo).buttons = dec2bin(button_data{trialNo}(:, 4)-1, 3)-'0';
        
        % clean the buttonpresses (remove doubles)
        [percepts(trialNo).buttons, percepts(trialNo).start] = remove_doublebtns(percepts(trialNo).buttons, percepts(trialNo).start);
        
        % parse the percepts
        [percepts(trialNo).buttons, percepts(trialNo).duration] = parse_percepts(percepts(trialNo).start, percepts(trialNo).buttons, trial_dur);
        
        % clean the percepts
        [percepts(trialNo).buttons, percepts(trialNo).duration, percepts(trialNo).start] = ...
            remove_tooshort(percepts(trialNo).buttons, percepts(trialNo).duration, percepts(trialNo).start, 0.5);
        [percepts(trialNo).buttons, percepts(trialNo).duration, percepts(trialNo).start] = ...
            remove_last(percepts(trialNo).buttons, percepts(trialNo).duration, percepts(trialNo).start, trial_dur);
        
        % determine index for percepts
        [percepts(trialNo).ccw_index, percepts(trialNo).cw_index, percepts(trialNo).mix_index] = find_percept_index(percepts(trialNo).buttons);
    end
    
    % determine median and mean percepts
    all_mix = [];
    all_cw = [];
    all_ccw = [];
    all_dom = [];
    mix_prop = [];
    for trialNo = 1:16
        all_mix = [all_mix; percepts(trialNo).duration(percepts(trialNo).mix_index)];
        all_cw = [all_cw; percepts(trialNo).duration(percepts(trialNo).cw_index)];
        all_ccw = [all_ccw; percepts(trialNo).duration(percepts(trialNo).ccw_index)];
        all_dom = [all_dom; percepts(trialNo).duration(percepts(trialNo).cw_index | percepts(trialNo).ccw_index)];
        mix_prop = [mix_prop; sum(percepts(trialNo).duration(percepts(trialNo).mix_index))/sum(percepts(trialNo).duration(percepts(trialNo).cw_index | percepts(trialNo).ccw_index))];
    end
    
    mix_prop(isinf(mix_prop)) = NaN;
    
    dom_num{group}(subject, 1) = numel(all_dom);
    if dom_num{group}(subject, 1) < 20
        remove_subject{group}(subject) = 1;
    end
    
    if ~isempty(all_cw) && ~isempty(all_ccw)
        bias{group}(subject, 1) = ttest2(all_cw, all_ccw);
    else
        bias{group}(subject, 1) = NaN;
        remove_subject{group}(subject) = 1;
    end
    
    
    mean_mixprop{group}(subject, 1) = nanmean(mix_prop);
    mean_mix{group}(subject, 1) = mean(all_mix);
    median_mix{group}(subject, 1) = median(all_mix);
    mean_dom{group}(subject, 1) = mean(all_dom);
    median_dom{group}(subject, 1) = median(all_dom);

end
end







