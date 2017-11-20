function respstats  = get_secondary_resp_features( bm, verbose )

%calculates features of respiratory data dependant on extrema, onsets, and
%tidal volumes

if nargin < 2
    verbose = 0;
end

if verbose == 1
    disp('Calculating secondary respiratory features')
end

% breathing rate is the sampling rate over the average number of samples in
% between breaths
br = bm.srate/mean(diff(bm.inhale_peaks));

% inter-breath interval is the average number of samples between breaths
% over the sampling rate
ibi=mean(diff(bm.inhale_peaks))/bm.srate;

% exclude outlier breaths and calculate peak flow rates
valid_inhale_flows = bm.peak_inspiratory_flows(bm.peak_inspiratory_flows>mean(bm.peak_inspiratory_flows) - 2 * std(bm.peak_inspiratory_flows) & bm.peak_inspiratory_flows< mean(bm.peak_inspiratory_flows) + 2 * std(bm.peak_inspiratory_flows));
valid_exhale_flows = bm.trough_expiratory_flows(bm.trough_expiratory_flows>mean(bm.trough_expiratory_flows) - 2 * std(bm.trough_expiratory_flows) & bm.trough_expiratory_flows< mean(bm.trough_expiratory_flows) + 2 * std(bm.trough_expiratory_flows));
avg_max_inhale_flows = mean(valid_inhale_flows);
avg_max_exhale_flows = mean(valid_exhale_flows);

% exclude outlier breaths and calculate breath volumes
valid_inhale_volumes = bm.inhale_volumes(bm.inhale_volumes>nanmean(bm.inhale_volumes) - 2 * std(bm.inhale_volumes) & bm.inhale_volumes< mean(bm.inhale_volumes) + 2 * std(bm.inhale_volumes));
valid_exhale_volumes = bm.exhale_volumes(bm.exhale_volumes>nanmean(bm.exhale_volumes) - 2 * nanstd(bm.exhale_volumes) & bm.exhale_volumes< nanmean(bm.exhale_volumes) + 2 * nanstd(bm.exhale_volumes));
avg_i_vol = mean(valid_inhale_volumes);
avg_e_vol = mean(valid_exhale_volumes);

% average exhale volume must always be negative. tidal volume is total air
% displaced by inhale and exhale
avg_tv = avg_i_vol + avg_e_vol;

% minute ventilation is the product of respiration rate and tidal volume
mv = br*avg_tv;

% duty cycle is the percent of each breathing cycle that was spent inhaling
inhale_durations = bm.exhale_onsets-bm.inhale_onsets;
avg_inhale_time = mean(inhale_durations)/bm.srate;
dc = avg_inhale_time / ibi;

cv_inhale_durations = std(inhale_durations)/mean(inhale_durations);

avg_exhale_time = ibi-avg_inhale_time;

% coefficient of variation of breathing rate describes variability in time
% between breaths
cv_br = std(diff(bm.inhale_peaks))/mean(diff(bm.inhale_peaks));

% coefficient of variation in breath size describes variability of breath
% sizes
cv_tv = std(valid_inhale_volumes)/median(valid_inhale_volumes);

% assigning values for output
keySet= {
    'Breathing Rate';
    'Average Inter-Breath Interval';
    'Average Peak Inspiratory Flow';
    'Average Peak Expiratory Flow';
    'Average Inhale Volume';
    'Average Exhale Volume';
    'Average Tidal Volume';
    'Minute Ventilation';
    'Duty Cycle';
    'Coefficient of Variation of Duty Cycle';
    'Average Inhale Length';
    'Average Exhale Length';
    'Coefficient of Variation of Breathing Rate';
    'Coefficient of Variation of Breath Volumes';
    };

valueSet={
    br; 
    ibi; 
    avg_max_inhale_flows; 
    avg_max_exhale_flows; 
    avg_i_vol; 
    avg_e_vol; 
    avg_tv; 
    mv; 
    dc; 
    cv_inhale_durations;
    avg_inhale_time;
    avg_exhale_time;
    cv_br; 
    cv_tv;
    };

% only include respiratory pauses for humans
if strcmp(bm.data_type, 'human')
    pct_inhale_pauses = sum(bm.inhale_pause_onsets > 0 ) / length(bm.inhale_pause_onsets);
    avg_inhale_pause_length = nanmean(bm.inhale_pause_lengths(bm.inhale_pause_lengths>0))/bm.srate;
    if isempty(avg_inhale_pause_length)
        avg_inhale_pause_length=0;
    end
    
    keySet{end+1} = 'Percent of Inhales With Pauses';
    keySet{end+1} = 'Average Length of Inhale Pause';
    valueSet{end+1} = pct_inhale_pauses;
    valueSet{end+1} = avg_inhale_pause_length;
    
    pct_exhale_pauses = sum(bm.exhale_pause_onsets > 0 ) / length(bm.exhale_pause_onsets);
    avg_exhale_pause_length = nanmean(bm.exhale_pause_lengths(bm.exhale_pause_lengths>0))/bm.srate;
    
    if isempty(avg_exhale_pause_length)
        avg_exhale_pause_length=0;
    end
    
    keySet{end+1} = 'Percent of Exhales With Pauses';
    keySet{end+1} = 'Average Length of Exhale Pause';
    valueSet{end+1} = pct_exhale_pauses;
    valueSet{end+1} = avg_exhale_pause_length;
end
    
respstats= containers.Map(keySet,valueSet);

if verbose == 1
    disp('Secondary Respiratory Features')
    for this_key = 1:length(keySet)
        disp(sprintf('%s : %0.5g',keySet{this_key},valueSet{this_key}));
    end
end

end

