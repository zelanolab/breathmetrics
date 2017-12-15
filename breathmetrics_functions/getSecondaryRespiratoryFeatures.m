function respirationStatistics  = getSecondaryRespiratoryFeatures( Bm, verbose )

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
breathingRate = Bm.srate/mean(diff(Bm.inhalePeaks));

% inter-breath interval is the average number of samples between breaths
% over the sampling rate
interBreathInterval = mean(diff(Bm.inhalePeaks))/Bm.srate;

% exclude outlier breaths and calculate peak flow rates
validInhaleFlows = Bm.peakInspiratoryFlows(Bm.peakInspiratoryFlows ...
    > mean(Bm.peakInspiratoryFlows) - 2 * std(Bm.peakInspiratoryFlows) ...
    & Bm.peakInspiratoryFlows< mean(Bm.peakInspiratoryFlows) + 2 * ...
    std(Bm.peakInspiratoryFlows));
validExhaleFlows = Bm.troughExpiratoryFlows(Bm.troughExpiratoryFlows ...
    > mean(Bm.troughExpiratoryFlows) - 2 * ... 
    std(Bm.troughExpiratoryFlows) & Bm.troughExpiratoryFlows < ...
    mean(Bm.troughExpiratoryFlows) + 2 * std(Bm.troughExpiratoryFlows));
avgMaxInhaleFlows = mean(validInhaleFlows);
avgMaxExhaleFlows = mean(validExhaleFlows);

% exclude outlier breaths and calculate breath volumes
validInhaleVolumes = Bm.inhaleVolumes(Bm.inhaleVolumes > ...
    nanmean(Bm.inhaleVolumes) - 2 * std(Bm.inhaleVolumes) & ...
    Bm.inhaleVolumes< mean(Bm.inhaleVolumes) + 2 * std(Bm.inhaleVolumes));
validExhaleVolumes = Bm.exhaleVolumes(Bm.exhaleVolumes > ...
    nanmean(Bm.exhaleVolumes) - 2 * nanstd(Bm.exhaleVolumes) & ...
    Bm.exhaleVolumes< nanmean(Bm.exhaleVolumes) + 2 * ...
    nanstd(Bm.exhaleVolumes));
avgInhaleVolumes = mean(validInhaleVolumes);
avgExhaleVolumes = mean(validExhaleVolumes);

% average exhale volume must always be negative. tidal volume is total air
% displaced by inhale and exhale
avgTidalVolume = avgInhaleVolumes + avgExhaleVolumes;

% minute ventilation is the product of respiration rate and tidal volume
minuteVentilation = breathingRate*avgTidalVolume;

% duty cycle is the percent of each breathing cycle that was spent inhaling
inhaleDurations = Bm.exhaleOnsets - Bm.inhaleOnsets;
avgInhaleDuration = nanmean(inhaleDurations)/Bm.srate;
dutyCycle = avgInhaleDuration / interBreathInterval;

CVInhaleDurations = std(inhaleDurations)/mean(inhaleDurations);

avgExhaleDurations = interBreathInterval - avgInhaleDuration;

% coefficient of variation of breathing rate describes variability in time
% between breaths
cvBreathingRate = std(diff(Bm.inhalePeaks))/mean(diff(Bm.inhalePeaks));

% coefficient of variation in breath size describes variability of breath
% sizes
CVTidalVolumes = std(validInhaleVolumes)/mean(validInhaleVolumes);

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
    breathingRate; 
    interBreathInterval; 
    avgMaxInhaleFlows; 
    avgMaxExhaleFlows; 
    avgInhaleVolumes; 
    avgExhaleVolumes; 
    avgTidalVolume; 
    minuteVentilation; 
    dutyCycle; 
    CVInhaleDurations;
    avgInhaleDuration;
    avgExhaleDurations;
    cvBreathingRate; 
    CVTidalVolumes;
    };

% only include respiratory pauses for humans
if strcmp(Bm.dataType, 'human')
    pctInhalePauses = sum(Bm.inhalePauseOnsets > 0 ) / ...
        length(Bm.inhalePauseOnsets);
    avgInhalePauseLengths = ... 
        nanmean(Bm.inhalePauseLengths(Bm.inhalePauseLengths>0));
    if isempty(avgInhalePauseLengths) || isnan(avgInhalePauseLengths)
        avgInhalePauseLengths=0;
    end
    
    keySet{end+1} = 'Percent of Inhales With Pauses';
    keySet{end+1} = 'Average Length of Inhale Pause';
    valueSet{end+1} = pctInhalePauses;
    valueSet{end+1} = avgInhalePauseLengths;
    
    pctInhalePauses = sum(Bm.exhalePauseOnsets > 0 ) / ...
        length(Bm.exhalePauseOnsets);
    avgExhalePauseLengths = ...
        nanmean(Bm.exhalePauseLengths(Bm.exhalePauseLengths>0));
    
    if isempty(avgExhalePauseLengths)|| isnan(avgExhalePauseLengths)
        avgExhalePauseLengths=0;
    end
    
    keySet{end+1} = 'Percent of Exhales With Pauses';
    keySet{end+1} = 'Average Length of Exhale Pause';
    valueSet{end+1} = pctInhalePauses;
    valueSet{end+1} = avgExhalePauseLengths;
end
    
respirationStatistics = containers.Map(keySet,valueSet);

if verbose == 1
    disp('Secondary Respiratory Features')
    for this_key = 1:length(keySet)
        fprintf('%s : %0.5g', keySet{this_key},valueSet{this_key});
        fprintf('\n')
    end
end

end

