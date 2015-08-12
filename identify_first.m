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
