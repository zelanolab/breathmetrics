function [fig] = plotRespiratoryFeatures( Bm, annotate, sizeData)
% Plots respiration as well as any respiratory features that have been
% estimated
% PARAMETERS:
% bm : BreathMetrics class object
% annotate : features to plot. Options are: 
% 'extrema', 'onsets','maxflow','volumes', and 'pauses'
% sizeData : size of feature labels. Helpful for visualizing 
% features in data of different window sizes.

if nargin < 3
    sizeData = 36;
end

paramsToPlot = {};
paramLabels = {};
i=1;

% plot all params that have been calculated
if ~isempty(Bm.inhalePeaks) 
    if strcmp(Bm.dataType,'humanAirflow') || strcmp(Bm.dataType,'rodentAirflow')
        paramsToPlot{i} = Bm.inhalePeaks;
        paramLabels{i} = 'Inhale Peaks';
        i=i+1;
    end
end

if ~isempty(Bm.exhaleTroughs)
    if strcmp(Bm.dataType,'humanAirflow') || strcmp(Bm.dataType,'rodentAirflow')
        paramsToPlot{i} = Bm.exhaleTroughs;
        paramLabels{i} = 'Exhale Troughs';
        i=i+1;
    end
end

if ~isempty(Bm.inhaleOnsets)
    paramsToPlot{i} = Bm.inhaleOnsets;
    paramLabels{i} = 'Inhale Onsets';
    i=i+1;
end

if ~isempty(Bm.exhaleOnsets)
    paramsToPlot{i} = Bm.exhaleOnsets;
    paramLabels{i} = 'Exhale Onsets';
    i=i+1;
end

if ~ isempty(Bm.inhalePauseOnsets)
    paramsToPlot{i} = Bm.inhalePauseOnsets(Bm.inhalePauseOnsets > 0);
    paramLabels{i} = 'Inhale Pauses';
    i=i+1;
end

if ~ isempty(Bm.exhalePauseOnsets)
    paramsToPlot{i} = Bm.exhalePauseOnsets(Bm.exhalePauseOnsets > 0);
    paramLabels{i} = 'Exhale Pauses';
end

if nargin < 2
    annotate=[];
end

respiratoryTrace = Bm.whichResp();
xAxis = Bm.time;

fig=figure; 
hold all;

title('Estimated Respiratory Features');
respiratoryHandle = plot(xAxis, respiratoryTrace,'k-');
allHandles = [respiratoryHandle];
legendText = {'Respiration'};

xlabel('Time (seconds)');

% different data types have different axes
if strcmp(Bm.dataType,'humanAirflow') || strcmp(Bm.dataType,'rodentAirflow')
    ylabel('Airflow (AU)');
elseif strcmp(Bm.dataType,'humanBB')
    ylabel('Breathing Belt (AU)');
elseif strcmp(Bm.dataType,'rodentThermocouple')
    ylabel('Thermocouple (AU)')
end
if ~isempty(paramsToPlot)
    MY_COLORS = parula(length(paramsToPlot));
    for paramInd=1:length(paramsToPlot)
        thisParam = paramsToPlot{paramInd};
        %exclude nans for points where pauses don't happen or volumes can't
        %be calculated
        realParams = thisParam(thisParam>0 & thisParam<length(xAxis)); 
        thisHandle = scatter(xAxis(realParams),respiratoryTrace(realParams),'MarkerEdgeColor',MY_COLORS(paramInd,:),'MarkerFaceColor',MY_COLORS(paramInd,:),'SizeData',sizeData);
        allHandles = [allHandles, thisHandle(1)];
        legendText{paramInd+1}=paramLabels{paramInd};

    end
end

legend(allHandles, legendText);

% placeholders for annotations
peakAnnotations = {};
troughAnnotations = {};
inhaleOnsetAnnotations = {};
exhaleOnsetAnnotations = {};
inhalePauseAnnotations = {};
exhalePauseAnnotations = {};

