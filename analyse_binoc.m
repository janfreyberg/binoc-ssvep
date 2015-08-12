function analyse_binoc()
try
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
else
    error('please provide directory where file is stored');
end


%% File Names
filenames{1} = dir([file_directory, '\*CTR*BinSSVEP.bdf']);
filenames{2} = dir([file_directory, '\*ASC*BinSSVEP.bdf']);
n{1} = size(filenames{1}, 1);
n{2} = size(filenames{2}, 1);

%% Global Variables
trial_dur = 12;
plotting = 0;
if isempty(gcp('nocreate'))
    try
        parpool(4);
    catch par_comp_err
        warning(par_comp_err.message);
    end
end
remove_subject{1} = false(n{1}, 1);
remove_subject{2} = false(n{2}, 1);
% Electrodes
electrodes = [27, 29, 30, 64];

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
    cfg.trialdef.prestim = 3;
    cfg.trialdef.poststim = 17; %actual length of trial 12 s
    
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
    
    
    mean_mixprop{group}(subject, 1) = mean(mix_prop);
    mean_mix{group}(subject, 1) = mean(all_mix);
    median_mix{group}(subject, 1) = median(all_mix);
    mean_dom{group}(subject, 1) = mean(all_dom);
    median_dom{group}(subject, 1) = median(all_dom);
    
    %% preprocessing
    for eventvalue = 201:216
        cfg_preproc{eventvalue} = cfg;
        cfg_preproc{eventvalue}.channel = electrodes;
        cfg_preproc{eventvalue}.continuous = 'yes';
        cfg_preproc{eventvalue}.demean    = 'yes';
        cfg_preproc{eventvalue}.detrend = 'no';
        cfg_preproc{eventvalue}.reref = 'no';
%         cfg_preproc{eventvalue}.refchannel = 1:64;
        cfg_preproc{eventvalue}.trl = cfg.trl( cfg.trl(:,4)==eventvalue, : );
    end
    
    parfor eventvalue = 201:216
        trial_data{eventvalue-200} = ft_preprocessing(cfg_preproc{eventvalue});
    end
    
    %% TFR
    cfg_tfr = [];
    cfg_tfr.method = 'wavelet';
    cfg_tfr.width = 16;
    cfg_tfr.foi = [28.8, 36];
    cfg_tfr.toi = -3:0.05:12;
    parfor eventvalue = 1:16
        freqs{eventvalue} = ft_freqanalysis(cfg_tfr, trial_data{eventvalue});
    end
    
    
    %% Average Over Mixed and Dominant Percepts
    
    shiftsize = -0.5; % The time you want EEG data to be shifted relative to Behavioural Data
    
    postWhole_dom = [];
    postWhole_sup = [];
    postWhole_mix = [];
%     byFreq_28 = zeros(3, 16);
%     byFreq_36 = zeros(3, 16);
    
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
        
        
        % First Whenever Freq 36 Was Dominant
        [sup_28, dom_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_36)+shiftsize, percepts(trialNo).duration(ssvep_index_36));
        % Now Whenever Freq 28 Was Dominant
        [dom_28, sup_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_28)+shiftsize, percepts(trialNo).duration(ssvep_index_28));
        % Now whenever people reported mixture
        [mix_28, mix_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_mix)+shiftsize, percepts(trialNo).duration(ssvep_index_mix));
        
        diff_mix = mix_28 - mix_36;
        
        
        postWhole_dom = [postWhole_dom, (dom_36), (dom_28)];
        postWhole_sup = [postWhole_sup, (sup_36), (sup_28)];
        postWhole_mix = [postWhole_mix, (mix_28), (mix_36)];
        
        for i = 1:10
            
            
            [sup_28, dom_36] = average_across_timebins(freqs{trialNo}, electrodes,...
                percepts(trialNo).start(ssvep_index_36)+shiftsize + percepts(trialNo).duration(ssvep_index_36)*(i-1)/10, percepts(trialNo).duration(ssvep_index_36)*0.1 );
            
            [dom_28, sup_36] = average_across_timebins(freqs{trialNo}, electrodes,...
                percepts(trialNo).start(ssvep_index_28)+shiftsize + percepts(trialNo).duration(ssvep_index_28)*(i-1)/10, percepts(trialNo).duration(ssvep_index_28)*0.1 );
            
            postWhole_dom_binned{i} = [postWhole_dom_binned{i}, (dom_36), (dom_28)];
            postWhole_sup_binned{i} = [postWhole_sup_binned{i}, (sup_36), (sup_28)];
        end
        
    end
