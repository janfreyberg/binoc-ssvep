
%% Setup!
%#ok<*AGROW>
%#ok<*SAGROW>
 %#ok<*NASGU>
clearvars;
clc;
load('buttons_freqs.mat');
if exist('E:\Documents\Recorded Data\EEG Feb 2015', 'dir') % location on desktop
    file_directory = 'E:\Documents\Recorded Data\EEG Feb 2015';
elseif exist('D:\Recorded Data', 'dir') % location on laptop
    file_directory = 'D:\Recorded Data';
elseif exist('/Users/jan/Documents/Recorded Data/', 'dir')
    file_directory = '/Users/jan/Documents/Recorded Data/';
else
    error('please provide directory where file is stored');
end

%% File Names
filenames{1} = dir(fullfile(file_directory, '*CTR*BinSSVEP.bdf'));
filenames{2} = dir(fullfile(file_directory, '*ASC*BinSSVEP.bdf'));
n{1} = size(filenames{1}, 1);
n{2} = size(filenames{2}, 1);

%% Global Variables
trial_dur = 12;
plotting = 0;
% if isempty(gcp('nocreate'))
%     try
%         parpool(4);
%     catch par_comp_err
%         warning(par_comp_err.message);
%     end
% end
remove_subject{1} = false(n{1}, 1);
remove_subject{2} = false(n{2}, 1);
% Electrodes
electrodes = [27, 29, 30, 64];
% electrodes = 1:64;
shiftsize = -0; % The time you want EEG data to be shifted relative to Behavioural Data