if ~isempty(annotate)
    % annotate information about peaks if they have been calculated
    if sum(strcmp(annotate, 'extrema')) > 0 || ...
            sum(strcmp(annotate,'volumes')) > 0 || ...
            sum(strcmp(annotate,'maxflow')) > 0
        if ~isempty(Bm.inhalePeaks) && ~isempty(Bm.exhaleTroughs)
            for i=1:length(Bm.inhalePeaks)
                peakAnnotations{i} = ...
                    sprintf('Peak at %.1f\n', Bm.time(Bm.inhalePeaks(i)));
            end
            for e=1:length(Bm.exhaleVolumes)
                troughAnnotations{e} = sprintf('Trough at %.1f\n', ...
                    Bm.time(Bm.exhaleTroughs(e)));
            end
        else
            disp('Breath extrema have not been calculated.')
        end
    end
    % annotate information about airflow if it have been calculated
    if sum(strcmp(annotate, 'maxflow')) > 0
        if strcmp(Bm.dataType,'humanAirflow') || strcmp(Bm.dataType,'rodentAirflow')
            if ~isempty(Bm.inhalePeaks) && ~isempty(Bm.exhaleTroughs)
                for i=1:length(Bm.inhalePeaks)
                    peakAnnotations{i} = sprintf('%s%s\n', ...
                        peakAnnotations{i}, sprintf(' Max Flow: %.2g', ...
                        Bm.peakInspiratoryFlows(i)));
                end
                for e=1:length(Bm.exhaleTroughs)
                    troughAnnotations{e} = sprintf('%s%s\n', ...
                        troughAnnotations{e}, sprintf(' Max Flow: %.2g', ...
                        Bm.troughExpiratoryFlows(e)));
                end
            else
                disp('Max flow at breath extrema have not been calculated.')
            end
        else
            disp(['Max flow cannot be calculated for human breathing' ...
                  'belt or rodent thermocouple data.']);
        end
    end

    % annotate information about breath volumes if they have been calculated
    if sum(strcmp(annotate,'volumes')) > 0
        if ~isempty(Bm.inhaleVolumes) && ~isempty(Bm.exhaleVolumes)
            for i=1:length(Bm.inhaleVolumes)
                peakAnnotations{i} = sprintf('%s%s', ...
                    peakAnnotations{i}, sprintf(' Volume: %.3g', ...
                    Bm.inhaleVolumes(i)));
            end
            for e=1:length(Bm.exhaleVolumes)
                troughAnnotations{e} = sprintf('%s%s', ...
                    troughAnnotations{e}, sprintf(' Volume: %.3g', ...
                    Bm.exhaleVolumes(e)));
            end
        else
            disp('Breath volumes have not been calculated.')
        end
    end
    
    if sum(strcmp(annotate, 'onsets')) > 0
        if ~isempty(Bm.inhaleOnsets) && ~isempty(Bm.exhaleOnsets)
            for i=1:length(Bm.inhaleOnsets)
                inhaleOnsetAnnotations{i} = sprintf('Inhale at %.1f', ...
                    Bm.time(Bm.inhaleOnsets(i)));
            end
            for e=1:length(Bm.exhaleOnsets)
                exhaleOnsetAnnotations{e} = sprintf('Exhale at %.1f', ...
                    Bm.time(Bm.exhaleOnsets(e)));
            end
        else
            disp('Breath onsets have not been calculated.')
        end
    end
    
    if sum(strcmp(annotate,'pauses')) > 0
        if ~isempty(Bm.inhalePauseOnsets) &&...
                ~isempty(Bm.exhalePauseOnsets)
            % remove nan's for breaths where there was no pause
            realInhalePauseOnsets = ...
                Bm.inhalePauseOnsets(Bm.inhalePauseOnsets>0);
            realExhalePauseOnsets = ...
                Bm.exhalePauseOnsets(Bm.exhalePauseOnsets>0);
            
            if ~isempty(realInhalePauseOnsets)
                for i=1:length(realInhalePauseOnsets)
                    inhalePauseAnnotations{i} = ...
                        sprintf('Inhale pause at %.1f', ...
                        Bm.time(realInhalePauseOnsets(i)));
                end
            else
                disp('No inhale pauses detected');
            end
            if ~isempty(realExhalePauseOnsets)
                for e=1:length(realExhalePauseOnsets)
                    exhalePauseAnnotations{e} = ...
                        sprintf('Exhale pause at %.1f', ...
                        Bm.time(realExhalePauseOnsets(e)));
                end
            else
                disp('No exhale pauses detected');
            end
        else
            disp('Respiratory pauses have not been calculated.')
        end
    end
end

% plot annotations
if ~isempty(peakAnnotations) && ~isempty(troughAnnotations)
    for i=1:length(Bm.inhalePeaks)
        text(xAxis(Bm.inhalePeaks(i)), ...
            respiratoryTrace(Bm.inhalePeaks(i)), peakAnnotations{i});
    end
    for e=1:length(Bm.exhaleTroughs)
        text(xAxis(Bm.exhaleTroughs(e)), ...
            respiratoryTrace(Bm.exhaleTroughs(e)), troughAnnotations{e});
    end
end

if ~isempty(inhaleOnsetAnnotations) && ~isempty(exhaleOnsetAnnotations)
    for i=1:length(Bm.inhaleOnsets)
        text(xAxis(Bm.inhaleOnsets(i)), ...
            respiratoryTrace(Bm.inhaleOnsets(i)), ...
            inhaleOnsetAnnotations{i});
    end
    for e=1:length(Bm.exhaleOnsets)
        text(xAxis(Bm.exhaleOnsets(e)), ...
            respiratoryTrace(Bm.exhaleOnsets(e)), ...
            exhaleOnsetAnnotations{e});
    end
end

if ~isempty(inhalePauseAnnotations)
    for i=1:length(realInhalePauseOnsets)
        text(xAxis(realInhalePauseOnsets(i)), ...
            respiratoryTrace(realInhalePauseOnsets(i)), ...
            inhalePauseAnnotations{i});
    end
end

if ~isempty(exhalePauseAnnotations)
    for e=1:length(realExhalePauseOnsets)
        text(xAxis(realExhalePauseOnsets(e)), ...
            respiratoryTrace(realExhalePauseOnsets(e)), ...
            exhalePauseAnnotations{e});
    end
end


