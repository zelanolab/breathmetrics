function [inhaleLengths, exhaleLengths, inhalePauseLengths, ...
    exhalePauseLengths] = findBreathLengths(Bm)

inhaleLengths = zeros(1,length(Bm.inhaleOnsets));
exhaleLengths = zeros(1,length(Bm.exhaleOnsets));
inhalePauseLengths = zeros(1,length(Bm.inhaleOnsets));
exhalePauseLengths = zeros(1,length(Bm.exhaleOnsets));

% calculate inhale lengths
for i = 1:length(Bm.inhaleOnsets)
    if ~isnan(Bm.inhaleOffsets(i))
        inhaleLengths(i) = Bm.inhaleOffsets(i)-Bm.inhaleOnsets(i);
    else
        inhaleLengths(i) = nan;
    end
end

% calculate exhale lengths
for e=1:length(Bm.exhaleOnsets)
    if ~isnan(Bm.exhaleOffsets(e))
        exhaleLengths(e) = Bm.exhaleOffsets(e)-Bm.exhaleOnsets(e);
    else
        exhaleLengths(e) = nan;
    end
end

% calculate inhale pause lengths
for i=1:length(Bm.inhalePauseOnsets)
    if ~isnan(Bm.inhalePauseOnsets(i))
        inhalePauseLengths(i) = Bm.exhaleOnsets(i) - Bm.inhalePauseOnsets(i);
    else
        inhalePauseLengths(i) = nan;
    end
end

% calculate exhale pause lengths
for e=1:length(Bm.exhalePauseOnsets)
    if ~isnan(Bm.exhalePauseOnsets(e))
        if e<length(Bm.inhaleOnsets)
            exhalePauseLengths(e) = Bm.inhaleOnsets(e+1) - ...
                Bm.exhalePauseOnsets(e);
        else
            exhalePauseLengths(e) = nan;
        end
    else
        exhalePauseLengths(e) = nan;
    end
end

% normalize back into real time
inhaleLengths = inhaleLengths ./ Bm.srate;
exhaleLengths = exhaleLengths ./ Bm.srate;

inhalePauseLengths = inhalePauseLengths ./ Bm.srate;
exhalePauseLengths = exhalePauseLengths ./ Bm.srate;