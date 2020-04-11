function [ inhaleOnsets, exhaleOnsets, inhalePauseOnsets, ...
    exhalePauseOnsets ] = ...
    findRespiratoryPausesAndOnsets( resp, myPeaks, myTroughs, nBINS )
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
inhaleOnsets = zeros(1, length(myPeaks));
exhaleOnsets = zeros(1, length(myTroughs)); % changed on 4/11/20

% inhale pause onsets happen after inhales but before exhales
% exhale pause onsets happen after exhales but before inhales 
inhalePauseOnsets = zeros(1,length(myPeaks));
exhalePauseOnsets = zeros(1,length(myTroughs)); % changed on 4/11/20
inhalePauseOnsets(:)=nan;
exhalePauseOnsets(:)=nan;

% 100 bins works well for data with sampling rates>100 Hz. 
% use differen nBINS for data with lower sampling rates
% sampling rate is too slow.
if nargin<4
    nBINS = 100;
end
    
if nBINS >= 100
    maxPauseBins=5;
else
    maxPauseBins=2;
end

% free parameter for sensitivity of calling something a pause or not.
MAXIMUM_BIN_THRESHOLD = 5;

% thresholds the mode bin (cycle zero cross) must fall between.
% fast breathing sometimes looks like a square wave so the mode is at the
% head or the tail and doesn't reflect a breath onset.
UPPER_THRESHOLD = round(nBINS*.7);
LOWER_THRESHOLD = round(nBINS*.3);

% If this fails, use average of trace
SIMPLE_ZERO_CROSS = mean(resp);

% first onset is special because it's not between two peaks. If there is 
% lots of time before the first peak, limit it to within 4000 samples.

% head and tail onsets are hard to estimate without lims. use average
% breathing interval in these cases.
TAIL_ONSET_LIMS = floor(mean(diff(myPeaks)));


if myPeaks(1) > TAIL_ONSET_LIMS
    firstZeroCrossBoundary = myPeaks(1)-TAIL_ONSET_LIMS;
else
    firstZeroCrossBoundary=1;
end

% Estimate last zero cross (inhale onset) before first peak
% If there is not a full cycle before the first peak, this estimation will
% be unreliable.
THIS_WINDOW = resp(firstZeroCrossBoundary:myPeaks(1));
CUSTOM_BINS = linspace(min(THIS_WINDOW),max(THIS_WINDOW), nBINS);
[AMPLITUDE_VALUES, WINDOW_BINS] = hist(THIS_WINDOW, CUSTOM_BINS);
[~,MODE_BIN] = max(AMPLITUDE_VALUES);
ZERO_CROSS_THRESHOLD = WINDOW_BINS(MODE_BIN);
if MODE_BIN < LOWER_THRESHOLD || MODE_BIN > UPPER_THRESHOLD
    ZERO_CROSS_THRESHOLD = SIMPLE_ZERO_CROSS;
end
    
POSSIBLE_INHALE_INDS = THIS_WINDOW < ZERO_CROSS_THRESHOLD;
if sum(POSSIBLE_INHALE_INDS) > 0
    INHALE_ONSET = find(POSSIBLE_INHALE_INDS == 1, 1, 'last');
    inhaleOnsets(1,1) = firstZeroCrossBoundary + INHALE_ONSET;
else
    inhaleOnsets(1,1) = firstZeroCrossBoundary;
end

