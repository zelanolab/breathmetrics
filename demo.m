%% Demo for The Respiratory Flow Signal Processing Toolbox
% Breathmetrics is a toolbox for automatically characterizing features 
% respiratory flow

% This demo will demonstrate how to run breathmetrics on a dataset to
% extract respiratory features, access the features of interest, calculate
% summaries of these features, and visualize them.

%% SETUP:
% To use BreathMetrics, simply add this directory and all of its 
% subdirectories to your matlab path. All functions in the
% breathmetrics_functions directory can be called independantly but it is
% recommended that you call them within the breathmetrics class object as
% demonstrated below.

%% Simulating Data for analysis
% Simulate data for demo
nBreathingCycles=100; % number of breathing cycles to simulate
srate=2000; % sampling rate
breathingRate=.25; % breathing rate
averageAmplitude=2; % average flow of inhales and exhales
amplitudeVariance=.25; % variance in inhale and exhale amplitudes [0,1]
phaseVariance=.1; % variance in inter-breath intervals [0,1]
inhalePausePct=.3; % proportion of inhales followed by a pause [0,1]
inhalePauseAvgLength=.1; % proportion of inhale occupied by pause [0,1]
inhalePauseLengthVariance=.2; % variance in inhale pause lengths [0,1]
exhalePausePct=.3; % proportion of inhales followed by a pause [0,1]
exhalePauseAvgLength=.1; % proportion of exhale occupied by pause [0,1]
exhalePauseLengthVariance=.2; % variance in exhale pause lengths [0,1]
pauseAmplitude=.1; % amplitude of pauses
pauseAmplitudeVariance=.2; % variance in amplitude of pauses [0,1]
signalNoise = 0; % proportion of signal that is noise [0,1]

[simulatedRespiration, params1, params2] = simulateRespiratoryData(nBreathingCycles, srate, ...
    breathingRate, averageAmplitude, amplitudeVariance, phaseVariance, ...
    inhalePausePct, inhalePauseAvgLength, inhalePauseLengthVariance, ...
    exhalePausePct, exhalePauseAvgLength, exhalePauseLengthVariance, ...
    pauseAmplitude, pauseAmplitudeVariance, signalNoise);
dataType = 'human';

%% Load sample data for analysis
respiratoryData = load('sample_data.mat');
respiratoryTrace = respiratoryData.resp;
srate = respiratoryData.srate;
dataType = 'human';

%%
% All analyses are done with the breathmetrics class.
% It requires three inputs:
% 1. A vector of respirometer data 
% 2. A sampling rate
% 3. A data type: 'human' is the only kind that currently works


% initialize class

% simulated
%bm = breathmetrics(sim_resp, sim_srate, data_type);

% real data
bm = breathmetrics(respiratoryTrace, srate, dataType);

% bm is now a class object with many properites, most will be empty
% call bm to see its properties
% rawRespiration is the raw vector of respiratory data.
% smoothedRespiration is that vector mean smoothed by 50 ms window. This
% is not fully baseline corrected yet.
% srate is your sampling rate
% time is a 1xN vector where each point represents where each sample in the
% other fields occur in real time.

% run bm.estimateAllFeatures() to gather them all and skip to statistics
% and visualization methods

% run the following cells in sequence as the calculations depend on the
% preceeding ones

%% 1. De-noising respiration and correcting to baseline

% print out steps as they go. Set to 0 to silence.
verbose=1; 

%use a sliding window to correct respiratory data to baseline
baselineCorrectionMethod = 'sliding'; 
% 'simple' uses the mean. It isless accurate but faster
%baseline_correction_method = 'simple';

%zScore (1 or 0). 1 z-scores the amplitude values in the recording. Better
%for between-subject comparisions. 0 does not z-score the data.
zScore=0;

bm.correctRespirationToBaseline(baselineCorrectionMethod, zScore, verbose)
%bm.estimateAllFeatures(verbose);

% NOTE: the methods below check if baseline correction as been performed.
% If there is a value in bm.baselineCorrectedRespiration, these analyses
% will automatically be performed on this data.
% If not, smoothedRespiration will be used. This is allowed, but not 
% advised as baseline correction is necessary for accurate feature 
% extraction.

%plot 1 minute of sample data
PLOT_LIMITS = 1:60000;
figure; hold all;

