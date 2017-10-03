function simresp = simulate_resp_data(n_samples, srate, breathing_rate, avg_amp, amp_var, phase_var, pct_phase_pause)

% simulates respiration data
% n_points : number of simulated respiratory samples to simulate
% srate : sampling rate
% breathing_rate : respiratory cycles per second
% avg_amp : amplitude of inhales and exhales
% amp_var : float 0:i how much noise to add to amplitudes of breaths
% phase_var : float 0:i how much noise to add to phase of breaths
% pct_phase_pause : float 0:1 what percent of inhales have a phase pause
% before them
%keyboard
% n samples to complete 1 cycle of breathing.
resp_phase = srate/breathing_rate;

% produce this many total cycles of simulated data. Make more than expected
% because high varience in phase can randomly make too little data than 
% desired.
n_cycles=ceil(n_samples/resp_phase)*2;

amp_noise = abs((randn(1,n_cycles) * amp_var) +1);
phase_noise = abs((randn(1,n_cycles) * phase_var) +1) * resp_phase;

% initialize empty vector to fill with simulated data
simresp = zeros(1,n_samples * 2);
i=1;
for c = 1:n_cycles
    % compute this respiratory oscillation. adding in random variation to
    % oscillation length and amplitude
    this_cycle = sin(linspace(0,2 * pi, phase_noise(1, c))) * amp_noise(1, c) * avg_amp;
    % append it to simulated resperation vector
    simresp(1,i:i+length(this_cycle) - 1)= this_cycle;
    i= i + length(this_cycle) - 1;
    
    % add phase pause
    if rand < pct_phase_pause
        pause_len = randi(floor(length(this_cycle) / 4));
        phase_pause_noise = (randn(1,pause_len)-0.5) * (avg_amp/10);
        simresp(i:i+pause_len-1) = simresp(i-1) + phase_pause_noise;
        i=i+pause_len;
    end
end

simresp=simresp(1,1:n_samples);