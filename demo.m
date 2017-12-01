%% Demo for The Respiratory Flow Signal Processing Toolbox
% Breathmetrics is a toolbox for automatically characterizing features 
% respiratory flow

% This demo will demonstrate how to run breathmetrics on a dataset to
% extract respiratory features, access the features of interest, calculate
% summaries of these features, and visualize them.

%% Simulating Data for analysis
% Simulate data for demo
sim_srate = 1000; % handles weird sampling rates
n_samples = 200 * sim_srate; % 200 seconds of data
breathing_rate = .25; % breathe once every 4 seconds
avg_amp = 0.02; % amplitude of inhales and exhales
amp_var=0.1; % variance in amplitudes
phase_var = 0.1; % variance in breathing rate
pct_phase_pause = 0.75; % add pauses before inhales to this percent of breaths

sim_resp = simulate_resp_data(n_samples, sim_srate, breathing_rate, avg_amp, amp_var, phase_var, pct_phase_pause);
data_type = 'human';
%% Load sample data for analysis

respdat = load('sample_data.mat');
resp_trace = respdat.resp;
srate = respdat.srate;
data_type = 'human';
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
bm = breathmetrics(resp_trace, srate, data_type);

% bm is now a class object with many properites, most will be empty
% call bm to see its properties
% raw_respiration is the raw vector of respiratory data.
% smoothed_respiration is that vector mean smoothed by 50 ms window. This
% is not fully baseline corrected yet.
% srate is your sampling rate
% time is a 1xN vector where each point represents where each sample in the
% other fields occur in real time.

% run bm.estimate_all_features() to gather them all and skip to statistics
% and visualization methods

% run the following cells in sequence as the calculations depend on the
% preceeding ones

%% 1. De-noising respiration and correcting to baseline

% print out steps as they go. Set to 0 to silence.
verbose=1; 

%use a sliding window to correct respiratory data to baseline
baseline_correction_method = 'sliding'; 
% 'simple' uses the mean. It isless accurate but faster
%baseline_correction_method = 'simple';

%z_score (1 or 0). 1 z-scores the amplitude values in the recording. Better
%for between-subject comparisions. 0 does not z-score the data.
z_score=0;

bm.correct_resp_to_baseline(baseline_correction_method, z_score, verbose)
%bm.estimate_all_features(verbose);

% NOTE: the methods below check if baseline correction as been performed.
% If there is a value in bm.baseline_corrected_respiration, these analyses
% will automatically be performed on this data.
% If not, smoothed_respiration will be used. This is allowed, but not 
% advised as baseline correction is necessary for accurate feature 
% extraction.

%plot 1 minute of sample data
plot_lims = 1:60000;
figure; hold all;

r=plot(bm.time(plot_lims),bm.raw_respiration(plot_lims),'k-');
sm=plot(bm.time(plot_lims),bm.smoothed_respiration(plot_lims),'b-');
bc=plot(bm.time(plot_lims),bm.baseline_corrected_respiration(plot_lims),'r-');
legend([r,sm,bc],{'Raw Respiration';'Smoothed Respiration';'Baseline Corrected Respiration'});
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2. extracting features from respiration
% many features can be extracted from respiratory flow recordings but they
% must be called in the sequence described here. i.e. Calculating a feature 
% such as inhale volumes requires that the extrema and onsets have been
% calculated.

%% 2.1 finding peaks and troughs

bm.find_extrema(verbose);
% points where peaks and troughs occur can be accessed at bm.inhale_peaks
% and bm.exhale_troughs, respectively.
% similarly, the peak inspiratory and expiratory flow can be accessed at 
% bm.peak_inspiratory_flows and bm.trough_expiratory_flows

% points where the first 10 inhale peaks occur
disp(bm.inhale_peaks(1:10))

% flow value at those peaks
disp(bm.peak_inspiratory_flows(1:10))


% NOTE: To standardize data, inhales always occur before exhales.
% i.e. bm.inhale_peaks(k) will always be < bm.exhale_troughs(k). 
% This way it is easy to index which breaths occur when.



