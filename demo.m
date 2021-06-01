%% Demo for The Respiratory Flow Signal Processing Toolbox
% Breathmetrics is a toolbox for automatically characterizing features 
% respiratory flow

% This demo will demonstrate how to run breathmetrics on a dataset to
% extract respiratory features, access the features of interest, calculate
% summaries of these features, and visualize them.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PLEASE READ THROUGH THIS BEFORE USING THIS CODE FOR ANY ACADEMIC PROJECT
%
% If you encounter a problem that was not addressed in the text below,
% please email me (Torben Noto) at torben.noto@gmail.com with questions.
% I'd be happy to help you get this working.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%% SETUP:
% To use BreathMetrics, simply add this directory and all of its 
% subdirectories to your matlab path. 
% read about the 'pathtool' function if that sentance didn't make sense to
% you.

% All functions in the breathmetrics_functions directory can be called 
% independantly but it is recommended that you call them within the 
% breathmetrics class object as demonstrated below.


%% Organization of Demo

% 1. Get started quickly

% 2. Load your respiratory data into matlab and initialize the 
%    breathmetrics class

% 3. De-noise and baseline correcting the respiratory signal

% 4. Automatically extract all respiratory features

% 5. Automatically extract individual respiratory features

% 6. Visualize respiratory data and features

% 7. Other methods (instantaneous phase and simulating respiratory data)

%% 1: Getting Started Quickly
% There are really just two lines of code that you will need to know to 
% use this toolbox:

% initialize the class with your data, sampling rate and data type
% bmObj = breathmetrics(respiratoryRecording, srate, dataType);

% automatically estimate all of the respiratory features
%bmObj.estimateAllFeatures( zScore, baselineCorrectionMethod, verbose );
% You can also just use:
% bmObj.estimateAllFeatures();

% all features are stored in the bm object i.e. bm.inhaleDurations

% If you plan on doing a detailed analysis on your respiratory data, it is
% highly recommended that you read through the following cells to
% understand the methods.


%% 2.1: Load sample data for analysis

% if you have your own data, type the path to it into rootDir and the name
% of the file in respDataFileName
rootDir='';
respDataFileName='sample_data.mat';

% sample data contains 
respiratoryData = load(fullfile(rootDir,respDataFileName));

respiratoryRecording = respiratoryData.resp;
srate = respiratoryData.srate;
dataType = 'humanAirflow';


%% 2.2. Initializing the breathmetrics class with your data.

% All analyses in this toolbox are done with the breathmetrics class.

% The breathmetrics class requires three inputs:
% 1. A vector of respiratory data 
% 2. A sampling rate
% 3. A data type: 'humanAirflow' has been rigerously validated but 
% 'humanBB', 'rodentAirflow', and 'rodentThermocouple' data types are also
% supported.

% initialize the class

bmObj = breathmetrics(respiratoryRecording, srate, dataType);

% bmObj is now a class object with many properites, most will be empty at
% this point. 

% Call bmObj to see its properties

% rawRespiration is the raw vector of respiratory data.

% smoothedRespiration is that vector mean smoothed by 50 ms window. This
% is not fully baseline corrected yet.

% srate is your sampling rate

% time is a 1xN vector where each point represents where each sample in the
% other fields occur in real time.

%% 3: De-noiseing and baseline correcting the respiratory signal

% verbose prints out steps as they go. Set to 0 to silence.
verbose=1; 

% there are two methods for baseline correcting your respiratory data:
% * average over a slinding window
% * average over the mean and set to zero

% The sliding window is the most accurate method but takes slightly longer
baselineCorrectionMethod = 'sliding'; 
% baselineCorrectionMethod can be set to 'simple' to set the baseline as 
% the mean. It is a fraction less accurate but far faster.
%baselineCorrectionMethod = 'simple';

% the default baseline correction method is 'sliding'.


% zScore (0 or 1). 
% if zScore is set to 1, the amplitude in the recording will be normalized. 
% z-scoring can be helpful for comparing certain features for
% between-subject analyzes. 
% the default value is 0

