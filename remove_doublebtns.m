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
