function [inhale_onsets,exhale_onsets] = find_breath_onsets( resp, mypeaks, mytroughs )

% estimates inhale and exhale onsets in a respiratory trace

% resp: respiratory trace, deson't have to be baseline corrected but it has
% to be smoothed/de-noised.
% mypeaks : inhale peak indices of respiratory trace.
% mytroughs : exhale trough indices of respiratory trace.

% procedure: There must be one inhale between each trough and peak and 
% there must be one exhale onset between each peak and trough. 
% Inhale and exhale onsets typically look like phase 'pauses' or plateaus
% in the respiratory cycle and they don't always happen at 0. 
% For each half cycle of breathing, bin the amplitudes and look for a bin
% with high counts of data near the middle. If this bin exists, it is the
% amplitude where the inhale occurs. If no such bin exists, which happens
% especially in people with fast breathing rates, use the mean respiration
% as the threshold.
% To find the exhale onset, find the last amplitude value above this 
% threshold. To find the inhale onest, find the last amplitude value above
% this threshold in the reverse direction.

inhale_onsets = zeros(1,length(mypeaks));
exhale_onsets = zeros(1,length(mypeaks));

% free parameter. 20 bins works well for my data.
n_bins=50;

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
[vals,bins] = hist(this_window,custom_bins);
[~,mode_bin] = max(vals);
zero_cross_thresh = bins(mode_bin);
if mode_bin < lower_thresh || mode_bin > upper_thresh
    zero_cross_thresh = simple_zero_cross;
end
    
possible_inhale_inds = this_window < zero_cross_thresh;
if sum(possible_inhale_inds) > 0
    inhale_best_guess = find(possible_inhale_inds == 1, 1, 'last');
    inhale_onsets(1,1) = first_zc_bound + inhale_best_guess;
else
    inhale_onsets(1,1) = first_zc_bound;
end

% cycle through each peak-peak window of respiration data
for this_breath=1:length(mypeaks)-1
    
    % Find Next Exhale
    
    % troughs always follow peaks
    exhale_window = resp(mypeaks(this_breath):mytroughs(this_breath));
    custom_bins=linspace(min(exhale_window),max(exhale_window),n_bins);
    [vals,bins] = hist(exhale_window,custom_bins);
    [~,mode_bin] = max(vals);
    
    %zc_thresh = bins(mode_bin);
    %keyboard
    % check that mode bin is not on head or tail and revert to average if 
    % it is.
    if mode_bin < lower_thresh || mode_bin > upper_thresh 
       zc_thresh = simple_zero_cross + (bins(end)-bins(end-1));
    else
        zc_thresh = bins(mode_bin+1);
    end
    % these will always have a value
    possible_exhale_inds = exhale_window > zc_thresh;
    % find first value that crosses.
    exhale_best_guess = find( possible_exhale_inds == 0, 1, 'first' );
    exhale_onsets(1, this_breath) = mypeaks( this_breath ) + exhale_best_guess;
    
    
    % Find Next Inhale
    
    inhale_window = resp(mytroughs(this_breath):mypeaks(this_breath+1));
    custom_bins=linspace(min(inhale_window),max(inhale_window),n_bins);
    [vals,bins] = hist(inhale_window,custom_bins);
    [~,mode_bin] = max(vals);
    zc_thresh = bins(mode_bin);

    % check that mode bin is not on head or tail and revert to average if 
    % it is.
    if mode_bin < lower_thresh || mode_bin > upper_thresh 
       zc_thresh = simple_zero_cross;
    end
    
    % points where the trace crosses zero
    possible_inhale_inds = inhale_window > zc_thresh;
    % find last point in half-cycle below threshold
    inhale_best_guess = find( possible_inhale_inds == 0, 1, 'last' );
    % this is the inhale onset for the next peak so add 1 to keep indexing
    % consistant
    inhale_onsets(1, this_breath + 1) = mytroughs( this_breath ) + inhale_best_guess;
    
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
[~,mode_bin] = max(vals);
zero_cross_thresh = bins(mode_bin);
if mode_bin < lower_thresh || mode_bin > upper_thresh
    zero_cross_thresh = simple_zero_cross;
end

possible_exhale_inds = exhale_window < zero_cross_thresh;

% very unlikely but possible that no values fit this criteria
if sum(possible_exhale_inds)>0
    exhale_best_guess = find(possible_exhale_inds == 1, 1, 'first');
    exhale_onsets(1,end) = mypeaks(end) + exhale_best_guess;
else
    % about half a cycle of respiration.
    exhale_onsets(1,end) = last_zc_bound;
end