% plot these features
inhale_peaks_within_plotlims = find(bm.inhale_peaks>=min(plot_lims) & bm.inhale_peaks<max(plot_lims));
exhale_troughs_within_plotlims = find(bm.exhale_troughs>=min(plot_lims) & bm.exhale_troughs<max(plot_lims));

figure; hold all;
re=plot(bm.time(plot_lims),bm.baseline_corrected_respiration(plot_lims),'k-');
ip=scatter(bm.time(bm.inhale_peaks(inhale_peaks_within_plotlims)),bm.peak_inspiratory_flows(inhale_peaks_within_plotlims),'ro','filled');
et=scatter(bm.time(bm.exhale_troughs(exhale_troughs_within_plotlims)),bm.trough_expiratory_flows(exhale_troughs_within_plotlims),'bo','filled');
legend([re,ip,et],{'Baseline Corrected Respiration';'Inhale Peaks';'Exhale Troughs'})
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.2 estimate inhale and exhale onsets, and pauses
bm.find_onsets_and_pauses(verbose);

% first 10 inhale onsets
disp(bm.inhale_onsets(1:10));

% NOTE: each breath onset is indexed at the peak of the same breath.
% i.e. bm.inhale_onsets(k) is the same breath as bm.inhale_peaks(k).

% first 10 inhale pauses
disp(bm.inhale_pause_onsets);

% NOTE: if a pause does not occur at breath k, bm.inhale_pause_onsets(k)
% will be nan.
% Similar to onsets, pauses are indexed at the same breath.
% bm.inhale_onsets(k) will always be < bm.pause_onsets(k) if a pause occurs

% plot these features

inhale_onsets_within_plotlims = find(bm.inhale_onsets>=min(plot_lims) & bm.inhale_onsets<max(plot_lims));
exhale_onsets_within_plotlims = find(bm.exhale_onsets>=min(plot_lims) & bm.exhale_onsets<max(plot_lims));
inhale_pauses_within_plotlims = find(bm.inhale_pause_onsets>=min(plot_lims) & bm.inhale_pause_onsets<max(plot_lims));
exhale_pauses_within_plotlims = find(bm.exhale_pause_onsets>=min(plot_lims) & bm.exhale_pause_onsets<max(plot_lims));

figure; hold all;
re=plot(bm.time(plot_lims),bm.baseline_corrected_respiration(plot_lims),'k-');
io=scatter(bm.time(bm.inhale_onsets(inhale_onsets_within_plotlims)),bm.baseline_corrected_respiration(bm.inhale_onsets(inhale_onsets_within_plotlims)),'go','filled');
eo=scatter(bm.time(bm.exhale_onsets(exhale_onsets_within_plotlims)),bm.baseline_corrected_respiration(bm.exhale_onsets(exhale_onsets_within_plotlims)),'co','filled');
ip=scatter(bm.time(bm.inhale_pause_onsets(inhale_pauses_within_plotlims)),bm.baseline_corrected_respiration(bm.inhale_pause_onsets(inhale_pauses_within_plotlims)),'mo','filled');
ep=scatter(bm.time(bm.exhale_pause_onsets(exhale_pauses_within_plotlims)),bm.baseline_corrected_respiration(bm.exhale_pause_onsets(exhale_pauses_within_plotlims)),'yo','filled');
legend([re,io,eo,ip,ep],{'Baseline Corrected Respiration';'Inhale Onsets';'Exhale Onsets';'Inhale Pause Onsets';'Exhale Pause Onsets'})
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.3 calculate breath volumes
bm.find_inhale_and_exhale_volumes(verbose);

% same as above 
disp(bm.inhale_volumes(1:10));

% plot these features
figure; hold all;
re=plot(bm.time(plot_lims),bm.baseline_corrected_respiration(plot_lims),'k-');
for i=1:5
    text(bm.time(bm.inhale_peaks(i)),bm.peak_inspiratory_flows(i),sprintf('Inhale: %i, Volume: %.2f',i,bm.inhale_volumes(i)));
    text(bm.time(bm.exhale_troughs(i)),bm.trough_expiratory_flows(i),sprintf('Exhale: %i, Volume: %.2f',i,bm.exhale_volumes(i)));
