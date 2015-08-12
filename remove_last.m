function [percept_codes, percept_durs, percept_start] = remove_last(percept_codes, percept_durs, percept_start, trial_dur)

    slack = 0.01;
    
    last_trial_index = percept_durs >= trial_dur - slack;
    
    percept_codes(last_trial_index, :) = [];
    percept_durs(last_trial_index, :) = [];
    percept_start(last_trial_index, :) = [];

end
