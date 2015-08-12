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
