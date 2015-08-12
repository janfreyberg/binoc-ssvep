function [unique_code, unique_secs] = create_unique_list(button_codes, button_secs)
%CREATE_UNIQUE_LIST [button_codes, button_secs] = create_unique_list(button_codes, button_secs);
%   This removes duplicates

excess_samples = button_secs < 0;
            
duplicate_index = [false; all(button_codes(2:end, 1:3)==button_codes(1:end-1, 1:3), 2)];
            
unique_code = button_codes(~duplicate_index & ~excess_samples, 1:3);
unique_secs = button_secs(~duplicate_index & ~excess_samples, 1);


end