%% Loop Through Group and Subjects
for group = 1:1
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
    
    %% Preprocessing
        cfg_preproc = cfg;
        cfg_preproc.channel = 1:64;
        cfg_preproc.continuous = 'yes';
        cfg_preproc.demean    = 'yes';
        cfg_preproc.detrend = 'no';
        cfg_preproc.reref = 'yes';
        cfg_preproc.refchannel = 1:64;
        all_data = ft_preprocessing(cfg_preproc);
    
    %% TFR
    cfg_tfr = [];
    cfg_tfr.method = 'wavelet';
    cfg_tfr.channel = electrodes;
    cfg_tfr.width = 16;
    cfg_tfr.foi = [28.8, 36];
    cfg_tfr.toi = -3:0.05:12;
    cfg_tfr.keeptrials = 'yes'; % this makes sure all trials are separate
    
    freqs = ft_freqanalysis(cfg_tfr, all_data);
    
    
    %% Make a field in freqs that has info on button press
    
    freqs.dom36 = squeeze( false(size( freqs.powspctrm(:, 1, 1, :) )));
    freqs.dom28 = squeeze( false(size( freqs.powspctrm(:, 1, 1, :) )));
    freqs.mix = squeeze( false(size( freqs.powspctrm(:, 1, 1, :) )));
    
    for trialNo = 1:16
        
        if isequal(buttons_freqs(official_ID).flickerOrder(:, trialNo), buttons_freqs(official_ID).angleOrder(:, trialNo))
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        else
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        end
        
        for iPerc = find(ssvep_index_36)'
            if isempty(iPerc)
                break;
            end
            freqs.dom36( trialNo, freqs.time > percepts(trialNo).start(iPerc) & freqs.time > percepts(trialNo).start(iPerc)+percepts(trialNo).duration(iPerc) )=...
                true;
        end
        for iPerc = find(ssvep_index_28)'
            if isempty(iPerc)
                break;
            end
            freqs.dom28( trialNo, freqs.time > percepts(trialNo).start(iPerc) & freqs.time > percepts(trialNo).start(iPerc)+percepts(trialNo).duration(iPerc) )=...
                true;
        end
        for iPerc = find(ssvep_index_mix)'
            if isempty(iPerc)
                break;
            end
            freqs.mix( trialNo, freqs.time > percepts(trialNo).start(iPerc) & freqs.time > percepts(trialNo).start(iPerc)+percepts(trialNo).duration(iPerc) )=...
                true;
        end
        
    end
    
    
    
    %% Average Over Mixed and Dominant Percepts
    
    postWhole_dom = [];
    postWhole_sup = [];
    postWhole_mix = [];
    
    for trialNo = 1:16
        
        if isequal(buttons_freqs(official_ID).flickerOrder(:, trialNo), buttons_freqs(official_ID).angleOrder(:, trialNo))
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        else
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        end
        
        temp_freqs = freqs;
        temp_freqs.powspctrm = permute(freqs.powspctrm(trialNo, :, :, :), [2 3 4 1]);
        
        % First Whenever Freq 36 Was Dominant
        [sup_28, dom_36] = average_across_timebins(temp_freqs, electrodes, percepts(trialNo).start(ssvep_index_36)+shiftsize, percepts(trialNo).duration(ssvep_index_36));
        % Now Whenever Freq 28 Was Dominant
        [dom_28, sup_36] = average_across_timebins(temp_freqs, electrodes, percepts(trialNo).start(ssvep_index_28)+shiftsize, percepts(trialNo).duration(ssvep_index_28));
        % Now whenever people reported mixture
        [mix_28, mix_36] = average_across_timebins(temp_freqs, electrodes, percepts(trialNo).start(ssvep_index_mix)+shiftsize, percepts(trialNo).duration(ssvep_index_mix));
        
        diff_mix = mix_28 - mix_36;
        
        
        postWhole_dom = [postWhole_dom, (dom_36), (dom_28)];
        postWhole_sup = [postWhole_sup, (sup_36), (sup_28)];
        postWhole_mix = [postWhole_mix, (mix_28), (mix_36)];
        
        
    end
    % store for group
    postWhole_dom_av{group}(subject, :) = nanmean( nanmean( postWhole_dom, 1 ), 2 );
    postWhole_sup_av{group}(subject, :) = nanmean( nanmean( postWhole_sup, 1 ), 2 );
    postWhole_mix_av{group}(subject, :) = nanmean( nanmean( postWhole_mix, 1 ), 2 );
    
    
    %% Average Over One Sec of Mixed and Dominant Percepts
    
    
    postOne_dom = [];
    postOne_sup = [];
    postOne_mix = [];
    
    for trialNo = 1:16
        
        if isequal(buttons_freqs(official_ID).flickerOrder(:, trialNo), buttons_freqs(official_ID).angleOrder(:, trialNo))
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        else
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        end
        
        temp_freqs = freqs;
        temp_freqs.powspctrm = permute(freqs.powspctrm(trialNo, :, :, :), [2 3 4 1]);
        
        % First Whenever Freq 36 Was Dominant
        [sup_28, dom_36] = average_across_timebins(temp_freqs, electrodes, percepts(trialNo).start(ssvep_index_36)+shiftsize, ones(size(percepts(trialNo).duration(ssvep_index_36))));
        % Now Whenever Freq 28 Was Dominant
        [dom_28, sup_36] = average_across_timebins(temp_freqs, electrodes, percepts(trialNo).start(ssvep_index_28)+shiftsize, ones(size(percepts(trialNo).duration(ssvep_index_28))));
        % Now whenever people reported mixture
        [mix_28, mix_36] = average_across_timebins(temp_freqs, electrodes, percepts(trialNo).start(ssvep_index_mix)+shiftsize, ones(size(percepts(trialNo).duration(ssvep_index_mix))));
        
        diff_mix = mix_28 - mix_36;
        
        
        postOne_dom = [postOne_dom, (dom_36), (dom_28)];
        postOne_sup = [postOne_sup, (sup_36), (sup_28)];
        postOne_mix = [postOne_mix, (mix_28), (mix_36)];
        
        
    end
    % store for group
    postOne_dom_av{group}(subject, :) = nanmean( nanmean( postOne_dom, 1 ), 2 );
    postOne_sup_av{group}(subject, :) = nanmean( nanmean( postOne_sup, 1 ), 2 );
    postOne_mix_av{group}(subject, :) = nanmean( nanmean( postOne_mix, 1 ), 2 );
    
    
    %% Average Time Bins Across Mixed and Dominant Percepts
    nbins = 10;
    for i = 1:nbins;
        dom_binned{i} = [];
        sup_binned{i} = [];
    end
    
    for trialNo = 1:16
        
        if isequal(buttons_freqs(official_ID).flickerOrder(:, trialNo), buttons_freqs(official_ID).angleOrder(:, trialNo))
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        else
            ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
            ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
            ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
            all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
        end
        
        temp_freqs = freqs;
        temp_freqs.powspctrm = permute(freqs.powspctrm(trialNo, :, :, :), [2 3 4 1]);
        
        
        for i = 1:10
            [sup_28, dom_36] = average_across_timebins(temp_freqs, electrodes,...
                percepts(trialNo).start(ssvep_index_36)+shiftsize + percepts(trialNo).duration(ssvep_index_36)*(i-1)/10, percepts(trialNo).duration(ssvep_index_36)*0.1 );
            
            [dom_28, sup_36] = average_across_timebins(temp_freqs, electrodes,...
                percepts(trialNo).start(ssvep_index_28)+shiftsize + percepts(trialNo).duration(ssvep_index_28)*(i-1)/10, percepts(trialNo).duration(ssvep_index_28)*0.1 );
            
            dom_binned{i} = [dom_binned{i}, (dom_36), (dom_28)];
            sup_binned{i} = [sup_binned{i}, (sup_36), (sup_28)];
        end
        
    end
    
    for i = 1:10
        dom_bin_av{group}(subject, i) = mean(dom_binned{i});
        sup_bin_av{group}(subject, i) = mean(sup_binned{i});
    end
    
    
    %% Analyse Deviation from mean
    
    concat_diffs = [];
    concat_temp_powspctrm = [];
    all_samples{group, subject} = [];
    for trialNo = 1:16
        
        
        temp_freqs = freqs;
        temp_freqs.powspctrm = permute(freqs.powspctrm(trialNo, :, :, :), [2 3 4 1]);
        
        % Average across electrodes
