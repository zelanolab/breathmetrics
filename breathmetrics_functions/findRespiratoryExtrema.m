function [correctedPeaks, correctedTroughs] = findRespiratoryExtrema( ...
    resp, srate, customDecisionThreshold, swSizes )
%FIND_RESPIRATORY_PEAKS Finds peaks and troughs in respiratory data
%   resp : 1:n vector of respiratory trace
%   srate : sampling rate of respiratory trace
%   sw_sizes (OPTIONAL) : array of windows to use to find peaks. Default
%   values are sizes that work well for human nasal respiration data.

if nargin < 4
    srateAdjust = srate/1000;
    swSizes = [floor(100*srateAdjust),floor(300*srateAdjust), ...
        floor(700*srateAdjust), floor(1000*srateAdjust), ...
        floor(5000*srateAdjust)];
end

if nargin < 3
    customDecisionThreshold = 0;
end

% pad end with zeros to include tail of data missed by big windows
% otherwise
padInd = min([length(resp)-1,max(swSizes)*2]);
paddedResp = [resp, fliplr(resp(end-padInd:end))];

%initializing vector of all points where there is a peak or trough.
swPeakVect = zeros(1, size(paddedResp, 2));
swTroughVect = zeros(1, size(paddedResp, 2));

% peaks and troughs must exceed this value. Sometimes algorithm finds mini
% peaks in flat traces
peakThreshold = mean(resp(1,:)) + std(resp(1,:)) / 2;
troughThreshold = mean(resp(1,:)) - std(resp(1,:)) / 2;

% shifting window to be unbiased by starting point
SHIFTS = 1:3;
nWindows=length(swSizes)*length(SHIFTS);

% find maxes in each sliding window, in each shift, and return peaks that
% are agreed upon by majority windows.

% find extrema in each window of the data using each window size and offset
for win = 1:length(swSizes)
    
    sw = swSizes(win);
    % cut off end of data based on sw size
    nIters  = floor(length(paddedResp) / sw)-1; 
    
    for shift = SHIFTS
        % store maxima and minima of each window
        argmaxVect = zeros(1, nIters);
        argminVect = zeros(1, nIters);
        
        %shift starting point of sliding window to get unbiased maxes
        windowInit = (sw - floor(sw / shift)) + 1;
         
        % iterate by this window size and find all maxima and minima
        windowIter=windowInit;
        for i = 1:nIters
            thisWindow = paddedResp(1, windowIter:windowIter + sw - 1);
            [maxVal,maxInd] = max(thisWindow);
            
            % make sure peaks and troughs are real.
            if maxVal > peakThreshold
                % index in window + location of window in original resp time
                argmaxVect(1,i)=windowIter + maxInd-1;
            end
            [minVal,minInd] = min(thisWindow);
            if minVal < troughThreshold
                % index in window + location of window in original resp time
                argminVect(1,i)=windowIter+minInd-1;
            end
            windowIter = windowIter + sw;
        end
        % add 1 to consensus vector
        swPeakVect(1, nonzeros(argmaxVect)) = ...
            swPeakVect(1,nonzeros(argmaxVect)) + 1;
        swTroughVect(1, nonzeros(argminVect)) = ...
            swTroughVect(1, nonzeros(argminVect)) + 1;
    end
end


% find threshold that makes minimal difference in number of extrema found
% similar idea to knee method of k-means clustering

nPeaksFound = zeros(1, nWindows);
nTroughsFound = zeros(1, nWindows);
for threshold_ind = 1:nWindows
    nPeaksFound(1, threshold_ind) = sum(swPeakVect > threshold_ind);
    nTroughsFound(1, threshold_ind) = sum(swTroughVect > threshold_ind);
end

[~,bestPeakDiff] = max(diff(nPeaksFound));
[~,bestTroughDiff] = max(diff(nTroughsFound));

if customDecisionThreshold>0
    bestDecisionThreshold = customDecisionThreshold;
else
    bestDecisionThreshold = floor(mean([bestPeakDiff, bestTroughDiff]));
end

% % temporary peak inds. Eacy point where there is a real peak or trough
peakInds = find(swPeakVect >= bestDecisionThreshold);
troughInds = find(swTroughVect >= bestDecisionThreshold);


% sometimes there are multiple peaks or troughs in series which shouldn't 
% be possible. This loop ensures the series alternates peaks and troughs.

% first we must find the first peak
offByN = 1;
tri = 1;
while offByN
    if peakInds(tri)> troughInds(tri)
        troughInds = troughInds(1, tri + 1:end);
    else
        offByN=0;
    end
end

correctedPeaks = [];
correctedTroughs = [];


pki=1; % peak ind
tri=1; % trough ind

% variable to decide whether to record peak and trough inds.
proceedCheck = 1; 

% find peaks and troughs that alternate
while pki <length(peakInds)-1 && tri<length(troughInds)-1
    
    % time difference between peak and next trough
    peakTroughDiff = troughInds(tri) - peakInds(pki);
    
    % check if two peaks in a row
    peakPeakDiff = peakInds(pki+1) - peakInds(pki);
    
    if peakPeakDiff < peakTroughDiff
        % if two peaks in a row, take larger peak
        [~, nxtPk] = max([paddedResp(peakInds(pki)), ...
            paddedResp(peakInds(pki+1))]);
        if nxtPk == 2
            % forget this peak. keep next one.
            pki = pki+1;
        else
            % forget next peak. keep this one.
            peakInds = setdiff(peakInds, peakInds(1, pki+1));
        end
        % there still might be another peak to remove so go back and check
        % again
        proceedCheck=0;
    end
    
    % if the next extrema is a trough, check for trough series
    if proceedCheck == 1
        
        % check if trough is after this trough.
        troughTroughDiff = troughInds(tri + 1) - troughInds(tri);
        troughPeakDiff = peakInds(pki + 1) - troughInds(tri);
        
        if troughTroughDiff < troughPeakDiff
            % if two troughs in a row, take larger trough
            [~, nxtTr] = min([paddedResp(troughInds(tri)), ...
                paddedResp(troughInds(tri + 1))]);
            if nxtTr == 2
                % take second trough
                tri = tri + 1;
            else
                % remove second trough
                troughInds = setdiff(troughInds, troughInds(1, tri + 1));
            end
            % there still might be another trough to remove so go back and 
            % check again
            proceedCheck=0;
        end
    end
    
    % if both of the above pass we can save values
    if proceedCheck == 1
        % if peaks aren't ahead of troughs
        if peakTroughDiff > 0
            %time_diff_pt = [time_diff_pt peak_trough_diff*srate_adjust];
            correctedPeaks = [correctedPeaks peakInds(pki)];
            correctedTroughs = [correctedTroughs troughInds(tri)];
            
            % step forward
            tri=tri+1;
            pki=pki+1;
        else
            % peaks got ahead of troughs. This shouldn't ever happen.
            disp('Peaks got ahead of troughs. This shouldnt happen.');
            disp(strcat('Peak ind: ', num2str(peakInds(pki))));
            disp(strcat('Trough ind: ', num2str(troughInds(tri))));
            raise('unexpected error. stopping');
        end
    end
    proceedCheck=1;
end

% remove any peaks or troughs in padding
correctedPeaks = correctedPeaks(correctedPeaks < length(resp));
correctedTroughs = correctedTroughs(correctedTroughs < length(resp));

end