zScore=0;

bmObj.correctRespirationToBaseline(baselineCorrectionMethod, zScore, verbose)


%plot 1 minute of sample data
PLOT_LIMITS = 1:60000;
figure; hold all;

r=plot(bmObj.time(PLOT_LIMITS),bmObj.rawRespiration(PLOT_LIMITS),'k-');
sm=plot(bmObj.time(PLOT_LIMITS),bmObj.smoothedRespiration(PLOT_LIMITS),'b-');
bc=plot(bmObj.time(PLOT_LIMITS),bmObj.baselineCorrectedRespiration(PLOT_LIMITS),'r-');
legend([r,sm,bc],{'Raw Respiration';'Smoothed Respiration';'Baseline Corrected Respiration'});
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 4: Automatically extract all respiratory features.

% After you've initialized a breathmetrics object, execute the following 
% line of code and breathmetrics will automatically calculate all of the 
% features that it can in your data.
bmObj.estimateAllFeatures;


% this can also be called along with the following arguments:

% bmObj.estimateAllFeatures(zScore, baselineCorrectionMethod, ...
%     simplify, verbose);

% zScore: 0 (default) or 1 : z-scores the amplitude of the respiratory
%   recording. Helpful for comparing inter-subject comparisons
% baselineCorrectionMethod 'sliding' (default) or 'simple' : use baseline 
%   correction method in section above 
% simplify 0 or 1 (default): sets nInhales equal to nExhales. You must have
% equal nInhales and nExhales to use the GUI.
% verbose: 0 (default) or 1: prints output of inner functions

%% 5: Automatically extract individual respiratory features

% It is far easier and safer to estimate all of the features at once as 
% shown in the cell above, compared to extracting them individually. The
% purpose of the following cells is to explain what breathmetrics is doing.

% Many features can be extracted from respiratory flow recordings but they
% must be called in the sequence described here. 

% For example, Calculating breath volumes requires that breath onsets and
% offsets have already been found.

% NOTE: the methods below check if baseline correction as been performed.
% If there is a value in bm.baselineCorrectedRespiration, these analyses
% will automatically be performed on this data.
% If not, smoothedRespiration will be used. This is allowed, but not 
% advised as baseline correction is necessary for accurate feature 
% extraction.

%% 5.1 Finding peaks and troughs

simplify=1;

bmObj.findExtrema(simplify, verbose);
% points where peaks and troughs occur can be accessed at bm.inhalePeaks
% and bm.exhale_troughs, respectively.
% similarly, the peak inspiratory and expiratory flow can be accessed at 
% bm.peakInspiratoryFlows and bm.troughExpiratoryFlows

% simplify sets the number of inhales to the number of exhales.
% The reason for this is that sometimes the features of the final exhale
% cannot be parameterized, leaving mismatched numbers of inhales and
% exhales
% setting simplify to 1 discards the final inhale so that the numbers are
% the same. This is needed to use the GUI

nPlot=10;
% points where the first nPlot inhale peaks occur
disp(bmObj.inhalePeaks(1:nPlot))

% flow value at those peaks
disp(bmObj.peakInspiratoryFlows(1:nPlot))


% NOTE: To standardize data, inhales always occur before exhales.
% i.e. bm.inhalePeaks(k) will always be < bm.exhaleTroughs(k). 
% This way it is easy to index which breaths occur when.


% plot these features
inhalePeaksWithinPlotlimits = find(bmObj.inhalePeaks >= min(PLOT_LIMITS) ...
    & bmObj.inhalePeaks < max(PLOT_LIMITS));
exhaleTroughsWithinPlotlimits = find(bmObj.exhaleTroughs >= ...
    min(PLOT_LIMITS) & bmObj.exhaleTroughs < max(PLOT_LIMITS));

figure; hold all;
re=plot(bmObj.time(PLOT_LIMITS), ...
    bmObj.baselineCorrectedRespiration(PLOT_LIMITS), 'k-');
