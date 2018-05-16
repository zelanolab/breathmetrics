function [simulatedRespiration, rawFeatures, featureStats] = simulateRespiratoryData(nCycles, srate, ...
    breathingRate, averageAmplitude, amplitudeVariance, phaseVariance, ...
    inhalePausePct, inhalePauseAvgLength, inhalePauseLengthVariance, ...
    exhalePausePct, exhalePauseAvgLength, exhalePauseLengthVariance, ...
    pauseAmplitude, pauseAmplitudeVariance, signalNoise)

% Simulates a recording of human airflow data according to the
% specified parameters by appending individually constructed sin waves and 
% pauses in sequence.
% Because some of these features are statistical, the resultant simulation
% may deviate slightly from the desired input.
% Many parameters interact so errors may occur if extreme values are used.

% PARAMETERS: 
% nCycles : number of breathing cycles to simulate
% srate : sampling rate
% breathingRate : average breathing rate
% averageAmplitude : average amplitude of inhales and exhales
% amplitudeVariance : variance in respiratory amplitudes
% phaseVariance : variance in duration of individual breaths, ...
% inhalePausePct : percent of inhales followed by a pause
% inhalePauseAvgLength : average length of inhale pauses
% inhalePauseLengthVariance : variance in inhale pause length
% exhalePausePct : percent of exhales followed by a pause
% exhalePauseAvgLength : average length of exhale pauses
% exhalePauseLengthVariance : variance in exhale pause length
% pauseAmplitude : noise amplitude of pauses
% pauseAmplitudeVariance : variance in pause noise
% signalNoise : percent of noise saturation in the simulated signal

% RETURNS:
% simulatedRespiration : simulated respiratory signal
% rawFeatures : indices and durations of each breath onset, peak, and pause
% featureStats : statistics features embeded in simulatedRespiration

if nargin < 1
    nCycles = 100; % 
end
if nargin < 2
    srate = 1000; % 1000 hz sampling rate
end

if nargin < 3
    breathingRate = .25; % breathe once every 4 seconds
end

if nargin < 4
    averageAmplitude = 0.5; % amplitude of inhales and exhales
end

if nargin < 5
    amplitudeVariance = 0.2; % variance in amplitudes
end

if nargin < 6
    phaseVariance = 0.1; % variance in breathing rate
end

if nargin < 7
    inhalePausePct = 0.3; % percent of breaths with pauses
end

if nargin < 8
    inhalePauseAvgLength = 0.2; % length of pauses
end

if nargin < 9
    inhalePauseLengthVariance = 0.5; % variance in length of pauses
end

if nargin < 10
    exhalePausePct = 0.3; % percent of breaths with pauses
end

if nargin < 11
    exhalePauseAvgLength = 0.2; % length of pauses
end

if nargin < 12
    exhalePauseLengthVariance = 0.5; % variance in length of pauses
end

if nargin < 13
    pauseAmplitude = 0.1; % amplitude of pause noise
end

if nargin < 14
    pauseAmplitudeVariance = 0.2; % variance in pause amplitudes
end

if nargin < 15
    signalNoise = 0.1; % percent signal noise
end

samplePhase = srate / breathingRate;
inhalePausePhase = round(inhalePauseAvgLength * samplePhase);
exhalePausePhase = round(exhalePauseAvgLength * samplePhase);

% normalize variance by average breath amplitude
normedAmplitudeVariance = averageAmplitude * amplitudeVariance;
amplitudesWithNoise = randn(1,nCycles) * normedAmplitudeVariance + ...
    averageAmplitude;

% normalize phase by average breath length
normedPhaseVariance = phaseVariance * samplePhase;
phasesWithNoise = round(randn(1,nCycles) * normedPhaseVariance + samplePhase);

% normalize pause lengths by phase and variation
normedInhalePauseLengthVariance = inhalePausePhase * inhalePauseLengthVariance;
inhalePauseLengthsWithNoise = round(randn(1,nCycles) * normedInhalePauseLengthVariance + inhalePausePhase);
normedExhalePauseLengthVariance = exhalePausePhase * exhalePauseLengthVariance;
exhalePauseLengthsWithNoise = round(randn(1,nCycles) * normedExhalePauseLengthVariance + inhalePausePhase);

% normalize pause amplitudes
normedPauseAmplitudeVariance = pauseAmplitude * pauseAmplitudeVariance;

% initialize empty vector to fill with simulated data
simulatedRespiration = [];

% initialize parameters to save
inhaleOnsets=zeros(1,nCycles);
exhaleOnsets=zeros(1,nCycles);

inhalePauseOnsets=zeros(1,nCycles);
exhalePauseOnsets=zeros(1,nCycles);

inhaleLengths=zeros(1,nCycles);
inhalePauseLengths=zeros(1,nCycles);

exhaleLengths=zeros(1,nCycles);
exhalePauseLengths=zeros(1,nCycles);

inhalePeaks=zeros(1,nCycles);
exhaleTroughs=zeros(1,nCycles);

