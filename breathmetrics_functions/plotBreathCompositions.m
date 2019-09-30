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
        thisInhaleDur = Bm.inhaleDurations(b);
        thisInhalePauseDur = Bm.inhalePauseDurations(b);
        if isnan(thisInhalePauseDur)
            thisInhalePauseDur=0;
        end
        thisExhaleDur = Bm.exhaleDurations(b);
        if isnan(thisExhaleDur)
            thisExhaleDur=0;
        end
        thisExhalePauseDur = Bm.exhalePauseDurations(b);
        if isnan(thisExhalePauseDur)
            thisExhalePauseDur=0;
        end
        
        totalPoints = sum([thisInhaleDur, ...
            thisInhalePauseDur, thisExhaleDur, ...
            thisExhalePauseDur]);
        
        normedInhaleDur = round((thisInhaleDur/totalPoints) ...
            * MATRIX_SIZE);
        normedInhalePauseDur = ...
            round((thisInhalePauseDur/totalPoints) * MATRIX_SIZE);
        normedExhaleDur = round((thisExhaleDur/totalPoints)*MATRIX_SIZE);
        normedExhalePauseDur = ...
            round((thisExhalePauseDur/totalPoints) * MATRIX_SIZE);
        
        sumCheck = sum([normedInhaleDur, ...
            normedInhalePauseDur, normedExhaleDur, ...
            normedExhalePauseDur]);
        
        % sometimes rounding is off by 1
        if sumCheck>MATRIX_SIZE
            normedExhaleDur=normedExhaleDur-1;
        elseif sumCheck<MATRIX_SIZE
            normedExhaleDur=normedExhaleDur+1;
        end

        thisBreathComposition(1,ind:normedInhaleDur)=1;
        ind=normedInhaleDur;
        if normedInhalePauseDur>0
            thisBreathComposition(1,ind+1:ind+normedInhalePauseDur)=2;
            ind=ind+normedInhalePauseDur;
        end
        
        thisBreathComposition(1,ind+1:ind+normedExhaleDur)=3;
        ind=ind+normedExhaleDur;
        if normedExhalePauseDur>0
            thisBreathComposition(1,ind+1:ind+normedExhalePauseDur)=4;
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
        thisInhaleDur = round((Bm.inhaleDurations(b)/ ...
            maxBreathSize) * MATRIX_SIZE);
        thisBreathComposition(1, 1:thisInhaleDur) = 0;
        ind = thisInhaleDur + 1;
        thisInhalePauseDur = round((Bm.inhalePauseDurations(b) / ...
            maxBreathSize) * MATRIX_SIZE);
        if isnan(thisInhalePauseDur)
            thisInhalePauseDur = 0;
        end
        thisBreathComposition(1,ind:ind + thisInhalePauseDur) = 1;
        ind = ind + thisInhalePauseDur;
        thisExhaleDur = round((Bm.exhaleDurations(b) / ...
            maxBreathSize) * MATRIX_SIZE);
        if isnan(thisExhaleDur)
            thisExhaleDur=0;
        end
        thisBreathComposition(1, ind:ind + thisExhaleDur) = 2;
        ind = ind + thisExhaleDur;
        thisExhalePauseDur = round((Bm.exhalePauseDurations(b) / ...
            maxBreathSize) * MATRIX_SIZE);
        if isnan(thisExhalePauseDur)
            thisExhalePauseDur=0;
        end
        thisBreathComposition(1, ind:ind + thisExhalePauseDur) = 3;
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
        thisInhaleDur = Bm.inhaleDurations(b);
        % there is always an inhale in a breath
        plotSet = [ind, thisInhaleDur];
        ind=ind+1;

        %there is sometimes an inhale pause
        thisInhalePauseDur = Bm.inhalePauseDurations(b);
        if ~isnan(thisInhalePauseDur)
            plotSet(ind,:) = [2, thisInhalePauseDur];
            ind=ind+1;
        end

        thisExhaleDur = Bm.exhaleDurations(b);
        plotSet(ind,:) = [3, thisExhaleDur];
        ind=ind+1;
        thisExhalePauseDur = Bm.exhalePauseDurations(b);
        if ~isnan(thisExhalePauseDur)
            plotSet(ind,:) = [4, thisExhalePauseDur];
        end
        plot(plotSet(:,1), plotSet(:,2), 'color', MY_COLORS(b,:));
        scatter(plotSet(:,1), plotSet(:,2), ...
                'Marker','s','MarkerFaceColor', MY_COLORS(b,:), ...
                'MarkerEdgeColor','none');
    end
    inhaleStd = std(Bm.inhaleDurations);
    inhalePauseStd = nanstd(Bm.inhaleDurations);
    exhaleStd = std(Bm.exhaleDurations);
    exhalePauseStd = nanstd(Bm.exhaleDurations);
    allMeans = [mean(Bm.inhaleDurations), ...
        nanmean(Bm.inhalePauseDurations), mean(Bm.exhaleDurations), ...
        nanmean(Bm.exhalePauseDurations)];
    allStds = [inhaleStd, inhalePauseStd, exhaleStd, exhalePauseStd];
    errorbar([1,2,3,4], allMeans, allStds, 'Color', 'k', ...
                                             'LineStyle', 'none', ...
                                             'LineWidth', 2);
    xlim([0,5]);
    xTickLabels = {'Inhale Durations'; 'Inhale Pause Durations'; ...
        'Exhale Durations'; 'Exhale Pause Durations'};
    set(gca,'XTick', [1,2,3,4], 'XTickLabel', xTickLabels);
    ylabel('Time (seconds)');
    allMaxes = [nanmax(Bm.inhaleDurations),nanmax(Bm.inhalePauseDurations),nanmax(Bm.exhaleDurations),nanmax(Bm.exhalePauseDurations)];
    
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
    
    nBins = floor(length(Bm.inhaleDurations)/5);
    if nBins < 5
        nBins=10;
    end
    % inhale lengths
    subplot(2,2,1)
    [inhaleCounts, inhaleBins] = hist(Bm.inhaleDurations, nBins);
    bar(inhaleBins, inhaleCounts, 'FaceColor', MY_COLORS(1,:),...
        'EdgeColor','none');
    xlabel('Inhale Durations (seconds)')
    
    % inhale pause lengths
    subplot(2,2,2)
    [inhalePauseCounts, inhalePauseBins] = hist(Bm.inhalePauseDurations,nBins);
    bar(inhalePauseBins, inhalePauseCounts, 'FaceColor', MY_COLORS(2,:));
    xlabel('Inhale Pause Durations (seconds)')
    
    % exhale lengths
    subplot(2,2,3)
    [exhaleCounts, exhaleBins] = hist(Bm.exhaleDurations,nBins);
    bar(exhaleBins, exhaleCounts, 'FaceColor', MY_COLORS(3,:));
    xlabel('Exhale Durations (seconds)')
    
    % exhale pause lengths
    subplot(2,2,4)
    [exhalePauseCounts, exhalePauseBins] = hist(Bm.exhalePauseDurations, nBins);
    bar(exhalePauseBins, exhalePauseCounts, 'FaceColor', MY_COLORS(4,:));
    xlabel('Exhale Pause Durations (seconds)')
    
else
    fig = nan;
    fprintf(['Input ''%s'' not recognized. Please use ''raw'', ' ...
        '''normalized'', ''line'', or ''hist''.\n'], plotType)
end
end