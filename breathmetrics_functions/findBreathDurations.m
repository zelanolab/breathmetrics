function [inhaleDurations, exhaleDurations, inhalePauseDurations, ...
    exhalePauseDurations] = findBreathDurations(Bm)

inhaleDurations = zeros(1,length(Bm.inhaleOnsets));
exhaleDurations = zeros(1,length(Bm.exhaleOnsets));
inhalePauseDurations = zeros(1,length(Bm.inhaleOnsets));
exhalePauseDurations = zeros(1,length(Bm.exhaleOnsets));

% calculate inhale durations
for i = 1:length(Bm.inhaleOnsets)
    if ~isnan(Bm.inhaleOffsets(i))
        inhaleDurations(i) = Bm.inhaleOffsets(i)-Bm.inhaleOnsets(i);
    else
        inhaleDurations(i) = nan;
    end
end

% calculate exhale durations
for e=1:length(Bm.exhaleOnsets)
    if ~isnan(Bm.exhaleOffsets(e))
        exhaleDurations(e) = Bm.exhaleOffsets(e)-Bm.exhaleOnsets(e);
    else
        exhaleDurations(e) = nan;
    end
end

% calculate inhale pause durations
for i=1:length(Bm.inhalePauseOnsets)
    if ~isnan(Bm.inhalePauseOnsets(i))
        inhalePauseDurations(i) = Bm.exhaleOnsets(i) - Bm.inhalePauseOnsets(i);
    else
        inhalePauseDurations(i) = nan;
    end
end

% calculate exhale pause durations
for e=1:length(Bm.exhalePauseOnsets)
    if ~isnan(Bm.exhalePauseOnsets(e))
        if e<length(Bm.inhaleOnsets)
            exhalePauseDurations(e) = Bm.inhaleOnsets(e+1) - ...
                Bm.exhalePauseOnsets(e);
        else
            exhalePauseDurations(e) = nan;
        end
    else
        exhalePauseDurations(e) = nan;
    end
end

% normalize back into real time
inhaleDurations = inhaleDurations ./ Bm.srate;
exhaleDurations = exhaleDurations ./ Bm.srate;

inhalePauseDurations = inhalePauseDurations ./ Bm.srate;
exhalePauseDurations = exhalePauseDurations ./ Bm.srate;