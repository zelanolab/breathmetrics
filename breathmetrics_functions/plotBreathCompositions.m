function [fig] = plotBreathCompositions(Bm, plotType)
% plots the compositions of all breaths in Bm object.

% PARAMETERS: 
% bm : BreathMetrics class object
% plotType : 'raw' : Images the composition of each breath,
%                    leaving extra space for all breaths 
%                    shorter than the longest in duration
%            'normalized' : Images the composition of each
%                           breath, normalized by its duration.
%            'line' : Plots each breath as a line where the x-
%                     value represents phase and the y-value
%                     represents duration of phase
%            'hist' : Constructs histograms for durations of each phase
%                     of every breath.

% returns the figure produced

    
MATRIX_SIZE = 1000;
breathPhaseLabels = {'Inhales'; 'Inhale Pauses'; ...
                     'Exhales'; 'Exhale Pauses'};
customColors = [0 0.4470 0.7410; 
                0.8500 0.3250 0.0980; 
                0.9290 0.6940 0.1250; 
                0.4940 0.1840 0.5560; 
                1 1 1];
            
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
    colormap(customColors(1:4,:));
    image(breathMatrix);
    %imagesc(breathMatrix)
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

    % custom figure legend
    h = zeros(4, 1);
    for i=1:4
        h(i) = plot(NaN,NaN,'color',customColors(i,:),'LineWidth',2);
    end
    legend(h,breathPhaseLabels)

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

    colormap(customColors);
    % uint8 is necessary because inhales are stored as 0's, unlike the 
    % normalized function, which confuses imaging with a colormap.
    image(uint8(breathMatrix)); 
    xlim([0.5,MATRIX_SIZE+0.5])
    ylim([0.5,nBreaths+0.5])
    TICK_STEP = .5;
    xTickLabels = 0:TICK_STEP:maxBreathSize;
    xTicks = round(linspace(1, MATRIX_SIZE, length(xTickLabels)));
    set(gca,'XTick',xTicks,'XTickLabel',xTickLabels)
    xlabel('Time (seconds)')
    ylabel('Breath Number');
    
    % custom figure legend
    h = zeros(4, 1);
    for i=1:4
        h(i) = plot(NaN,NaN,'color',customColors(i,:),'LineWidth',2);
    end
    legend(h,breathPhaseLabels)

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
        plot(plotSet(:,1), plotSet(:,2), 'color', MY_COLORS(b,:));
        scatter(plotSet(:,1), plotSet(:,2), ...
                'Marker','s','MarkerFaceColor', MY_COLORS(b,:), ...
                'MarkerEdgeColor','none');
    end
    inhaleStd = std(Bm.inhaleLengths);
    inhalePauseStd = nanstd(Bm.inhaleLengths);
    exhaleStd = std(Bm.exhaleLengths);
    exhalePauseStd = nanstd(Bm.exhaleLengths);
    allMeans = [mean(Bm.inhaleLengths), ...
        nanmean(Bm.inhalePauseLengths), mean(Bm.exhaleLengths), ...
        nanmean(Bm.exhalePauseLengths)];
    allStds = [inhaleStd, inhalePauseStd, exhaleStd, exhalePauseStd];
    errorbar([1,2,3,4], allMeans, allStds, 'Color', 'k', ...
                                             'LineStyle', 'none', ...
                                             'LineWidth', 2);
    xlim([0,5]);
    xTickLabels = {'Inhale Durations'; 'Inhale Pause Durations'; ...
        'Exhale Durations'; 'Exhale Pause Durations'};
    set(gca,'XTick', [1,2,3,4], 'XTickLabel', xTickLabels);
    ylabel('Time (seconds)');
    allMaxes = [nanmax(Bm.inhaleLengths),nanmax(Bm.inhalePauseLengths),nanmax(Bm.exhaleLengths),nanmax(Bm.exhalePauseLengths)];
    
    ylim([0,max(allMaxes)+0.5]);
    toplineBump=0.2;
    bottomlineBump=0.1;
    fsize=10;
    text(1, allMaxes(1)+toplineBump, sprintf('Mean = %.3g seconds',allMeans(1)),'HorizontalAlignment','center','FontSize',fsize);
    text(1, allMaxes(1)+bottomlineBump, sprintf('Std = %.3g seconds',allStds(1)),'HorizontalAlignment','center','FontSize',fsize);
    
    text(2, allMaxes(2)+toplineBump, sprintf('Mean = %.3g seconds',allMeans(2)),'HorizontalAlignment','center','FontSize',fsize);
    text(2, allMaxes(2)+bottomlineBump, sprintf('Std = %.3g seconds',allStds(2)),'HorizontalAlignment','center','FontSize',fsize);
    
    text(3, allMaxes(3)+toplineBump, sprintf('Mean = %.3g seconds',allMeans(3)),'HorizontalAlignment','center','FontSize',fsize);
    text(3, allMaxes(3)+bottomlineBump, sprintf('Std = %.3g seconds',allStds(3)),'HorizontalAlignment','center','FontSize',fsize);
    
    text(4, allMaxes(4)+toplineBump, sprintf('Mean = %.3g seconds',allMeans(4)),'HorizontalAlignment','center','FontSize',fsize);
    text(4, allMaxes(4)+bottomlineBump, sprintf('Std = %.3g seconds',allStds(4)),'HorizontalAlignment','center','FontSize',fsize);

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
    bar(inhaleBins, inhaleCounts, 'FaceColor', MY_COLORS(1,:),...
        'EdgeColor','none');
    xlabel('Inhale Durations (seconds)')
    
    % inhale pause lengths
    subplot(2,2,2)
    [inhalePauseCounts, inhalePauseBins] = hist(Bm.inhalePauseLengths,nBins);
    bar(inhalePauseBins, inhalePauseCounts, 'FaceColor', MY_COLORS(2,:));
    xlabel('Inhale Pause Durations (seconds)')
    
    % exhale lengths
    subplot(2,2,3)
    [exhaleCounts, exhaleBins] = hist(Bm.exhaleLengths,nBins);
    bar(exhaleBins, exhaleCounts, 'FaceColor', MY_COLORS(3,:));
    xlabel('Exhale Durations (seconds)')
    
    % exhale pause lengths
    subplot(2,2,4)
    [exhalePauseCounts, exhalePauseBins] = hist(Bm.exhalePauseLengths, nBins);
    bar(exhalePauseBins, exhalePauseCounts, 'FaceColor', MY_COLORS(4,:));
    xlabel('Exhale Pause Durations (seconds)')
    
else
    fig = nan;
    fprintf(['Input ''%s'' not recognized. Please use ''raw'', ' ...
        '''normalized'', ''line'', or ''hist''.\n'], plotType)
end
end