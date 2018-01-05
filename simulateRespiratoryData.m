function [simulatedRespiration, params1, params2] = simulateRespiratoryData(nCycles, srate, ...
    breathingRate, averageAmplitude, amplitudeVariance, phaseVariance, ...
    inhalePausePct, inhalePauseAvgLength, inhalePauseLengthVariance, ...
    exhalePausePct, exhalePauseAvgLength, exhalePauseLengthVariance, ...
    pauseAmplitude, pauseAmplitudeVariance, signalNoise)

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
    inhalePausePct = 0.1; % percent of breaths with pauses
end

if nargin < 8
    inhalePauseAvgLength = 0.1; % length of pauses
end

if nargin < 9
    inhalePauseLengthVariance = 0.5; % variance in length of pauses
end

if nargin < 10
    exhalePausePct = 0.1; % percent of breaths with pauses
end

if nargin < 11
    exhalePauseAvgLength = 0.1; % length of pauses
end

if nargin < 12
    exhalePauseLengthVariance = 0.5; % variance in length of pauses
end

if nargin < 13
    pauseAmplitude = 0.1; % amplitude of pause noise
end

if nargin < 14
    pauseAmplitudeVariance = 0.2; % variance in pause lengths
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
inhaleLengths=zeros(1,nCycles);
inhalePauseLengths=zeros(1,nCycles);
exhaleLengths=zeros(1,nCycles);
exhalePauseLengths=zeros(1,nCycles);

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
    
    % compute inhale and exhale of this cycle.
    thisCycle = sin(linspace(0, 2*pi, cycleLength)) ...
        * amplitudesWithNoise(1, c);
    halfCycle=round(length(thisCycle)/2);
    thisInhale = thisCycle(1:halfCycle);
    thisInhaleLength=length(thisInhale);
    thisExhale = thisCycle(halfCycle+1:end);
    thisExhaleLength=length(thisExhale);
    
    % save these parameters for checking
    inhaleLengths(1,c) = thisInhaleLength/srate;
    inhalePauseLengths(1,c) = thisInhalePauseLength/srate;
    exhaleLengths(1,c) = thisExhaleLength/srate;
    exhalePauseLengths(1,c) = thisExhalePauseLength/srate;
    inhaleOnsets(1,c) = i/srate;
    exhaleOnsets(1,c) = (i + thisInhaleLength + thisInhalePauseLength)/srate;
    
    % append it to simulated resperation vector
    thisBreath = [thisInhale, thisInhalePause, thisExhale, thisExhalePause];
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
    'Inhale Lengths';
    'Inhale Pause Lengths';
    'Exhale Lengths';
    'Exhale Pause Lengths';
    };

params1ValueSet={
    inhaleOnsets; 
    exhaleOnsets; 
    inhaleLengths;
    inhalePauseLengths;
    exhaleLengths;
    exhalePauseLengths;
    };

params1 = containers.Map(params1KeySet,params1ValueSet);

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

estimatedBreathingRate = 1/mean(diff(inhaleOnsets));
params2ValueSet={
    estimatedBreathingRate
    mean(inhaleLengths); 
    avgInhalePauseLength;
    mean(exhaleLengths);
    avgExhalePauseLength;
    };

params2 = containers.Map(params2KeySet,params2ValueSet);

end
    
