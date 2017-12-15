function [inhaleVolumes,exhaleVolumes] = findRespiratoryVolumes(resp, ...
    srate, inhaleOnsets, exhaleOnsets, inhaleOffsets, exhaleOffsets)

% estimates the volume of air displaced in all inhales and exhales
% requires zero crosses
% assumes peaks always come first
% assumes respiration has been baseline corrected;


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