ip=scatter(bmObj.time(bmObj.inhalePeaks(inhalePeaksWithinPlotlimits)), ...
    bmObj.peakInspiratoryFlows(inhalePeaksWithinPlotlimits),'ro','filled');
et=scatter(bmObj.time(bmObj.exhaleTroughs(exhaleTroughsWithinPlotlimits)), ...
    bmObj.troughExpiratoryFlows(exhaleTroughsWithinPlotlimits), ...
    'bo', 'filled');
legendText = {
    'Baseline Corrected Respiration';
    'Inhale Peaks'; 
    'Exhale Troughs'
    };
legend([re,ip,et],legendText);
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 5.2 Estimate inhale and exhale onsets, and pauses
bmObj.findOnsetsAndPauses(verbose);

nPlot=10;
% first nPlot inhale onsets
disp(bmObj.inhaleOnsets(1:nPlot));

% NOTE: each breath onset is indexed at the peak of the same breath.
% i.e. bm.inhaleOnsets(k) is the same breath as bm.inhalePeaks(k).

% first 10 inhale pauses
disp(bmObj.inhalePauseOnsets);

% NOTE: if a pause does not occur at breath k, bm.inhalePauseOnsets(k)
% will be nan.
% Similar to onsets, pauses are indexed at the same breath.
% bm.inhaleOnsets(k) will always be < bm.pauseOnsets(k) if a pause occurs

% plot these features

inhaleOnsetsWithinPlotLimits = find(bmObj.inhaleOnsets >= min(PLOT_LIMITS) ...
    & bmObj.inhaleOnsets<max(PLOT_LIMITS));
exhaleOnsetsWithinPlotLimits = find(bmObj.exhaleOnsets >= min(PLOT_LIMITS) ...
    & bmObj.exhaleOnsets<max(PLOT_LIMITS));
inhalePausesWithinPlotLimits = find(bmObj.inhalePauseOnsets >= ...
    min(PLOT_LIMITS) & bmObj.inhalePauseOnsets < max(PLOT_LIMITS));
exhalePausesWithinPlotLimits = find(bmObj.exhalePauseOnsets >= ...
    min(PLOT_LIMITS) & bmObj.exhalePauseOnsets<max(PLOT_LIMITS));

figure; hold all;
re=plot(bmObj.time(PLOT_LIMITS), ...
    bmObj.baselineCorrectedRespiration(PLOT_LIMITS),'k-');
io=scatter(bmObj.time(bmObj.inhaleOnsets(inhaleOnsetsWithinPlotLimits)), ...
    bmObj.baselineCorrectedRespiration( ...
    bmObj.inhaleOnsets(inhaleOnsetsWithinPlotLimits)),'bo','filled');
eo=scatter(bmObj.time(bmObj.exhaleOnsets(exhaleOnsetsWithinPlotLimits)), ...
    bmObj.baselineCorrectedRespiration(bmObj.exhaleOnsets( ...
    exhaleOnsetsWithinPlotLimits)), 'ro', 'filled');
ip=scatter(bmObj.time(bmObj.inhalePauseOnsets(inhalePausesWithinPlotLimits)) ...
    ,bmObj.baselineCorrectedRespiration(bmObj.inhalePauseOnsets( ...
    inhalePausesWithinPlotLimits)), 'go', 'filled');