end
xlabel('Time (seconds)');
ylabel('Respiratory Flow');

%% 2.4 rapidly calculate all of the features above

% all of the features above can be called in sequence using the following
% code:
bm.estimate_all_features(verbose);
% NOTE: this uses default parameters for baseline correction (sliding 
% baseline correction window).

%% 2.5 Respiratory phase

% We have included code to calculate instantaneus respiratory phase using
% the angle of hilbert transformed data filtered by the average breathing 
% rate.
% However, this method is not recommended, as breath pauses and onsets
% often change amplitudes without changing phase so it may lead to false
% conclusions that should be reproduced using the other methods.

% If desired, this calculation can be performed using:
% bm.calculate_respiratory_phase(custom_filter, rate_estimation, verbose)

% if a custom filter is left empty, this butterworth filter will be used:
% myfilter = designfilt('lowpassfir', 'PassbandFrequency', filt_center, 'StopbandFrequency',filt_center + 0.2);
% breathing rate estimation can be calculated using the breathing rate
% found using the summary statistic method below by calling 
% 'feature_derived' or can be calculated using the peak of the power
% spectrum by calling 'pspec'

%% 3 calculate summary statistics 
bm.estimate_all_features(verbose);

% these can be viewed easily using bm.disp_secondary_features();

% secondary statistics are stored as key:value pairs.
% Values can be called using their corresponding key.
stat_keys = bm.secondary_features.keys();
breathing_rate_key = stat_keys{11}; % 'Breathing Rate'
breathing_rate = bm.secondary_features(breathing_rate_key);
fprintf('\n Breathing Rate: %.2g \n',breathing_rate);

%% 4 visualize all of the features that this toolbox can calculate
% bm.plot_features() allows you to see the location and value of each
% feature that has been calculated.
% because many features can be estimated, the user can choose which ones to
% annotate using the following options:
annotations = {'extrema', 'onsets','maxflow','volumes', 'pauses'};

% examples
fig = bm.plot_features({annotations{1},annotations{3}});
fig = bm.plot_features(annotations{5});

%% 4.1 visualize breath compositions

% the following code allows the user to see a summary of which phases
% breaths spend time in.

% these can be visualized in three ways: 'raw', 'normalized', or 'line'

fig = bm.plot_compositions('raw');
fig = bm.plot_compositions('normalized');
fig = bm.plot_compositions('line');



%% 4.2 calculate and plot event related respiratory responses

% like an event related potential in neural recordings, see breathing
% changes around a certain event type.

% Pick events to visualize. For this example, we will use inhale onsets but
% this can be experimental events as well.
my_events = bm.inhale_onsets;

% set number of samples before and after events to visualize
pre=500;
post=4000;

% NOTE: If any events or surrounding windows fall outside of the
% respiratory recording, their data will not be included in this
% visualization and the user will be notivied.

% First calculate the erp matrix of breath amplitudes x time using:
bm.erp(my_events,pre,post);

% To access the data of event related potentials you can use:
% bm.erp_matrix 
%to get the amplitude values and: 
%bm.erp_x_axis 
% to get the timing of the events in real time.

% plot the data stored in the class using:
bm.plot_respiratory_erp('simple');


%% 4.3 calculate and plot resampled event related respiratory responses
% because individuals breathe at different rates, it might be desirable to
% plot respiratory event related responses as a function of point in the
% breathing cycle, regardless of the period.

% this can be done by first selecting the proportion of the breathing cycle
% to plot before and after. 1 is a full cycle
pre_resampled = .5;
post_resampled = 1;
bm.resampled_erp(my_events, pre_resampled, post_resampled);

% To access the data of resampled event related potentials you can use:
% bm.resampled_erp_matrix 
%to get the amplitude values and: 
%bm.resampled_erp_x_axis 
% to get the normalized points in phase.

% plot it
bm.plot_respiratory_erp('resampled');

%% That's all! Thanks!



