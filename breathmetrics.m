classdef breathmetrics < handle 
    % VERSION: 1.1 6/29/2018 
    % Created by The Zelano Lab
    % This class takes in a respiratory trace and sampling rate and
    % contains methods for analysis and visualization of several features
    % of respiration that can be derived. See help in individual methods for
    % details.

    
    % PARAMETERS
    % resp : Respiration recording in the form of a 1xn vector 
    % srate : sampling rate of recording
    % dataType : Defines what kind of data the resp signal represents.
    % Must be set to 'humanAirflow', 'rodentAirflow', 'humanBB',
    % or 'rodentThermocouple'.
    
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
        trialEventInds
        rejectedEventInds
        featureEstimationsComplete
    end
   
    methods
        %%% constructor %%%
        function Bm = breathmetrics(resp, srate, dataType)
            
            Bm.rawRespiration=resp;
            Bm.srate = srate;
            Bm.dataType = dataType;
            Bm.featureEstimationsComplete=0;

            Bm.checkClassInputs();
            
            
            % mean smoothing window is different for rodents and humans
            if strcmp(dataType,'humanAirflow')
                smoothWinsize = 50; 
            
            elseif strcmp(dataType,'humanBB')
                smoothWinsize = 50; 
                disp(['Notice: Only certain features can be derived ' ...
                    'from breathing belt data'])
            
            elseif strcmp(dataType, 'rodentAirflow')
                smoothWinsize = 10;
            
            elseif strcmp(dataType, 'rodentThermocouple')
                smoothWinsize = 10;
                disp(['Notice: Only certain features can be derived ' ...
                    'from rodent thermocouple data'])
            else
                disp(['Data type not recognized. Please specify what' ...
                'kind of data this is by inserting ''humanAirflow'','...
                ' ''humanBB'', ''rodentAirflow'', or '...
                '''rodentThermocouple'' as the third input arguement' ...
                ' for BreathMetrics. Errors will occur if this is not'...
                ' done properly']);
                disp('Proceeding assuming that this is human airflow data.')
                Bm.dataType='humanAirflow';
                smoothWinsize = 50;
            end
            
            % de-noise data
            srateCorrectedSmoothedWindow = ...
                floor((srate/1000) * smoothWinsize);
            % smooth.m works but depends on signal processing toolbox
            % this custom smoothing method isn't dependant and differences
            % are almost indecernable.
            Bm.smoothedRespiration = ...
                fftSmooth(resp, srateCorrectedSmoothedWindow)';
            
            % time is like fieldtrip. All events are indexed by point in
            % time vector.
            Bm.time = (1:length(resp)) / Bm.srate;
        end
        
        %%% Preprocessing Methods %%%
        
        function validParams = checkClassInputs(bm)
            % Helper function to check if class inputs are valid.
            respErrorMessage = ['Respiratory data must be in the form '...
                        'of a 1 x N vector. Please check that your ' ...
                        'data is in the correct format.'];
                    
            if isnumeric(bm.rawRespiration)
                if length(size(bm.rawRespiration)) == 2
                    respCheck=1;
                else
                    respCheck=0;
                    error(respErrorMessage);
                end
            else
                respCheck=0;
                error(respErrorMessage);
            end
            
            srateErrorMessage = ['Sampling rates greater than 5000 hz ' ...
                    'and less than 20 hz are not supported at this ' ...
                    'time. Please resample your data and try again.'];
            if isnumeric(bm.srate)
                if bm.srate > 5000 || bm.srate < 20
                    srateCheck=0;
                    error(srateErrorMessage);
                else
                    srateCheck=1;
                end
            else
                srateCheck=0;
                error(srateErrorMessage);
            end
            
            supportedDataTypes = {
                'humanAirflow';
                'humanBB';
                'rodentAirflow';
                'rodentThermocouple'};
            
            dataTypeError = ['Data type not recognized. Please specify' ...
                ' what kind of data this is by inserting '...
                '''humanAirflow'', ''humanBB'', ''rodentAirflow'', or '...
                '''rodentThermocouple'' as the third input arguement' ...
                ' for BreathMetrics. Errors will occur if this is not'...
                ' done properly'];
            if ismember(bm.dataType,supportedDataTypes)
                typeCheck=1;
            else
                typeCheck=0;
                error(dataTypeError);
            end
            
            validParams = sum([respCheck,srateCheck, typeCheck])==3;
        end
        
        function bm = correctRespirationToBaseline(bm, method, ...
                zScore, verbose)
            % Corrects respiratory traces to baseline by removing offsets, 
            % global linear trends and temporary drifts
            % PARAMETERS
            % method : 
            %    'sliding' (default): uses a 60 second sliding window to 
            %    remove acute drifts in signal baseline.
            %    'simple' : subtracts the mean from the signal. Much faster
            %    but does not remove acute shifts in signal baseline.
            % zScore : 0 (default) or 1 | computes the z-score for  
            %          respiratory amplitudes to normalize for comparison  
            %          between subjects.
            % verbose : 0 (default) or 1 | displays each step of this 
            %          function
            
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
                    disp(['No method given. Defaulting to mean ' ...
                        'baseline subtraction.'])
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
            % Internal function that decides whether to use baseline 
            % corrected or raw respiratory trace. Not intended to be used 
            % by users
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
            % Estimate peaks and troughs in respiratory data.
            % PARAMETERS
            % bm : BreathMetrics object
            % verbose : 0 (default) or 1 : displays each step of this
            % function
            
            if nargin < 2
                verbose = 0;
            end
            thisResp = whichResp(bm, verbose);
            
            % humans and rodents breathe at different time scales so use
            % different sized extrema-finding windows
            
            % peaks and troughs are identified the same way for human
            % airflow and breathing belt recordings
            if strfind(bm.dataType, 'human')==1
                [putativePeaks, putativeTroughs] = ...
                    findRespiratoryExtrema( thisResp, bm.srate );
                
                
            % same extrema finding for thermocouple and airflow recordings
            % in rodents
            elseif strfind(bm.dataType, 'rodent')==1
                srateAdjust = bm.srate/1000;
                rodentSWSizes = [floor(5*srateAdjust), ...
                    floor(10 * srateAdjust), floor(20 * srateAdjust), ...
                    floor(50 * srateAdjust)];
                [putativePeaks, putativeTroughs] = ...
                    findRespiratoryExtrema( thisResp, bm.srate, ...
                    0, rodentSWSizes );
            end
            
            % The extrema represent the peak flow rates of inhales and 
            % exhales only in airflow recordings.
            if strcmp(bm.dataType,'humanAirflow') || strcmp(bm.dataType,'rodentAirflow')
                % indices of extrema
                bm.inhalePeaks = putativePeaks;
                bm.exhaleTroughs = putativeTroughs;

                % values of extrema
                bm.peakInspiratoryFlows = thisResp(putativePeaks);
                bm.troughExpiratoryFlows = thisResp(putativeTroughs);
            end
            
            % In human breathing belt recordings, the peaks and troughs 
            % represent exhale and inhale onsets, respectively, because the
            % point where volume has maximized and instantaneously
            % decreases demarcates an exhale. This is unlike zero-crosses 
            % which demarcate breath onsets in airflow recordings.
            if strcmp(bm.dataType,'humanBB')
                bm.inhaleOnsets = putativeTroughs;
                bm.exhaleOnsets = putativePeaks;
            
            % In rodent thermocouple recordings, the peaks and troughs 
            % represent inhale and exhale onsets, respectively. Inhales
            % decrease the temperature in the nose and the onset is
            % demarcated by the first point this happens - the inflection
            % point of the peaks. Visa versa for exhales.
            elseif strcmp(bm.dataType,'rodentThermocouple')
                bm.inhaleOnsets = putativePeaks;
                bm.exhaleOnsets = putativeTroughs;
            end
        end
        
        function bm = findOnsetsAndPauses(bm, verbose )
            % Find breath onsets and pauses in respiratory recording. 
            % Only valid for analyzing airflow data.
            % PARAMETERS
            % bm : BreathMetrics object
            % verbose : 0 (default) or 1 : displays each step of this
            % function
            if nargin < 2
                verbose = 0;
            end
            thisResp = whichResp(bm, verbose);
            % Identifying pauses in data with different sampling rates
            % require different binning criteria to identify pauses.
            nBINS=floor(bm.srate/100);
            if nBINS<=20
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
            % Only valid for analyzing airflow data.
            % PARAMETERS
            % bm : BreathMetrics object
            % verbose : 0 (default) or 1 : displays each step of this
            % function
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
            % Only valid for analyzing airflow data.
            [inhaleLens, exhaleLens, inhalePauseLens, ...
                exhalePauseLens] = findBreathLengths(bm);
            bm.inhaleLengths = inhaleLens;
            bm.exhaleLengths = exhaleLens;
            bm.inhalePauseLengths = inhalePauseLens;
            bm.exhalePauseLengths = exhalePauseLens;
        end
            
        function bm = findInhaleAndExhaleVolumes(bm, verbose )
            % estimates inhale and exhale volumes.
            % Only valid for analyzing airflow data.
            
            % PARAMETERS
            % bm : BreathMetrics object
            % verbose : 0 (default) or 1 : displays each step of this
            % function
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
            % parameters above. Assumes that every valid feature for this 
            % data type has already been calculated.
            
            % PARAMETERS
            % bm : BreathMetrics object
            % verbose : 0 (default) or 1 : displays statistical summary
            % for all features calculated
            
            if nargin < 2
                % It's likely that users will want to print these if they
                % are caluclated.
                verbose=1;
            end
            respStats  = getSecondaryRespiratoryFeatures( bm, verbose );
            bm.secondaryFeatures = respStats;
            bm.checkFeatureEstimations();
        end
        
        function dispSecondaryFeatures(bm)
            % Print out statistical summary of all features that were 
            % estimated.
            
            keySet = bm.secondaryFeatures.keys;
            disp('Summary of Respiratory Features:')
            for thisKey = 1:length(keySet)
                fprintf('\n %s : %0.5g \n',keySet{thisKey}, ...
                    bm.secondaryFeatures(keySet{thisKey}));
            end
        end
        
        function bm = checkFeatureEstimations(bm)
            % checks whether each feature has been estimated
            % sets bm.featureEstimationsComplete to 1 if this is true
            
            airflowCompleteFeatureSet={
                'baselineCorrectedRespiration';'inhalePeaks';
                'exhaleTroughs';'peakInspiratoryFlows';
                'troughExpiratoryFlows';'inhaleOnsets';
                'exhaleOnsets';'inhaleOffsets';
                'exhaleOffsets';'inhaleVolumes';
                'exhaleVolumes';'inhaleLengths';
                'exhaleLengths';'inhalePauseOnsets';
                'inhalePauseLengths';'exhalePauseOnsets';
                'exhalePauseLengths';'secondaryFeatures'};
            
            otherSignalCompleteFeatureSet={
                'baselineCorrectedRespiration';'inhalePeaks';
                'exhaleTroughs';'secondaryFeatures'};
            
            if strcmp(bm.dataType,'humanAirflow') || ...
                    strcmp(bm.dataType,'rodentAirflow')
                thisFeatureSet = airflowCompleteFeatureSet;
            elseif strcmp(bm.dataType,'humanBB') || ...
                    strcmp(bm.dataType,'rodentThermocouple')
                thisFeatureSet = otherSignalCompleteFeatureSet;
            else
                disp('This data type is not recognized.');
                thisFeatureSet=[];
            end
            
            nMissingFeatures=0;
            for i = 1:length(thisFeatureSet)
                thisFeature=thisFeatureSet{i};
                if isempty(bm.(thisFeature))
                    nMissingFeatures=nMissingFeatures+1;
                    fprintf(['\n Feature: %s has not been calculated' ...
                        '\n'],thisFeature);
                end
            end
            
            if nMissingFeatures == 0
                bm.featureEstimationsComplete=1;
            end
            
        end
            
        function bm = estimateAllFeatures( bm, zScore, ...
                baselineCorrectionMethod, verbose )
            % Calls methods above to estimate all features of respiration 
            % that can be calculated for this data type.
            
            % PARAMETERS
            % method : 
            %    'sliding' (default): uses a 60 second sliding window to 
            %    remove acute drifts in signal baseline.
            %    'simple' : subtracts the mean from the signal. Much faster
            %    but does not remove acute shifts in signal baseline.
            % zScore : 0 (default) or 1 | computes the z-score for  
            %          respiratory amplitudes to normalize for comparison  
            %          between subjects.
            % verbose : 0  or 1 (default) | displays each step of every
            %          embedded function called by this one
            
            if nargin < 2
                zScore = 0;
            end
            if nargin < 3
                baselineCorrectionMethod = 'sliding';
            end
            if nargin < 4
                verbose = 1;
            end
            
            if strcmp(bm.dataType,'humanAirflow') || ...
                    strcmp(bm.dataType,'rodentAirflow')
                
                bm.correctRespirationToBaseline(baselineCorrectionMethod, ...
                    zScore, verbose);
                bm.findExtrema(verbose);
                bm.findOnsetsAndPauses(verbose);
                bm.findInhaleAndExhaleOffsets(verbose);
                bm.findBreathAndPauseLengths();
                bm.findInhaleAndExhaleVolumes(verbose);
                bm.getSecondaryFeatures(verbose);
                
            elseif strcmp(bm.dataType,'humanBB') || ...
                    strcmp(bm.dataType,'rodentThermocouple')
                % only subset of features can be calculated in rodent
                % thermocouple recordings.
                bm.correctRespirationToBaseline(...
                    baselineCorrectionMethod, zScore, verbose);
                bm.findExtrema(verbose);
                bm.getSecondaryFeatures(verbose);
            end
            bm = bm.checkFeatureEstimations();
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
            
            % PARAMETERS
            % bm : BreathMetrics class object
            % myFilter : MATLAB digital filter object. Filter to use to
            % calculate phase
            % rateEstimation : 
            %    'featureDerived' : calculates breathing rate by
            %                       calculating average inter-breath 
            %                       interval
            % 'pspec' : calculates breathing rate using the peak of the
            %           power spectrum.
            % verbose : 0 or 1 (default) : displays each step of the
            %           function
            
            thisResp = bm.whichResp();
            if nargin < 4
                verbose=1;
            end
            if nargin < 3
                rateEstimation = 'featureDerived';
            end
            
            if strcmp(rateEstimation,'featureDerived')
                % breathing rate derived from inter-breath interval
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
            bm.respiratoryPhase = angle(hilbert(filteredResp));
        end
        
        %%% Event Related Potential (ERP) methods %%%
        
        function bm = calculateERP( bm, eventArray , pre, post, ...
                appendNaNs,verbose)
            % Calculates an event related potential (ERP) of the 
            % respiratory trace 'pre' and 'post' milliseconds before and 
            % after time indices in eventArray, excluding events where a 
            % full window could not be computed.
            % Events that were used are saved in bm.TrialEvents and events
            % that could not be used are saved in bm.RejectedEvents.
            
            % PARAMETERS
            % bm : BreathMetrics class object
            % eventArray : indices of events to be used as onsets for the
            % ERP
            % pre : milliseconds before each event in eventArray to include
            %       in ERP calculation (must be positive).
            % post : milliseconds after each event in eventArray to include
            %        in ERP calculation.
            % verbose : 0 or 1 (default) : displays each step of this
            %           function
            
            if nargin<5
                appendNaNs=0;
            end
            if nargin<6
                verbose=0;
            end
            
            thisResp = whichResp(bm);
            
            % convert pre and post from ms into samples
            toRealMs = bm.srate / 1000;
            preSamples = round(pre * toRealMs);
            postSamples = round(post * toRealMs);

            [thisERPMatrix,theseTrialEvents,theseRejectedEvents,...
                theseTrialEventInds,theseRejectedEventInds] = ...
                createRespiratoryERPMatrix( thisResp, eventArray, ...
                preSamples, postSamples, appendNaNs, verbose );
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
            bm.trialEventInds = theseTrialEventInds;
            bm.rejectedEventInds=theseRejectedEventInds;
        end
        
        function bm = calculateResampledERP(bm, eventArray, prePct, ...
                postPct, resampleSize, appendNaNs, verbose)
            % Calculates an event related potential (ERP) of the 
            % respiratory trace resampled by the average breathing rate to 
            % a length of 'resampleSize' at each event in eventArray.
            %'pre' and 'post' are the fraction of the average breathing 
            % rate to include in the ERP, excluding events where a 
            % full window could not be computed.
            % Events that were used are saved in bm.TrialEvents and events
            % that could not be used are saved in bm.RejectedEvents.
            
            % PARAMETERS
            % bm : BreathMetrics class object
            % eventArray : indices of events to be used as onsets for the
            % ERP
            % prePct : percent of resampleSize window to use as baseline
            %          for ERP calculation (must be positive)
            % postPct : percent of resampleSize window to use as window
            %           size for ERP calculation
            % resampleSize : number of samples to which each ERP window
            %                will be resampled (default is 2000 samples)
            % verbose : 0 or 1 (default) : displays each step of this
            %           function
            
            if nargin < 7
                verbose=1;
            end
            
            if nargin < 6
                % resample the erp window by this many points
                appendNaNs=0;
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
            avgResp = bm.secondaryFeatures(...
                'Average Inter-Breath Interval');
            rsPre=round(avgResp * bm.srate * prePct);
            rsPost=round(avgResp * bm.srate * postPct);
            
            thisResp = whichResp(bm);
            
            % get times a full cycle before and after each event
            [normalizedERP,theseTrialEvents,theseRejectedEvents,...
                theseTrialEventInds,theseRejectedEventInds] = ...
                createRespiratoryERPMatrix(thisResp, eventArray, ...
                rsPre, rsPost, appendNaNs, verbose);
            
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
            bm.trialEventInds = theseTrialEventInds;
            bm.rejectedEventInds=theseRejectedEventInds;
            
            bm.resampledERPxAxis = linspace(-prePct*100, ...
                postPct*100, resampleSize);
        end

        
        %%% Plotting methods %%%
        
        function fig = plotFeatures(bm, annotate, sizeData)
            % Plots all respiratory features that have been calculated
            % property list is cell of strings with labels of of features 
            % to plot. 
            
            % PARAMETERS:
            % bm : BreathMetrics class object
            % annotate : features to plot. Options are: 
            % 'extrema', 'onsets','maxflow','volumes', and 'pauses'
            % sizeData : size of feature labels. Helpful for visualizing 
            % features in data of different window sizes.
            
            if nargin<3
                sizeData=36;
            end
            if nargin<2
                annotate=0;
            end
            fig = plotRespiratoryFeatures(bm, annotate, sizeData);
        end
        
        function fig = plotCompositions(bm, plotType)
            % Images compositions of each breath in the recording. 
            
            % PARAMETERS:
            % bm : BreathMetrics class object
            % plotType : 'raw' : images the composition of each breath,
            %                    leaving extra space for all breaths 
            %                    shorter than the longest in duration
            %            'normalized' : images the composition of each
            %                           breath, normalized by its duration.
            %            'line' : Plots each breath as a line where the x-
            %                     value represents phase and the y-value
            %                     represents duration of phase
            
            if strcmp(bm.dataType,'humanAirflow') || ...
                    strcmp(bm.dataType,'rodentAirflow')
                if nargin < 2
                    disp(['No plot type entered. Use ''raw'', ' ...
                        '''normalized'', or ''line'' to specify.']);
                    disp('Proceeding using ''raw''');
                    plotType='raw';
                end

                fig = plotBreathCompositions(bm, plotType);
            else
                disp(['This function depends on breath durations, ' ...
                'which is not supported at this time for rodent ' ...
                'thermocouple data.']);
            end
        end
        
        function fig = plotRespiratoryERP(bm,simpleOrResampled)
            % Plots an erp of respiratory data that has been generated
            % using calculateERP or calculateResampledERP. One of these
            % functions must be run prior to calling this function.
            
            % simpleOrResampled : set to 'simple' to plot the precalculated 
            % standard ERP or set to 'resampled' to plot the precalculated
            % resampled ERP.
            
            if ischar(simpleOrResampled)
                if strcmp(simpleOrResampled,'simple')
                    thisERPMatrix = bm.ERPMatrix;
                    xAxis = bm.ERPxAxis;
                elseif strcmp(simpleOrResampled,'resampled')
                    thisERPMatrix = bm.resampledERPMatrix;
                    xAxis = bm.resampledERPxAxis;
                else
                    disp(['Method not recognized. Please set ' ...
                        'SimpleOrResampled to ''simple'' or ' ...
                        '''resampled.'''])
                end
            else
                disp(['ERP method not specified. Please set ' ...
                    'SimpleOrResampled to ''simple'' or ' ...
                    '''resampled.'' Proceeding using a standard ERP.' ])
                thisERPMatrix = bm.ERPMatrix;
                xAxis = bm.ERPxAxis;
                simpleOrResampled='simple';
            end
            
            fig = plotRespiratoryERP(thisERPMatrix, ...
                xAxis, simpleOrResampled);
        end
        
        function launchGUI(bm)
            v = ver('test');
            if isempty(v)
                disp(['The GUI is dependant on the GUI Layout Toolbox,' ...
                    ' which has has not been installed on your ' ...
                    'machine. Information about installing this ' ...
                    'package can be found here: ' ...
                    'https://www.mathworks.com/matlabcentral/' ...
                    'fileexchange/47982-gui-layout-toolbox'])
            else
                BreathMetricsGUI(bm);
            end
        end
    end
end
