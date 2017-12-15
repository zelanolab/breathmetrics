function [ pauseOnsets, pauseLengths ] = findRespiratoryPauses( resp, inhaleOnsets, exhaleTroughs )
%FIND_RESPIRATORY_PAUSES Finds pauses in breathing preceding inhales
% 
%   resp : 1:n vector of respiratory trace
%   inhale_onsets : time points when inhales initiate
%   inhale_onsets : time points when exhales initiate


% parameters optimized for our dataset
N_BINS = 30;
MAX_THRESHOLD = 25;

% respiratory pauses are indexed by the trough they follow
pauseOnsets = zeros(1,length(exhaleTroughs));
pauseLengths = zeros(1,length(exhaleTroughs));

% can't estimate respiratory pause for first breath in series
for THIS_BREATH = 1:length(exhaleTroughs)-1
    % get window of breathing between this trough and the next inhale
    % inhale onsets are organized such that they always preceed troughs.
    THIS_TROUGH = exhaleTroughs(THIS_BREATH);
    NEXT_INHALE_ONSET = inhaleOnsets(THIS_BREATH+1);
    THIS_WINDOW = resp(THIS_TROUGH:NEXT_INHALE_ONSET);
    
    % find max bin
    [vals,bins] = hist(THIS_WINDOW, N_BINS);
    [~, max_ind] = max(vals);
    
    % if max bin is close to value of inhale onset and there are enough values in it, then it is a pause
    if (max_ind > MAX_THRESHOLD || bins(max_ind) > THIS_WINDOW(end)) && bins(max_ind) > mean(THIS_WINDOW)
        BIN_THRESHOLD = bins(max_ind-1);
        
        % index of next inhale - index of pause start = pause length
        PAUSE_WINDOW_IND = find(THIS_WINDOW > BIN_THRESHOLD, 1, 'first');
        PAUSE_LENGTH = length(THIS_WINDOW) - PAUSE_WINDOW_IND;
        PAUSE_IND = PAUSE_WINDOW_IND + THIS_TROUGH;
    else
        PAUSE_IND = 0;
        PAUSE_LENGTH=0;
    end
    
    pauseOnsets(1,THIS_BREATH)=PAUSE_IND;
    pauseLengths(1,THIS_BREATH)=PAUSE_LENGTH;
end
