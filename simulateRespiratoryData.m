function [simulatedRespiration, fig] = simulateRespiratoryData(nSamples, srate, ...
    breathingRate, averageAmplitude, amplitudeVariance, phaseVariance, ...
    pctPhasePause, averagePauseLength, pauseLengthVariance, ...
    pauseAmplitude, pauseAmplitudeVariance)

% nSamples, 
% srate
% breathingRate
% averageAmplitude
% amplitudeVariance
% phaseVariance
% pctPhasePause
% averagePauseLength
% pauseLengthVariance
% pauseAmplitude
% pauseAmplitudeVariance

if nargin < 1
    nSamples = 200000; % 200000 samples
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
    pctPhasePause = 0.75; % percent of breaths with pauses
end

if nargin < 8
    averagePauseLength = 0.1; % length of pauses
end

if nargin < 9
    pauseLengthVariance = 0.5; % variance in length of pauses
end

if nargin < 10
    pauseAmplitude = 0.1; % amplitude of pause noise
end

if nargin < 11
    pauseAmplitudeVariance = 0.2; % variance in pause lengths
end

if nargin < 12
    plotMe = 1;
end

samplePhase = srate / breathingRate;
pausePhase = round(averagePauseLength * samplePhase);

% produce this many total cycles of simulated data. Make more than expected
% because high varience in phase can randomly make too little data than 
% desired.
nCycles = ceil(nSamples / samplePhase) * 2;
normedAmplitudeVariance = averageAmplitude * amplitudeVariance;
amplitudesWithNoise = randn(1,nCycles) * normedAmplitudeVariance + ...
    averageAmplitude;
normedPhaseVariance = phaseVariance * samplePhase;
phasesWithNoise = round(randn(1,nCycles) * normedPhaseVariance + samplePhase);

normedPauseLengthVariance = pausePhase * pauseLengthVariance;
pauseLengthsWithNoise = round(randn(1,nCycles) * normedPauseLengthVariance + pausePhase);
normedPauseAmplitudeVariance = pauseAmplitude * pauseAmplitudeVariance;
pauseAmplitudesWithNoise = randn(1,nCycles) * normedPauseAmplitudeVariance + pauseAmplitude;

% initialize empty vector to fill with simulated data
simulatedRespiration = zeros(1,nSamples * 2);
i=1;
for c = 1:nCycles
    % compute this respiratory oscillation. adding in random variation to
    % oscillation length and amplitude
    thisCycle = sin(linspace(0,2 * pi, phasesWithNoise(1, c))) ...
        * amplitudesWithNoise(1, c);
    % append it to simulated resperation vector
    simulatedRespiration(1, i:i+length(thisCycle) - 1) = thisCycle;
    i = i + length(thisCycle) - 1;
    
    % add phase pause
    if rand < pctPhasePause
        thisPauseLength = pauseLengthsWithNoise(1,c);
        thisPauseAmplitude = pauseAmplitudesWithNoise(1,c);
        simulatedRespiration(i:i+thisPauseLength-1) = thisPauseAmplitude;
        i=i+thisPauseLength;
    end
end

simulatedRespiration=simulatedRespiration(1,1:nSamples);

if plotMe == 1
    fig = figure; hold all;
    subplot(2,1,1)
    timeVector = (1:nSamples) / srate;
    plot(timeVector, simulatedRespiration, 'k-');
    xlabel('Time (s)');
    ylabel('Amplitude (AU)');
    subplot(2,1,2)
    TableData = [ nSamples srate breathingRate averageAmplitude ...
        amplitudeVariance phaseVariance pctPhasePause ...
        averagePauseLength pauseLengthVariance pauseAmplitude ...
        pauseAmplitudeVariance];
    ColumnNames = {
        'nSamples';
        'srate';
        'breathingRate';
        'averageAmplitude';
        'amplitudeVariance';
        'phaseVariance';
        'pctPhasePause';
        'averagePauseLength';
        'pauseLengthVariance';
        'pauseAmplitude';
        'pauseAmplitudeVariance'; 
    };
    uitable('Data', TableData, 'ColumnName', ColumnNames, ...
    'Units', 'Normalized', 'Position', [0, 0, 1, .5]);
end
    
