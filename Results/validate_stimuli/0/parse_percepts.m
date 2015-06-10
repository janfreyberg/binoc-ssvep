function [button_codes, percept_duration] = parse_percepts( button_times, button_codes, max_time )
% [button_codes, percept_duration] = parse_percepts( button_times, button_codes )
%   This script takes time of button onset, and code of which buttons were
%   pressed, and returns the length of a percept, and what that percept
%   was. These are not cleaned, so you need to do cleaning later.

if nargin > 2
    max_time = 16;
end

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

