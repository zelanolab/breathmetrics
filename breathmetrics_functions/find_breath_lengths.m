function [inhale_lengths, exhale_lengths, inhale_pause_lengths, exhale_pause_lengths] = find_breath_lengths(bm)

inhale_lengths = zeros(1,length(bm.inhale_onsets));
exhale_lengths = zeros(1,length(bm.exhale_onsets));
inhale_pause_lengths = zeros(1,length(bm.inhale_onsets));
exhale_pause_lengths = zeros(1,length(bm.exhale_onsets));

% calculate inhale lengths
for i=1:length(bm.inhale_onsets)
    if ~isnan(bm.inhale_offsets(i))
        inhale_lengths(i)=bm.inhale_offsets(i)-bm.inhale_onsets(i);
    else
        inhale_lengths(i)=nan;
    end
end

% calculate exhale lengths
for e=1:length(bm.exhale_onsets)
    if ~isnan(bm.exhale_offsets(e))
        exhale_lengths(e)=bm.exhale_offsets(e)-bm.exhale_onsets(e);
    else
        exhale_lengths(e)=nan;
    end
end

% calculate inhale pause lengths
for i=1:length(bm.inhale_pause_onsets)
    if ~isnan(bm.inhale_pause_onsets(i))
        inhale_pause_lengths(i)=bm.exhale_onsets(i)-bm.inhale_pause_onsets(i);
    else
        inhale_pause_lengths(i)=nan;
    end
end

% calculate exhale pause lengths
for e=1:length(bm.exhale_pause_onsets)
    if ~isnan(bm.exhale_pause_onsets(e))
        if e<length(bm.inhale_onsets)
            exhale_pause_lengths(e)=bm.inhale_onsets(e+1)-bm.exhale_pause_onsets(e);
        else
            exhale_pause_lengths(e)=nan;
        end
    else
        exhale_pause_lengths(e)=nan;
    end
end

% normalized back into real time
inhale_lengths = inhale_lengths ./ bm.srate;
exhale_lengths = exhale_lengths ./ bm.srate;

inhale_pause_lengths = inhale_pause_lengths ./ bm.srate;
exhale_pause_lengths = exhale_pause_lengths ./ bm.srate;