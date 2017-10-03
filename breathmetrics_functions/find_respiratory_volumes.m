function [inhale_volumes,exhale_volumes] = find_respiratory_volumes(resp, srate, inhale_onsets, exhale_onsets)

% estimates the volume of air displaced in all inhales and exhales
% requires zero crosses
% assumes peaks always come first
% assumes respiration has been baseline corrected;

inhale_volumes = zeros(1,length(inhale_onsets));
exhale_volumes = zeros(1,length(inhale_onsets)-1);

for bi = 1:length(exhale_onsets)
    inhale_integral = sum(resp(inhale_onsets(bi):exhale_onsets(bi)));
    inhale_volumes(1,bi)=inhale_integral;
end

for bi = 1:length(exhale_onsets)-1
    exhale_integral = sum(resp(exhale_onsets(bi):inhale_onsets(bi+1)));
    exhale_volumes(1,bi)=exhale_integral;
end

% normalize for different sampling rates
inhale_volumes = (inhale_volumes/srate)*1000;
exhale_volumes = (exhale_volumes/srate)*1000;
