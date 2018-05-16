function [fig] = plotBreathCompositions(Bm, plotType)
% plots the compositions of all breaths in Bm object.

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

% returns the figure produced

    
MATRIX_SIZE = 1000;
nBreaths = length(Bm.inhaleOnsets);

if strcmp(plotType, 'normalized')
    fig = figure; hold all;
    
    breathMatrix = zeros(nBreaths, MATRIX_SIZE);

    for b = 1:nBreaths
        ind = 1;
        thisBreathComposition = zeros(1,MATRIX_SIZE);
        thisInhaleLength = Bm.inhaleLengths(b);
        thisInhalePauseLength = Bm.inhalePauseLengths(b);
        if isnan(thisInhalePauseLength)
            thisInhalePauseLength=0;
        end
        thisExhaleLength = Bm.exhaleLengths(b);
        if isnan(thisExhaleLength)
            thisExhaleLength=0;
        end
        thisExhalePauseLength = Bm.exhalePauseLengths(b);
        if isnan(thisExhalePauseLength)
            thisExhalePauseLength=0;
        end
        totalPoints = sum([thisInhaleLength, ... 
            thisInhalePauseLength, thisExhaleLength, ...
            thisExhalePauseLength]);
        normedInhaleLength = round((thisInhaleLength/totalPoints) ...
            * MATRIX_SIZE);
        normedInhalePauseLength = ...
            round((thisInhalePauseLength/totalPoints) * MATRIX_SIZE);
        normedExhaleLength = round((thisExhaleLength/totalPoints)*MATRIX_SIZE);
        normedExhalePauseLength = ...
            round((thisExhalePauseLength/totalPoints) * MATRIX_SIZE);
        sumCheck = sum([normedInhaleLength, ...
            normedInhalePauseLength, normedExhaleLength, ...
            normedExhalePauseLength]);
        % sometimes rounding is off by 1
        if sumCheck>MATRIX_SIZE
            normedExhaleLength=normedExhaleLength-1;
        elseif sumCheck<MATRIX_SIZE
            normedExhaleLength=normedExhaleLength+1;
        end

        thisBreathComposition(1,ind:normedInhaleLength)=1;
        ind=normedInhaleLength;
        if normedInhalePauseLength>0
            thisBreathComposition(1,ind+1:ind+normedInhalePauseLength)=2;
            ind=ind+normedInhalePauseLength;
        end
        
        thisBreathComposition(1,ind+1:ind+normedExhaleLength)=3;
        ind=ind+normedExhaleLength;
        if normedExhalePauseLength>0
            thisBreathComposition(1,ind+1:ind+normedExhalePauseLength)=4;
        end
        breathMatrix(b,:)=thisBreathComposition;
    end

    % image
    imagesc(breathMatrix)
    xlim([0.5,MATRIX_SIZE + 0.5])

    % normalizing x ticks
    xTicks = linspace(1, MATRIX_SIZE, 11);
    xTickLabels = {};
    for i=1:length(xTicks)
        X_PCT = xTicks(i)/MATRIX_SIZE;
        xTickLabels{i} = sprintf('%i%%',round(X_PCT*100));
    end

    set(gca,'XTick', xTicks,'XTickLabel', xTickLabels);
    ylim([0.5, nBreaths + 0.5])
    xlabel('Proportion of Breathing Period')
    ylabel('Breath Number')

    % colorbar
    cb = colorbar('Location','NorthOutside'); 
    caxis([1,4]) 
    xTickLabels = {'Inhales'; 'Inhale Pauses'; 'Exhales'; 'Exhale Pauses'};
    set(cb, 'XTick', [1,2,3,4], 'XTickLabel', xTickLabels)

elseif strcmp(plotType,'raw')
    % plots length of each component of each breath
    
    fig = figure; hold all;
    
    MATRIX_SIZE = 1000;
    maxBreathSize = ceil(max(diff(Bm.inhaleOnsets))/Bm.srate);
    breathMatrix = zeros(nBreaths, MATRIX_SIZE);
    for b=1:nBreaths
        thisBreathComposition = ones(1,MATRIX_SIZE)*4;
        %this_breath_comp(:)=nan;
        thisInhaleLength = round((Bm.inhaleLengths(b)/ ...
            maxBreathSize) * MATRIX_SIZE);
        thisBreathComposition(1, 1:thisInhaleLength) = 0;
        ind = thisInhaleLength + 1;
        thisInhalePauseLength = round((Bm.inhalePauseLengths(b) / ...
            maxBreathSize) * MATRIX_SIZE);
        if isnan(thisInhalePauseLength)
            thisInhalePauseLength = 0;
        end
        thisBreathComposition(1,ind:ind + thisInhalePauseLength) = 1;
        ind = ind + thisInhalePauseLength;
        thisExhaleLength = round((Bm.exhaleLengths(b) / ...
            maxBreathSize) * MATRIX_SIZE);
        if isnan(thisExhaleLength)
            thisExhaleLength=0;
        end
        thisBreathComposition(1, ind:ind + thisExhaleLength) = 2;
        ind = ind + thisExhaleLength;
        thisExhalePauseLength = round((Bm.exhalePauseLengths(b) / ...
            maxBreathSize) * MATRIX_SIZE);
        if isnan(thisExhalePauseLength)
            thisExhalePauseLength=0;
        end
        thisBreathComposition(1, ind:ind + thisExhalePauseLength) = 3;
        if length(thisBreathComposition)>MATRIX_SIZE
            thisBreathComposition = ...
                thisBreathComposition(1, 1:MATRIX_SIZE);
        end
        breathMatrix(b,:) = thisBreathComposition;
    end

    % image
    imagesc(breathMatrix)
    xlim([0.5,MATRIX_SIZE+0.5])
    ylim([0.5,nBreaths+0.5])
    TICK_STEP = .5;
    xTickLabels = 0:TICK_STEP:maxBreathSize;
    xTicks = round(linspace(1, MATRIX_SIZE, length(xTickLabels)));
    set(gca,'XTick',xTicks,'XTickLabel',xTickLabels)
    xlabel('Time (sec)')
    ylabel('Breath Number')

    % colorbar
    cb = colorbar('Location','NorthOutside'); 
    caxis([0,4])
    xTickLabels = {'Inhales'; 'Inhale Pauses'; 'Exhales'; ...
        'Exhale Pauses'; 'Empty Space'};
    set(cb, 'XTick', [0,1,2,3,4], 'XTickLabel', xTickLabels)