r=plot(bm.time(PLOT_LIMITS),bm.rawRespiration(PLOT_LIMITS),'k-');
sm=plot(bm.time(PLOT_LIMITS),bm.smoothedRespiration(PLOT_LIMITS),'b-');
bc=plot(bm.time(PLOT_LIMITS),bm.baselineCorrectedRespiration(PLOT_LIMITS),'r-');
legend([r,sm,bc],{'Raw Respiration';'Smoothed Respiration';'Baseline Corrected Respiration'});
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2. extracting features from respiration
% many features can be extracted from respiratory flow recordings but they
% must be called in the sequence described here. i.e. Calculating a feature 
% such as inhale volumes requires that the extrema and onsets have been
% calculated.

%% 2.1 finding peaks and troughs

bm.findExtrema(verbose);
% points where peaks and troughs occur can be accessed at bm.inhalePeaks
% and bm.exhale_troughs, respectively.
% similarly, the peak inspiratory and expiratory flow can be accessed at 
% bm.peakInspiratoryFlows and bm.troughExpiratoryFlows

% points where the first 10 inhale peaks occur
disp(bm.inhalePeaks(1:10))

% flow value at those peaks
disp(bm.peakInspiratoryFlows(1:10))


% NOTE: To standardize data, inhales always occur before exhales.
% i.e. bm.inhalePeaks(k) will always be < bm.exhaleTroughs(k). 
% This way it is easy to index which breaths occur when.


% plot these features
inhalePeaksWithinPlotlimits = find(bm.inhalePeaks >= min(PLOT_LIMITS) ...
    & bm.inhalePeaks < max(PLOT_LIMITS));
exhaleTroughsWithinPlotlimits = find(bm.exhaleTroughs >= ...
    min(PLOT_LIMITS) & bm.exhaleTroughs < max(PLOT_LIMITS));

figure; hold all;
re=plot(bm.time(PLOT_LIMITS), ...
    bm.baselineCorrectedRespiration(PLOT_LIMITS), 'k-');
ip=scatter(bm.time(bm.inhalePeaks(inhalePeaksWithinPlotlimits)), ...
    bm.peakInspiratoryFlows(inhalePeaksWithinPlotlimits),'ro','filled');
et=scatter(bm.time(bm.exhaleTroughs(exhaleTroughsWithinPlotlimits)), ...
    bm.troughExpiratoryFlows(exhaleTroughsWithinPlotlimits), ...
    'bo', 'filled');
legendText = {
    'Baseline Corrected Respiration';
    'Inhale Peaks'; 
    'Exhale Troughs'
    };
legend([re,ip,et],legendText);
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.2 estimate inhale and exhale onsets, and pauses
bm.findOnsetsAndPauses(verbose);

% first 10 inhale onsets
disp(bm.inhaleOnsets(1:10));

% NOTE: each breath onset is indexed at the peak of the same breath.
% i.e. bm.inhaleOnsets(k) is the same breath as bm.inhalePeaks(k).

% first 10 inhale pauses
disp(bm.inhalePauseOnsets);

% NOTE: if a pause does not occur at breath k, bm.inhalePauseOnsets(k)
% will be nan.
% Similar to onsets, pauses are indexed at the same breath.
% bm.inhaleOnsets(k) will always be < bm.pauseOnsets(k) if a pause occurs

% plot these features

inhaleOnsetsWithinPlotLimits = find(bm.inhaleOnsets >= min(PLOT_LIMITS) ...
    & bm.inhaleOnsets<max(PLOT_LIMITS));
exhaleOnsetsWithinPlotLimits = find(bm.exhaleOnsets >= min(PLOT_LIMITS) ...
    & bm.exhaleOnsets<max(PLOT_LIMITS));
inhalePausesWithinPlotLimits = find(bm.inhalePauseOnsets >= ...
    min(PLOT_LIMITS) & bm.inhalePauseOnsets < max(PLOT_LIMITS));
exhalePausesWithinPlotLimits = find(bm.exhalePauseOnsets >= ...
    min(PLOT_LIMITS) & bm.exhalePauseOnsets<max(PLOT_LIMITS));

figure; hold all;
re=plot(bm.time(PLOT_LIMITS), ...
    bm.baselineCorrectedRespiration(PLOT_LIMITS),'k-');
io=scatter(bm.time(bm.inhaleOnsets(inhaleOnsetsWithinPlotLimits)), ...
    bm.baselineCorrectedRespiration( ...
    bm.inhaleOnsets(inhaleOnsetsWithinPlotLimits)),'bo','filled');
eo=scatter(bm.time(bm.exhaleOnsets(exhaleOnsetsWithinPlotLimits)), ...
    bm.baselineCorrectedRespiration(bm.exhaleOnsets( ...
    exhaleOnsetsWithinPlotLimits)), 'ro', 'filled');