% store for group
    postWhole_dom_av{group}(subject, :) = nanmean( nanmean( postWhole_dom, 1 ), 2 );
    postWhole_sup_av{group}(subject, :) = nanmean( nanmean( postWhole_sup, 1 ), 2 );
    postWhole_mix_av{group}(subject, :) = nanmean( nanmean( postWhole_mix, 1 ), 2 );
    
    for i = 1:10
        dom_bin_av{group}(subject, i) = mean(postWhole_dom_binned{i});
        sup_bin_av{group}(subject, i) = mean(postWhole_sup_binned{i});
    end
    
%     byFreq_av_28{group}(subject, 1:3) = nanmean(byFreq_28(:, :), 2)';
%     byFreq_av_36{group}(subject, 1:3) = nanmean(byFreq_36(:, :), 2)';
    
    %% Average Time Bins Across Mixed and Dominant Percepts
    nbins = 10;
    for i = 1:nbins;
        postWhole_dom_binned{i} = [];
        postWhole_sup_binned{i} = [];
    end

    
    %% Analyse the time IMMEDIATELY before and after a dominant percept
    % prepare variables
    
    pre500_dom = [];
    pre500_sup = [];
    post500_dom = [];
    post500_sup = [];
    
    % Loop through trials
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
        
        % 500 ms BEFORE dominant percepts
        
        % Freq 36 Was Dominant
        [sup_28, dom_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_36), -0.5*ones(size(percepts(trialNo).start(ssvep_index_36))));
        % Freq 28 Was Dominant
        [dom_28, sup_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_28), -0.5*ones(size(percepts(trialNo).start(ssvep_index_28))));
        
        pre500_dom = [pre500_dom, dom_36, dom_28];
        pre500_sup = [pre500_sup, sup_36, sup_28];
        
        % 500 ms AFTER dominant percepts
        
        % Freq 36 Was Dominant
        [sup_28, dom_36] = ...
            average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_36) + percepts(trialNo).duration(ssvep_index_36), 0.5*ones(size(percepts(trialNo).start(ssvep_index_36))));
        % Freq 28 Was Dominant
        [dom_28, sup_36] = average_across_timebins(freqs{trialNo}, electrodes, percepts(trialNo).start(ssvep_index_28) + percepts(trialNo).duration(ssvep_index_28), 0.5*ones(size(percepts(trialNo).start(ssvep_index_28))));

        
        post500_dom = [post500_dom, dom_36, dom_28];
        post500_sup = [post500_sup, sup_36, sup_28];
    end
    
    % store for group
    pre500_dom_av{group}(subject, 1) = nanmean( pre500_dom );
    pre500_sup_av{group}(subject, 1) = nanmean( pre500_sup );
    post500_dom_av{group}(subject, 1) = nanmean( post500_dom );
    post500_sup_av{group}(subject, 1) = nanmean( post500_sup );
    
    %% Analyse Deviation from mean
    
    concat_diffs = [];
    concat_temp_powspctrm = [];
    for trialNo = 1:16
        
        % Average across electrodes
        temp_powspctrm = nanmean( freqs{trialNo}.powspctrm( :, 1:2, : ), 1 );
        
        for frequency_of_interest = 1:2
            
            mu = nanmean( temp_powspctrm( 1, frequency_of_interest, freqs{trialNo}.time > 0.5 & freqs{trialNo}.time < 12 ), 3 );
            sd = nanstd( temp_powspctrm( 1, frequency_of_interest, freqs{trialNo}.time > 0.5 & freqs{trialNo}.time < 12 ), [], 3 );
            
            % Normalisation
            temp_powspctrm( 1, frequency_of_interest, :) = (temp_powspctrm( 1, frequency_of_interest, :)) / mu;
            
        end
        
        diff_powspctrm = permute( temp_powspctrm( 1, 1, : ) - temp_powspctrm( 1, 2, : ), [1, 3, 2] );
        concat_temp_powspctrm = [concat_temp_powspctrm, permute(temp_powspctrm( 1, :, freqs{trialNo}.time > 0.5 & freqs{trialNo}.time < 12 ), [2, 3, 1])];
        concat_diffs = [concat_diffs, diff_powspctrm(1, freqs{trialNo}.time > 0.5 & freqs{trialNo}.time < 12)];
    end
    
    sd_of_diff{group}(subject, 1) = nanstd(concat_diffs);
    wta{group}(subject, 1) = nanmean( abs(concat_temp_powspctrm(1, :)-concat_temp_powspctrm(2, :))./(concat_temp_powspctrm(1, :)+concat_temp_powspctrm(2, :)) );
    
    %% Analyse Correlation between frequencies
    % concatenate each trial sequence, excluding the first second of a
    % trial
    all_samples_36 = [];
    all_samples_28 = [];
    for trialNo = 1:16
        % scale each frequency to the trial mean
