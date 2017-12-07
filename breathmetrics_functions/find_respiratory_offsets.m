function [inhale_offsets,exhale_offsets] = find_respiratory_offsets(this_resp, inhale_onsets, exhale_onsets, inhale_pause_onsets, exhale_pause_onsets)
%FIND_RESPIRATORY_OFFSETS Finds where each inhale and exhale ends
    
inhale_offsets = zeros(size(inhale_onsets));
exhale_offsets = zeros(size(exhale_onsets));

% finding inhale offsets
for bi = 1:length(exhale_onsets)
    if isnan(inhale_pause_onsets(bi))
        inhale_offsets(1,bi) = exhale_onsets(bi);
    else
        inhale_offsets(1,bi) = inhale_pause_onsets(bi);
    end
end

% finding exhale offsets
for bi = 1:length(exhale_onsets)-1
    if isnan(exhale_pause_onsets(bi))
        exhale_offsets(1,bi) = inhale_onsets(bi+1);
    else
        exhale_offsets(1,bi) = exhale_pause_onsets(bi);
    end
end

% last exhale is different because there is no following inhale
final_window = this_resp(exhale_onsets(end):end);
putative_exhale_end = find(final_window>0,1,'first');

% check that there is a real exhale end that it isn't artifact
avg_exhale_len=mean(exhale_offsets(1,1:end-1) - exhale_onsets(1,1:end-1));
lower_lim = avg_exhale_len / 4;
upper_lim = avg_exhale_len * 1.75;
if isempty(putative_exhale_end) || putative_exhale_end < lower_lim || putative_exhale_end > upper_lim
    % end of exhale cannot be calculated
    exhale_offsets(1,end) = nan;
else
    exhale_offsets(1,end) = exhale_onsets(1,end) + putative_exhale_end;
end