elseif strcmp(plotType,'line')
    % plots each breath as a function of how much time is spent in each
    % phase
    
    fig = figure; hold all;
    
    MY_COLORS = parula(nBreaths);
    for b=1:nBreaths
        ind=1;
        thisInhaleLength = Bm.inhaleLengths(b);
        % there is always an inhale in a breath
        plotSet = [ind, thisInhaleLength];
        ind=ind+1;

        %there is sometimes an inhale pause
        thisInhalePauseLength = Bm.inhalePauseLengths(b);
        if ~isnan(thisInhalePauseLength)
            plotSet(ind,:) = [2, thisInhalePauseLength];
            ind=ind+1;
        end

        thisExhaleLength = Bm.exhaleLengths(b);
        plotSet(ind,:) = [3, thisExhaleLength];
        ind=ind+1;
        thisExhalePauseLength = Bm.exhalePauseLengths(b);
        if ~isnan(thisExhalePauseLength)
            plotSet(ind,:) = [4, thisExhalePauseLength];
        end
        plot(plotSet(:,1), plotSet(:,2), 'color', MY_COLORS(b,:))
    end
    inhaleSem = std(Bm.inhaleLengths)/sqrt(length(Bm.inhaleLengths));
    inhalePauseSem = nanstd(Bm.inhaleLengths) / ...
        sqrt(sum(~isnan(Bm.inhalePauseLengths)));
    exhaleSem = std(Bm.exhaleLengths) / sqrt(length(Bm.exhaleLengths));
    exhalePauseSem = nanstd(Bm.exhaleLengths) ...
        / sqrt(sum(~isnan(Bm.exhalePauseLengths)));
    allMeans = [mean(Bm.inhaleLengths), ...
        nanmean(Bm.inhalePauseLengths), mean(Bm.exhaleLengths), ...
        nanmean(Bm.exhalePauseLengths)];
    allSems = [inhaleSem, inhalePauseSem, exhaleSem, exhalePauseSem];
    errorbar([1,2,3,4], allMeans, allSems, 'Color', 'k', ...
                                             'LineStyle', 'none', ...
                                             'LineWidth', 3);
    xlim([0.5,4.5]);
    xTickLabels = {'Inhale Lengths'; 'Inhale Pause Lengths'; ...
        'Exhale Lengths'; 'Exhale Pause Lengths'};
    set(gca,'XTick', [1,2,3,4], 'XTickLabel', xTickLabels)

elseif strcmp(plotType, 'hist')
    % plots histogram of each breath component
    
    fig = figure; hold all;
    MY_COLORS = parula(4);
    
    nBins = floor(length(Bm.inhaleLengths)/5);
    if nBins < 5
        nBins=10;
    end
    % inhale lengths
    subplot(2,2,1)
    [inhaleCounts, inhaleBins] = hist(Bm.inhaleLengths, nBins);
    bar(inhaleBins, inhaleCounts, 'FaceColor', MY_COLORS(1,:));
    xlabel('Inhale Lengths (s)')
    
    % inhale pause lengths
    subplot(2,2,2)
    [inhalePauseCounts, inhalePauseBins] = hist(Bm.inhalePauseLengths,nBins);
    bar(inhalePauseBins, inhalePauseCounts, 'FaceColor', MY_COLORS(2,:));
    xlabel('Inhale Pause Lengths (s)')
    
    % exhale lengths
    subplot(2,2,3)
    [exhaleCounts, exhaleBins] = hist(Bm.exhaleLengths,nBins);
    bar(exhaleBins, exhaleCounts, 'FaceColor', MY_COLORS(3,:));
    xlabel('Exhale Lengths (s)')
    
    % exhale pause lengths
    subplot(2,2,4)
    [exhalePauseCounts, exhalePauseBins] = hist(Bm.exhalePauseLengths, nBins);
    bar(exhalePauseBins, exhalePauseCounts, 'FaceColor', MY_COLORS(4,:));
    xlabel('Exhale Pause Lengths (s)')
    
else
    fig = nan;
    fprintf(['Input ''%s'' not recognized. Please use ''raw'', ' ...
        '''normalized'', ''line'', or ''hist''.\n'], plotType)
end
end