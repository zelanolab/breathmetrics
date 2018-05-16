function [inhaleVolumes,exhaleVolumes] = findRespiratoryVolumes(resp, ...
    srate, inhaleOnsets, exhaleOnsets, inhaleOffsets, exhaleOffsets)

% Estimates the volume of air displaced in all inhales and exhales by 
% calculating the integral of each breath.
% Only valid for airflow data and requires that respiration has been 
% baseline corrected and that inhale onsets and offsets have been 
% computed.

% PARAMETERS:
% resp: respiratory trace (1xN vector)
% srate: sampling rate
% inhaleOnsets: inhale onsets
% inhaleOffsets: inhale offsets
% exhaleOnsets: exhale onsets
% exhaleOffsets: exhale offsets

inhaleVolumes = zeros(1,length(inhaleOnsets));
exhaleVolumes = zeros(1,length(exhaleOnsets));

for bi = 1:length(inhaleOnsets)
    if ~isnan(inhaleOffsets(1,bi))
        thisInhale = inhaleOnsets(1,bi):inhaleOffsets(1,bi);
        inhaleIntegral = sum(abs(resp(thisInhale)));
        inhaleVolumes(1,bi)=inhaleIntegral;
    else
        inhaleVolumes(1,bi)=nan;
    end
end

for bi = 1:length(exhaleOnsets)
    if ~isnan(exhaleOffsets(1,bi))
        thisExhale = exhaleOnsets(1,bi):exhaleOffsets(1,bi);
        exhaleIntegral = sum(abs(resp(thisExhale)));
        exhaleVolumes(1,bi)=exhaleIntegral;
    else
        exhaleVolumes(1,bi)=nan;
    end
end

% normalize for different sampling rates
inhaleVolumes = (inhaleVolumes / srate) * 1000;
exhaleVolumes = (exhaleVolumes / srate) * 1000;