ip=scatter(bm.time(bm.inhalePauseOnsets(inhalePausesWithinPlotLimits)) ...
    ,bm.baselineCorrectedRespiration(bm.inhalePauseOnsets( ...
    inhalePausesWithinPlotLimits)), 'go', 'filled');
ep=scatter(bm.time(bm.exhalePauseOnsets(exhalePausesWithinPlotLimits)), ...
    bm.baselineCorrectedRespiration(bm.exhalePauseOnsets( ...
    exhalePausesWithinPlotLimits)), 'yo', 'filled');
legendText={
    'Baseline Corrected Respiration';
    'Inhale Onsets';'Exhale Onsets';
    'Inhale Pause Onsets';
    'Exhale Pause Onsets'
    };
legend([re,io,eo,ip,ep],legendText);
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.3 calculate breath offsets
% each breath ends when either a pause occurs or the next breath begins
% this function finds the appropriate endpoint for each breath

bm.findInhaleAndExhaleOffsets(bm);

% plot these features

inhaleOnsetsWithinPlotLimits = find(bm.inhaleOnsets >= ...
    min(PLOT_LIMITS) & bm.inhaleOnsets<max(PLOT_LIMITS));
exhaleOnsetsWithinPlotLimits = find(bm.exhaleOnsets >= ...
    min(PLOT_LIMITS) & bm.exhaleOnsets<max(PLOT_LIMITS));
inhaleOffsetsWithinPlotLimits = find(bm.inhaleOffsets >= ...
    min(PLOT_LIMITS) & bm.inhaleOffsets < max(PLOT_LIMITS));
exhaleOffsetsWithinPlotLimits = find(bm.exhaleOffsets >= ...
    min(PLOT_LIMITS) & bm.exhaleOffsets < max(PLOT_LIMITS));

figure; hold all;
re=plot(bm.time(PLOT_LIMITS), ...
    bm.baselineCorrectedRespiration(PLOT_LIMITS),'k-');
io=scatter(bm.time(bm.inhaleOnsets(inhaleOnsetsWithinPlotLimits)), ...
    bm.baselineCorrectedRespiration(bm.inhaleOnsets( ...
    inhaleOnsetsWithinPlotLimits)), 'bo', 'filled');
eo=scatter(bm.time(bm.exhaleOnsets(exhaleOnsetsWithinPlotLimits)), ...
    bm.baselineCorrectedRespiration(bm.exhaleOnsets( ...
    exhaleOnsetsWithinPlotLimits)),'ro','filled');
ip=scatter(bm.time(bm.inhaleOffsets(inhaleOffsetsWithinPlotLimits)), ...
    bm.baselineCorrectedRespiration(bm.inhaleOffsets( ...
    inhaleOffsetsWithinPlotLimits)),'go','filled');
ep=scatter(bm.time(bm.exhaleOffsets(exhaleOffsetsWithinPlotLimits)), ...
    bm.baselineCorrectedRespiration(bm.exhaleOffsets( ...
    exhaleOffsetsWithinPlotLimits)),'yo','filled');
legendText = {
    'Baseline Corrected Respiration';
    'Inhale Onsets';
    'Exhale Onsets';
    'Inhale Offsets';
    'Exhale Offsets'};
legend([re,io,eo,ip,ep],legendText);
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.4 calculate breath lengths
% calculate the length of each breath and pause
bm = findBreathAndPauseLengths(bm);

% plot these features
figure; hold all;
re=plot(bm.time(PLOT_LIMITS), ...
    bm.baselineCorrectedRespiration(PLOT_LIMITS), 'k-');
for i=[1,3,5,7]
    text(bm.time(bm.inhalePeaks(i)),bm.peakInspiratoryFlows(i), ...
        sprintf('Inhale: %i, %.2f s',i,bm.inhaleLengths(i)));
    text(bm.time(bm.exhaleTroughs(i)),bm.troughExpiratoryFlows(i), ...
        sprintf('Exhale: %i, %.2f s',i,bm.exhaleLengths(i)));
    text(bm.time(bm.inhalePeaks(i))+1,bm.peakInspiratoryFlows(i)-.2, ...
        sprintf('Inhale Pause: %i, %.2f s',i,bm.inhalePauseLengths(i)));
    text(bm.time(bm.exhaleTroughs(i))+1,bm.troughExpiratoryFlows(i)-.2, ...
        sprintf('Exhale Pause: %i, %.2f s',i,bm.exhalePauseLengths(i)));