i=1;
for c = 1:nCycles
    
    % determine length of inhale pause for this cycle
    if rand < inhalePausePct
        thisInhalePauseLength = inhalePauseLengthsWithNoise(1,c);
        thisInhalePause = randn(1,thisInhalePauseLength)*normedPauseAmplitudeVariance;
    else
        thisInhalePauseLength=0;
        thisInhalePause = [];
    end
    
    % determine length of exhale pause for this cycle
    if rand < exhalePausePct
        thisExhalePauseLength = exhalePauseLengthsWithNoise(1,c);
        thisExhalePause = randn(1,thisExhalePauseLength)*normedPauseAmplitudeVariance;
    else
        thisExhalePauseLength=0;
        thisExhalePause = [];
    end
    
    % determine length of inhale and exhale for this cycle to main
    % breathing rate
    cycleLength = phasesWithNoise(1,c) - (thisInhalePauseLength+thisExhalePauseLength);
    
    % if pauses are longer than the time alloted for this breath, set them
    % to 0 so a real breath can be simulated. This will deviate the
    % statistics from those initialized but is unavoidable at the current 
    % state.
    if cycleLength <= 0 || cycleLength < min(phasesWithNoise)/4
        thisInhalePauseLength=0;
        thisInhalePause=[];
        thisExhalePauseLength=0;
        thisExhalePause = [];
        cycleLength = phasesWithNoise(1,c) - (thisInhalePauseLength+thisExhalePauseLength);
    end
    
    % compute inhale and exhale of this cycle.
    thisCycle = sin(linspace(0, 2*pi, cycleLength)) ...
        * amplitudesWithNoise(1, c);
    halfCycle=round(length(thisCycle)/2);
    thisInhale = thisCycle(1:halfCycle);
    thisInhaleLength=length(thisInhale);
    thisExhale = thisCycle(halfCycle+1:end);
    thisExhaleLength=length(thisExhale);
    
    
    
    % save these parameters for checking
    inhaleLengths(1,c) = thisInhaleLength;
    inhalePauseLengths(1,c) = thisInhalePauseLength;
    exhaleLengths(1,c) = thisExhaleLength;
    exhalePauseLengths(1,c) = thisExhalePauseLength;
    inhaleOnsets(1,c) = i;
    exhaleOnsets(1,c) = i + thisInhaleLength + thisInhalePauseLength;
    
    if thisInhalePause
        inhalePauseOnsets(1,c) = i+thisInhaleLength;
    else
        inhalePauseOnsets(1,c) = nan;
    end
    
    if thisExhalePause
        exhalePauseOnsets(1,c) = i + thisInhaleLength + ...
            thisInhalePauseLength + thisExhaleLength;
    else
        exhalePauseOnsets(1,c) = nan;
    end
    
    % compose breath from parameters
    thisBreath = [thisInhale, thisInhalePause, thisExhale, thisExhalePause];
    
    % compute max flow for inhale and exhale for this breath
    [~,maxInd] = max(thisBreath);
    [~,minInd] = min(thisBreath);
    inhalePeaks(1,c) = i+maxInd;
    exhaleTroughs(1,c) = i+minInd;
    
    % append breath to simulated resperation vector
    simulatedRespiration(1, i:i+length(thisBreath) - 1) = thisBreath;
    i = i + length(thisBreath) - 1;
end

if signalNoise == 0
    signalNoise = 0.0001;
end

% add signal noise to simulated respiration
noiseVector = rand(size(simulatedRespiration)) * averageAmplitude;
simulatedRespiration = (simulatedRespiration * (1-signalNoise)) + (noiseVector * signalNoise);


% assign values to parameters for later analyses
params1KeySet= {
    'Inhale Onsets';
    'Exhale Onsets';
    'Inhale Pause Onsets';
    'Exhale Pause Onsets';
    'Inhale Lengths';
    'Inhale Pause Lengths';
    'Exhale Lengths';
    'Exhale Pause Lengths';
    'Inhale Peaks';
    'Exhale Troughs';
    };

params1ValueSet={
    inhaleOnsets; 
    exhaleOnsets;
    inhalePauseOnsets; 
    exhalePauseOnsets;
    inhaleLengths/srate;
    inhalePauseLengths/srate;
    exhaleLengths/srate;
    exhalePauseLengths/srate;
    inhalePeaks;
    exhaleTroughs;
    };

rawFeatures = containers.Map(params1KeySet,params1ValueSet);

params2KeySet= {
    'Breathing Rate';
    'Average Inhale Length';
    'Average Inhale Pause Length';
    'Average Exhale Length';
    'Average Exhale Pause Length';
    };

% calculating length of pauses only when they occur 
% (ignoring pauses of 0 length in calculation)
avgInhalePauseLength = mean(inhalePauseLengths(inhalePauseLengths>0));
if isempty(avgInhalePauseLength)
        avgInhalePauseLength=0;
end

avgExhalePauseLength = mean(exhalePauseLengths(exhalePauseLengths>0));
if isempty(avgExhalePauseLength)
        avgExhalePauseLength=0;
end

estimatedBreathingRate = (1/mean(diff(inhaleOnsets)))*srate;
params2ValueSet={
    estimatedBreathingRate
    mean(inhaleLengths/srate); 
    avgInhalePauseLength/srate;
    mean(exhaleLengths/srate);
    avgExhalePauseLength/srate;
    };

featureStats = containers.Map(params2KeySet,params2ValueSet);

end
    
