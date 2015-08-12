function [total_green, total_red, total_mix] = identify_totals(percept_durs, green_index, red_index, mix_index)
%IDENTIFY_TOTALS [total_green, total_red, total_mix] = identify_totals(percept_durs, green_index, red_index, mix_index)
%   This function just adds up all the total percept durations

        total_green = sum(percept_durs( green_index ));
        total_red = sum(percept_durs( red_index ));
        total_mix = sum(percept_durs( mix_index ));



end
