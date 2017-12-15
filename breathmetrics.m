classdef breathmetrics < handle 
    % This class takes in a respiratory trace and sampling rate and
    % contains methods for analysis and visualization of several features
    % of respiration that can be derived.
    
    properties
        rawRespiration
        smoothedRespiration
        dataType
        srate
        time
        baselineCorrectedRespiration
        inhalePeaks
        exhaleTroughs
        peakInspiratoryFlows
        troughExpiratoryFlows
        inhaleOnsets
        exhaleOnsets
        inhaleOffsets
        exhaleOffsets
        inhaleVolumes
        exhaleVolumes
        inhaleLengths
        exhaleLengths
        inhalePauseOnsets
        inhalePauseLengths
        exhalePauseOnsets
        exhalePauseLengths
        secondaryFeatures
        respiratoryPhase
        ERPMatrix
        ERPxAxis
        resampledERPMatrix
        resampledERPxAxis
        trialEvents
    end
   
    methods
        %%% constructor
        function Bm = breathmetrics(resp, srate, dataType)
            if nargin < 3
                dataType = 'human';
                disp('WARNING: Data type not specified.');
                disp(['Please use input ''human'' or ''rodent'' as ' ...
                'the third input arguement to specify']);
                disp('Proceeding assuming that this is human data.')
            end
            
            if srate > 5000 || srate < 20
                disp(['Sampling rates greater than 5000 hz and less ' ...
                    'than 20 hz are not supported at this time. ' ...
                    'Please resample your data and try again.']);
            end
            
            % flip data that is vertical instead of horizontal
            if size(resp,1) == 1 && size(resp,2) > 1
                resp = resp';
            end
            
            Bm.rawRespiration=resp;
            Bm.srate = srate;
            Bm.dataType = dataType;
            
            % mean smoothing window is different for rodents and humans
            if strcmp(dataType,'human')
                smoothWinsize = 50; 
            elseif strcmp(dataType, 'rodent')
                smoothWinsize = 10;
            else
                disp(['Data type not recognized. Please use ''human'' ' ...
                    'or ''rodent'' to specify'])
                smoothWinsize = 50;
            end
            
            % de-noise data
            srateCorrectedSmoothedWindow = ...
                floor((srate/1000) * smoothWinsize);
            Bm.smoothedRespiration = ...
                smooth(resp, srateCorrectedSmoothedWindow)';
            
            % time is like fieldtrip. All events are indexed by point in
            % time vector.
            Bm.time = (1:length(resp)) / Bm.srate;
        end
        
        %%% Preprocessing Methods
        
        function bm = correctRespirationToBaseline(bm, method, zScore, verbose)
            % Corrects respiratory traces to baseline and removes global 
            % linear trends
            
            % default window size for sliding window mean is 60 seconds.
            swSize = 60; 
            
            if nargin < 4
                verbose = 1;
            end
            
            if nargin < 3
                zScore=0;
            end
            
            if nargin < 2 || isempty(method)
                method='simple';
                if verbose == 1
                    disp('No method given. Defaulting to mean.')
                end
            end
            
            % first remove any global linear trend in data;
            thisResp = detrend(bm.smoothedRespiration);
            
            %find mean resp
            respMean = thisResp - mean(thisResp);
            
            if strcmp(method,'simple')
                bm.baselineCorrectedRespiration = respMean;
                
            elseif strcmp(method, 'sliding')
                % for periodic drifts in data
                srateCorrectedSW = floor(bm.srate * swSize);
                if verbose == 1
                    fprintf( [ 'Calculating sliding average using ', ...
                        'window size of %i seconds \n' ],swSize);
                end
                
                respSlidingMean=smooth(thisResp, srateCorrectedSW);
                % correct tails of sliding mean
                respSlidingMean(1:srateCorrectedSW) = mean(thisResp);
                respSlidingMean(end-srateCorrectedSW:end) = mean(thisResp);
                bm.baselineCorrectedRespiration = ...
                    thisResp - respSlidingMean';
            
            else
                disp(['Baseline correction method not recognized. '
                    'Please use ''simple'' or ''sliding'' as inputs.'])
            end
            
            % z score respiratory amplitudes to control for breath sizes
            % when comparing certain features between individuals
            if zScore == 1
                bm.baselineCorrectedRespiration = ...
                    zscore(bm.baselineCorrectedRespiration);
            end
        end
        
        function thisResp = whichResp(bm, verbose )
            % helper function that decides whether to use baseline 
            %corrected or raw respiratory trace
            if nargin < 2
                verbose = 0;
            end
            
            % probably shouldn't use raw respiration for most calculations
            % so notify user.
            if isempty(bm.baselineCorrectedRespiration)
                disp(['No baseline corrected respiration found.' ...
                    'Using smoothed respiration.'])
                disp(['Non-baseline corrected data can give ' ...
                    'inaccurate estimations of breath onsets and volumes'])
                disp(['Use correctRespToBaseline to remove drifts' ...
                    ' or offsets in the data'])
                thisResp = bm.smoothedRespiration;
            else
                if verbose == 1
                    disp('Using baseline corrected respiration');
                end
                thisResp = bm.baselineCorrectedRespiration;
            end
        end
        
        %%% Feature Extraction Methods %%%
        
        function bm = findExtrema(bm, verbose)
            % estimate peaks and troughs in data
            if nargin < 2
                verbose = 0;
            end
            thisResp = whichResp(bm, verbose);
            
            % humans and rodents breathe at totally different time scales
            if strcmp(bm.dataType, 'human')
                [putativePeaks, putativeTroughs] = ...
                    findRespiratoryExtrema( thisResp, bm.srate );
            else
                srateAdjust = bm.srate/1000;
                rodentSWSizes = [floor(5*srateAdjust), ...
                    floor(10 * srateAdjust), floor(20 * srateAdjust), ...
                    floor(50 * srateAdjust)];
                [putativePeaks, putativeTroughs] = ...
                    findRespiratoryExtrema( thisResp, bm.srate, ...
                    0, rodentSWSizes );
            end
            % indices of extrema
            bm.inhalePeaks = putativePeaks;
            bm.exhaleTroughs = putativeTroughs;
            
            % values of extrema
            bm.peakInspiratoryFlows = thisResp(putativePeaks);
            bm.troughExpiratoryFlows = thisResp(putativeTroughs);
        end
        
        function bm = findOnsetsAndPauses(bm, verbose )
            % estimate zero crosses in data
            if nargin < 2
                verbose = 0;
            end
            thisResp = whichResp(bm, verbose);
            
            [theseInhaleOnsets, theseExhaleOnsets, ...
                theseInhalePauseOnsets, theseExhalePauseOnsets] = ...
                findRespiratoryPausesAndOnsets(thisResp, ...
                bm.inhalePeaks, bm.exhaleTroughs);
            bm.inhaleOnsets = theseInhaleOnsets;
            bm.exhaleOnsets = theseExhaleOnsets;
            bm.inhalePauseOnsets = theseInhalePauseOnsets;
            bm.exhalePauseOnsets = theseExhalePauseOnsets;
            
        end
        
        function bm = findInhaleAndExhaleOffsets(bm, verbose )
            % finds the end of each inhale and exhale
            if nargin < 2
                verbose = 0;
            end
            thisResp = whichResp(bm, verbose);
            [inhaleOffs,exhaleOffs]=findRespiratoryOffsets(thisResp, ...
                bm.inhaleOnsets, bm.exhaleOnsets, ...
                bm.inhalePauseOnsets, bm.exhalePauseOnsets);
            bm.inhaleOffsets=inhaleOffs;
            bm.exhaleOffsets=exhaleOffs;
        end
        
        function bm = findBreathAndPauseLengths(bm)
            % calculate length of each breath
            [inhaleLens, exhaleLens, inhalePauseLens, ...
                exhalePauseLens] = findBreathLengths(bm);
            bm.inhaleLengths = inhaleLens;
            bm.exhaleLengths = exhaleLens;
            bm.inhalePauseLengths = inhalePauseLens;
            bm.exhalePauseLengths = exhalePauseLens;
        end
            
        function bm = findInhaleAndExhaleVolumes(bm, verbose )
            % estimate inhale and exhale volumes
            if nargin < 2
                verbose = 0;
            end
            thisResp = whichResp(bm, verbose);
            [inhaleVols,exhaleVols] = findRespiratoryVolumes( ...
                thisResp, bm.srate, bm.inhaleOnsets, bm.exhaleOnsets, ...
                bm.inhaleOffsets, bm.exhaleOffsets);
            bm.inhaleVolumes = inhaleVols;
            bm.exhaleVolumes = exhaleVols;
        end
        
        function bm = getSecondaryFeatures( bm, verbose )
            % Estimate all features that can be caluclated using the
            % parameters above
            % *dependant on extrema, onsets, and volumes
            if nargin < 2
                % probably want to print these
                verbose=1;
            end
            respStats  = getSecondaryRespiratoryFeatures( bm, verbose );
            bm.secondaryFeatures = respStats;
        end
        
        function dispSecondaryFeatures(bm)
            % print out summary of all features estimated
            
            keySet = bm.secondaryFeatures.keys;
            disp('Summary of Respiratory Features:')
            for thisKey = 1:length(keySet)
                fprintf('\n %s : %0.5g \n',keySet{thisKey}, ...
                    bm.secondaryFeatures(keySet{thisKey}));
            end
        end
        
        function bm = estimateAllFeatures( bm, zScore, ...
                baselineCorrectionMethod, verbose )
            % estimates all event independant features of respiration that 
            % can be calculated
            
            if nargin < 2
                zScore = 0;
            end
            if nargin < 3
                baselineCorrectionMethod = 'simple';
            end
            if nargin < 4
                verbose = 1;
            end
            
            bm.correctRespirationToBaseline(baselineCorrectionMethod, ...
                zScore, verbose);
            bm.findExtrema(verbose);
            bm.findOnsetsAndPauses(verbose);
            bm.findInhaleAndExhaleOffsets(verbose);
            bm.findBreathAndPauseLengths();
            bm.findInhaleAndExhaleVolumes(verbose);
            bm.getSecondaryFeatures(verbose);
        end
        
        function bm = calculateRespiratoryPhase(bm, myFilter, ...
                rateEstimation, verbose)
            % calculates real-time respiratory phase 
            % Warning: Because respiration tends to be non-stationary this 
            % function and other filtering methods are not advised
            
            thisResp = bm.whichResp();
            if nargin < 4
                verbose=1;
            end
            if nargin < 3
                rateEstimation = 'feature_derived';
            end
            
            if strcmp(rateEstimation,'feature_derived')
                % breathing rate derived from breathing rate
                filtCenter = bm.secondaryFeatures('Breathing Rate');
            elseif strcmp(rateEstimation, 'pspec')
                % breathing rate derived from power spectrum
                [Pxx,pspecAxis] = pwelch(thisResp, [], [], [], ...
                    bm.srate, 'twosided');
                [~, pspecMaxInd] = max(Pxx);
                
                filtCenter = pspecAxis(pspecMaxInd); 
                if verbose == 1
                    fprintf(['breathing rate and filtering center', ...
                        ' frequency calculated from power', ...
                        ' spectrum : %0.2g /n'],filtCenter);
                end
            end
        
            if nargin < 2 
                myFilter = designfilt( ...
                    'lowpassfir', 'PassbandFrequency', ...
                    filtCenter, 'StopbandFrequency', ...
                    filtCenter + 0.2);
            end
            
            if isempty(myFilter)
                myFilter = designfilt( ...
                    'lowpassfir','PassbandFrequency', ...
                    filtCenter, 'StopbandFrequency', ...
                    filtCenter + 0.2);
            end
            
            % filter respiration for central frequency and calcuate phase
            filteredResp = filtfilt(myFilter, thisResp);
            bm.respPhase = angle(hilbert(filteredResp));
        end
        
        function bm = calculateERP( bm, eventArray , pre, post, verbose)
            % calculates an event related potential of the respiratory
            % trace pre and post milliseconds before and after time points
            % in eventArray.
            
            if nargin<5
                verbose=1;
            end
            
            thisResp = whichResp(bm);
            
            % convert pre and post from ms into samples
            toRealMs = bm.srate / 1000;
            preSamples = round(pre * toRealMs);
            postSamples = round(post * toRealMs);

            thisERPMatrix = createRespiratoryERPMatrix( thisResp, ...
                eventArray, preSamples, postSamples, verbose );
            srateStep = 1000 / bm.srate;
            
            % if sampling rate is a float, x axis can mismatch
            tempxAxis = -pre:srateStep:post+srateStep;

            if length(tempxAxis) > size(thisERPMatrix,2)
                bm.ERPxAxis = tempxAxis(1:size(thisERPMatrix,2));
            elseif length(tempxAxis) < size(thisERPMatrix,2)
                thisERPMatrix = thisERPMatrix(:,1:length(tempxAxis));
                bm.ERPxAxis = tempxAxis;
            end
            bm.trialEvents = eventArray;
            bm.ERPMatrix = thisERPMatrix;
        end
        
        function bm = calculateResampledERP(bm, eventArray, prePct, ...
                postPct, resampleSize, verbose)
            % Calculates a 'event related potential' of the respiratory  
            % trace resampled by the average breathing rate. Helpful for
            % comparing events between traces with different breathing
            % rates.
            
            if nargin < 6
                verbose=1;
            end
            if nargin < 5
                % resample the erp window by this many points
                resampleSize=2000;
            end
            
            if nargin < 3
                % 1 full cycle before events
                prePct=1;
                % 1 full cycle after events
                postPct=1;
            end
            
            % get respiration around events resampled to breathing rate to
            % normalize between subjects
            avgResp = bm.secondaryFeatures('Average Inter-Breath Interval');
            rsPre=round(avgResp * bm.srate * prePct);
            rsPost=round(avgResp * bm.srate * postPct);
            
            thisResp = whichResp(bm);
            
            % get times a full cycle before and after each event
            normalizedERP = createRespiratoryERPMatrix(thisResp, ...
                eventArray, rsPre, rsPost, verbose);
            
            % resample this cycle into resampleSize points
            resampleInds=linspace(1, rsPre + rsPost + 1, resampleSize);
            
            % resample each event and store in matrix
            thisResampledERPMatrix = zeros(size(normalizedERP,1), ...
                resampleSize);
            for e=1:size(normalizedERP,1)
                thisResampledERPMatrix(e,:) = ...
                    interp1(1:size(normalizedERP,2), ...
                    normalizedERP(e,:), resampleInds);
            end
            
            bm.resampledERPMatrix = thisResampledERPMatrix;
            bm.trialEvents = eventArray;
            bm.resampledERPxAxis = linspace(-prePct*100, ...
                postPct*100, resampleSize);
        end

        
        %%% Plotting methods
        
        function fig = plotFeatures(bm, annotate, sizeData)
            % plot all respiratory features that have been calculated
            % property list is string of features to plot 
            if nargin<3
                sizeData=36;
            end
            if nargin<2
                annotate=0;
            end
            fig = plotRespiratoryFeatures(bm, annotate, sizeData);
        end
        
        function fig = plotCompositions(bm, plotType)
            % plot compositions of breaths. Use 'raw', 'normalized', or
            % 'line' as inputs
            
            if nargin < 2
                disp(['No plot type entered. Use ''raw'', ' ...
                    '''normalized'', or ''line'' to specify.']);
                disp('Proceeding using ''raw''');
                plotType='raw';
            end
            
            fig = plotBreathCompositions(bm, plotType);
        end
        
        function fig = plotRespiratoryERP(bm,simpleOrResampled)
            % plot erp (not resampled erp)
            
            if ischar(simpleOrResampled)
                if strcmp(simpleOrResampled,'simple')
                    thisERPMatrix = bm.ERPMatrix;
                    xAxis = bm.ERPxAxis;
                elseif strcmp(simpleOrResampled,'resampled')
                    thisERPMatrix = bm.resampledERPMatrix;
                    xAxis = bm.resampledERPxAxis;
                else
                    disp('method not recognized. Use simple or resampled.')
                end
            else
                % just do simple erp
                thisERPMatrix = bm.ERPMatrix;
                xAxis = bm.ERPxAxis;
                simpleOrResampled='simple';
            end
            
            fig = plotRespiratoryERP(thisERPMatrix, ...
                xAxis, simpleOrResampled);
        end
    end
end
