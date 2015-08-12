function [green_index, red_index, mix_index] = find_percept_index(percept_codes)
%FIND_PERCEPT_INDEX [green_index, red_index, mix_index] = find_percept_index(percept_codes);
%   just outputs a logical index for each percept

            green_index = ismember(percept_codes, [1 0 0], 'rows');
            red_index = ismember(percept_codes, [0 0 1], 'rows');
            mix_index = ismember(percept_codes, [0 1 0], 'rows') | ismember(percept_codes, [1 1 0], 'rows') |...
                            ismember(percept_codes, [0 1 1], 'rows') | ismember(percept_codes, [1 1 1], 'rows');



end