%         temp_powspctrm = nanmean( temp_freqs.powspctrm( :, :, : ), 1 );
        
        for frequency_of_interest = 1:2
            
            mu = nanmean( temp_freqs.powspctrm( :, frequency_of_interest, temp_freqs.time > 0.5 & temp_freqs.time < 12 ), 3 );
            sd = nanstd( temp_freqs.powspctrm( :, frequency_of_interest, temp_freqs.time > 0.5 & temp_freqs.time < 12 ), [], 3 );
            
            % Normalisation
            for iElec = 1:size( temp_freqs.powspctrm, 1 )
                temp_freqs.powspctrm( iElec, frequency_of_interest, :) = (temp_freqs.powspctrm( iElec, frequency_of_interest, :)) / mu(iElec);
            end
            
        end
        trialtime = temp_freqs.time > 0.5 & temp_freqs.time < 12;
        all_samples{group, subject} = [all_samples{group, subject}, squeeze(nanmean(temp_freqs.powspctrm(:, :, temp_freqs.time > 0.5 & temp_freqs.time < 12), 1))];
        
        diffs_by_elec(:, :, :, trialNo) = temp_freqs.powspctrm(:, 1, :) - temp_freqs.powspctrm(:, 2, :);
        wtas_by_elec(:, :, :, trialNo) = abs(temp_freqs.powspctrm(:, 1, :) - temp_freqs.powspctrm(:, 2, :)) ./ (temp_freqs.powspctrm(:, 1, :) + temp_freqs.powspctrm(:, 2, :));
        
%         wta_by_elec_mix(:, :, :, trialNo) = abs(temp_freqs.powspctrm(:, 1, freqs.mix(trialNo, :)) - temp_freqs.powspctrm(:, 2, freqs.mix(trialNo, :))) ./ (temp_freqs.powspctrm(:, 1, freqs.mix(trialNo, :)) + temp_freqs.powspctrm(:, 2, freqs.mix(trialNo, :)));
        
    end
    
    index_mix_wta = permute(freqs.mix, [3 4 2 1]);
    for iElec = 1:numel(electrodes)-1
        index_mix_wta = cat(1, index_mix_wta, permute(freqs.mix, [3 4 2 1]));
    end
    index_dom_wta = permute(freqs.dom28 | freqs.dom36, [3 4 2 1]);
    for iElec = 1:numel(electrodes)-1
        index_dom_wta = cat(1, index_dom_wta, permute(freqs.dom28 | freqs.dom36, [3 4 2 1]));
    end
    
    wta{group}(subject, 1) = squeeze(nanmean( nanmean( nanmean( wtas_by_elec(:, :, trialtime, :), 3 ), 1), 4));
    wta_mix{group}(subject, 1) = squeeze(nanmean( nanmean( nanmean( wtas_by_elec(index_mix_wta), 3 ), 1), 4));
    wta_dom{group}(subject, 1) = squeeze(nanmean( nanmean( nanmean( wtas_by_elec(index_dom_wta), 3 ), 1), 4));
    
    difference_SD{group}(subject, 1) = squeeze(nanmean( nanmean( nanstd( diffs_by_elec, [], 3 ), 1), 4));
    difference_mix{group}(subject, 1) = squeeze(nanmean( nanmean( nanmean( abs(diffs_by_elec(index_mix_wta)), 3 ), 1), 4));
    difference_dom{group}(subject, 1) = squeeze(nanmean( nanmean( nanmean( abs(diffs_by_elec(index_dom_wta)), 3 ), 1), 4));
    
