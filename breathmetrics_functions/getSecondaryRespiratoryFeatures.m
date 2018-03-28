function respirationStatistics  = getSecondaryRespiratoryFeatures( Bm, verbose )

%calculates features of respiratory data. Running this method assumes that 
% you have already derived all possible features

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

if strcmp(Bm.dataType,'human') || strcmp(Bm.dataType,'rodentAirflow')
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
    avgInhaleLength = nanmean(Bm.inhaleLengths);
    avgExhaleLength = nanmean(Bm.exhaleLengths);

    dutyCycle = avgInhaleLength / interBreathInterval;

    CVInhaleLengths = nanstd(Bm.inhaleLengths)/avgInhaleLength;

    pctInhalePauses = sum(Bm.inhalePauseOnsets > 0 ) / ...
        length(Bm.inhalePauseOnsets);

    avgInhalePauseLength = nanmean(Bm.inhalePauseLengths(Bm.inhalePauseLengths>0));
    if isempty(avgInhalePauseLength) || isnan(avgInhalePauseLength)
            avgInhalePauseLength=0;
    end

    pctExhalePauses = sum(Bm.exhalePauseOnsets > 0 ) / ...
            length(Bm.exhalePauseOnsets);

    avgExhalePauseLength = nanmean(Bm.exhalePauseLengths(Bm.exhalePauseLengths>0));
    if isempty(avgExhalePauseLength) || isnan(avgExhalePauseLength)
            avgExhalePauseLength=0;
    end

    % coefficient of variation in breath size describes variability of breath
    % sizes
    CVTidalVolumes = std(validInhaleVolumes)/mean(validInhaleVolumes);
end

% coefficient of variation of breathing rate describes variability in time
% between breaths
cvBreathingRate = std(diff(Bm.inhalePeaks))/mean(diff(Bm.inhalePeaks));


% assigning values for output
if strcmp(Bm.dataType,'human') || strcmp(Bm.dataType,'rodentAirflow')
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
        'Average Inhale Pause Length';
        'Average Exhale Length';
        'Average Exhale Pause Length';
        'Percent of Breaths With Inhale Pause';
        'Percent of Breaths With Exhale Pause';
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
        CVInhaleLengths;
        avgInhaleLength;
        avgInhalePauseLength;
        avgExhaleLength;
        avgExhalePauseLength;
        pctInhalePauses
        pctExhalePauses;
        cvBreathingRate; 
        CVTidalVolumes;
        };
elseif strcmp(Bm.dataType,'rodentThermocouple')
    keySet= {
        'Breathing Rate';
        'Average Inter-Breath Interval';
        'Coefficient of Variation of Breathing Rate';
        };
    valueSet={
        breathingRate; 
        interBreathInterval; 
        cvBreathingRate; 
        };
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

