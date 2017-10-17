function [ inhale_onsets, exhale_onsets, inhale_pause_onsets ] = find_respiratory_pauses_and_onsets( resp, mypeaks, mytroughs )
%FIND_RESPIRATORY_PAUSES_AND_ONSETS finds each breath onset and respiratory
%pause in the data, given the peaks and troughs

%   Steps: 
%   1. Find breath onsets for the first and last breath.
%   2. For each trough-to-peak window, check if there is a respiratory pause.
%   3. If no pause, then just find when the trace crosses baseline.
%   4. if there is a pause, the amplitude range that it pauses over.
%   5. Find onset and offset of pause.
%   6. Find exhale onset in peak-to-trough window where it crosses baseline.
%   7. Repeat.

% Assume that there is exactly one onset per breath
inhale_onsets = zeros(1,length(mypeaks));
exhale_onsets = zeros(1,length(mypeaks));

inhale_pause_onsets = zeros(1,length(mypeaks));

% free parameter. 100 bins works well for my data. Will probably break if
% sampling rate is too slow.
n_bins=100;

% thresholds the mode bin (cycle zero cross) must fall between.
% fast breathing sometimes looks like a square wave so the mode is at the
% head or the tail and doesn't reflect a breath onset.
upper_thresh = round(n_bins*.7);
lower_thresh = round(n_bins*.3);

% If this fails, use average of trace
simple_zero_cross = mean(resp);

% first onset is special because it's not between two peaks. If there is 
% lots of time before the first peak, limit it to within 4000 samples.

% head and tail onsets are hard to estimate without lims. use average
% breathing interval in these cases.
tail_onset_lims=floor(mean(diff(mypeaks)));

if mypeaks(1)>tail_onset_lims
    first_zc_bound=mypeaks(1)-tail_onset_lims;
else
    first_zc_bound=1;
end

% Estimate last zero cross (inhale onset) before first peak
% If there is not a full cycle before the first peak, this estimation will
% be unreliable.
this_window=resp(first_zc_bound:mypeaks(1));
custom_bins=linspace(min(this_window),max(this_window),n_bins);
[amp_vals,window_bins] = hist(this_window,custom_bins);
[~,mode_bin] = max(amp_vals);
zero_cross_thresh = window_bins(mode_bin);
if mode_bin < lower_thresh || mode_bin > upper_thresh
    zero_cross_thresh = simple_zero_cross;
end
    
possible_inhale_inds = this_window < zero_cross_thresh;
if sum(possible_inhale_inds) > 0
    inhale_onset = find(possible_inhale_inds == 1, 1, 'last');
    inhale_onsets(1,1) = first_zc_bound + inhale_onset;
else
    inhale_onsets(1,1) = first_zc_bound;
end


% cycle through each peak-peak window of respiration data
for this_breath=1:length(mypeaks)-1
    
    % Find next inhale onset and pause
    
    inhale_window = resp(mytroughs(this_breath):mypeaks(this_breath+1));
    custom_bins=linspace(min(inhale_window),max(inhale_window),n_bins);
    [amp_vals, window_bins] = hist(inhale_window, custom_bins);
    [~,mode_bin] = max(amp_vals);
    max_bin_ratio = amp_vals(mode_bin)/mean(amp_vals);
    if mode_bin < lower_thresh || mode_bin > upper_thresh || max_bin_ratio < 10
       % data does not cluster in the middle, indicating no respiratory
       % pause. So just use baseline crossing as inhale onset
       this_inhale_thresh = simple_zero_cross;
       % points where the trace crosses zero
       possible_inhale_inds = inhale_window > this_inhale_thresh;
       % find last point in half-cycle below threshold
       inhale_onset = find( possible_inhale_inds == 0, 1, 'last' );
       % this is the inhale onset for the next peak so add 1 to keep indexing
       % consistant
       inhale_pause_onsets(1, this_breath + 1) = nan;
       inhale_onsets(1, this_breath + 1) = mytroughs( this_breath ) + inhale_onset;
        
    else
        % add bins to find good range of variance for this respiratory pause
        min_pause_range = window_bins(mode_bin);
        max_pause_range = window_bins(mode_bin+1);
        max_bin_total = amp_vals(mode_bin);
        % percent of amplitudes added by including a bin compared to max bin
        binning_thresh = .25; 
        
        % add bins in positive direction
        for additional_bin = 1:5
            this_bin = mode_bin-additional_bin;
            this_many_vals_added = amp_vals(this_bin);
            if this_many_vals_added > max_bin_total * binning_thresh
                min_pause_range = window_bins(this_bin);
            end
        end
        
        % add bins in negative direction
        for additional_bin = 1:5
            this_bin = mode_bin+additional_bin;
            this_many_vals_added = amp_vals(this_bin);
            if this_many_vals_added > max_bin_total * binning_thresh
                max_pause_range = window_bins(this_bin);
            end
        end
            
        putative_pause_inds = find(inhale_window>min_pause_range  & inhale_window<max_pause_range);
        pause_onset = putative_pause_inds(1)-1;
        inhale_onset = putative_pause_inds(end)+1;
        inhale_pause_onsets(1, this_breath + 1) = mytroughs( this_breath ) + pause_onset;
        inhale_onsets(1, this_breath + 1) = mytroughs( this_breath ) + inhale_onset;
    end
    
    % Find Next Exhale
    
    % troughs always follow peaks
    exhale_window = resp(mypeaks(this_breath):mytroughs(this_breath));
    custom_bins=linspace(min(exhale_window),max(exhale_window),n_bins);
    [vals,bins] = hist(exhale_window,custom_bins);
    zc_thresh = simple_zero_cross + (bins(end)-bins(end-1));
    
    % these will always have a value
    possible_exhale_inds = exhale_window > zc_thresh;
    % find first value that crosses.
    exhale_onset = find( possible_exhale_inds == 0, 1, 'first' );
    exhale_onsets(1, this_breath) = mypeaks( this_breath ) + exhale_onset;
end

% last exhale onset is also special because it's not in a peak-peak cycle
% treat it similar to first inhale
if length(resp) - mypeaks(end) > tail_onset_lims
    last_zc_bound = mypeaks(end) + tail_onset_lims;
else
    last_zc_bound = length(resp);
end

exhale_window = resp(mypeaks(end):last_zc_bound);
custom_bins=linspace(min(exhale_window),max(exhale_window),n_bins);
[vals,bins] = hist(exhale_window,custom_bins);
zero_cross_thresh = simple_zero_cross;

possible_exhale_inds = exhale_window < zero_cross_thresh;

% very unlikely but possible that no values fit this criteria
if sum(possible_exhale_inds)>0
    exhale_best_guess = find(possible_exhale_inds == 1, 1, 'first');
    exhale_onsets(1,end) = mypeaks(end) + exhale_best_guess;
else
    % about half a cycle of respiration.
    exhale_onsets(1,end) = last_zc_bound;
end

