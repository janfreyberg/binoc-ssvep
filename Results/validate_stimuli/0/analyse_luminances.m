clear all
%#ok<*SAGROW>

fileList = ls('*.mat');
fileNum = size(fileList, 1);

for iSubject = 1:fileNum
    disp(['Processing: ', fileList(iSubject, 17:end-4)]);
    load(fileList(iSubject, :), 'trialData', 'luminanceOrder', 'flickerOrder', 'angleOrder', 'luminances', 'trialdur');
    
    % pre-process data: identify unique events, convert to binary
    for iTrial = 1:numel(trialData);
        
        temp_unique = trialData(iTrial).trigg( trialData(iTrial).trigg~=0 );
        times_unique = trialData(iTrial).pressSecs( trialData(iTrial).trigg~=0 ) - trialData(iTrial).pressSecs(2);
        binary_unique = dec2bin(temp_unique - 1, 3);
        vector_unique = [str2num(binary_unique(:, 1)), str2num(binary_unique(:, 2)), str2num(binary_unique(:, 3))]; %#ok<ST2NM>
        
        button_times{iTrial} = times_unique;
        button_codes{iTrial} = vector_unique;
    end
    
    % non-flickering trials
    stat_trials = flickerOrder(1, :) == 3;
    j = 0;
    for iTrial = find(stat_trials)
        j = j+1;
        [temp_codes, temp_duration] = parse_percepts(button_times{iTrial}, button_codes{iTrial}, trialdur);
        
            % Clean the percepts
            clean_index = true(size(temp_duration));
            clean_index(ismember(temp_codes, [1 0 1], 'rows')) = false;
            clean_index(ismember(temp_codes, [0 0 0], 'rows')) = false;
            clean_index(temp_duration < 0.05) = false;
            
            % Divide into Mixed, Dominant, DomLeft, DomRight
            mix_index = ismember(temp_codes, [0 1 0], 'rows') | ismember(temp_codes, [1 1 0], 'rows')...
                            | ismember(temp_codes, [1 1 1], 'rows') | ismember(temp_codes, [0 1 1], 'rows');
            dom_index = ismember(temp_codes, [1 0 0], 'rows') | ismember(temp_codes, [0 0 1], 'rows');
            lef_index = ismember(temp_codes, [1 0 0], 'rows');
            rig_index = ismember(temp_codes, [0 0 1], 'rows');
            
        mix_percepts{iSubject, 1, j} = temp_duration(mix_index & clean_index);
        dom_percepts{iSubject, 1, j} = temp_duration(dom_index & clean_index);
        
    end
    mix_median(iSubject, 1) = median( [mix_percepts{iSubject, 1, 1}; mix_percepts{iSubject, 1, 2}; mix_percepts{iSubject, 1, 3}; mix_percepts{iSubject, 1, 4}] );
    mix_mean(iSubject, 1) = mean( [mix_percepts{iSubject, 1, 1}; mix_percepts{iSubject, 1, 2}; mix_percepts{iSubject, 1, 3}; mix_percepts{iSubject, 1, 4}] );
    dom_median(iSubject, 1) = median( [dom_percepts{iSubject, 1, 1}; dom_percepts{iSubject, 1, 2}; dom_percepts{iSubject, 1, 3}; dom_percepts{iSubject, 1, 4}] );
    dom_mean(iSubject, 1) = mean( [dom_percepts{iSubject, 1, 1}; dom_percepts{iSubject, 1, 2}; dom_percepts{iSubject, 1, 3}; dom_percepts{iSubject, 1, 4}] );

    
    % luminance trials of flickering
    for iLum = 1:numel(luminances);
        
        flick_lums{iLum} = luminanceOrder == iLum & ~stat_trials;
        
        j = 0;
        for iTrial = find(flick_lums{iLum});
            j = j+1;
            [temp_codes, temp_duration] = parse_percepts(button_times{iTrial}, button_codes{iTrial}, trialdur);

                % Clean the percepts
                clean_index = true(size(temp_duration));
                clean_index(ismember(temp_codes, [1 0 1], 'rows')) = false;
                clean_index(ismember(temp_codes, [0 0 0], 'rows')) = false;
                clean_index(temp_duration < 0.05) = false;

                % Divide into Mixed, Dominant, DomLeft, DomRight
                mix_index = ismember(temp_codes, [0 1 0], 'rows') | ismember(temp_codes, [1 1 0], 'rows')...
                                | ismember(temp_codes, [1 1 1], 'rows') | ismember(temp_codes, [0 1 1], 'rows');
                dom_index = ismember(temp_codes, [1 0 0], 'rows') | ismember(temp_codes, [0 0 1], 'rows');
                lef_index = ismember(temp_codes, [1 0 0], 'rows');
                rig_index = ismember(temp_codes, [0 0 1], 'rows');
            
            mix_percepts{iSubject, 1+iLum, j} = temp_duration(mix_index & clean_index);
            dom_percepts{iSubject, 1+iLum, j} = temp_duration(dom_index & clean_index);
            
            
            
        end
        mix_median(iSubject, 1+iLum) = median( [mix_percepts{iSubject, 1+iLum, 1}; mix_percepts{iSubject, 1+iLum, 2}; mix_percepts{iSubject, 1+iLum, 3}; mix_percepts{iSubject, 1+iLum, 4}] );
        mix_mean(iSubject, 1+iLum) = mean( [mix_percepts{iSubject, 1+iLum, 1}; mix_percepts{iSubject, 1+iLum, 2}; mix_percepts{iSubject, 1+iLum, 3}; mix_percepts{iSubject, 1+iLum, 4}] );
        dom_median(iSubject, 1+iLum) = median( [dom_percepts{iSubject, 1+iLum, 1}; dom_percepts{iSubject, 1+iLum, 2}; dom_percepts{iSubject, 1+iLum, 3}; dom_percepts{iSubject, 1+iLum, 4}] );
        dom_mean(iSubject, 1+iLum) = mean( [dom_percepts{iSubject, 1+iLum, 1}; dom_percepts{iSubject, 1+iLum, 2}; dom_percepts{iSubject, 1+iLum, 3}; dom_percepts{iSubject, 1+iLum, 4}] );

    end
    
    
    
    
    
    
    
end