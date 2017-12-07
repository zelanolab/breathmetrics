function [inhale_volumes,exhale_volumes] = find_respiratory_volumes(resp, srate, inhale_onsets, exhale_onsets, inhale_offsets, exhale_offsets)

% estimates the volume of air displaced in all inhales and exhales
% requires zero crosses
% assumes peaks always come first
% assumes respiration has been baseline corrected;


inhale_volumes = zeros(1,length(inhale_onsets));
exhale_volumes = zeros(1,length(exhale_onsets));

for bi = 1:length(inhale_onsets)
    if ~isnan(inhale_offsets(1,bi))
        this_inhale = inhale_onsets(1,bi):inhale_offsets(1,bi);
        inhale_integral = sum(abs(resp(this_inhale)));
        inhale_volumes(1,bi)=inhale_integral;
    else
        inhale_volumes(1,bi)=nan;
    end
end

for bi = 1:length(exhale_onsets)
    if ~isnan(exhale_offsets(1,bi))
        this_exhale = exhale_onsets(1,bi):exhale_offsets(1,bi);
        exhale_integral = sum(abs(resp(this_exhale)));
        exhale_volumes(1,bi)=exhale_integral;
    else
        exhale_volumes(1,bi)=nan;
    end
end

% normalize for different sampling rates
inhale_volumes = (inhale_volumes/srate)*1000;
exhale_volumes = (exhale_volumes/srate)*1000;