end
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.5 calculate breath volumes
bm.findInhaleAndExhaleVolumes(verbose);

% plot these features
figure; hold all;
re=plot(bm.time(PLOT_LIMITS), ...
    bm.baselineCorrectedRespiration(PLOT_LIMITS), 'k-');
for i=1:5
    text(bm.time(bm.inhalePeaks(i)), bm.peakInspiratoryFlows(i), ...
        sprintf('Inhale: %i, Volume: %.2f',i,bm.inhaleVolumes(i)));
    text(bm.time(bm.exhaleTroughs(i)),bm.troughExpiratoryFlows(i), ...
        sprintf('Exhale: %i, Volume: %.2f',i,bm.exhaleVolumes(i)));
end
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.6 rapidly calculate all of the features shown above

% all of the features above can be called in sequence using the following
% code:
bm.estimateAllFeatures(verbose);
% NOTE: this uses default parameters for baseline correction (sliding 
% baseline correction window).

%% 2.7 Respiratory phase

% We have included code to calculate instantaneus respiratory phase using
% the angle of hilbert transformed data filtered by the average breathing 
% rate.
% However, this method is not recommended, as breath pauses and onsets
% often change amplitudes without changing phase so it may lead to false
% conclusions that should be reproduced using the other methods.

% If desired, this calculation can be performed using:
% bm.calculateRespiratoryPhase(customFilter, rate_estimation, verbose)

% if a custom filter is left empty, this butterworth filter will be used:
% myfilter = designfilt('lowpassfir', 'PassbandFrequency', filt_center, ...
%                           'StopbandFrequency',filt_center + 0.2);
% breathing rate estimation can be calculated using the breathing rate
% found using the summary statistic method below by calling 
% 'feature_derived' or can be calculated using the peak of the power
% spectrum by calling 'pspec'

%% 3 calculate summary statistics 
bm.estimateAllFeatures(verbose);

% these can be viewed easily using bm.dispSecondaryFeatures();

% secondary statistics are stored as key:value pairs.
% Values can be called using their corresponding key.
statKeys = bm.secondaryFeatures.keys();
breathingRateKey = statKeys{11}; % 'Breathing Rate'
breathingRate = bm.secondaryFeatures(breathingRateKey);
fprintf('\nBreathing Rate: %.2g \n', breathingRate);

%% 4 visualize all of the features that this toolbox can calculate
% bm.plotFeatures() allows you to see the location and value of each
% feature that has been calculated.
% because many features can be estimated, the user can choose which ones to
% annotate using the following options:
annotations = {'extrema', 'onsets','maxflow','volumes', 'pauses'};

% examples
fig = bm.plotFeatures({annotations{1},annotations{3}});
fig = bm.plotFeatures(annotations{5});

%% 4.1 visualize breath compositions

% the following code allows the user to see a summary of which phases
% breaths spend time in.

% these can be visualized in three ways: 'raw', 'normalized', or 'line'

fig = bm.plotCompositions('raw');
fig = bm.plotCompositions('normalized');
fig = bm.plotCompositions('line');



%% 4.2 calculate and plot event related respiratory responses

% like an event related potential in neural recordings, see breathing
% changes around a certain event type.

% Pick events to visualize. For this example, we will use inhale onsets but
% this can be experimental events as well.
myEvents = bm.inhaleOnsets;

% set number of samples before and after events to visualize
pre=500;
post=4000;

% NOTE: If any events or surrounding windows fall outside of the
% respiratory recording, their data will not be included in this
% visualization and the user will be notivied.

% First calculate the erp matrix of breath amplitudes x time using:
bm.calculateERP(myEvents, pre, post);

% To access the data of event related potentials you can use:
% bm.ERPMatrix 
%to get the amplitude values and: 
%bm.ERPxAxis 
% to get the timing of the events in real time.

% plot the data stored in the class using:
bm.plotRespiratoryERP('simple');


%% 4.3 calculate and plot resampled event related respiratory responses
% because individuals breathe at different rates, it might be desirable to
% plot respiratory event related responses as a function of point in the
% breathing cycle, regardless of the period.

% this can be done by first selecting the proportion of the breathing cycle
% to plot before and after. 1 is a full cycle
preResampled = .5;
postResampled = 1;
bm.calculateResampledERP(myEvents, preResampled, postResampled);

% To access the data of resampled event related potentials you can use:
% bm.resampledERPMatrix 
%to get the amplitude values and: 
%bm.resampledERPxAxis 
% to get the normalized points in phase.

% plot it
bm.plotRespiratoryERP('resampled');

%% That's all! 
