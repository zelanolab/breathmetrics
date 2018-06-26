classdef BreathMetricsGUI < handle
    %GUI for manual inspection of respiratory events estimated using
    %BreathMetrics.
    
    properties
        
        % figure properties
        fig
        ax1
        handles
        
        % breathmetrics object
        bm
        
        % breath phase onsets
        inhaleOnsets
        inhalePauseOnsets
        exhaleOnsets
        exhalePauseOnsets
        breathPhases={'Inhales';'Inhale Pauses';'Exhales';'Exhale Pauses'}
        
        % text describing phase
        thisPhase
        
        % ERP matrix of every breath for a given phase
        thisPhaseERP
        
        % index in ERP matrix to retrieve this breath
        thisERPInd
        
        % x axis for plot
        ERPtimeWindow
        
        % temporary variable for index of breath being analyzed
        thisPhaseInd
        
        % text for populating contents of breath indices listbox
        phaseIndString
        
        % indices of breaths where ERPs could be calculated
        validInds
        
        % time points of breaths where ERPs could be calculated
        validTimes
        
        % indices of breaths where ERPs could not be calculated
        invalidInds
        
        % 1 x n vector ERP of a breath
        thisBreath
        
        % windows for pre and post onset for plots
        tPre=5000;
        tPost=5000;
        
        % y label changes based on what kind of breathing signal is being
        % analyzed
        dataYLabel
        
    end
    
    methods
        
        function obj = BreathMetricsGUI(bm)
            % Constructor function.
            
            disp('Class initializing')
            
            if bm.checkFeatureEstimations == 0
                disp('All features have not been estimated yet.');
                disp('Estimating them now.');
                bm.estimateAllFeatures();
            end
            
            switch bm.dataType
                case 'humanAirflow' 
                    obj.dataYLabel = 'Airflow (AU)';
                case 'rodentAirflow'
                    obj.dataYLabel = 'Airflow (AU)';
                case 'humanBB'
                    obj.dataYLabel = 'Breathing Belt (AU)';
                case 'rodentThermocouple'
                    obj.dataYLabel = 'Thermocouple (AU)';
            end
            
            obj.inhaleOnsets=bm.inhaleOnsets;
            obj.inhalePauseOnsets=bm.inhalePauseOnsets;
            obj.exhaleOnsets=bm.exhaleOnsets;
            obj.exhalePauseOnsets=bm.exhalePauseOnsets;
            
            obj.bm = bm;
            obj.thisPhase='Inhale Onsets';
            
            obj.calculateERPforPhase(obj.thisPhase);
            obj.thisBreath = obj.thisPhaseERP(obj.thisERPInd,:);
                        
            obj.buildUI();
            
        end
        
        function buildUI(obj)
            % constructs the main figure using the GUI Layout Toolbox (uix)
            % (Sampson & Tordoff, Matlab File Exchange 2014)
            
            obj.fig = figure( ...
                'Name',         sprintf('BreathMetrics GUI'), ...
                'NumberTitle',  'off', ...
                'ToolBar',      'figure',...
                'Menubar',      'none');
            
            obj.handles.mainBox = uix.HBox('Parent', obj.fig);
            
            % left side of GUI where plotting happens
            obj.handles.leftBox = uix.VBox('Parent', obj.handles.mainBox);
            
            % HBox containing main breathing ERP figure
            obj.handles.plotBox = uix.HBox( ...
                'Parent', obj.handles.leftBox, ...
                'Padding', 10);
            
            % BoxPanel containing main breathing ERP figure
            obj.handles.plotPanel = uix.BoxPanel( ...
                'Parent',obj.handles.plotBox, ...
                'Title','Respiratory Feature Will Be Plot Here');
             
            
            % right side of GUI where data is selected
            obj.handles.rightBox = uix.VBox( ...
                'Parent', obj.handles.mainBox);
            
            % contains lists for phase and breath index selection
            obj.handles.listBox = uix.HBox( ...
                'Parent', obj.handles.rightBox, ...
                'Padding', 10);
            
            % VBox containing phase selection tool
            obj.handles.listBoxLeft = uix.VBox( ...
                'Parent', obj.handles.listBox);
            
            % BoxPanel containing phase selection tool
            obj.handles.listBoxLeftPanel = uix.BoxPanel( ...
                'Parent',obj.handles.listBoxLeft, ...
                'Title','Phase Selection');
            
            % VBox containing breath index selection tool
            obj.handles.listBoxRight = uix.VBox( ...
                'Parent', obj.handles.listBox);
            
            % BoxPanel containing breath index selection tool
            obj.handles.listBoxRightPanel = uix.BoxPanel( ...
                'Parent',obj.handles.listBoxRight, ...
                'Title','Breath Selection');
            
            % buttons to select size of pre and post windows
            obj.handles.windowSelectBox = uix.HBox( ...
                'Parent', obj.handles.rightBox, ...
                'Padding', 10);
            
            % VBox containing pre event window size
            obj.handles.windowSelectBoxLeft = uix.VBox( ...
                'Parent', obj.handles.windowSelectBox);
            
            % BoxPanel containing pre event window size
            obj.handles.windowSelectPanelLeft = uix.BoxPanel( ...
                'Parent',obj.handles.windowSelectBoxLeft, ...
                'Title','Window Size Pre (ms)');
            
            % VBox containing post event window size
            obj.handles.windowSelectBoxRight = uix.VBox( ...
                'Parent', obj.handles.windowSelectBox);
            
            % BoxPanel containing post event window size
            obj.handles.windowSelectPanelRight = uix.BoxPanel( ...
                'Parent',obj.handles.windowSelectBoxRight, ...
                'Title','Window Size Post (ms)');
            
            % Hbox containing update plot button
            obj.handles.buttonBox = uix.HBox( ...
                'Parent', obj.handles.rightBox, ...
                'Padding', 10);
            
            obj.handles.rightBox.Heights = [200, 100, 100];
            
            % fill in each sector of the grid
            ax = axes( 'Parent', obj.handles.plotPanel );
            obj.handles.ax1 = ax;
            
            % listbox of breath phases
            obj.handles.PhaseList = uicontrol( ...
                'Style','listbox',...
                'Parent', obj.handles.listBoxLeftPanel, ...
                'FontSize', 12,...
                'Value', 1, ...
                'String', obj.breathPhases, ...
                'Callback', @(a,b)obj.updatePhase());
            
            % listbox of breath indices
            obj.handles.indexList = uicontrol( ...
                'Style','listbox',...
                'Parent', obj.handles.listBoxRightPanel, ...
                'FontSize', 12,...
                'Value', 1, ...
                'String', uint8(obj.validInds), ...
                'Callback',@(a,b)obj.updatePhaseIndex());
            
            % text box for selecting size of pre window
            obj.handles.windowSelectLeft = uicontrol( ...
                'Style', 'edit', ...
                'Parent', obj.handles.windowSelectPanelLeft, ...
                'String', '5000', ...
                'Callback', @(a,b)obj.updateWinsizeLeft());
        
            % text box for selecting size of post window
            obj.handles.windowSelectRight = uicontrol( ...
                'Style', 'edit', ...
                'Parent', obj.handles.windowSelectPanelRight, ...
                'String', '5000', ...
                'Callback', @(a,b)obj.updateWinsizeRight());
        
            % button for updating the main breathing plot
            obj.handles.updatePlotButton = uicontrol( ...
                'Style', 'pushbutton', ...
                'Parent', obj.handles.buttonBox, ...
                'String', 'Update Plot', ...
                'Callback', @(a,b)obj.updatePlot());
        end
        
        function updateWinsizeLeft(obj)
            % callback function for pre phase onset window size selection.
            
            thisTextInput = obj.handles.windowSelectLeft.String;
            if all(isstrprop(thisTextInput,'digit'))
                thisNum=str2double(thisTextInput);
                if thisNum<0
                    thisNum=-thisNum;
                end
            else
                disp('Window Sizes must be numeric');
                thisNum=5000;
            end
            obj.tPre=thisNum;
            obj.calculateERPforPhase(obj.thisPhase);
        end
        
        function updateWinsizeRight(obj)
            % callback function for post phase onset window size selection.
            
            thisTextInput = obj.handles.windowSelectRight.String;
            if all(isstrprop(thisTextInput,'digit'))
                thisNum=str2double(thisTextInput);
                if thisNum<0
                    thisNum=-thisNum;
                end
            else
                disp('Window Sizes must be numeric');
                thisNum=5000;
            end
            obj.tPost=thisNum;
            obj.calculateERPforPhase(obj.thisPhase);
        end
        
        function updatePhase(obj)
            % callback function for phase selection listbox tool.
            
            phaseInd = obj.handles.PhaseList.Value;
            switch phaseInd
                case 1
                    thisPhaseTemp='Inhale Onsets';
                case 2
                    thisPhaseTemp='Inhale Pause Onsets';
                case 3
                    thisPhaseTemp='Exhale Onsets';
                case 4
                    thisPhaseTemp='Exhale Pause Onsets';
            end
            obj.thisPhase = thisPhaseTemp;
            obj.calculateERPforPhase(obj.thisPhase);
            obj.updatePhaseIndexList();
        end
        
        function updatePhaseIndexList(obj)
            % updates contents breath index selection listbox tool based on
            % what phase is selected.
            
            nEvents=length([obj.bm.trialEventInds, ...
                obj.bm.rejectedEventInds]);
            tempPhaseIndString=cell(1,nEvents);
            for iter=1:nEvents
                if ismember(iter,obj.validInds)
                    tempPhaseIndString{1,iter}=num2str(iter);
                else
                    tempPhaseIndString{1,iter}='no pause at this index';
                end
            end
            obj.phaseIndString=tempPhaseIndString;
            obj.handles.indexList.String=obj.phaseIndString;
            obj.handles.indexList.Value = 1;
            obj.indexERP();
        end
        
        
        function updatePhaseIndex(obj)
            % callback for phase index selection listbox.
            
            thisInd = obj.handles.indexList.Value;

            if ismember(thisInd,obj.validInds)
                obj.thisPhaseInd = obj.handles.indexList.Value;
            else
                obj.thisPhaseInd = [];
            end
            obj.indexERP();
        end
        
        function indexERP(obj)
            % finds the index in the ERP structure that matches the breath
            % selected with the breath index listbox.
            
            if ~isempty(obj.thisPhaseInd)
                tempERPInd = find(obj.thisPhaseInd==obj.validInds);
            else
                tempERPInd=[];
            end
            
            obj.thisERPInd=tempERPInd;
            
        end
        
        function calculateERPforPhase(obj,thisPhase)
            % calculates a 2 dimensional ERP matrix for every breath at a
            % given phase using BreathMetrics' calculateERP function. 
            % i.e. a 130 inhale x 5000 sample pre event + 5000 sample post
            % event matrix.
            
            switch thisPhase
                case 'Inhale Onsets'
                    theseEvents=obj.bm.inhaleOnsets;
                case 'Inhale Pause Onsets'
                    theseEvents=obj.bm.inhalePauseOnsets;
                case 'Exhale Onsets'
                    theseEvents=obj.bm.exhaleOnsets;
                case 'Exhale Pause Onsets'
                    theseEvents=obj.bm.exhalePauseOnsets;
            end
            
            obj.bm.calculateERP( theseEvents , obj.tPre, obj.tPost, 1, 0);
            obj.ERPtimeWindow = obj.bm.ERPxAxis;
            obj.thisPhaseERP = obj.bm.ERPMatrix;
            obj.validInds = uint8(obj.bm.trialEventInds);
            obj.validTimes = obj.bm.time(obj.bm.trialEvents);
            obj.invalidInds = uint8(obj.bm.rejectedEventInds);
            
            if ~isempty(obj.validInds)
                obj.thisPhaseInd = min(obj.validInds);
            else
                obj.thisPhaseInd=[];
            end
            
            obj.thisERPInd = 1;
            obj.updatePhaseIndexList();
            
        end
        
        function updatePlot(obj)
            % updates the plot based on input from other elements
            
            if ~isempty(obj.handles.ax1.Children)
                % erase old plot
                obj.handles.ax1.Children(1).Visible='off';
                if length(obj.handles.ax1.Children)>1
                    obj.handles.ax1.Children(2).Visible='off';
                end
            end
            
            if ~isempty(obj.thisPhaseInd) && ~isempty(obj.thisERPInd)
                % generate new plot if valid breath index is selected
                hold on
                xlabel(obj.handles.ax1,'Time (seconds)');
                xlim(obj.handles.ax1,[-obj.tPre,obj.tPost]);
                ylabel(obj.handles.ax1, obj.dataYLabel);
                obj.handles.thisBreath = ...
                    obj.thisPhaseERP(obj.thisERPInd,:);
                singlePhase=obj.thisPhase(1:end-1);
                
                plot(obj.handles.ax1,obj.ERPtimeWindow , ...
                    obj.handles.thisBreath,'Color','k','LineWidth',1);
                scatter(1,obj.handles.thisBreath(obj.tPre), ...
                    'bx','LineWidth',2);
                
                mytitle=sprintf('%s for Breath #%i at %.4g (seconds)', ...
                    singlePhase, obj.thisPhaseInd, ...
                    obj.validTimes(obj.thisERPInd));
                obj.handles.plotPanel.Title=mytitle;

                hold off
                
            else
                thisErrorMsg = ['The waveform for this index could not' ...
                    ' be calculated either because it does not exist ' ...
                    '(i.e. there was no inhale pause at inhale N) or '...
                    'it is on the edge of the recording and outside '... 
                    'the boundaries of the window.)'];
                sprintf('%s',thisErrorMsg)

            end
        end
    end
end