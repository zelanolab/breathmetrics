function respirationStatistics  = getSecondaryRespiratoryFeatures( Bm, verbose )

%calculates features of respiratory data. Running this method assumes that 
% you have already derived all possible features

if nargin < 2
    verbose = 0;
end

if verbose == 1
    disp('Calculating secondary respiratory features')
end




% first find valid breaths

% edited 4/11/20
% split nBreaths into inhales and exhales to fix indexing error from 
% myPeak error in findRespiratoryExtrema
    
nInhales=length(Bm.inhaleOnsets);
nExhales=length(Bm.exhaleOnsets);
if isempty(Bm.statuses)
    validInhaleInds=1:nInhales;
    validExhaleInds=1:nExhales;
else
    
    IndexInvalid = strfind(Bm.statuses,'rejected');
    invalidBreathInds = find(not(cellfun('isempty',IndexInvalid)));
    validInhaleInds=setdiff(1:nInhales,invalidBreathInds);
    validExhaleInds=setdiff(1:nExhales,invalidBreathInds);
    if isempty(validInhaleInds)
        warndlg('No valid breaths found. If the status of a breath is set to ''rejected'', it will not be used to compute secondary features');
    end
end

nValidInhales=length(validInhaleInds);
nValidExhales=length(validExhaleInds);

%%% Breathing Rate %%%
% breathing rate is the sampling rate over the average number of samples 
% in between breaths.

% this is tricky when certain breaths have been rejected
breathDiffs=nan(1,1);
vbIter=1;
for i = 1:nValidInhales-1
    thisBreath=validInhaleInds(i);
    nextBreath=validInhaleInds(i+1);
    % if there is no rejected breath between these breaths, they can be
    % used to compute breathing rate.
    if nextBreath == thisBreath+1
        breathDiffs(1,vbIter)=Bm.inhaleOnsets(nextBreath)-Bm.inhaleOnsets(thisBreath);
        vbIter=vbIter+1;
    end
end

breathingRate = Bm.srate/mean(breathDiffs);

%%% Inter-Breath Interval %%%
% inter-breath interval is the inverse of breathing rate
interBreathInterval = 1/breathingRate;

%%% Coefficient of Variation of Breathing Rate %%% 
% this describes variability in time between breaths
cvBreathingRate = std(breathDiffs)/mean(breathDiffs);

if strcmp(Bm.dataType,'humanAirflow') || strcmp(Bm.dataType,'rodentAirflow')
    % the following features can only be computed for airflow data
    
    %%% Peak Flow Rates %%%
    % the maximum rate of airflow at each inhale and exhale
    
    % inhales
    validInhaleFlows=excludeOutliers(Bm.peakInspiratoryFlows, validInhaleInds);
    avgMaxInhaleFlow = mean(validInhaleFlows);
    
    % exhales
    validExhaleFlows=excludeOutliers(Bm.troughExpiratoryFlows, validExhaleInds);
    avgMaxExhaleFlow = mean(validExhaleFlows);

    %%% Breath Volumes %%%
    % the volume of each breath is the integral of the airflow
    
    % inhales
    validInhaleVolumes=excludeOutliers(Bm.inhaleVolumes, validInhaleInds);
    avgInhaleVolume = mean(validInhaleVolumes);
    
    % exhales
    validExhaleVolumes=excludeOutliers(Bm.exhaleVolumes, validExhaleInds);
    avgExhaleVolume = mean(validExhaleVolumes);

    %%% Tidal volume %%%
    % tidal volume is the total air displaced by inhale and exhale
    avgTidalVolume = avgInhaleVolume + avgExhaleVolume;

    %%% Minute Ventilation %%%
    % minute ventilation is the product of respiration rate and tidal volume
    minuteVentilation = breathingRate * avgTidalVolume;

    %%% Duty Cycle %%%
    % duty cycle is the percent of each breathing cycle that was spent in
    % a phase
    
    % get avg duration of each phase
    avgInhaleDuration = nanmean(Bm.inhaleDurations);
    avgExhaleDuration = nanmean(Bm.exhaleDurations);
    
    % because pauses don't necessarily occur on every breath, multiply this
    % value by total number that occured.
    pctInhalePause=sum(~isnan(Bm.inhalePauseDurations))/nValidInhales;
    avgInhalePauseDuration = nanmean(Bm.inhalePauseDurations(validInhaleInds)) * pctInhalePause;
    
    pctExhalePause=sum(~isnan(Bm.exhalePauseDurations))/nValidExhales;
    avgExhalePauseDuration = nanmean(Bm.exhalePauseDurations(validExhaleInds)) * pctExhalePause;

    inhaleDutyCycle = avgInhaleDuration / interBreathInterval;
    inhalePauseDutyCycle = avgInhalePauseDuration / interBreathInterval;
    exhaleDutyCycle = avgExhaleDuration / interBreathInterval;
    exhalePauseDutyCycle = avgExhalePauseDuration / interBreathInterval;

    CVInhaleDuration = nanstd(Bm.inhaleDurations)/avgInhaleDuration;
    CVInhalePauseDuration = nanstd(Bm.inhalePauseDurations)/avgInhalePauseDuration;
    CVExhaleDuration = nanstd(Bm.exhaleDurations)/avgExhaleDuration;
    CVExhalePauseDuration = nanstd(Bm.exhalePauseDurations)/avgExhalePauseDuration;

    % if there were no pauses, the average pause duration is 0, not nan
    if isempty(avgInhalePauseDuration) || isnan(avgInhalePauseDuration)
            avgInhalePauseDuration=0;
    end

    if isempty(avgExhalePauseDuration) || isnan(avgExhalePauseDuration)
            avgExhalePauseDuration=0;
    end

    % coefficient of variation in breath size describes variability of breath
    % sizes
    CVTidalVolume = std(validInhaleVolumes)/mean(validInhaleVolumes);
    
