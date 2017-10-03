function [corrected_peaks, corrected_troughs] = find_respiratory_extrema( resp, srate, custom_decision_threshold, sw_sizes )
%FIND_RESPIRATORY_PEAKS Finds peaks and troughs in respiratory data
%   resp : 1:n vector of respiratory trace
%   srate : sampling rate of respiratory trace
%   sw_sizes (OPTIONAL) : array of windows to use to find peaks. Default
%   values are sizes that work well for human nasal respiration data.

if nargin < 4
    srate_adjust = srate/1000;
    sw_sizes = [floor(300*srate_adjust),floor(700*srate_adjust),floor(1000*srate_adjust),floor(5000*srate_adjust)];
    %disp(strcat('using sw_sizes:',mat2str(sw_sizes)))
end

if nargin < 3
    custom_decision_threshold = 0;
end

% pad end with zeros to include tail of data missed by big windows
% otherwise
padind = min([length(resp)-1,max(sw_sizes)*2]);
padded_resp = [resp, fliplr(resp(end-padind:end))];

%initializing vector of all points where there is a peak or trough.
sw_peak_vect = zeros(1,size(padded_resp,2));
sw_trough_vect = zeros(1,size(padded_resp,2));

% peaks and troughs must exceed this value. Sometimes algorithm finds mini
% peaks in flat traces
peak_threshold = mean(resp(1,:)) + std(resp(1,:))/2;
trough_threshold = mean(resp(1,:)) - std(resp(1,:))/2;

% shifting window to be unbiased by starting point
shifts = 1:3;
n_windows=length(sw_sizes)*length(shifts);

% find maxes in each sliding window, in each shift, and return peaks that
% are agreed upon by majority windows.

% find extrema in each window of the data using each window size and offset
for win = 1:length(sw_sizes)
    
    sw = sw_sizes(win);
    n_iters  = floor(length(padded_resp)/sw)-1; % cut off end of data based on sw size
    
    for shift = shifts
        % store maxima and minima of each window
        argmax_vect = zeros(1,n_iters);
        argmin_vect = zeros(1,n_iters);
        
        %shift starting point of sliding window to get unbiased maxes
        window_init = (sw-floor(sw/shift))+1;
         
        % iterate by this window size and find all maxima and minima
        window_iter=window_init;
        for i = 1:n_iters
            this_win = padded_resp(1,window_iter:window_iter+sw-1);
            [max_val,max_ind] = max(this_win);
            
            % make sure peaks and troughs are real.
            if max_val > peak_threshold
                % index in window + location of window in original resp time
                argmax_vect(1,i)=window_iter + max_ind-1;
            end
            [val,min_ind] = min(this_win);
            if val < trough_threshold
                % index in window + location of window in original resp time
                argmin_vect(1,i)=window_iter+min_ind-1;
            end
            window_iter = window_iter+sw;
        end
        % add 1 to consensus vector
        sw_peak_vect(1,nonzeros(argmax_vect)) = sw_peak_vect(1,nonzeros(argmax_vect))+1;
        sw_trough_vect(1,nonzeros(argmin_vect)) = sw_trough_vect(1,nonzeros(argmin_vect))+1;
    end
end


% find threshold that makes minimal difference in number of extrema found
% similar idea to knee method of k-means clustering

n_peaks_found=zeros(1,n_windows);
n_troughs_found=zeros(1,n_windows);
for threshold=1:n_windows
    n_peaks_found(1,threshold)=sum(sw_peak_vect>threshold);
    n_troughs_found(1,threshold)=sum(sw_trough_vect>threshold);
end

[~,best_peak_diff] = max(diff(n_peaks_found));
[~,best_trough_diff] = max(diff(n_troughs_found));

if custom_decision_threshold>0
    best_decision_threshold = custom_decision_threshold;
else
    best_decision_threshold = floor(mean([best_peak_diff,best_trough_diff]));
end

% % temporary peak inds. Eacy point where there is a real peak or trough
peak_inds = find(sw_peak_vect >= best_decision_threshold);
trough_inds = find(sw_trough_vect >= best_decision_threshold);


% sometimes there are multiple peaks or troughs in series which shouldn't 
% be possible. This loop ensures the series alternates peaks and troughs.

% first we must find the first peak
off_by_n= 1;
ti=1;
while off_by_n
    if peak_inds(ti)> trough_inds(ti)
        trough_inds = trough_inds(1,ti+1:end);
    else
        off_by_n=0;
    end
end

corrected_peaks = [];
corrected_troughs = [];


pi=1; % peak ind
ti=1; % trough ind

proceed=1; % variable to decide whether to record peak and trough inds.

% find peaks and troughs that alternate
while pi<length(peak_inds)-1 && ti<length(trough_inds)-1
    
    % time difference between peak and next trough
    peak_trough_diff = trough_inds(ti)-peak_inds(pi);
    
    % check if two peaks in a row
    peak_peak_diff = peak_inds(pi+1) - peak_inds(pi);
    if peak_peak_diff < peak_trough_diff
        % if two peaks in a row, take larger peak
        [~, ind] = max([padded_resp(peak_inds(pi)),padded_resp(peak_inds(pi+1))]);
        if ind == 2
            % forget this peak. keep next one.
            pi = pi+1;
        else
            % forget next peak. keep this one.
            peak_inds = setdiff(peak_inds,peak_inds(1,pi+1));
        end
        % there still might be another peak to remove so go back and check
        % again
        proceed=0;
    end
    
    % if the next extrema is a trough, check for trough series
    if proceed == 1
        
        % check if trough is after this trough.
        trough_trough_diff = trough_inds(ti+1)-trough_inds(ti);
        trough_peak_diff = peak_inds(pi+1)-trough_inds(ti);
        
        if trough_trough_diff < trough_peak_diff
            % if two troughs in a row, take larger trough
            [~, ind] = min([padded_resp(trough_inds(ti)),padded_resp(trough_inds(ti+1))]);
            if ind == 2
                % take second trough
                ti = ti+1;
            else
                % remove second trough
                trough_inds = setdiff(trough_inds,trough_inds(1,ti+1));
            end
            % there still might be another trough to remove so go back and 
            % check again
            proceed=0;
        end
    end
    
    % if both of the above pass we can save values
    if proceed == 1
        % if peaks aren't ahead of troughs
        if peak_trough_diff > 0
            %time_diff_pt = [time_diff_pt peak_trough_diff*srate_adjust];
            corrected_peaks = [corrected_peaks peak_inds(pi)];
            corrected_troughs = [corrected_troughs trough_inds(ti)];
            
            % step forward
            ti=ti+1;
            pi=pi+1;
        else
            % peaks got ahead of troughs. This shouldn't happen.
            disp('Peaks got ahead of troughs. This shouldnt happen.');
            disp(strcat('Peak ind: ', num2str(peak_inds(pi))));
            disp(strcat('Trough ind: ', num2str(trough_inds(ti))));
            raise('unexpected error. stopping')
        end
    end
    proceed=1;
end

% remove any peaks or troughs in padding
corrected_peaks = corrected_peaks(corrected_peaks<length(resp));
corrected_troughs = corrected_troughs(corrected_troughs<length(resp));

end

