function [ pause_onsets, pause_lengths ] = find_respiratory_pauses( resp, inhale_onsets, exhale_troughs )
%FIND_RESPIRATORY_PAUSES Finds pauses in breathing preceding inhales
%   resp : 1:n vector of respiratory trace
%   inhale_onsets : time points when inhales initiate
%   inhale_onsets : time points when exhales initiate


% parameters optimized for our dataset
n_bins = 30;
max_thresh = 25;

% respiratory pauses are indexed by the trough they follow
pause_onsets = zeros(1,length(exhale_troughs));
pause_lengths = zeros(1,length(exhale_troughs));

% can't estimate respiratory pause for first breath in series
for this_breath = 1:length(exhale_troughs)-1
    % get window of breathing between this trough and the next inhale
    % inhale onsets are organized such that they always preceed troughs.
    this_trough = exhale_troughs(this_breath);
    next_inhale_onset = inhale_onsets(this_breath+1);
    this_window = resp(this_trough:next_inhale_onset);
    
    % find max bin
    [vals,bins] = hist(this_window,n_bins);
    [~, max_ind] = max(vals);
    
    % if max bin is close to value of inhale onset and there are enough values in it, then it is a pause
    if (max_ind > max_thresh || bins(max_ind) > this_window(end)) && bins(max_ind) > mean(this_window)
        bin_thresh = bins(max_ind-1);
        
        % index of next inhale - index of pause start = pause length
        pause_window_ind = find(this_window > bin_thresh, 1, 'first');
        pause_length = length(this_window) - pause_window_ind;
        pause_ind = pause_window_ind + this_trough;
    else
        pause_ind = 0;
        pause_length=0;
    end
    
    pause_onsets(1,this_breath)=pause_ind;
    pause_lengths(1,this_breath)=pause_length;
end