end


% assigning values for output

if strcmp(Bm.dataType,'humanAirflow') || strcmp(Bm.dataType,'rodentAirflow')
    keySet= {
        'Breathing Rate';
        'Average Inter-Breath Interval';
        
        'Average Peak Inspiratory Flow';
        'Average Peak Expiratory Flow';
        
        'Average Inhale Volume';
        'Average Exhale Volume';
        'Average Tidal Volume';
        'Minute Ventilation';
        
        'Duty Cycle of Inhale';
        'Duty Cycle of Inhale Pause';
        'Duty Cycle of Exhale';
        'Duty Cycle of Exhale Pause';
        
        'Coefficient of Variation of Inhale Duty Cycle';
        'Coefficient of Variation of Inhale Pause Duty Cycle';
        'Coefficient of Variation of Exhale Duty Cycle';
        'Coefficient of Variation of Exhale Pause Duty Cycle';
        
        'Average Inhale Duration';
        'Average Inhale Pause Duration';
        'Average Exhale Duration';
        'Average Exhale Pause Duration';
        
        'Percent of Breaths With Inhale Pause';
        'Percent of Breaths With Exhale Pause';
        
        'Coefficient of Variation of Breathing Rate';
        'Coefficient of Variation of Breath Volumes';
        
        };

    valueSet={
        breathingRate; 
        interBreathInterval; 
        
        avgMaxInhaleFlow; 
        avgMaxExhaleFlow; 
        
        avgInhaleVolume; 
        avgExhaleVolume; 
        avgTidalVolume; 
        minuteVentilation; 
        
        inhaleDutyCycle; 
        inhalePauseDutyCycle; 
        exhaleDutyCycle; 
        exhalePauseDutyCycle; 
        
        CVInhaleDuration;
        CVInhalePauseDuration;
        CVExhaleDuration;
        CVExhalePauseDuration;
        
        avgInhaleDuration;
        avgInhalePauseDuration;
        avgExhaleDuration;
        avgExhalePauseDuration;
        
        pctInhalePause
        pctExhalePause;
        
        cvBreathingRate; 
        CVTidalVolume;
        };
elseif strcmp(Bm.dataType,'humanBB') || strcmp(Bm.dataType,'rodentThermocouple') 
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

function validVals=excludeOutliers(origVals,validBreathInds)
    
    % rejects values exceeding 2 stds from the mean
    
    upperBound=nanmean(origVals) + 2 * nanstd(origVals);
    lowerBound=nanmean(origVals) - 2 * nanstd(origVals);
    
    validValInds = find(origVals(origVals > lowerBound & origVals < upperBound));
    
    validVals = origVals(intersect(validValInds, validBreathInds));
    
end
