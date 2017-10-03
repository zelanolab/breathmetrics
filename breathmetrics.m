classdef breathmetrics < handle 
    % This class takes in a respiratory trace and sampling rate and
    % contains methods for analysis and visualization of several features
    % of respiration that can be derived.
    
    properties
        raw_respiration
        smoothed_respiration
        data_type
        srate
        time
        baseline_corrected_respiration
        inhale_peaks
        exhale_troughs
        peak_inspiratory_flows
        trough_expiratory_flows
        inhale_onsets
        exhale_onsets
        inhale_volumes
        exhale_volumes
        respiratory_pause_onsets
        respiratory_pause_lengths
        has_respiratory_pause
        secondary_features
        resp_phase
        erp_matrix
        erp_x_axis
        resampled_erp_matrix
        resampled_erp_x_axis
        trial_events
    end
   
    methods
        % constructor
        function bm = breathmetrics(resp, srate, data_type)
            if nargin < 3
                data_type = 'human';
                disp('WARNING: Data type not specified.');
                disp('Please use input ''human'' or ''rodent'' as the third input arguement to specify');
                disp('Proceeding assuming that it is human spirometer data.')
            end
            
            if srate>5000 || srate<20
                disp('Sampling rates greater than 500 hz and less than 20 hz are not supported at this time. Please resample your data and try again');
            end
            
            % flip data that is vertical instead of horizontal
            if size(resp,1) == 1 && size(resp,2) > 1
                resp = resp';
            end
            
            bm.raw_respiration=resp;
            bm.srate = srate;
            bm.data_type = data_type;
            
            % mean smoothing window is different for rodents and humans
            if strcmp(data_type,'human')
                smooth_winsize = 50; 
            elseif strcmp(data_type, 'rodent')
                smooth_winsize = 10;
            else
                disp('Data type not recognized. Please use ''human'' or ''rodent'' to specify')
                smooth_winsize = 50;
            end
            
            % de-noise data
            srate_corrected_smoothed_win=floor((srate/1000) * smooth_winsize);
            bm.smoothed_respiration = smooth(resp, srate_corrected_smoothed_win)';
            
            % time is like fieldtrip. All events are indexed by point in
            % time vector.
            bm.time = (1:length(resp))*bm.srate;
        end
        
        %%% Preprocessing Methods
        
        function bm = correct_resp_to_baseline(bm, method, z_score, verbose)
            % Corrects respiratory traces to baseline and removes global 
            % linear trends
            
            sw_size = 60; % default window size for sliding window mean is 60 seconds.
            
            if nargin < 4
                verbose = 1;
            end
            
            if nargin < 3
                z_score=0;
            end
            
            if nargin < 2 || isempty(method)
                method='simple';
                if verbose == 1
                    disp('No method given. Defaulting to mean.')
                end
            end
            
            % first remove any global linear trend in data;
            this_resp = detrend(bm.smoothed_respiration);
            
            %find mean resp
            resp_mean = this_resp - mean(this_resp);
            
            if strcmp(method,'simple')
                bm.baseline_corrected_respiration = resp_mean;
                
            elseif strcmp(method,'sliding')
                % for periodic drifts in data
                srate_corrected_sw = floor(bm.srate * sw_size);
                if verbose == 1
                    disp(sprintf('Calculating sliding average using window size of %i seconds',sw_size));
                end
                
                resp_sliding_mean=smooth(this_resp,srate_corrected_sw);
                % correct tails of sliding mean
                resp_sliding_mean(1:srate_corrected_sw)=mean(this_resp);
                resp_sliding_mean(end-srate_corrected_sw:end)=mean(this_resp);
                bm.baseline_corrected_respiration = this_resp - resp_sliding_mean';
            
            else
                disp('Baseline correction method not recognized. Use simple or sliding')
            end
            
            % z score respiratory amplitudes to control for breath sizes
            % when comparing certain features between individuals
            if z_score == 1
                bm.baseline_corrected_respiration = zscore(bm.baseline_corrected_respiration);
            end
        end
        
        function this_resp = which_resp(bm, verbose )
            % helper function that decides whether to use baseline corrected or 
            % raw respiratory trace
            if nargin < 2
                verbose = 0;
            end
            
            % probably shouldn't use raw respiration for most calculations
            % so notify user.
            if isempty(bm.baseline_corrected_respiration)
                disp('No baseline corrected respiration found. Using smoothed respiration.')
                disp('Non-baseline corrected data can give inaccurate estimations of breath onsets and volumes')
                disp('Use correct_resp_to_baseline to remove drifts or offsets in the data')
                this_resp = bm.smoothed_respiration;
            else
                if verbose == 1
                    disp('Using baseline corrected respiration');
                end
                this_resp = bm.baseline_corrected_respiration;
            end
        end
        
        %%% Feature Extraction Methods %%%
        
        function bm = find_extrema(bm, verbose)
            % estimate peaks and troughs in data
            if nargin < 2
                verbose = 0;
            end
            this_resp = which_resp(bm, verbose);
            
            % humans and rodents breathe at totally different time scales
            if strcmp(bm.data_type, 'human')
                [putative_peaks,putative_troughs] = find_respiratory_extrema( this_resp, bm.srate );
            else
                srate_adjust = bm.srate/1000;
                rodent_sw_sizes = [floor(5*srate_adjust),floor(10*srate_adjust),floor(20*srate_adjust),floor(50*srate_adjust)];
                [putative_peaks,putative_troughs] = find_respiratory_extrema( this_resp, bm.srate, 0, rodent_sw_sizes );
            end
            % indices of extrema
            bm.inhale_peaks = putative_peaks;
            bm.exhale_troughs = putative_troughs;
            
            % values of extrema
            bm.peak_inspiratory_flows = this_resp(putative_peaks);
            bm.trough_expiratory_flows = this_resp(putative_troughs);
        end
        
        function bm = find_zeros(bm, verbose )
            % estimate zero crosses in data
            if nargin < 2
                verbose = 0;
            end
            this_resp = which_resp(bm, verbose);
            
            % new method
            [these_inhale_onsets, these_exhale_onsets] = find_breath_onsets(this_resp, bm.inhale_peaks, bm.exhale_troughs);
            bm.inhale_onsets = these_inhale_onsets;
            bm.exhale_onsets = these_exhale_onsets;
        end
        
        function bm = find_pauses(bm, verbose)
            
            if strcmp(bm.data_type, 'rodent')
                disp('WARNING: respiratory pause estimations are not reliable for rodent data. Interpretation of this metric is not advised');
            end
            % estimate zero crosses in data
            if nargin < 2
                verbose = 0;
            end
            this_resp = which_resp(bm, verbose);
            [pause_onsets, pause_lengths] = find_respiratory_pauses(this_resp, bm.inhale_onsets, bm.exhale_troughs);
            bm.respiratory_pause_onsets = pause_onsets;
            bm.respiratory_pause_lengths = pause_lengths;
            bm.has_respiratory_pause = pause_onsets > 0;
        end
            
        function bm = find_inhale_and_exhale_volumes(bm, verbose )
            % estimate inhale and exhale volumes
            if nargin < 2
                verbose = 0;
            end
            this_resp = which_resp(bm, verbose);
            [inhale_vols,exhale_vols] = find_respiratory_volumes( this_resp, bm.srate, bm.inhale_onsets, bm.exhale_onsets );
            bm.inhale_volumes = inhale_vols;
            bm.exhale_volumes = exhale_vols;
        end
        
        function bm = get_secondary_features( bm, verbose )
            % estimate features dependant on extrema, onsets, and volumes
            
            if nargin < 2
                % probably want to print these
                verbose=1;
            end
            respstats  = get_secondary_resp_features( bm, verbose );
            bm.secondary_features=respstats;
        end
        
        function disp_secondary_features(bm)
            % print out summary of all features estimated
            
            keySet = bm.secondary_features.keys;
            disp('Summary of Respiratory Features:')
            for this_key = 1:length(keySet)
                disp(sprintf('%s : %0.5g',keySet{this_key}, bm.secondary_features(keySet{this_key})));
            end
        end
        
        function bm = estimate_all_features( bm, z_score, baseline_correction_method, verbose )
            % estimates all event independant features of respiration that 
            % can be calculated
            
            if nargin < 2
                z_score = 0;
            end
            if nargin < 3
                baseline_correction_method = 'simple';
            end
            if nargin < 4
                verbose = 1;
            end
            
            bm.correct_resp_to_baseline(baseline_correction_method, z_score, verbose);
            bm.find_extrema(verbose);
            bm.find_zeros(verbose);
            bm.find_inhale_and_exhale_volumes(verbose);
            if strcmp(bm.data_type,'human')
                bm.find_pauses(verbose);
            end
            bm.get_secondary_features(verbose);
        end
        
        function bm = calculate_resp_phase(bm, myfilter, rate_estimation, verbose)
            % calculates real-time respiratory phase 
            this_resp = bm.which_resp();
            if nargin < 4
                verbose=1;
            end
            if nargin < 3
                rate_estimation = 'feature_derived';
            end
            
            if strcmp(rate_estimation,'feature_derived')
                filt_center = bm.secondary_features('Breathing Rate');
            elseif strcmp(rate_estimation, 'pspec')
                [Pxx,pspec_axis] = pwelch(this_resp, [], [], [], bm.srate, 'twosided');
                [~, pspec_max_ind] = max(Pxx);
                filt_center = pspec_axis(pspec_max_ind); % breathing rate derived from power spectrum
                if verbose == 1
                    disp(sprintf('breathing rate and filtering center frequency calculated from power spectrum : %0.2g',filt_center));
                end
            end
        
            if nargin < 2
                myfilter = designfilt('lowpassfir', 'PassbandFrequency', filt_center, 'StopbandFrequency',filt_center + 0.2);
            end
            
            if isempty(myfilter)
                myfilter = designfilt('lowpassfir','PassbandFrequency', filt_center, 'StopbandFrequency',filt_center + 0.2);
            end
            
            % filter respiration for central frequency and calcuate phase
            filtered_resp = filtfilt(myfilter, this_resp);
            bm.resp_phase = angle(hilbert(filtered_resp));
        end
        
        function bm = erp( bm, event_array , pre, post)
            % calculates an 'event related potential' of the respiratory
            % trace pre and post milliseconds before and after time points
            % in event_array.
            
            this_resp = which_resp(bm);
            if nargin<3
                pre = bm.secondary_features('Average Inter-Breath Interval');
                post = bm.secondary_features('Average Inter-Breath Interval');
            end
            
            % convert pre and post from ms into samples
            to_real_ms = bm.srate/1000;
            pre_samples = round(pre*to_real_ms);
            post_samples = round(post*to_real_ms);

            erpmat = create_erp_mat( this_resp, event_array, pre_samples, post_samples );
            srate_step=1000/bm.srate;
            bm.trial_events = event_array;
            bm.erp_matrix = erpmat;
            
            % if sampling rate is a float, x axis can mismatch
            temp_x_axis = -pre:srate_step:post+srate_step;
            
            if length(bm.erp_x_axis) ~= size(bm.erp_matrix,2)
                bm.erp_x_axis = temp_x_axis(1:size(bm.erp_matrix,2));
            else
                bm.erp_x_axis = temp_x_axis;
            end
        end
        
        function bm = resampled_erp(bm, event_array, pre_pct, post_pct, resample_size)
            % Calculates a 'event related potential' of the respiratory  
            % trace resampled by the average breathing rate. Helpful for
            % comparing events between traces with different breathing
            % rates.
            
            if nargin < 5
                % resample the erp window by this many points
                resample_size=2000;
            end
            
            if nargin < 3
                % 1 full cycle before events
                pre_pct=1;
                % 1 full cycle after events
                post_pct=1;
            end
            
            % get respiration around events resampled to breathing rate to
            % normalize between subjects
            avg_resp = bm.secondary_features('Average Inter-Breath Interval');
            rs_pre=round(avg_resp*bm.srate*pre_pct);
            rs_post=round(avg_resp*bm.srate*post_pct);
            
            this_resp = which_resp(bm);
            
            % get times a full cycle before and after each event
            normalized_erp = create_erp_mat(this_resp, event_array, rs_pre, rs_post);
            
            % resample this cycle into resample_size points
            resample_inds=linspace(1,rs_pre+rs_post+1,resample_size);
            
            % resample each event and store in matrix
            this_resampled_erp_matrix = zeros(size(normalized_erp,1),resample_size);
            for e=1:size(normalized_erp,1)
                this_resampled_erp_matrix(e,:) = interp1(1:size(normalized_erp,2),normalized_erp(e,:),resample_inds);
            end
            
            bm.resampled_erp_matrix = this_resampled_erp_matrix;
            bm.trial_events = event_array;
            bm.resampled_erp_x_axis = linspace(-pre_pct*100, post_pct*100, resample_size);
        end

        
        %%% Plotting methods
        
        function fig = plot_features(bm, annotate)
            % plot all respiratory features that have been calculated
            % property_list is string of features to plot 
            if nargin<2
                annotate=0;
            end
            fig = plot_respiratory_features(bm, annotate);
        end
        
        function fig = plot_respiratory_erp(bm,simple_or_resampled)
            % plot erp (not resampled erp)
            
            if ischar(simple_or_resampled)
                if strcmp(simple_or_resampled,'simple')
                    erpmat = bm.erp_matrix;
                    x_axis = bm.erp_x_axis;
                elseif strcmp(simple_or_resampled,'resampled')
                    erpmat = bm.resampled_erp_matrix;
                    x_axis = bm.resampled_erp_x_axis;
                else
                    disp('method not recognized. Use simple or resampled.')
                end
            else
                % just do simple erp
                erpmat = bm.erp_matrix;
                x_axis = bm.erp_x_axis;
                simple_or_resampled='simple';
            end
            
            fig = plot_resp_erp(erpmat,x_axis,simple_or_resampled);
        end
    end
end
