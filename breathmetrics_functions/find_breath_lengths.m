function [inhale_lengths, exhale_lengths, inhale_pause_lengths, exhale_pause_lengths] = find_breath_lengths(bm)

inhale_lengths = zeros(1,length(bm.inhale_onsets));
exhale_lengths = zeros(1,length(bm.exhale_onsets));
inhale_pause_lengths = zeros(1,length(bm.inhale_onsets));
exhale_pause_lengths = zeros(1,length(bm.exhale_onsets));

% calculate inhale lengths
for i=1:length(bm.inhale_onsets)
    if ~isnan(bm.inhale_pause_onsets(i))
        inhale_lengths(i)=bm.inhale_pause_onsets(i)-bm.inhale_onsets(i);
    else
        inhale_lengths(i)=bm.exhale_onsets(i)-bm.inhale_onsets(i);
    end
end

% calculate exhale lengths
for e=1:length(bm.exhale_onsets)
    if ~isnan(bm.exhale_pause_onsets(e))
        exhale_lengths(e)=bm.exhale_pause_onsets(e)-bm.exhale_onsets(e);
    elseif e<length(bm.inhale_onsets)
        exhale_lengths(e)=bm.inhale_onsets(e+1)-bm.exhale_onsets(e);
    else
        % last window is tricky beacuse next breath is not defined
        end_window = bm.baseline_corrected_respiration(bm.exhale_onsets(e):end);
        exhale_best_guess = find(end_window>0, 1, 'first');
        if isempty(exhale_best_guess)
            exhale_lengths(e)=nan;
        else
            exhale_lengths(e)=exhale_best_guess;
        end
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