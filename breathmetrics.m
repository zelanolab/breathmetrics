 classdef breathmetrics < matlab.mixin.Copyable
    % Version 2.0 9/30/2019
    %
    % Created by The Zelano Lab
    %
    % This class takes in a respiratory trace and sampling rate and
    % contains methods for analysis and visualization of several features
    % of respiration that can be derived. See help in individual methods for
    % details.
    %
    % Version 1.1 created on 6/29/2018 
    %
    % IMPORTANT NOTE:
    % breathmetrics acts as a handle, meaning that if you set another
    % variable to it, changing its properties will change the properties of
    % BOTH OBJECTS. If you want to make a copy use the copy function as so:
    % newBmObj=copy(bmObj);

    
    % PARAMETERS
    % resp : Respiration recording in the form of a 1xn vector 
    % srate : sampling rate of recording
    % dataType : Defines what kind of data the resp signal represents.
    % Must be set to 'humanAirflow', 'rodentAirflow', 'humanBB',
    % or 'rodentThermocouple'.
    
    properties
        % signal properties
        dataType
        srate
        time
        
        % breathing signal
        rawRespiration
        smoothedRespiration
        baselineCorrectedRespiration
        
        % calculated features
        inhalePeaks
        exhaleTroughs
        
        peakInspiratoryFlows
        troughExpiratoryFlows
        
        inhaleOnsets
        exhaleOnsets
        
        inhaleOffsets
        exhaleOffsets
        
        inhaleTimeToPeak
        exhaleTimeToTrough
        
        inhaleVolumes
        exhaleVolumes
        
        inhaleDurations
        exhaleDurations
        
        inhalePauseOnsets
        exhalePauseOnsets
        
        inhalePauseDurations
        exhalePauseDurations
        
        secondaryFeatures
        
        respiratoryPhase
        
        % erp params
        ERPMatrix
        ERPxAxis
        
        resampledERPMatrix
        resampledERPxAxis
        
        ERPtrialEvents
        ERPrejectedEvents
        
        ERPtrialEventInds
        ERPrejectedEventInds
        
        statuses
        notes
        
        featureEstimationsComplete
        featuresManuallyEdited
    end
   
    methods
        %%% constructor %%%
        function Bm = breathmetrics(resp, srate, dataType)
            
            Bm.rawRespiration=resp;
            Bm.srate = srate;
            Bm.dataType = dataType;
            Bm.featureEstimationsComplete=0;
            Bm.featuresManuallyEdited=0;

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
        
        function validParams = checkClassInputs(Bm)
            % Helper function to check if class inputs are valid.
            respErrorMessage = ['Respiratory data must be in the form '...
                        'of a 1 x N vector. Please check that your ' ...
                        'data is in the correct format.'];
                    
            if isnumeric(Bm.rawRespiration)
                if length(size(Bm.rawRespiration)) == 2
                    if size(Bm.rawRespiration,1) ~= 1
                        Bm.rawRespiration = Bm.rawRespiration';
                    end
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
            if isnumeric(Bm.srate)
                if Bm.srate > 5000 || Bm.srate < 20
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
            if ismember(Bm.dataType,supportedDataTypes)
                typeCheck=1;
            else
                typeCheck=0;
                error(dataTypeError);
            end
            
            validParams = sum([respCheck,srateCheck, typeCheck]) == 3;
        end
        
        function Bm = correctRespirationToBaseline(Bm, method, ...
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
            thisResp = detrend(Bm.smoothedRespiration);
            
            %find mean resp
            respMean = thisResp - mean(thisResp);
            
            
            if strcmp(method,'simple')
                Bm.baselineCorrectedRespiration = respMean;
                
            elseif strcmp(method, 'sliding')
                % for periodic drifts in data
                srateCorrectedSW = floor(Bm.srate * swSize);
                if verbose == 1
                    fprintf( [ 'Calculating sliding average using ', ...
                        'window size of %i seconds \n' ],swSize);
                end
                
                respSlidingMean=fftSmooth(thisResp, srateCorrectedSW);
                
                % subtract sliding mean from respiratory trace
                Bm.baselineCorrectedRespiration = ...
                    thisResp - respSlidingMean';
            
            else
                disp(['Baseline correction method not recognized. '
                    'Please use ''simple'' or ''sliding'' as inputs.'])
            end
            
            % z score respiratory amplitudes to control for breath sizes
            % when comparing certain features between individuals
            if zScore == 1
                Bm.baselineCorrectedRespiration = ...
                    zscore(Bm.baselineCorrectedRespiration);
            end
            
        end
        
        function thisResp = whichResp(Bm, verbose )
            % Internal function that decides whether to use baseline 
            % corrected or raw respiratory trace. Not intended to be used 
            % by users
            if nargin < 2
                verbose = 0;
            end
            
            % Using raw respiration for most calculations is not
            % recommended so notify user.
            if isempty(Bm.baselineCorrectedRespiration)
                disp(['No baseline corrected respiration found.' ...
                    'Using smoothed respiration.'])
                disp(['Non-baseline corrected data can give ' ...
                    'inaccurate estimations of breath onsets and volumes'])
                disp(['Use correctRespToBaseline to remove drifts' ...
                    ' or offsets in the data'])
                thisResp = Bm.smoothedRespiration;
            else
                if verbose == 1
                    disp('Using baseline corrected respiration');
                end
                thisResp = Bm.baselineCorrectedRespiration;
            end
        end
        
        %%% Feature Extraction Methods %%%
        
        function Bm = findExtrema(Bm, simplify, verbose)
            % Estimate peaks and troughs in respiratory data.
            % PARAMETERS
            % bm : BreathMetrics object
            % simplify: 0 (default) or 1 : if zero nInhales=nExhales
            % (discards final inhale if there is no subsequent exhale)
            % verbose : 0 (default) or 1 : displays each step of this
            % function
            
            if nargin < 2
                simplify = 1;
            end
            if nargin < 3
                verbose = 0;
            end
            
            thisResp = whichResp(Bm, verbose);
            
            if verbose
                disp('to find extrema');
            end
            
            % humans and rodents breathe at different time scales so use
            % different sized extrema-finding windows
            
            % peaks and troughs are identified the same way for human
            % airflow and breathing belt recordings
            if strfind(Bm.dataType, 'human')==1
                [putativePeaks, putativeTroughs] = ...
                    findRespiratoryExtrema( thisResp, Bm.srate );
                
            % same extrema finding for thermocouple and airflow recordings
            % in rodents
            elseif strfind(Bm.dataType, 'rodent')==1
                srateAdjust = Bm.srate/1000;
                rodentSWSizes = [floor(5*srateAdjust), ...
                    floor(10 * srateAdjust), floor(20 * srateAdjust), ...
                    floor(50 * srateAdjust)];
                [putativePeaks, putativeTroughs] = ...
                    findRespiratoryExtrema( thisResp, Bm.srate, ...
                    0, rodentSWSizes );
            end
            
            % set nPeaks to nTroughs
            if simplify
                putativePeaks=putativePeaks(1:length(putativeTroughs));
            end
            
            % The extrema represent the peak flow rates of inhales and 
            % exhales only in airflow recordings.
            if strcmp(Bm.dataType,'humanAirflow') || strcmp(Bm.dataType,'rodentAirflow')
                % indices of extrema
                Bm.inhalePeaks = putativePeaks;
                Bm.exhaleTroughs = putativeTroughs;

                % values of extrema
                Bm.peakInspiratoryFlows = thisResp(putativePeaks);
                Bm.troughExpiratoryFlows = thisResp(putativeTroughs);
            end
            
            % In human breathing belt recordings, the peaks and troughs 
            % represent exhale and inhale onsets, respectively, because the
            % point where volume has maximized and instantaneously
            % decreases demarcates an exhale. This is unlike zero-crosses 
            % which demarcate breath onsets in airflow recordings.
            if strcmp(Bm.dataType,'humanBB')
                
                % make sure inhale happens before exhale
                if putativeTroughs(1)>putativePeaks(1)
                    putativePeaks=putativePeaks(2:end);
                    putativeTroughs=putativeTroughs(1:end-1);
                end
                    
                Bm.inhaleOnsets = putativeTroughs;
                Bm.exhaleOnsets = putativePeaks;

            
            % In rodent thermocouple recordings, the peaks and troughs 
            % represent inhale and exhale onsets, respectively. Inhales
            % decrease the temperature in the nose and the onset is
            % demarcated by the first point this happens - the inflection
            % point of the peaks. Visa versa for exhales.
            elseif strcmp(Bm.dataType,'rodentThermocouple')
                Bm.inhaleOnsets = putativePeaks;
                Bm.exhaleOnsets = putativeTroughs;
            end
        end
        
        function Bm = findOnsetsAndPauses(Bm, verbose )
            % Find breath onsets and pauses in respiratory recording. 
            % Only valid for analyzing airflow data.
            % PARAMETERS
            % bm : BreathMetrics object
            % verbose : 0 (default) or 1 : displays each step of this
            % function
            if nargin < 2
                verbose = 0;
            end
            
            thisResp = whichResp(Bm, verbose);
            
            if verbose
                disp('to find breath onsets and pauses');
            end
            
            % Identifying pauses in data with different sampling rates
            % require different binning criteria to identify pauses.
            nBINS=floor(Bm.srate/100);
            if nBINS<=20
                nBINS=20;
            end
    
            [theseInhaleOnsets, theseExhaleOnsets, ...
                theseInhalePauseOnsets, theseExhalePauseOnsets] = ...
                findRespiratoryPausesAndOnsets(thisResp, ...
                Bm.inhalePeaks, Bm.exhaleTroughs,nBINS);
            Bm.inhaleOnsets = theseInhaleOnsets;
            Bm.exhaleOnsets = theseExhaleOnsets;
            Bm.inhalePauseOnsets = theseInhalePauseOnsets;
            Bm.exhalePauseOnsets = theseExhalePauseOnsets;
            
            
            % and calculate time to peak
            timeToPeaks=(Bm.inhalePeaks-Bm.inhaleOnsets)/Bm.srate;
            
            % sometimes no trough of exhale at last breath
            nTroughs=length(Bm.exhaleTroughs);
            timeToTroughs=(Bm.exhaleTroughs(1:nTroughs)-Bm.exhaleOnsets(1:nTroughs))/Bm.srate;
            
            Bm.inhaleTimeToPeak=timeToPeaks;
            Bm.exhaleTimeToTrough=timeToTroughs;
            
        end
        
        
        function Bm = findInhaleAndExhaleOffsets(Bm, verbose )
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
            
            thisResp = whichResp(Bm, verbose);
            
            if verbose==1
                disp('to find breath offsets');
            end
            
            [inhaleOffs,exhaleOffs]=findRespiratoryOffsets(thisResp, ...
                Bm.inhaleOnsets, Bm.exhaleOnsets, ...
                Bm.inhalePauseOnsets, Bm.exhalePauseOnsets);
            Bm.inhaleOffsets=inhaleOffs;
            Bm.exhaleOffsets=exhaleOffs;
        end
        
        function Bm = findBreathAndPauseDurations(Bm)
            % calculates the duration of each breath and respiratory pause.
            % Only valid for analyzing airflow data.
            [inhaleDurs, exhaleDurs, inhalePauseDurs, ...
                exhalePauseDurs] = findBreathDurations(Bm);
            Bm.inhaleDurations = inhaleDurs;
            Bm.exhaleDurations = exhaleDurs;
            Bm.inhalePauseDurations = inhalePauseDurs;
            Bm.exhalePauseDurations = exhalePauseDurs;
        end
            
        function Bm = findInhaleAndExhaleVolumes(Bm, verbose )
            % estimates inhale and exhale volumes.
            % Only valid for analyzing airflow data.
            
            % PARAMETERS
            % bm : BreathMetrics object
            % verbose : 0 (default) or 1 : displays each step of this
            % function
            if nargin < 2
                verbose = 0;
            end
            
            thisResp = whichResp(Bm, verbose);
            
            if verbose
                disp('to calculate breath volumes');
            end
            
            [inhaleVols,exhaleVols] = findRespiratoryVolumes( ...
                thisResp, Bm.srate, Bm.inhaleOnsets, Bm.exhaleOnsets, ...
                Bm.inhaleOffsets, Bm.exhaleOffsets);
            Bm.inhaleVolumes = inhaleVols;
            Bm.exhaleVolumes = exhaleVols;
        end
        
        function Bm = getSecondaryFeatures( Bm, verbose )
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
            respStats  = getSecondaryRespiratoryFeatures( Bm, verbose );
            Bm.secondaryFeatures = respStats;
            Bm.checkFeatureEstimations();
        end
        
        function dispSecondaryFeatures(Bm)
            % Print out statistical summary of all features that were 
            % estimated.
            
            keySet = Bm.secondaryFeatures.keys;
            disp('Summary of Respiratory Features:')
            for thisKey = 1:length(keySet)
                fprintf('\n %s : %0.5g \n',keySet{thisKey}, ...
                    Bm.secondaryFeatures(keySet{thisKey}));
            end
        end
        
        function Bm = checkFeatureEstimations(Bm)
            % checks whether each feature has been estimated
            % sets bm.featureEstimationsComplete to 1 if this is true
            
            airflowCompleteFeatureSet={
                'baselineCorrectedRespiration';'inhalePeaks';
                'exhaleTroughs';'peakInspiratoryFlows';
                'troughExpiratoryFlows';'inhaleOnsets';
                'exhaleOnsets';'inhaleOffsets';
                'exhaleOffsets';'inhaleVolumes';
                'exhaleVolumes';'inhaleDurations';
                'exhaleDurations';'inhalePauseOnsets';
                'inhalePauseDurations';'exhalePauseOnsets';
                'exhalePauseDurations';'secondaryFeatures'};
            
            otherSignalCompleteFeatureSet={
                'baselineCorrectedRespiration';'inhaleOnsets';
                'exhaleOnsets';'secondaryFeatures'};
            
            if strcmp(Bm.dataType,'humanAirflow') || ...
                    strcmp(Bm.dataType,'rodentAirflow')
                thisFeatureSet = airflowCompleteFeatureSet;
            elseif strcmp(Bm.dataType,'humanBB') || ...
                    strcmp(Bm.dataType,'rodentThermocouple')
                thisFeatureSet = otherSignalCompleteFeatureSet;
            else
                disp('This data type is not recognized.');
                thisFeatureSet=[];
            end
            
            nMissingFeatures=0;
            for i = 1:length(thisFeatureSet)
                thisFeature=thisFeatureSet{i};
                if isempty(Bm.(thisFeature))
                    nMissingFeatures=nMissingFeatures+1;
                    fprintf(['\n Feature: %s has not been calculated' ...
                        '\n'],thisFeature);
                end
            end
            
            if nMissingFeatures == 0
                Bm.featureEstimationsComplete=1;
            end
            
        end
            
        function Bm = estimateAllFeatures( Bm, zScore, ...
                baselineCorrectionMethod, simplify, verbose )
            % Calls methods above to estimate all features of respiration 
            % that can be calculated for this data type.
            
            % PARAMETERS
            % method : 
            %    'sliding' (default): uses a 60 second sliding window to 
            %    remove acute drifts in signal baseline.
            %    'simple' : subtracts the mean from the signal. Much faster
            %    but does not remove acute shifts in signal baseline.
            %
            % zScore : 0 (default) or 1 | computes the z-score for  
            %          respiratory amplitudes to normalize for comparison  
            %          between subjects.
            %
            % simplify: 0 or 1  (default)| if set to 1 nInhales = nExhales
            %           params of final exhales sometimes can't be computed
            %           this function discards the final inhale to keep
            %           nInhales and nExhales the same.
            %
            % verbose : 0  or 1 (default) | displays each step of every
            %          embedded function called by this one
            
            if nargin < 2
                zScore = 0;
            end
            if nargin < 3
                baselineCorrectionMethod = 'sliding';
            end
            if nargin < 4
                simplify = 1;
            end
            if nargin < 5
                verbose = 1;
            end
            
            if strcmp(Bm.dataType,'humanAirflow') || ...
                    strcmp(Bm.dataType,'rodentAirflow')
                
                Bm.correctRespirationToBaseline(baselineCorrectionMethod, ...
                    zScore, verbose);
                Bm.findExtrema(simplify, verbose);
                Bm.findOnsetsAndPauses(verbose);
                Bm.findInhaleAndExhaleOffsets(verbose);
                Bm.findBreathAndPauseDurations();
                Bm.findInhaleAndExhaleVolumes(verbose);
                Bm.getSecondaryFeatures(verbose);
                
            elseif strcmp(Bm.dataType,'humanBB') || ...
                    strcmp(Bm.dataType,'rodentThermocouple')
                % only subset of features can be calculated in rodent
                % thermocouple recordings.
                Bm.correctRespirationToBaseline(...
                    baselineCorrectionMethod, zScore, verbose);
                Bm.findExtrema(simplify, verbose);
                Bm.getSecondaryFeatures(verbose);
            end
            Bm = Bm.checkFeatureEstimations();
        end
        
        function Bm = manualAdjustPostProcess( Bm ) 
            % call this after manually changing phase onsets to recompute
            % features
            verbose=0;
            
            if strcmp(Bm.dataType,'humanAirflow') || ...
                    strcmp(Bm.dataType,'rodentAirflow')
                
                % these must be recomputed if onsets have changed
                Bm.findInhaleAndExhaleOffsets(verbose);
                Bm.findBreathAndPauseDurations();
                Bm.findInhaleAndExhaleVolumes(verbose);
                Bm.getSecondaryFeatures(verbose);
                
            elseif strcmp(Bm.dataType,'humanBB') || ...
                    strcmp(Bm.dataType,'rodentThermocouple')
                % only subset of features can be calculated in rodent
                % thermocouple recordings.
                
                Bm.getSecondaryFeatures(verbose);
            end
            Bm = Bm.checkFeatureEstimations();
            
        end
            
        function Bm = calculateRespiratoryPhase(Bm, myFilter, ...
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
            
            
            if nargin < 4
                verbose=1;
            end
            
            if nargin < 3
                rateEstimation = 'featureDerived';
            end
            
            thisResp = Bm.whichResp(verbose);

            if verbose
                disp('to calculate phase');
            end
            
            if strcmp(rateEstimation,'featureDerived')
                % breathing rate derived from inter-breath interval
                filtCenter = Bm.secondaryFeatures('Breathing Rate');
                
            elseif strcmp(rateEstimation, 'pspec')
                % breathing rate derived from power spectrum
                [Pxx,pspecAxis] = pwelch(thisResp, [], [], [], ...
                    Bm.srate, 'twosided');
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
                myFilter = designfilt('lowpassfir', ...
                    'PassbandFrequency', filtCenter, ...
                    'StopbandFrequency', filtCenter + FILTER_BANDWIDTH,...
                    'SampleRate',Bm.srate,...
                    'DesignMethod', 'kaiserwin');
            end
            
            if isempty(myFilter)
                FILTER_BANDWIDTH=0.2;
                myFilter = designfilt('lowpassfir', ...
                    'PassbandFrequency', filtCenter, ...
                    'StopbandFrequency', filtCenter + FILTER_BANDWIDTH,...
                    'SampleRate',Bm.srate,...
                    'DesignMethod', 'kaiserwin');
            end
            
            % filter respiration for central frequency and calcuate phase
            % using a two-way Butterworth filter.
            filteredResp = filtfilt(myFilter, thisResp);
            % calculate instantaneus phase with the angle of the hilbert
            % transformed data.
            Bm.respiratoryPhase = angle(hilbert(filteredResp));
        end
        
        %%% Event Related Potential (ERP) methods %%%
        
        function Bm = calculateERP( Bm, eventArray , pre, post, ...
                appendNaNs,erpType,verbose)
            % Calculates an event related potential (ERP) of the 
            % respiratory trace 'pre' and 'post' milliseconds before and 
            % after time indices in eventArray, excluding events where a 
            % full window could not be computed.
            % Events that were used are saved in bm.ERPtrialEvents and events
            % that could not be used are saved in bm.ERPrejectedEvents.
            
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
                erpType='normal';
            end
                
            if nargin<7
                verbose=0;
            end
            
            
            if strcmp(erpType,'normal')
                thisResp = Bm.whichResp( verbose);
            elseif strcmp(erpType,'phase')
                thisResp = Bm.respiratoryPhase;
                if verbose
                    disp('using respiratory phase');
                end
            end
                
            if verbose
                disp('to calculate ERP');
            end
            
            
            % convert pre and post from ms into samples
            toRealMs = Bm.srate / 1000;
            preSamples = round(pre * toRealMs);
            postSamples = round(post * toRealMs);

            [thisERPMatrix,theseTrialEvents,theseRejectedEvents,...
                theseTrialEventInds,theseRejectedEventInds] = ...
                createRespiratoryERPMatrix( thisResp, eventArray, ...
                preSamples, postSamples, appendNaNs, verbose );
            srateStep = 1000 / Bm.srate;
            
            % if sampling rate is a float, x axis can mismatch. Following
            % code resolves this but can be off by 1 sample.
            tempxAxis = -pre:srateStep:post+srateStep;

            if length(tempxAxis) > size(thisERPMatrix,2)
                Bm.ERPxAxis = tempxAxis(1:size(thisERPMatrix,2));
            elseif length(tempxAxis) < size(thisERPMatrix,2)
                thisERPMatrix = thisERPMatrix(:,1:length(tempxAxis));
                Bm.ERPxAxis = tempxAxis;
            end
            
            Bm.ERPMatrix = thisERPMatrix;
            Bm.ERPtrialEvents = theseTrialEvents;
            Bm.ERPrejectedEvents=theseRejectedEvents;
            Bm.ERPtrialEventInds = theseTrialEventInds;
            Bm.ERPrejectedEventInds=theseRejectedEventInds;
        end
        
        function Bm = calculateResampledERP(Bm, eventArray, prePct, ...
                postPct, resampleSize, appendNaNs, verbose, normalizeTo)
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
            
            
            if nargin < 8
                normalizeTo='IBI';
            end
            
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
            switch normalizeTo
                case 'IBI'
                    avgResp = Bm.secondaryFeatures(...
                        'Average Inter-Breath Interval');
                case 'Inhale'
                    avgResp = Bm.secondaryFeatures(...
                        'Average Inhale Duration');
                case 'Exhale'
                    avgResp = Bm.secondaryFeatures(...
                        'Average Exhale Duration');
            end
            
            rsPre=round(avgResp * Bm.srate * prePct);
            rsPost=round(avgResp * Bm.srate * postPct);
            
            thisResp = Bm.whichResp(verbose);
            
            if verbose
                disp('to calculate resampled ERP');
            end
            
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
            
            Bm.resampledERPMatrix = thisResampledERPMatrix;
            Bm.ERPtrialEvents = theseTrialEvents;
            Bm.ERPrejectedEvents=theseRejectedEvents;
            Bm.ERPtrialEventInds = theseTrialEventInds;
            Bm.ERPrejectedEventInds=theseRejectedEventInds;
            
            Bm.resampledERPxAxis = linspace(-prePct*100, ...
                postPct*100, resampleSize);
        end

        
        %%% Plotting methods %%%
        
        function fig = plotFeatures(Bm, annotate, sizeData)
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
            fig = plotRespiratoryFeatures(Bm, annotate, sizeData);
        end
        
        function fig = plotCompositions(Bm, plotType)
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
            
            if strcmp(Bm.dataType,'humanAirflow') || ...
                    strcmp(Bm.dataType,'rodentAirflow')
                if nargin < 2
                    disp(['No plot type entered. Use ''raw'', ' ...
                        '''normalized'', or ''line'' to specify.']);
                    disp('Proceeding using ''raw''');
                    plotType='raw';
                end

                fig = plotBreathCompositions(Bm, plotType);
            else
                disp(['This function depends on breath durations, ' ...
                'which is not supported at this time for rodent ' ...
                'thermocouple data.']);
            end
        end
        
        function fig = plotRespiratoryERP(Bm,simpleOrResampled)
            % Plots an erp of respiratory data that has been generated
            % using calculateERP or calculateResampledERP. One of these
            % functions must be run prior to calling this function.
            
            % simpleOrResampled : set to 'simple' to plot the precalculated 
            % standard ERP or set to 'resampled' to plot the precalculated
            % resampled ERP.
            
            if ischar(simpleOrResampled)
                if strcmp(simpleOrResampled,'simple')
                    thisERPMatrix = Bm.ERPMatrix;
                    xAxis = Bm.ERPxAxis;
                elseif strcmp(simpleOrResampled,'resampled')
                    thisERPMatrix = Bm.resampledERPMatrix;
                    xAxis = Bm.resampledERPxAxis;
                else
                    disp(['Method not recognized. Please set ' ...
                        'SimpleOrResampled to ''simple'' or ' ...
                        '''resampled.'''])
                end
            else
                disp(['ERP method not specified. Please set ' ...
                    'SimpleOrResampled to ''simple'' or ' ...
                    '''resampled.'' Proceeding using a standard ERP.' ])
                thisERPMatrix = Bm.ERPMatrix;
                xAxis = Bm.ERPxAxis;
                simpleOrResampled='simple';
            end
            
            fig = plotRespiratoryERP(thisERPMatrix, ...
                xAxis, simpleOrResampled);
        end
        
        % to launch the GUI use the following code:
        % newBM = bmGUI(bmObj)
        
    end
end