%     for iElec = 1:64
%     difference_dom_by_elec{group, subject}(1, iElec) =...
%         squeeze(nanmean( abs(diffs_by_elec(iElec, index_dom_wta(iElec, :, :, :))) ));
%     end

    %% Analyse the time IMMEDIATELY before and after a dominant percept
%     prepare variables
%     
%     pre500_dom = [];
%     pre500_sup = [];
%     post500_dom = [];
%     post500_sup = [];
%     
%     Loop through trials
%     for trialNo = 1:16
%         
%         if isequal(buttons_freqs(official_ID).flickerOrder(:, trialNo), buttons_freqs(official_ID).angleOrder(:, trialNo))
%             ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
%             ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
%             ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
%             all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
%         else
%             ssvep_index_28 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).cw_index;
%             ssvep_index_36 = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).ccw_index;
%             ssvep_index_mix = percepts(trialNo).start > 1 & percepts(trialNo).duration > 0.15 & percepts(trialNo).mix_index;
%             all_percepts = ssvep_index_36 | ssvep_index_28 | ssvep_index_mix;
%         end
%         
%         500 ms BEFORE dominant percepts
%         
%         Freq 36 Was Dominant
%         [sup_28, dom_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_36), -0.5*ones(size(percepts(trialNo).start(ssvep_index_36))));
%         Freq 28 Was Dominant
%         [dom_28, sup_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_28), -0.5*ones(size(percepts(trialNo).start(ssvep_index_28))));
%         
%         pre500_dom = [pre500_dom, dom_36, dom_28];
%         pre500_sup = [pre500_sup, sup_36, sup_28];
%         
%         500 ms AFTER dominant percepts
%         
%         Freq 36 Was Dominant
%         [sup_28, dom_36] = ...
%             average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_36) + percepts(trialNo).duration(ssvep_index_36), 0.5*ones(size(percepts(trialNo).start(ssvep_index_36))));
%         Freq 28 Was Dominant
%         [dom_28, sup_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_28) + percepts(trialNo).duration(ssvep_index_28), 0.5*ones(size(percepts(trialNo).start(ssvep_index_28))));
% 
%         
%         post500_dom = [post500_dom, dom_36, dom_28];
%         post500_sup = [post500_sup, sup_36, sup_28];
%     end
%     
%     store for group
%     pre500_dom_av{group}(subject, 1) = nanmean( pre500_dom );
%     pre500_sup_av{group}(subject, 1) = nanmean( pre500_sup );
%     post500_dom_av{group}(subject, 1) = nanmean( post500_dom );
%     post500_sup_av{group}(subject, 1) = nanmean( post500_sup );


    %% Analyse Correlation between frequencies
%     % concatenate each trial sequence, excluding the first second of a
%     % trial
%     all_samples_36 = [];
%     all_samples_28 = [];
%     for trialNo = 1:16
%         % scale each frequency to the trial mean
%         mean_36 = mean( mean(freqs{trialNo}.powspctrm(:, 2, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), 3);
%         mean_28 = mean( mean(freqs{trialNo}.powspctrm(:, 1, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), 3);
%         normalised_36 = permute( mean(freqs{trialNo}.powspctrm(electrodes, 2, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ) / mean_36, [3, 1, 2]);
%         normalised_28 = permute( mean(freqs{trialNo}.powspctrm(electrodes, 1, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ) / mean_28, [3, 1, 2]);
%         not_normalised_36 = permute( mean(freqs{trialNo}.powspctrm(:, 2, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), [3, 1, 2]);
%         not_normalised_28 = permute( mean(freqs{trialNo}.powspctrm(:, 1, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), [3, 1, 2]);
%         
%         all_samples_36 = [all_samples_36; not_normalised_36];
%         all_samples_28 = [all_samples_28; not_normalised_28];
%     end
%     
%     pearson_r{group}(subject, 1) = corr(all_samples_36, all_samples_28);
    

end
end

return;
plot_percept_avg;
plot_onesec_avg;
plot_timecourse;
plot_wta;
plot_behav;