ep=scatter(bmObj.time(bmObj.exhalePauseOnsets(exhalePausesWithinPlotLimits)), ...
    bmObj.baselineCorrectedRespiration(bmObj.exhalePauseOnsets( ...
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

%% 5.3 calculate breath offsets

% Each breath ends when either a pause occurs or the next breath begins
% this function finds the appropriate endpoint for each breath

bmObj.findInhaleAndExhaleOffsets(bmObj);

% plot these features

inhaleOnsetsWithinPlotLimits = find(bmObj.inhaleOnsets >= ...
    min(PLOT_LIMITS) & bmObj.inhaleOnsets<max(PLOT_LIMITS));
exhaleOnsetsWithinPlotLimits = find(bmObj.exhaleOnsets >= ...
    min(PLOT_LIMITS) & bmObj.exhaleOnsets<max(PLOT_LIMITS));
inhaleOffsetsWithinPlotLimits = find(bmObj.inhaleOffsets >= ...
    min(PLOT_LIMITS) & bmObj.inhaleOffsets < max(PLOT_LIMITS));
exhaleOffsetsWithinPlotLimits = find(bmObj.exhaleOffsets >= ...
    min(PLOT_LIMITS) & bmObj.exhaleOffsets < max(PLOT_LIMITS));

figure; hold all;
re=plot(bmObj.time(PLOT_LIMITS), ...
    bmObj.baselineCorrectedRespiration(PLOT_LIMITS),'k-');
io=scatter(bmObj.time(bmObj.inhaleOnsets(inhaleOnsetsWithinPlotLimits)), ...
    bmObj.baselineCorrectedRespiration(bmObj.inhaleOnsets( ...
    inhaleOnsetsWithinPlotLimits)), 'bo', 'filled');
eo=scatter(bmObj.time(bmObj.exhaleOnsets(exhaleOnsetsWithinPlotLimits)), ...
    bmObj.baselineCorrectedRespiration(bmObj.exhaleOnsets( ...
    exhaleOnsetsWithinPlotLimits)),'ro','filled');
ip=scatter(bmObj.time(bmObj.inhaleOffsets(inhaleOffsetsWithinPlotLimits)), ...
    bmObj.baselineCorrectedRespiration(bmObj.inhaleOffsets( ...
    inhaleOffsetsWithinPlotLimits)),'go','filled');
ep=scatter(bmObj.time(bmObj.exhaleOffsets(exhaleOffsetsWithinPlotLimits)), ...
    bmObj.baselineCorrectedRespiration(bmObj.exhaleOffsets( ...
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

%% 5.4 calculate breath durations

% calculate the duration of each breath and pause
bmObj = findBreathAndPauseDurations(bmObj);

% plot these features
figure; hold all;
re=plot(bmObj.time(PLOT_LIMITS), ...
    bmObj.baselineCorrectedRespiration(PLOT_LIMITS), 'k-');
for i=[1,3,5,7]
    text(bmObj.time(bmObj.inhalePeaks(i)),bmObj.peakInspiratoryFlows(i), ...
        sprintf('Inhale: %i, %.2f s',i,bmObj.inhaleDurations(i)));
    
    text(bmObj.time(bmObj.exhaleTroughs(i)),bmObj.troughExpiratoryFlows(i), ...
        sprintf('Exhale: %i, %.2f s',i,bmObj.exhaleDurations(i)));
    
    if ~isnan(bmObj.inhalePauseDurations(i))
        text(bmObj.time(bmObj.inhalePeaks(i))+1,bmObj.peakInspiratoryFlows(i)-.2, ...
            sprintf('Inhale Pause: %i, %.2f s',i,bmObj.inhalePauseDurations(i)));
    else
        text(bmObj.time(bmObj.inhalePeaks(i))+1,bmObj.peakInspiratoryFlows(i)-.2, ...
            sprintf('No Inhale Pause at breath %i',i));
    end
    
    if ~isnan(bmObj.exhalePauseDurations(i))
        text(bmObj.time(bmObj.exhaleTroughs(i))+1,bmObj.troughExpiratoryFlows(i)-.2, ...
            sprintf('Exhale Pause: %i, %.2f s',i,bmObj.exhalePauseDurations(i)));
    else
        text(bmObj.time(bmObj.exhaleTroughs(i))+1,bmObj.troughExpiratoryFlows(i)-.2, ...
            sprintf('No Exhale Pause at breath %i',i));
    end
end
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 5.5 Calculate breath volumes

bmObj.findInhaleAndExhaleVolumes(verbose);

% plot these features
figure; hold all;
re=plot(bmObj.time(PLOT_LIMITS), ...
    bmObj.baselineCorrectedRespiration(PLOT_LIMITS), 'k-');
for i=1:5
    text(bmObj.time(bmObj.inhalePeaks(i)), bmObj.peakInspiratoryFlows(i), ...
        sprintf('Inhale: %i, Volume: %.2f',i,bmObj.inhaleVolumes(i)));
    text(bmObj.time(bmObj.exhaleTroughs(i)),bmObj.troughExpiratoryFlows(i), ...
        sprintf('Exhale: %i, Volume: %.2f',i,bmObj.exhaleVolumes(i)));
end
xlabel('Time (seconds)');
ylabel('Respiratory Flow');


%% 5.6 Calculate secondary features of breathing

% Different measures can be used to describe breathing over the course of
% the recording such as breating rate, tidal volume, and percent of breaths
% with inhale pauses. 

% These are all derived using the following method.

bmObj.getSecondaryFeatures( verbose );

% these can be viewed easily using bmObj.dispSecondaryFeatures();

% secondary statistics are stored as key:value pairs.
% Values can be called using their corresponding key.
statKeys = bmObj.secondaryFeatures.keys();
breathingRateKey = statKeys{11}; % 'Breathing Rate'
breathingRate = bmObj.secondaryFeatures(breathingRateKey);
fprintf('\nBreathing Rate: %.3g \n', breathingRate);


%% 6 Visualization Tools

%% 6.1 Plot respiratory recording with features overlayed.

% bmObj.plotFeatures() allows you to see the location and value of each
% feature that has been calculated.
% because many features can be estimated, the user can choose which ones to
% annotate using the following options:
annotations = {'extrema', 'onsets','maxflow','volumes', 'pauses'};

% examples
fig = bmObj.plotFeatures({annotations{1},annotations{3}});
set(fig.CurrentAxes,'XLim',[1,60]);

fig = bmObj.plotFeatures(annotations{5});
set(fig.CurrentAxes,'XLim',[1,60]);

%% 6.2 Visualize breath compositions

% The following code allows the user to see a summary of which phases
% breaths spend time in.

% these can be visualized in three ways: 'raw', 'normalized', or 'line'

fig1 = bmObj.plotCompositions('raw');
fig2 = bmObj.plotCompositions('normalized');
fig3 = bmObj.plotCompositions('line');


%% 6.3 Calculate and plot event related respiratory responses

% With this code you can visualize breathing centered around certain time
% points.
% This is like an event related potential in neural recordings. 

% Pick events to visualize. For this example, we will use inhale onsets but
% this can be experimental events as well.
myEvents = bmObj.inhaleOnsets;

% set number of samples before and after events to visualize
pre=500;
post=4000;

% NOTE: If any events or surrounding windows fall outside of the
% respiratory recording, their data will not be included in this
% visualization and the user will be notivied.

% First calculate the erp matrix of breath amplitudes x time using:
bmObj.calculateERP(myEvents, pre, post);

% To access the data of event related potentials you can use:
% bm.ERPMatrix 
%to get the amplitude values and: 
%bm.ERPxAxis 
% to get the timing of the events in real time.

% plot the data stored in the class using:
bmObj.plotRespiratoryERP('simple');


%% 6.4 calculate and plot resampled event related respiratory responses

% Because individuals breathe at different rates, it might be desirable to
% plot respiratory event related responses as a function of point in the
% breathing cycle, regardless of the period.

% this can be done by first selecting the proportion of the breathing cycle
% to plot before and after. 1 is a full cycle
preResampled = .5;
postResampled = 1;
bmObj.calculateResampledERP(myEvents, preResampled, postResampled);

% To access the data of resampled event related potentials you can use:
% bmObj.resampledERPMatrix 
%to get the amplitude values and: 
%bmObj.resampledERPxAxis 
% to get the normalized points in phase.

% plot it
bmObj.plotRespiratoryERP('resampled');



%% 7. Other Methods

% None of these functions are needed but maybe you'll find them helpful.

%% 7.2: Respiratory phase

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


%% 7.2: Simulating Data for analysis

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
dataType = 'humanAirflow';

%% That's all! 