% cycle through each peak-peak window of respiration data
for THIS_BREATH = 1:length(myPeaks)-1
    
    % Find next inhale onset and pause
    
    INHALE_WINDOW = resp(myTroughs(THIS_BREATH):myPeaks(THIS_BREATH+1));
    CUSTOM_BINS = linspace(min(INHALE_WINDOW),max(INHALE_WINDOW),nBINS);
    [AMPLITUDE_VALUES, WINDOW_BINS] = hist(INHALE_WINDOW, CUSTOM_BINS);
    [~,MODE_BIN] = max(AMPLITUDE_VALUES);
    MAX_BIN_RATIO = AMPLITUDE_VALUES(MODE_BIN)/mean(AMPLITUDE_VALUES);
    isExhalePause = ~(MODE_BIN < LOWER_THRESHOLD || MODE_BIN > UPPER_THRESHOLD || MAX_BIN_RATIO < MAXIMUM_BIN_THRESHOLD);
    
    if ~isExhalePause
       % data does not cluster in the middle, indicating no respiratory
       % pause. So just use baseline crossing as inhale onset
       THIS_INHALE_THRESHOLD = SIMPLE_ZERO_CROSS;
       
       % points where the trace crosses zero
       POSSIBLE_INHALE_INDS = INHALE_WINDOW > THIS_INHALE_THRESHOLD;
       
       % find last point in half-cycle below threshold
       INHALE_ONSET = find( POSSIBLE_INHALE_INDS == 0, 1, 'last' );
       
       % this is the inhale onset for the next peak so add 1 to keep indexing
       % consistant
       exhalePauseOnsets(1, THIS_BREATH) = nan;
       inhaleOnsets(1, THIS_BREATH + 1) = myTroughs( THIS_BREATH ) + INHALE_ONSET;
        
    else
        % add bins to find good range of variance for this respiratory pause
        MIN_PAUSE_RANGE = WINDOW_BINS(MODE_BIN);
        MAX_PAUSE_RANGE = WINDOW_BINS(MODE_BIN+1);
        MAX_BIN_TOTAL = AMPLITUDE_VALUES(MODE_BIN);
        
        % percent of amplitudes added by including a bin compared to max bin
        BINNING_THRESHOLD = .25; 
        
        % add bins in positive direction
        for ADDITIONAL_BIN = 1:maxPauseBins
            THIS_BIN = MODE_BIN-ADDITIONAL_BIN;
            nVALS_ADDED = AMPLITUDE_VALUES(THIS_BIN);
            if nVALS_ADDED > MAX_BIN_TOTAL * BINNING_THRESHOLD
                MIN_PAUSE_RANGE = WINDOW_BINS(THIS_BIN);
            end
        end
        
        % add bins in negative direction
        for ADDITIONAL_BIN = 1:maxPauseBins
            THIS_BIN = MODE_BIN+ADDITIONAL_BIN;
            nVALS_ADDED = AMPLITUDE_VALUES(THIS_BIN);
            if nVALS_ADDED > MAX_BIN_TOTAL * BINNING_THRESHOLD
                MAX_PAUSE_RANGE = WINDOW_BINS(THIS_BIN);
            end
        end
            
        PUTATIVE_PAUSE_INDS = find(INHALE_WINDOW > MIN_PAUSE_RANGE  & INHALE_WINDOW<MAX_PAUSE_RANGE);
        PAUSE_ONSET = PUTATIVE_PAUSE_INDS(1)-1;
        INHALE_ONSET = PUTATIVE_PAUSE_INDS(end)+1;
        exhalePauseOnsets(1, THIS_BREATH) = myTroughs( THIS_BREATH ) + PAUSE_ONSET;
        inhaleOnsets(1, THIS_BREATH + 1) = myTroughs( THIS_BREATH ) + INHALE_ONSET;
    end
    
    % Find Next Exhale
    
    % troughs always follow peaks
    EXHALE_WINDOW = resp(myPeaks(THIS_BREATH):myTroughs(THIS_BREATH));
    CUSTOM_BINS=linspace(min(EXHALE_WINDOW),max(EXHALE_WINDOW),nBINS);
    [AMPLITUDE_VALUES, WINDOW_BINS] = hist(EXHALE_WINDOW, CUSTOM_BINS);
    [~,MODE_BIN] = max(AMPLITUDE_VALUES);
    MAX_BIN_RATIO = AMPLITUDE_VALUES(MODE_BIN)/mean(AMPLITUDE_VALUES);
    
    isInhalePause = ~(MODE_BIN < LOWER_THRESHOLD || MODE_BIN > UPPER_THRESHOLD || MAX_BIN_RATIO < MAXIMUM_BIN_THRESHOLD);
    
    if ~isInhalePause
       % data does not cluster in the middle, indicating no respiratory
       % pause. So just use baseline crossing as inhale onset
       THIS_EXHALE_THRESHOLD = SIMPLE_ZERO_CROSS;
       
       % points where the trace crosses zero
       POSSIBLE_EXHALE_INDS = EXHALE_WINDOW > THIS_EXHALE_THRESHOLD;
       
       % find last point in half-cycle below threshold
       EXHALE_ONSET = find( POSSIBLE_EXHALE_INDS == 1, 1, 'last' );
       % this is the exhale onset for the next trough
       
       inhalePauseOnsets(1, THIS_BREATH) = nan;
       exhaleOnsets(1, THIS_BREATH) = myPeaks( THIS_BREATH ) + EXHALE_ONSET;
    else
        % add bins to find good range of variance for this respiratory pause
        MIN_PAUSE_RANGE = WINDOW_BINS(MODE_BIN);
        MAX_PAUSE_RANGE = WINDOW_BINS(MODE_BIN+1);
        MAX_BIN_TOTAL = AMPLITUDE_VALUES(MODE_BIN);
        % percent of amplitudes added by including a bin compared to max bin
        BINNING_THRESHOLD = .25; 
        
        % add bins in positive direction
        for ADDITIONAL_BIN = 1:5
            THIS_BIN = MODE_BIN-ADDITIONAL_BIN;
            nVALS_ADDED = AMPLITUDE_VALUES(THIS_BIN);
            if nVALS_ADDED > MAX_BIN_TOTAL * BINNING_THRESHOLD
                MIN_PAUSE_RANGE = WINDOW_BINS(THIS_BIN);
            end
        end
        
        % add bins in negative direction
        for ADDITIONAL_BIN = 1:5
            THIS_BIN = MODE_BIN+ADDITIONAL_BIN;
            nVALS_ADDED = AMPLITUDE_VALUES(THIS_BIN);
            if nVALS_ADDED > MAX_BIN_TOTAL * BINNING_THRESHOLD
                MAX_PAUSE_RANGE = WINDOW_BINS(THIS_BIN);
            end
        end
            
        PUTATIVE_PAUSE_INDS = find(EXHALE_WINDOW > MIN_PAUSE_RANGE  & EXHALE_WINDOW < MAX_PAUSE_RANGE);
        PAUSE_ONSET = PUTATIVE_PAUSE_INDS(1)-1;
        EXHALE_ONSET = PUTATIVE_PAUSE_INDS(end)+1;
        inhalePauseOnsets(1, THIS_BREATH) = myPeaks( THIS_BREATH ) + PAUSE_ONSET;
        exhaleOnsets(1, THIS_BREATH) = myPeaks( THIS_BREATH ) + EXHALE_ONSET;
    end 
end

% last exhale onset is also special because it's not in a peak-peak cycle
% treat it similar to first inhale
if length(resp) - myPeaks(end) > TAIL_ONSET_LIMS
    LAST_ZERO_CROSS_BOUNDARY = myPeaks(end) + TAIL_ONSET_LIMS;
else
    LAST_ZERO_CROSS_BOUNDARY = length(resp);
end

EXHALE_WINDOW = resp(myPeaks(end):LAST_ZERO_CROSS_BOUNDARY);
ZERO_CROSS_THRESHOLD = SIMPLE_ZERO_CROSS;

POSSIBLE_EXHALE_INDS = EXHALE_WINDOW < ZERO_CROSS_THRESHOLD;

% unlikely but possible that no values fit this criteria
if sum(POSSIBLE_EXHALE_INDS)>0
    EXHALE_BEST_GUESS = find(POSSIBLE_EXHALE_INDS == 1, 1, 'first');
    exhaleOnsets(1,end) = myPeaks(end) + EXHALE_BEST_GUESS;
else
    % about half a cycle of respiration.
    exhaleOnsets(1,end) = LAST_ZERO_CROSS_BOUNDARY;
end
