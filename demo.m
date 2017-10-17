%% Demo for The Respiratory Signal Processing Toolbox

% Simulate data for demo
sim_srate = 1000; % handles weird sampling rates
n_samples = 200 * sim_srate; % 200 seconds of data
breathing_rate = .25; % breathe once every 4 seconds
avg_amp = 0.02; % amplitude of inhales and exhales
amp_var=0.1; % variance in amplitudes
phase_var = 0.1; % variance in breathing rate
pct_phase_pause = 0.75; % add pauses before inhales to this percent of breaths

sim_resp = simulate_resp_data(n_samples, sim_srate, breathing_rate, avg_amp, amp_var, phase_var, pct_phase_pause);

% All analyses are done with the breathmetrics class
% It requires a  vector of respirometer data and a sampling rate to
% initialize

data_type = 'human';
% initialize class
%bm = breathmetrics(sim_resp, sim_srate, data_type);


% usage on real data
respdat = load('./sample_data.mat');
resp_trace = respdat.resp;
srate = respdat.srate;
bm = breathmetrics(resp_trace, srate, data_type);
bm.estimate_all_features();

% print out steps as they go. Set to 0 to silence.
verbose=1; 

bm.estimate_all_features(verbose);

% visualize all of the features that this toolbox can calculate
bm.plot_features();

% print summary of all features
secondary_feature_keys = bm.secondary_features.keys();
for k = 1:length(bm.secondary_features.keys())
    this_key=secondary_feature_keys{k};
    disp(sprintf('%s : %g', this_key, bm.secondary_features(this_key)))
end

pre=500;
post=4000;

% plot all inhales
bm.erp(bm.inhale_onsets,pre,post);
bm.resampled_erp(bm.inhale_onsets,.8,.8);
bm.plot_respiratory_erp('simple');
bm.plot_respiratory_erp('resampled');
