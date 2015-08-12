function [percept_codes, percept_durs, percept_start] = remove_tooshort(percept_codes, percept_durs, percept_start, min_percept_dur)

    too_short_index = percept_durs < min_percept_dur;
    percept_codes(too_short_index, :) = [];
    percept_durs(too_short_index, :) = [];
    percept_start(too_short_index, :) = [];

end