%         mean_36 = mean( mean(freqs{trialNo}.powspctrm(:, 2, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), 3);
%         mean_28 = mean( mean(freqs{trialNo}.powspctrm(:, 1, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), 3);
%         normalised_36 = permute( mean(freqs{trialNo}.powspctrm(electrodes, 2, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ) / mean_36, [3, 1, 2]);
%         normalised_28 = permute( mean(freqs{trialNo}.powspctrm(electrodes, 1, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ) / mean_28, [3, 1, 2]);
        not_normalised_36 = permute( mean(freqs{trialNo}.powspctrm(:, 2, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), [3, 1, 2]);
        not_normalised_28 = permute( mean(freqs{trialNo}.powspctrm(:, 1, (freqs{trialNo}.time > 1 & freqs{trialNo}.time < 12)), 1 ), [3, 1, 2]);
        
        all_samples_36 = [all_samples_36; not_normalised_36];
        all_samples_28 = [all_samples_28; not_normalised_28];
    end
    
    pearson_r{group}(subject, 1) = corr(all_samples_36, all_samples_28);
    
end
end

return;

catch err
    disp(fileID);
    rethrow(err);
end

    %% Plot based on buttons
    % whole percept
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    hold on;
    linespec_dom{1} = '--ko'; linespec_dom{2} = ':kv';
    linespec_sup{1} = '--ro'; linespec_sup{2} = ':rv';
    linespec_mix{1} = '--mo'; linespec_mix{2} = '--mv';
    for group = 1:2
    errorbar(0.8, nanmean(postWhole_dom_av{group}(~remove_subject{group}(1:end))), nansem(postWhole_dom_av{group}(~remove_subject{group})), linespec_dom{group});
    errorbar(1.2, nanmean(postWhole_sup_av{group}(~remove_subject{group}(1:end))), nansem(postWhole_sup_av{group}(~remove_subject{group})), linespec_sup{group});
%     errorbar(1.0, nanmean(postWhole_mix_av{group}(~remove_subject{group}(1:end))), nansem(postWhole_mix_av{group}(~remove_subject{group})), linespec_mix{group});
    
    plot( [0.8, 1.2], [nanmean(postWhole_dom_av{group}(~remove_subject{group}(1:end))), nanmean(postWhole_sup_av{group}(~remove_subject{group}(1:end)))], 'Color', [0.7 0.7 0.7]);
    % Add horizontal Line
    plot(get(gca,'xlim'), [1 1]);
    end
    suptitle('Freq Power Whole Spectrum');
    
    %% Difference between Dom and Sup
    % whole percept
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     figure;
%     hold on;
%     linespec_dom{1} = '--ko'; linespec_dom{2} = ':kv';
%     linespec_sup{1} = '--ro'; linespec_sup{2} = ':rv';
%     linespec_mix{1} = '--mo'; linespec_mix{2} = '--mv';
%     for group = 1:2
%     errorbar(1.2, nanmean(postWhole_sup_av{group}(~remove_subject{group}(1:end))) - nanmean(postWhole_dom_av{group}(~remove_subject{group}(1:end))),...
%         nansem(postWhole_sup_av{group}(~remove_subject{group}) - postWhole_dom_av{group}(~remove_subject{group})), linespec_sup{group});
% %     errorbar(1.0, nanmean(postWhole_mix_av{group}(~remove_subject{group}(1:end))), nansem(postWhole_mix_av{group}(~remove_subject{group})), linespec_mix{group});
%     
%     % Add horizontal Line
%     plot(get(gca,'xlim'), [0 0]);
%     end
%     suptitle('Freq Power Whole Spectrum');
    
    % timecourse over dom percept
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    hold on;
    for group = 1:2
        
        errorbar(1:10, nanmean(dom_bin_av{group}(~remove_subject{group}, :), 1), nansem(dom_bin_av{group}(~remove_subject{group}, :), 1), linespec_dom{group});
        errorbar(1:10, nanmean(sup_bin_av{group}(~remove_subject{group}, :), 1), nansem(sup_bin_av{group}(~remove_subject{group}, :), 1), linespec_sup{group});
        
    end
    figure;
    hold on;
    for group = 1:2
        
        errorbar(1:10, nanmean(dom_bin_av{group}(~remove_subject{group}, :), 1) - nanmean(sup_bin_av{group}(~remove_subject{group}, :), 1),...
            nansem(dom_bin_av{group}(~remove_subject{group}, :) - sup_bin_av{group}(~remove_subject{group}, :), 1), linespec_dom{group});        
    end
    
    % Pre and post dominant percept
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    hold on;
    for group = 1:2
        % first pre
        errorbar(0.8+0.1*group, nanmean(pre500_dom_av{group}(~remove_subject{group})), nansem(pre500_dom_av{group}(~remove_subject{group})), linespec_dom{group});
        errorbar(1.2+0.1*group, nanmean(pre500_sup_av{group}(~remove_subject{group})), nansem(pre500_sup_av{group}(~remove_subject{group})), linespec_sup{group});
        
        % in the middle plot percept average
        errorbar(1.8+0.1*group, nanmean(postWhole_dom_av{group}(~remove_subject{group})), nansem(postWhole_dom_av{group}(~remove_subject{group})), linespec_dom{group});
        errorbar(2.2+0.1*group, nanmean(postWhole_sup_av{group}(~remove_subject{group})), nansem(postWhole_sup_av{group}(~remove_subject{group})), linespec_sup{group});
        
        % next post
        errorbar(2.8+0.1*group, nanmean(post500_dom_av{group}(~remove_subject{group})), nansem(post500_dom_av{group}(~remove_subject{group})), linespec_dom{group});
        errorbar(3.2+0.1*group, nanmean(post500_sup_av{group}(~remove_subject{group})), nansem(post500_sup_av{group}(~remove_subject{group})), linespec_sup{group});
        
        set(gca, 'XTick', [1 2 3], 'XTickLabel', {'500 ms before dom', 'dom percept', '500 ms after dom'});
    end
    suptitle('Freq Power Pre- During- and Post- Dom Percpt');
    
    %% Behavioural result: Dominant and Mixed Percept Duration
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    hold on;
    for group = 1:2
        errorbar(0.8+group*0.1, nanmean(mean_mix{group}(~remove_subject{group})), nansem(mean_mix{group}(~remove_subject{group})), linespec_mix{group} );
        scatter( 0.8+group*0.1*ones(size(mean_mix{group}(~remove_subject{group}))), mean_mix{group}(~remove_subject{group}) );
        errorbar(1.8+group*0.1, nanmean(mean_dom{group}(~remove_subject{group})), nansem(mean_dom{group}(~remove_subject{group})), linespec_dom{group} );
        scatter( 1.8+group*0.1*ones(size(mean_mix{group}(~remove_subject{group}))), mean_dom{group}(~remove_subject{group}) );
    end
    suptitle('Mixed / Dominant Durations');
    
    
    % Stability of the signal
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    marker{1} = 'o'; marker{2} = 'v';
    hold on;
    for group = 1:2
        
        errorbar(0.8+group*0.1, nanmean( nanmean(byTrial_stability{group}(:, 1, :), 3), 1) , nansem( nanmean(byTrial_stability{group}(:, 1, :), 3), 1), marker{group} );
        errorbar(2.8+group*0.1, nanmean( nanmean(byTrial_stability{group}(:, 2, :), 3), 1) , nansem( nanmean(byTrial_stability{group}(:, 2, :), 3), 1), marker{group} );
        
        errorbar(1.8+group*0.1, nanmean( nanmean( nanmean(byTrial_stability{group}(:, :, :), 3), 2), 1) , nansem( nanmean( nanmean(byTrial_stability{group}(:, :, :), 3), 2), 1), marker{group} );
        
    end
    suptitle('"Stability" of signal, SD / MEAN');
    
    % Intra-variability of the signal
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    marker{1} = 'o'; marker{2} = 'v';
    hold on;
    for group = 1:2
        
        errorbar(28.65+group*0.1, nanmean( nanstd(byTrial_mu{group}(:, 1, :), [], 3), 1) , nansem( nanstd(byTrial_mu{group}(:, 1, :), [], 3), 1), marker{group} );
        
        errorbar(35.85+group*0.1, nanmean( nanstd(byTrial_mu{group}(:, 2, :), [], 3), 1) , nansem( nanstd(byTrial_mu{group}(:, 2, :), [], 3), 1), marker{group} );
        
        errorbar(32.25+group*0.1, nanmean( nanmean( nanstd(byTrial_mu{group}(:, :, :), [], 3), 2), 1) , nansem( nanmean( nanstd(byTrial_mu{group}(:, :, :), [], 3), 2), 1), marker{group} );
        
    end
    suptitle('Variability between trials for one individual');
    
    % Variability of the DIFFERENCE of the signal
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    figure;
    marker{1} = 'o'; marker{2} = 'v';
    hold on;
    for group = 1:2
        
        errorbar(group, nanmean( sd_of_diff{group}(~remove_subject{group}) ), nansem( sd_of_diff{group}(~remove_subject{group}) ), marker{group});
        scatter(group*ones(size( sd_of_diff{group}(~remove_subject{group}) )), sd_of_diff{group}(~remove_subject{group}), marker{group});
        
    end
    
    hhh;
    
    % Seperated by frequency
    figure;
    for group = 1:2
    subplot(1, 2, 1); hold on;
    title('28.8 Hz');
    errorbar([1, 2, 3], nanmean(byFreq_av_28{group}, 1), nansem(byFreq_av_28{group}, 1), linespec_dom{group});
    subplot(1, 2, 2); hold on;
    title('36 Hz');
    errorbar([1, 2, 3], nanmean(byFreq_av_36{group}, 1), nansem(byFreq_av_36{group}, 1), linespec_dom{group});
    end
    
    
    
    % suppression index?
    figure;
    hold on;
    for group = 1:2
    suppression_index{group} = postWhole_dom_av{group} ./ postWhole_sup_av{group};
%     bar(group, nanmedian(suppression_index(~remove_subject{group})), 0.4);
    errorbar(group, nanmean(suppression_index{group}(~remove_subject{group})), nansem(suppression_index{group}(~remove_subject{group})), 'o');
    xlim([0, 3]);
    end
    
    % time course around switch
    figure;
    hold on;
    plot( nanmedian(avg_amp_sup{group}( ~remove_subject{group}, : ), 1), 'r' );
    plot( nanmedian(avg_amp_sup{group}( ~remove_subject{group}, : ), 1) - nanstd(avg_amp_sup{1}, 1)/sqrt(size(avg_amp_sup{1}, 1)), 'r:');
    plot( nanmedian(avg_amp_sup{group}( ~remove_subject{group}, : ), 1) + nanstd(avg_amp_sup{1}, 1)/sqrt(size(avg_amp_sup{1}, 1)), 'r:');
    plot( nanmedian(avg_amp_dom{group}( ~remove_subject{group}, : ), 1), 'g' );
    plot( nanmedian(avg_amp_dom{group}( ~remove_subject{group}, : ), 1) - nanstd(avg_amp_dom{1}, 1)/sqrt(size(avg_amp_dom{1}, 1)), 'g:');
    plot( nanmedian(avg_amp_dom{group}( ~remove_subject{group}, : ), 1) + nanstd(avg_amp_dom{1}, 1)/sqrt(size(avg_amp_dom{1}, 1)), 'g:');
    
    % time course across a dominant percept
    figure;
    hold on;
    linespec_dom{1} = '--ko'; linespec_dom{2} = ':kv';
    linespec_sup{1} = '--ro'; linespec_sup{2} = ':rv';
    for group = 1:2
        errorbar(1:10, nanmean(postWhole_dom_binned_av{group}, 1), nansem(postWhole_dom_binned_av{group}, 1), linespec_dom{group} );
        errorbar(1:10, nanmean(postWhole_sup_binned_av{group}, 1), nansem(postWhole_sup_binned_av{group}, 1), linespec_sup{group} );
    end
    figure;
    hold on;
    for group = 1:2
        errorbar( nanmean(postWhole_dom_binned_av{group}-postWhole_sup_binned_av{group}, 1), nansem(postWhole_dom_binned_av{group}-postWhole_sup_binned_av{group}, 1), linespec_dom{group} );
    end
    
    figure;
    hold on;
    plot(nanmean( amps_dom{group, subject}, 1 ), 'k');
    plot(nanmean( amps_sup{group, subject}, 1 ), 'r');
    % add vertical line to mark the switch
    hx = graph2d.constantline(20, 'LineStyle',':', 'Color',[.7 .7 .7]); changedependvar(hx,'x');

end

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

% Average across electrodes
temp_powspctrm = nanmean( freqs.powspctrm(:, :, :), 1 );

% Decide what time-segment of the trial to use for normalisation
% this ignores the first second for obvious reasons
time_index = freqs.time > 1 & freqs.time < 12;




% Take SD of this new average across time & mean
powspctrm_mu_28 = nanmean( temp_powspctrm(1, 1, time_index) );
powspctrm_sd_28 = nanstd( temp_powspctrm(1, 1, time_index) );
powspctrm_mu_36 = nanmean( temp_powspctrm(1, 2, time_index) );
powspctrm_sd_36 = nanstd( temp_powspctrm(1, 2, time_index) );


% Make a normalised power spectrum
% Z-Score transform
% norm_powspctrm(1, 1, :) = (temp_powspctrm(1, 1, :) - powspctrm_mu_28) / (powspctrm_sd_28);
% norm_powspctrm(1, 2, :) = (temp_powspctrm(1, 2, :) - powspctrm_mu_36) / (powspctrm_sd_36);

% Simply divide by the trial mean
norm_powspctrm(1, 1, :) = temp_powspctrm(1, 1, :) / (powspctrm_mu_28);
norm_powspctrm(1, 2, :) = temp_powspctrm(1, 2, :) / (powspctrm_mu_36);

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
            mean(norm_powspctrm(1, 1, (freqs.time > t_0 & freqs.time < t_end)), 1);
%         samples = ...
%             padarray(samples, [0, 0, 20-size(samples, 3)], NaN, 'post');

        % reshape
        freq28 = [freq28, (permute(samples, [1, 3, 2]))];

    % %%%%%%%%%%%%%%%%%%
    % Frequency 36
    % %%%%%%%%%%%%%%%%%%
        % cut out relevant sample
        samples = ...
            mean(norm_powspctrm(1, 2, (freqs.time > t_0 & freqs.time < t_end)), 1);
%         samples = ...
%             padarray(samples, [0, 0, 20-size(samples, 3)], NaN, 'post');


        % reshape
        freq36 = [freq36, (permute(samples, [1, 3, 2]))];

end
end

function trl = remove_overlaps(cfg)

% remove any mistaken trials
kickOut = [];
if size(cfg.trl, 1) > 1
    kickOut(1, 1) = false;
    for i = 2:size(cfg.trl, 1)
        if ~kickOut(i-1, 1) && cfg.trl(i, 1) + cfg.trialdef.prestim*1024 <= cfg.trl(i-1, 1) + cfg.trialdef.prestim*1024 + 12*1024
            kickOut(i, 1) = true; %#ok<*AGROW>
        else
            kickOut(i, 1) = false;
        end
    end
    cfg.trl(logical(kickOut), :) = [];
end

trl = cfg.trl;
end

function [percept_codes, percept_durs, percept_start] = remove_last(percept_codes, percept_durs, percept_start, trial_dur)

    slack = 0.01;
    
    last_trial_index = percept_durs >= trial_dur - slack;
    
    percept_codes(last_trial_index, :) = [];
    percept_durs(last_trial_index, :) = [];
    percept_start(last_trial_index, :) = [];

end

function [percept_codes, percept_durs, percept_start] = remove_tooshort(percept_codes, percept_durs, percept_start, min_percept_dur)

    too_short_index = percept_durs < min_percept_dur;
    percept_codes(too_short_index, :) = [];
    percept_durs(too_short_index, :) = [];
    percept_start(too_short_index, :) = [];

end

function [button_codes, percept_duration] = parse_percepts( button_times, button_codes, max_time )
% [button_codes, percept_duration] = parse_percepts( button_times, button_codes )
%   This script takes time of button onset, and code of which buttons were
%   pressed, and returns the length of a percept, and what that percept
%   was. These are not cleaned, so you need to do cleaning later.


% preallocate for speed
percept_duration = zeros(numel(button_times), 1);

for i = 1:numel(button_times);
    if i < numel(button_times)
        percept_duration(i) = button_times(i+1) - button_times(i);
    elseif i == numel(button_times)
        percept_duration(i) = max_time - button_times(i);
    end
end


end

function [ button_codes, button_seconds ] = remove_doublebtns( button_codes, button_seconds )
%REMOVE_DOUBLEBTNS []remove_doublebtns(
%   Removes any time both dominant buttons were pressed.

% Just take out all the ones with two mixed percepts
two_domin_index = ismember(button_codes, [1 0 1], 'rows');
button_codes(two_domin_index, :) = [];
button_seconds(two_domin_index, :) = [];

% Turn mixed buttons into ONLY mixed buttons
button_codes(logical(button_codes(:, 2)), [1, 3]) = 0;


end

function [total_green, total_red, total_mix] = identify_totals(percept_durs, green_index, red_index, mix_index)
%IDENTIFY_TOTALS [total_green, total_red, total_mix] = identify_totals(percept_durs, green_index, red_index, mix_index)
%   This function just adds up all the total percept durations

        total_green = sum(percept_durs( green_index ));
        total_red = sum(percept_durs( red_index ));
        total_mix = sum(percept_durs( mix_index ));



end

function [ first_right, first_left, first_up, first_l_or_r ] = identify_first( percept_codes, percept_start )
%[first_right, first_left, first_up] = identify_first(percept_codes,
%percept_start)
%   This returns the first time a button was pressed, in seconds. It
%   returns NaN when the button was not pressed this time.

green_index = ismember(percept_codes, [1 0 0], 'rows');
red_index = ismember(percept_codes, [0 0 1], 'rows');
mix_index = ismember(percept_codes, [0 1 0], 'rows') | ismember(percept_codes, [1 1 0], 'rows') |...
            ismember(percept_codes, [0 1 1], 'rows') | ismember(percept_codes, [1 1 1], 'rows');

if any(green_index)
    % green was pressed
    first_left = percept_start( find(green_index, 1, 'first') );
else
    first_left = NaN;
end

if any(red_index)
    % red was pressed
    first_right = percept_start( find(red_index, 1, 'first') );
else
    first_right = NaN;
end

if any(mix_index)
    % Up was pressed
    first_up = percept_start( find(mix_index, 1, 'first') );
else
    first_up = NaN;
end

first_l_or_r = min([first_right, first_left]);

end

function [unique_code, unique_secs] = create_unique_list(button_codes, button_secs)
%CREATE_UNIQUE_LIST [button_codes, button_secs] = create_unique_list(button_codes, button_secs);
%   This removes duplicates

excess_samples = button_secs < 0;
            
duplicate_index = [false; all(button_codes(2:end, 1:3)==button_codes(1:end-1, 1:3), 2)];
            
unique_code = button_codes(~duplicate_index & ~excess_samples, 1:3);
unique_secs = button_secs(~duplicate_index & ~excess_samples, 1);


end

function [green_index, red_index, mix_index] = find_percept_index(percept_codes)
%FIND_PERCEPT_INDEX [green_index, red_index, mix_index] = find_percept_index(percept_codes);
%   just outputs a logical index for each percept

            green_index = ismember(percept_codes, [1 0 0], 'rows');
            red_index = ismember(percept_codes, [0 0 1], 'rows');
            mix_index = ismember(percept_codes, [0 1 0], 'rows') | ismember(percept_codes, [1 1 0], 'rows') |...
                            ismember(percept_codes, [0 1 1], 'rows') | ismember(percept_codes, [1 1 1], 'rows');



end

