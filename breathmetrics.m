classdef breathmetrics < handle 
    % VERSION: 0.1 3/23/2018
    % This class takes in a respiratory trace and sampling rate and
    % contains methods for analysis and visualization of several features
    % of respiration that can be derived. See help in indivudal methods for
    % details.
    
    % PARAMETERS
    % resp : Respiration recording in the form of a 1xn vector 
    % srate : sampling rate of recording
    % dataType : either 'human' or 'rodent'. Human data is assumed to be
    % airflow recordings and rodent data is assumed to be thermocouple
    % data.
    
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
        rejectedEvents
    end
   
    methods
        %%% constructor %%%
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
            
            % flip respiratory recording vector if is incorrect orientation
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
                disp(['Notice: Only certain features can be derived ' ...
                    'from rodent data'])
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
        
        %%% Preprocessing Methods %%%
        
        function bm = correctRespirationToBaseline(bm, method, zScore, verbose)
            % Corrects respiratory traces to baseline and removes global 
            % linear trends and drifts
            
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
                    disp('No method given. Defaulting to mean baseline subtraction.')
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
            
            % Using raw respiration for most calculations is not
            % recommended so notify user.
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
            
            % humans and rodents breathe at different time scales so use
            % different sized extrema-finding windows
            if strcmp(bm.dataType, 'human')
                [putativePeaks, putativeTroughs] = ...
                    findRespiratoryExtrema( thisResp, bm.srate );
            elseif strcmp(bm.dataType, 'rodent')
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
            
            % in rodent thermocouple recordings, the peaks and troughs 
            % represent inhales and exhales, not zero-crosses like in 
            % airflow recordings
            if strcmp(bm.dataType,'rodent')
                bm.inhaleOnsets = putativePeaks;
                bm.exhaleOnsets = putativeTroughs;
            end
        end
        
        function bm = findOnsetsAndPauses(bm, verbose )
            % Find breath onsets and pauses in respiratory recording. Only
            % called in human airflow data.
            if nargin < 2
                verbose = 0;
            end
            thisResp = whichResp(bm, verbose);
            
            if bm.srate>100
                nBINS=100;
            else
                % Identifying pauses in data with very low sampling rates
                % requires different criteria to identify pauses.
                nBINS=20;
            end
            [theseInhaleOnsets, theseExhaleOnsets, ...
                theseInhalePauseOnsets, theseExhalePauseOnsets] = ...
                findRespiratoryPausesAndOnsets(thisResp, ...
                bm.inhalePeaks, bm.exhaleTroughs,nBINS);
            bm.inhaleOnsets = theseInhaleOnsets;
            bm.exhaleOnsets = theseExhaleOnsets;
            bm.inhalePauseOnsets = theseInhalePauseOnsets;
            bm.exhalePauseOnsets = theseExhalePauseOnsets;
            
        end
        
        function bm = findInhaleAndExhaleOffsets(bm, verbose )
            % finds the end of each inhale, exhale, inhale pause, and
            % exhale pause.
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
            % calculates the length of each breath and respiratory pause.
            [inhaleLens, exhaleLens, inhalePauseLens, ...
                exhalePauseLens] = findBreathLengths(bm);
            bm.inhaleLengths = inhaleLens;
            bm.exhaleLengths = exhaleLens;
            bm.inhalePauseLengths = inhalePauseLens;
            bm.exhalePauseLengths = exhalePauseLens;
        end
            
        function bm = findInhaleAndExhaleVolumes(bm, verbose )
            % estimates inhale and exhale volumes.
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
            % Estimates all features that can be caluclated using the
            % parameters above. Assumes every feature has already been 
            % calculated.
            % Only breath onsets can be identified in rodent thermocouple 
            % data.
            if nargin < 2
                % It's likely that users will want to print these if they
                % are caluclated.
                verbose=1;
            end
            respStats  = getSecondaryRespiratoryFeatures( bm, verbose );
            bm.secondaryFeatures = respStats;
        end
        
        function dispSecondaryFeatures(bm)
            % Print out summary of all features that were estimated.
            
            keySet = bm.secondaryFeatures.keys;
            disp('Summary of Respiratory Features:')
            for thisKey = 1:length(keySet)
                fprintf('\n %s : %0.5g \n',keySet{thisKey}, ...
                    bm.secondaryFeatures(keySet{thisKey}));
            end
        end
        
        function bm = estimateAllFeatures( bm, zScore, ...
                baselineCorrectionMethod, verbose )
            % Calls methods above to estimate all features of respiration 
            % that can be calculated.
            
            if nargin < 2
                zScore = 0;
            end
            if nargin < 3
                baselineCorrectionMethod = 'sliding';
            end
            if nargin < 4
                verbose = 1;
            end
            if strcmp(bm.dataType,'human')
                
                bm.correctRespirationToBaseline(baselineCorrectionMethod, ...
                    zScore, verbose);
                bm.findExtrema(verbose);
                bm.findOnsetsAndPauses(verbose);
                bm.findInhaleAndExhaleOffsets(verbose);
                bm.findBreathAndPauseLengths();
                bm.findInhaleAndExhaleVolumes(verbose);
                bm.getSecondaryFeatures(verbose);
                
            elseif strcmp(bm.dataType,'rodent')
                % only subset of features can be calculated in rodent
                % thermocouple recordings.
                bm.correctRespirationToBaseline(baselineCorrectionMethod, ...
                    zScore, verbose);
                bm.findExtrema(verbose);
                bm.getSecondaryFeatures(verbose);
            end
        end
        
        function bm = calculateRespiratoryPhase(bm, myFilter, ...
                rateEstimation, verbose)
            % Calculates real-time respiratory phase by computing a 
            % low-pass two-way butterworth filter of the data. Bandwidth 
            % of the filter is .2 Hz greater than the peak of the power 
            % spectrum of the recording.
            % Warning: Because respiration tends to be non-stationary this 
            % function and other filtering methods are not advised for
            % accurate feature extraction.
            
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
                FILTER_BANDWIDTH=0.2;
                myFilter = designfilt( ...
                    'lowpassfir', 'PassbandFrequency', ...
                    filtCenter, 'StopbandFrequency', ...
                    filtCenter + FILTER_BANDWIDTH);
            end
            
            if isempty(myFilter)
                FILTER_BANDWIDTH=0.2;
                myFilter = designfilt( ...
                    'lowpassfir','PassbandFrequency', ...
                    filtCenter, 'StopbandFrequency', ...
                    filtCenter + FILTER_BANDWIDTH);
            end
            
            % filter respiration for central frequency and calcuate phase
            % using a two-way Butterworth filter.
            filteredResp = filtfilt(myFilter, thisResp);
            % calculate instantaneus phase with the angle of the hilbert
            % transformed data.
            bm.respPhase = angle(hilbert(filteredResp));
        end
        
        %%% Event Related Potential (ERP) methods %%%
        function bm = calculateERP( bm, eventArray , pre, post, verbose)
            % Calculates an event related potential (ERP) of the 
            % respiratory trace 'pre' and 'post' milliseconds before and 
            % after time indices in eventArray. Excludes events where a 
            % full window could not be computed.
            % Events that were used are saved in bm.TrialEvents and events
            % that could not be used are saved in bm.RejectedEvents.
            
            if nargin<5
                verbose=1;
            end
            
            thisResp = whichResp(bm);
            
            % convert pre and post from ms into samples
            toRealMs = bm.srate / 1000;
            preSamples = round(pre * toRealMs);
            postSamples = round(post * toRealMs);

            [thisERPMatrix,theseTrialEvents,theseRejectedEvents] = createRespiratoryERPMatrix( thisResp, ...
                eventArray, preSamples, postSamples, verbose );
            srateStep = 1000 / bm.srate;
            
            % if sampling rate is a float, x axis can mismatch. Following
            % code resolves this but can be off by 1 sample.
            tempxAxis = -pre:srateStep:post+srateStep;

            if length(tempxAxis) > size(thisERPMatrix,2)
                bm.ERPxAxis = tempxAxis(1:size(thisERPMatrix,2));
            elseif length(tempxAxis) < size(thisERPMatrix,2)
                thisERPMatrix = thisERPMatrix(:,1:length(tempxAxis));
                bm.ERPxAxis = tempxAxis;
            end
            
            bm.ERPMatrix = thisERPMatrix;
            bm.trialEvents = theseTrialEvents;
            bm.rejectedEvents=theseRejectedEvents;
        end
        
        function bm = calculateResampledERP(bm, eventArray, prePct, ...
                postPct, resampleSize, verbose)
            % Calculates an event related potential (ERP) of the 
            % respiratory trace resampled by the average breathing rate to 
            % a length of 'resampleSize' at each event in eventArray.
            %'pre' and 'post' are the fraction of the average breathing 
            % rate to include in the ERP.     
            % Excludes events where a full window could not be computed.
            % Events that were used are saved in bm.TrialEvents and events
            % that could not be used are saved in bm.RejectedEvents.
            
            if nargin < 6
                verbose=1;
            end
            if nargin < 5
                % resample the erp window by this many points
                resampleSize=2000;
            end
            
            if resampleSize == 0
                disp('Resample size cannot be zero.');
                disp('Setting resample size to 2000 samples');
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
            [normalizedERP,theseTrialEvents,theseRejectedEvents] = createRespiratoryERPMatrix(thisResp, ...
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
            bm.trialEvents = theseTrialEvents;
            bm.rejectedEvents=theseRejectedEvents;
            
            bm.resampledERPxAxis = linspace(-prePct*100, ...
                postPct*100, resampleSize);
        end

        
        %%% Plotting methods %%%
        % Warning: Plotting methods have not been rigerously tested for
        % rodent data.
        
        function fig = plotFeatures(bm, annotate, sizeData)
            % Plots all respiratory features that have been calculated
            % property list is cell of strings with labels of of features 
            % to plot. 
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
            
            if strcmp(bm.dataType,'human')
                if nargin < 2
                    disp(['No plot type entered. Use ''raw'', ' ...
                        '''normalized'', or ''line'' to specify.']);
                    disp('Proceeding using ''raw''');
                    plotType='raw';
                end

                fig = plotBreathCompositions(bm, plotType);
            else
                disp(['This function depends on breath lengths which ' ...
                'is not supported at this time for rodent data.']);
            end
        end
        
        function fig = plotRespiratoryERP(bm,simpleOrResampled)
            % Plot ERP (not resampled erp)
            
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
