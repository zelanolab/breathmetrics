function newBM = bmGui(bmObj)

% initialize static parameters
S.myColors=parula(4);
S.breathSelectMenuColNames={'Breath No.';'Onset';'Offset';'Status';'Note'};
S.breathEditMenuColNames={'Inhale';'Inhale Pause';'Exhale';'Exhale Pause'};

% figure params
myPadding=10;

figureWindowWidth=1250;
figureWindowHeight=600;

figureXInit=0;
figureYInit=figureWindowHeight+100;

figureWindowInds=[figureXInit,figureYInit,figureWindowWidth,figureWindowHeight];

buttonSize=[125,25];
biggerButtonSize=[180,40];
smallerButtonSize=[100,25];

%%% INITIALIZE LOCATIONS OF FIGURE ELEMENTS %%%

%%% LEFT SIDE %%%

% text above table to select breath
breathSelectMenuTitleTextBottom=figureWindowHeight-biggerButtonSize(2)-myPadding;
breathSelectMenuTitleTextWidth=350;

breathSelectMenuX=myPadding*2;

breathSelectTitleTextInds = [...
    breathSelectMenuX,...
    breathSelectMenuTitleTextBottom,...
    breathSelectMenuTitleTextWidth,...
    biggerButtonSize(2)];

% table to select breath

breathSelectMenuWidth=breathSelectMenuTitleTextWidth;
breathSelectMenuRight=breathSelectMenuX+breathSelectMenuWidth;

breathSelectMenuHeight=breathSelectMenuTitleTextBottom-myPadding*4;
breathSelectMenuBottom=breathSelectMenuTitleTextBottom-breathSelectMenuHeight-myPadding;

breathSelectMenuInds = [...
    breathSelectMenuX,...
    breathSelectMenuBottom,...
    breathSelectMenuWidth,...
    breathSelectMenuHeight];

%%% buttons on left side %%%

% previous breath and next breath buttons

prevBreathButtonX=breathSelectMenuRight+myPadding;
nextBreathButtonX=prevBreathButtonX+smallerButtonSize(1)+myPadding;
breathNavButtonBottom=breathSelectMenuTitleTextBottom-smallerButtonSize(2)-myPadding;

prevBreathButtonInds=[...
    prevBreathButtonX,...
    breathNavButtonBottom,...
    smallerButtonSize(1),...
    smallerButtonSize(2)]; 

nextBreathButtonInds=[...
    nextBreathButtonX,...
    breathNavButtonBottom,...
    smallerButtonSize(1),...
    smallerButtonSize(2)]; 

leftSideButtonSpacing=-myPadding-biggerButtonSize(2);

% button to add note to selected breath
noteButtonX=breathSelectMenuRight+myPadding;
noteButtonBottom=breathNavButtonBottom+leftSideButtonSpacing;

noteButtonInds=[...
    noteButtonX,...
    noteButtonBottom,...
    biggerButtonSize(1),...
    biggerButtonSize(2)]; 


% button to reject breath
rejectButtonBottom=noteButtonBottom+leftSideButtonSpacing;

rejectButtonInds=[...
    noteButtonX,...
    rejectButtonBottom,...
    biggerButtonSize(1),...
    biggerButtonSize(2)];

% button to revert breath to orignal
revertBreathButtonBottom=rejectButtonBottom+leftSideButtonSpacing;

revertBreathButtonInds=[...
    noteButtonX,...
    revertBreathButtonBottom,...
    biggerButtonSize(1),...
    biggerButtonSize(2)];

% button to save all changes
saveAllChangesButtonBottom=myPadding*3;

saveAllChangesButtonInds=[...
    noteButtonX,...
    saveAllChangesButtonBottom,...
    biggerButtonSize(1),...
    biggerButtonSize(2)];

%%% RIGHT SIDE %%%

% plotting axis

plottingAxisWidth=600;
plottingAxisHeight=300;

% text above axis
axisTextBottom=breathSelectMenuTitleTextBottom;

plottingAxisNudge=50;
plottingAxisX=noteButtonX+biggerButtonSize(1)+myPadding+plottingAxisNudge;
plottingAxisBottom=axisTextBottom-myPadding*2 - plottingAxisHeight;

axisTextInds = [...
    plottingAxisX,...
    axisTextBottom,...
    plottingAxisWidth,...
    biggerButtonSize(2)];


axisWindowInds=[...
    plottingAxisX,...
    plottingAxisBottom,...
    plottingAxisWidth,...
    plottingAxisHeight
    ];

% editable text boxes that show params of breaths
% also buttons to initialize new instances of pauses

breathEditTextBoxHeight=50;
breathEditTextBoxTitleHeight=25;

breathEditTextBoxWidth=100;

onsetEditTextBoxTitleBottom=plottingAxisBottom-breathEditTextBoxHeight-myPadding-10;
onsetEditTextBoxBottom=onsetEditTextBoxTitleBottom-breathEditTextBoxHeight;
pauseInitButtonBottom=onsetEditTextBoxBottom-buttonSize(2)-myPadding;
pauseRemoveButtonBottom=pauseInitButtonBottom-buttonSize(2);

% create buttons
xIter=plottingAxisX+myPadding;

onsetEditTextBoxTitleInds=zeros(4,4);
onsetEditTextBoxInds=zeros(4,4);
pauseInitButtonInds=zeros(4,4);
pauseRemoveButtonInds=zeros(4,4);

% make special padding so they look nice
phasePadding=(plottingAxisWidth-4*breathEditTextBoxWidth)/3 - myPadding*2;

for i=1:4
    thisEditBoxInds=[xIter,...
        onsetEditTextBoxBottom,...
        breathEditTextBoxWidth,...
        breathEditTextBoxHeight];
    onsetEditTextBoxInds(i,:)=thisEditBoxInds;
    
    thisEditBoxTitleInds=[xIter,...
        onsetEditTextBoxTitleBottom,...
        breathEditTextBoxWidth,...
        breathEditTextBoxTitleHeight];
    onsetEditTextBoxTitleInds(i,:)=thisEditBoxTitleInds;
    
    thisPauseInitButtonInds=[xIter,...
        pauseInitButtonBottom,...
        breathEditTextBoxWidth,...
        buttonSize(2)];
    pauseInitButtonInds(i,:)=thisPauseInitButtonInds;
    
    thisPauseRemoveButtonInds=[xIter,...
        pauseRemoveButtonBottom,...
        breathEditTextBoxWidth,...
        buttonSize(2)];
    pauseRemoveButtonInds(i,:)=thisPauseRemoveButtonInds;
    
    xIter=xIter+phasePadding+breathEditTextBoxWidth;
end


% button to update changes from text
updateTextButtonXInd=plottingAxisX;
updateTextButtonYInd=pauseRemoveButtonBottom-myPadding/2-biggerButtonSize(2);

updateTextButtonInds=[updateTextButtonXInd,...
        updateTextButtonYInd,...
        biggerButtonSize(1),...
        biggerButtonSize(2)];
    
    
% button to update changes from draggable points
updateDPButtonXInd=updateTextButtonXInd+biggerButtonSize(1)+myPadding;

updateDPButtonInds=[updateDPButtonXInd,...
        updateTextButtonYInd,...
        biggerButtonSize(1),...
        biggerButtonSize(2)];
    
% button to save changes
saveThisChangeButtonXInd=updateDPButtonXInd+biggerButtonSize(1)+myPadding;
saveThisChangeButtonWidth=200;
saveThisChangeButtonInds=[saveThisChangeButtonXInd,...
        updateTextButtonYInd,...
        saveThisChangeButtonWidth,...
        biggerButtonSize(2)];

S.xLims=[-3,3];
S.yLims=[-1,1];


%%% initialize figure %%%

S.fh = figure(...
    'position',figureWindowInds,...
    'menubar','none',...
    'name','BreathMetrics GUI',...
    'numbertitle','off',...
    'resize','off');
setappdata(S.fh, 'Tag', 'running');

% most data is stored in S.fh.UserData
% initialize it here

% breath edit menu
UserData.breathEditMat=[bmObj.inhaleOnsets;bmObj.inhalePauseOnsets;bmObj.exhaleOnsets;bmObj.exhalePauseOnsets]'/bmObj.srate;

% breath number and n breaths
UserData.thisBreath=1;

nBreaths=length(bmObj.inhaleOnsets);
UserData.nBreaths=nBreaths;

% organize bm params 
% breathmetrics object
UserData.bmObj=bmObj;

% params for breath select menu

breathInds=(1:nBreaths)';
BMinhaleOnsets=(bmObj.inhaleOnsets/bmObj.srate)';
BMexhaleOnsets=(bmObj.exhaleOffsets/bmObj.srate)';

% keyboard
breathSelectMat=num2cell([breathInds,BMinhaleOnsets,BMexhaleOnsets]);

% statuses ('valid','edited','rejected')
if isempty(bmObj.statuses)
    breathStatuses=cell(nBreaths,1);
    breathStatuses(:)={'valid'};
    breathSelectMat(:,4)=breathStatuses;
else
    breathSelectMat(:,4)=bmObj.statuses;
end

if isempty(bmObj.notes)
    % make empty array for notes
    breathNotes=cell(nBreaths,1);
    breathSelectMat(:,5)=breathNotes;
else
    breathSelectMat(:,5)=bmObj.notes;
end
UserData.breathSelectMat=breathSelectMat;

% storage for temporary changes to breaths
UserData.tempPhaseOnsetChanges=UserData.breathEditMat(1,:);

% save original data in case user want to revert back
UserData.initialBreathEditMat=UserData.breathEditMat;

% changes when user wants to save
UserData.Tag=[];

% output variable
UserData.newBM=[];

% save bm params into fh.UserData
set(S.fh, 'UserData', UserData);


%%% populate figure with elements %%%

%%% left side %%%


% title above breath select menu
S.breathSelectTitleText = uicontrol(...
    'style','text',...
    'unit','pix',...
    'position',breathSelectTitleTextInds,...
    'string','Select A Breath',...
    'fontsize',16);
    
% breath selection table
S.uit = uitable(...
    'Position',breathSelectMenuInds,...
    'ColumnName',S.breathSelectMenuColNames,...
    'Data',S.fh.UserData.breathSelectMat);

S.prevBreathButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',prevBreathButtonInds,...
    'fontsize',10,...
    'string','Previous Breath');

S.nextBreathButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',nextBreathButtonInds,...
    'fontsize',10,...
    'string','Next Breath');

S.noteButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',noteButtonInds,...
    'fontsize',14,...
    'string','Add Note To This Breath');

% button to reject selected breath from analysis
S.rejectButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',rejectButtonInds,...
    'fontsize',14,...
    'string','Reject This Breath');

% button to reject selected breath from analysis
S.revertChangesButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',revertBreathButtonInds,...
    'fontsize',12,...
    'string','Revert Changes To This Breath');

% button to reject selected breath from analysis
S.saveChangesButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',saveAllChangesButtonInds,...
    'fontsize',14,...
    'string','SAVE ALL CHANGES');


%%% right side %%%

% title above breath select menu
S.axisText = uicontrol(...
    'style','text',...
    'unit','pix',...
    'position',axisTextInds,...
    'string','Plot and Edit This Breath',...
    'fontsize',16);

% plotting window
S.ax = axes(...
    'units','pixels',...
    'position',axisWindowInds,...
    'Xlim',S.yLims,...
    'YLim',S.xLims);

% for zooming
set(S.ax.Toolbar,'Visible','on');

% text boxes to display and edit phase onsets
for i=1:4
    
    % title field
    S.phaseEditTexts(i) = uicontrol(...
        'style','text',...
        'unit','pix',...
        'position',onsetEditTextBoxTitleInds(i,:),...
        'string',S.breathEditMenuColNames{i},...
        'backgroundcolor',S.myColors(i,:),...
        'fontsize',12);
    
    % editable box field
    S.phaseEditors(i) = uicontrol(...
        'style','edit',...
        'units','pix',...
        'min',0,'max',1,... % for editing (?)
        'position',onsetEditTextBoxInds(i,:),...
        'backgroundcolor','w',...
        'HorizontalAlign','center',...
        'fontsize',16);
end

for i=1:4
    if ismember(i,[2,4])
        % buttons to create new pauses
        S.pauseInits(i) = uicontrol(...
        'style','push',...
        'units','pixels',...
        'position',pauseInitButtonInds(i,:),...
        'fontsize',14,...
        'string','Create');
            
        % buttons to remove pauses
        S.pauseRemoves(i) = uicontrol(...
        'style','push',...
        'units','pixels',...
        'position',pauseRemoveButtonInds(i,:),...
        'fontsize',14,...
        'string','Remove');
    end
end


% button to update plot from text
S.updatePlotFromTextButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',updateTextButtonInds,...
    'fontsize',14,...
    'string','Update Plot From Text');
  
% button to update plot from draggable points
S.updatePlotFromPointButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',updateDPButtonInds,...
    'fontsize',14,...
    'string','Update Plot From Points');

% button to save changes made by text or point
S.saveThisChangeButton = uicontrol(...
    'style','push',...
    'units','pixels',...
    'position',saveThisChangeButtonInds,...
    'fontsize',14,...
    'string','Save Changes To This Breath');


% set call functions to include structure with all elements

%%% left side %%%
set(S.uit,'CellSelectionCallback',{@uitable_CellSelectionCallback,S})

set(S.prevBreathButton,'call',{@prevBreathCallback,S});
set(S.nextBreathButton,'call',{@nextBreathCallback,S});

set(S.noteButton,'call',{@noteCallback,S});
set(S.rejectButton,'call',{@rejectBreathCallback,S});
set(S.revertChangesButton,'call',{@revertChangesCallback,S});

set(S.saveChangesButton,'call',{@saveAllChangesCallback,S});

%%% right side %%%
set(S.updatePlotFromTextButton,'call',{@updatePlotFromTextCallback,S});
set(S.updatePlotFromPointButton,'call',{@updatePlotFromPointCallback,S});
set(S.saveThisChangeButton,'call',{@saveTempChangesCallback,S});

for i=1:4
    if ismember(i,[2,4])
        
        set(S.pauseInits(i),'call',{...
            @createNewPauseFromButtonCallback,...
            S,...
            S.breathEditMenuColNames{i}});
        set(S.pauseRemoves(i),'call',{...
            @removePauseFromButtonCallback,...
            S,...
            S.breathEditMenuColNames{i}});
    end
end

% plot first breath when this initializes
plotMeCallback({},{},S,0);

% save function changes tag of button to 'done'
waitfor(S.saveChangesButton,'Tag');

newBM=S.fh.UserData.newBM;

newBM.manualAdjustPostProcess();

close(S.fh);

end % main function

%%
%%% CALLBACK FUNCTIONS %%%

%%% left side %%%

% select cell on table and remember breath number
function uitable_CellSelectionCallback(varargin)

% save the selected breath in UserData when you click a row in the table
eventdata=varargin{2};
S=varargin{3};

% sometimes this is called and event data is empty
if size(eventdata.Indices,1)>0
    
    selectedRow = eventdata.Indices(1);
    UserData=S.fh.UserData;
    UserData.thisBreath=selectedRow;
    
    % overwrite changes to last breath with this breath's params
    UserData.tempPhaseOnsetChanges=UserData.breathEditMat(UserData.thisBreath,:);
    set( S.fh, 'UserData', UserData);
    
    % plot this breath when you click on it
    plotMeCallback({},{},S,0);
end

end

% go to breath before this one
function [] = prevBreathCallback(varargin)

S = varargin{3};  % Get the structure.

UserData=S.fh.UserData;
thisBreath=UserData.thisBreath;

if thisBreath == 1
    goToBreath=1;
else
    goToBreath=thisBreath-1;
end

UserData.thisBreath=goToBreath;
set( S.fh, 'UserData', UserData);
plotMeCallback({},{},S,0);

end

% go to next breath
function [] = nextBreathCallback(varargin)

S = varargin{3};  % Get the structure.

UserData=S.fh.UserData;
thisBreath=UserData.thisBreath;

if thisBreath == UserData.nBreaths
    goToBreath=UserData.nBreaths;
else
    goToBreath=thisBreath+1;
end

UserData.thisBreath=goToBreath;
set( S.fh, 'UserData', UserData);
plotMeCallback({},{},S,0);

end

% function to plot selected breath
function [] = plotMeCallback(varargin)
% Callback for pushbutton
S = varargin{3};  % Get the structure.
bmObj = S.fh.UserData.bmObj; % get bm

if nargin<4
    isUpdatePlot=0;
else
    isUpdatePlot=1;
end

if nargin>3
    if iscell(varargin(4))
        if varargin{4}==0
            isUpdatePlot=0;
        end
    end
end

% get range of onset and offset of this breath
io=S.fh.UserData.breathSelectMat{S.fh.UserData.thisBreath,2};
eo=S.fh.UserData.breathSelectMat{S.fh.UserData.thisBreath,3};
breathStatus=S.fh.UserData.breathSelectMat{S.fh.UserData.thisBreath,4};

lineType='k-';
breathInfo='';

switch breathStatus
    case 'valid'
        lineType='k-';
        breathInfo=breathStatus;
    case 'edited'
        lineType='g-';
        breathInfo=breathStatus;
    case 'rejected'
        lineType='r-';
        breathInfo=breathStatus;
end

if isnan(eo)
    ibi=bmObj.secondaryFeatures('Average Inter-Breath Interval');
    eo=io+ibi;
end
    
% plot breathing centered on selected breath
thisMidpoint=mean([io,eo]);

if ~isnan(thisMidpoint)
    nSamplesInRecording=length(bmObj.baselineCorrectedRespiration);
    plottingWindowLims=[...
        (S.xLims(1)*bmObj.srate+(io*bmObj.srate)),...
        (S.xLims(2)*bmObj.srate+(eo*bmObj.srate))];
    
    % make sure plotting window doesn't extend beyond boundaries of 
    % data
    if plottingWindowLims(1)<1
        plottingWindowLims(1)=1;
    end
    
    if plottingWindowLims(2)>nSamplesInRecording-1
        plottingWindowLims(2)=nSamplesInRecording;
    end
    plottingWindowInds=plottingWindowLims(1):plottingWindowLims(2);
    
    timeThisWindow=bmObj.time(plottingWindowInds);
    respThisWindow=bmObj.baselineCorrectedRespiration(plottingWindowInds);
    
    newXLims=[min(timeThisWindow),max(timeThisWindow)];
    
    hold(S.ax,'off');
    
    r=plot(S.ax,...
        timeThisWindow,...
        respThisWindow,...
        lineType,...
        'LineWidth',2);
    
    hold(S.ax,'on');
    
    
    % update labels and title
    titleText=sprintf('Breath %i (%s)', S.fh.UserData.thisBreath,breathInfo);
    set(get(S.ax,'XLabel'),'String','Time (S)');
    set(get(S.ax,'YLabel'),'String','Amplitude');
    set(get(S.ax,'title'),'String',titleText);
    
    % update xlims
    set(S.ax,'XLim',newXLims);
    
    
    phasePoints=[];
    
    for ph=1:4
        if ~isUpdatePlot
            thisPhaseOnset=S.fh.UserData.breathEditMat(S.fh.UserData.thisBreath,ph);
        else
            thisPhaseOnset=S.fh.UserData.tempPhaseOnsetChanges(ph);
        end
        
        % put it in the edit box
        set(S.phaseEditors(ph),'String',num2str(thisPhaseOnset));
        
        if ~isnan(thisPhaseOnset)
            
            thisPhaseYInd=bmObj.baselineCorrectedRespiration(1,round(thisPhaseOnset*bmObj.srate));
            
            phasePoints(end+1)=drawpoint(S.ax,...
                'Position',[thisPhaseOnset,thisPhaseYInd],...
                'Label',S.breathEditMenuColNames{ph},...
                'Color',S.myColors(ph,:));
            
        end
    end
    
end

end

% add note to selected breath
function [] = noteCallback(varargin)
% Callback for pushbutton
S = varargin{3};  % Get the structure.

UserData=S.fh.UserData;

% prompt user for note
noteToAdd = inputdlg('Add a Note');
if ~isempty(noteToAdd)
    % add note
    UserData.breathSelectMat{UserData.thisBreath,5}=noteToAdd{1};
    set( S.fh, 'UserData', UserData);
    set( S.uit,'Data',S.fh.UserData.breathSelectMat);
end

end


% revert all changes made to this breath back to original
function revertChangesCallback(varargin)

S=varargin{3};

UserData=S.fh.UserData;


originalVals=UserData.initialBreathEditMat(UserData.thisBreath,:);

UserData.tempPhaseOnsetChanges=originalVals;
UserData.breathSelectMat{UserData.thisBreath,4}='valid';

set( S.fh, 'UserData', UserData);
set( S.uit,'Data',S.fh.UserData.breathSelectMat);
plotMeCallback({},{},S,1);
end

% reject selected breath
function [] = rejectBreathCallback(varargin)
% Callback for pushbutton
S = varargin{3};  % Get the structure.

UserData=S.fh.UserData;

% set status of this breath to rejected
UserData.breathSelectMat{UserData.thisBreath,4}='rejected';
set( S.fh, 'UserData', UserData);
set( S.uit,'Data',S.fh.UserData.breathSelectMat);

end

%%% right side %%%

% initialize new pause onset
function createNewPauseFromButtonCallback(varargin)

S=varargin{3};
pauseType=varargin{4};

thisMidpoint=mean(S.ax.XLim);

% get numbers in each phase edit field
UserData=S.fh.UserData;

if strcmp(pauseType,'Inhale Pause')
    pauseInd=2;
else
    pauseInd=4;
end

tempPhaseOnsetChanges=nan(1,4);
for ph=1:4
    if ph==pauseInd
        set(S.phaseEditors(ph),'String',num2str(thisMidpoint));
    end
        
    newInd=get(S.phaseEditors(ph),'String');
    if isnumeric(str2double(newInd))
        tempPhaseOnsetChanges(1,ph)=str2double(newInd);
    else
        disp('This must be a number');
    end
end

tempPhaseOnsetChanges(1,pauseInd)=thisMidpoint;

% save it
UserData.tempPhaseOnsetChanges=tempPhaseOnsetChanges;
set( S.fh, 'UserData', UserData);

plotMeCallback({},{},S,1);
end

% remove pause from figure
function removePauseFromButtonCallback(varargin)

S=varargin{3};
pauseType=varargin{4};

% get numbers in each phase edit field
UserData=S.fh.UserData;

if strcmp(pauseType,'Inhale Pause')
    pauseInd=2;
else
    pauseInd=4;
end

tempPhaseOnsetChanges=nan(1,4);
for ph=1:4
    if ph==pauseInd
        set(S.phaseEditors(ph),'String','NaN');
    end
        
    newInd=get(S.phaseEditors(ph),'String');
    if isnumeric(str2double(newInd))
        tempPhaseOnsetChanges(1,ph)=str2double(newInd);
    else
        disp('This must be a number');
    end
end

% save it
UserData.tempPhaseOnsetChanges=tempPhaseOnsetChanges;
set( S.fh, 'UserData', UserData);

plotMeCallback({},{},S,1);

end


% updates the plot from text input, saves new timepoints into temporary storage
function updatePlotFromTextCallback(varargin)
S=varargin{3};

% get numbers in each phase edit field
UserData=S.fh.UserData;

tempPhaseOnsetChanges=nan(1,4);
for ph=1:4
    newInd=get(S.phaseEditors(ph),'String');
    if isnumeric(str2double(newInd))
        tempPhaseOnsetChanges(1,ph)=str2double(newInd);
    else
        disp('This must be a number');
    end
end

% save in temporary storage
UserData.tempPhaseOnsetChanges=tempPhaseOnsetChanges;

set( S.fh, 'UserData', UserData);

plotMeCallback({},{},S,1);
end

% updates the plot from drawpoint location
% saves new timepoints into temporary storage

function updatePlotFromPointCallback(varargin)

S=varargin{3};
UserData=S.fh.UserData;

% indices of new points will be put in here
tempPhaseOnsetChanges=nan(1,4);

% get positions of points
nChildren=length(S.ax.Children);
for el=1:nChildren
    thisPlotEl=S.ax.Children(el);
    if isa(thisPlotEl,'images.roi.Point')
        thisAdjustedOnset=thisPlotEl.Position(1);
        thisLabel=thisPlotEl.Label;
        IndexC = find(strcmp(S.breathEditMenuColNames,thisLabel));
        tempPhaseOnsetChanges(1,IndexC)=thisAdjustedOnset;
    end
end

% save it

UserData.tempPhaseOnsetChanges=tempPhaseOnsetChanges;

% save in temporary storage
set( S.fh, 'UserData', UserData);

plotMeCallback({},{},S,1);
end

% saves temporary changes into storage
% calls validityDecision to check that points make sense
function saveTempChangesCallback(varargin)

S=varargin{3};

UserData=S.fh.UserData;

newVals=UserData.tempPhaseOnsetChanges;

UserData=S.fh.UserData;

newValsInSamples=round(newVals*UserData.bmObj.srate);


% check that new vals are valid
[changesAreValid,errorText]=checkNewVals(S,newValsInSamples);

% raise error if there is one
if ~isempty(errorText)
%     f = uifigure;
%     uialert(f,errorText,'BM GUI Error');
    warndlg(errorText);
end

if changesAreValid

    % check if values are new
    oldValsInSamples=UserData.breathEditMat(UserData.thisBreath,:)*UserData.bmObj.srate;

    % doing this way to handle nans
    valueDiffs=nansum([newValsInSamples;-oldValsInSamples],1);

    if sum(valueDiffs)~=0

        % save these values
        UserData.breathEditMat(UserData.thisBreath,:)=UserData.tempPhaseOnsetChanges;

        % set status of this breath to edited
        UserData.breathSelectMat{UserData.thisBreath,4}='edited';
        
        set( S.fh, 'UserData', UserData);
        set( S.uit,'Data',S.fh.UserData.breathSelectMat);
    else
        warndlg('No changes have been made. Update the plot after you move a point before attempting to save.');
    end
end
end

% checks that selected points are valid to save
function [validityDecision,errorText]=checkNewVals(S,newVals)

validityDecision=1;
errorText=[];


UserData=S.fh.UserData;

inhaleOnset=newVals(1);
inhalePauseOnset=newVals(2);
exhaleOnset=newVals(3);
exhalePauseOnset=newVals(4);


% check that selections are valid
% rules:
% points must be within bounds of recording
% phases must proceed in correct order (i,ip,e,ep)

% check for pauses because nans break things
isInhalePause=~isnan(inhalePauseOnset);
isExhalePause=~isnan(exhalePauseOnset);

recordingLen=length(UserData.bmObj.rawRespiration);

% are inhales and exhales within bounds of recording?
if any(newVals<1)
    validityDecision=0;
    errorText='Selected points are not within the timecourse of the recording.';
end

if any(newVals>recordingLen)
    validityDecision=0;
    errorText='Selected points are not within the timecourse of the recording.';
end

% check that phases proceed in order

% check inhale
% inhale lims
if UserData.thisBreath==1
    inhaleMinBoundary=1;
else
    inhaleMinBoundary=UserData.bmObj.exhaleOnsets(UserData.thisBreath-1);
end

if isInhalePause
    inhaleMaxBoundary=inhalePauseOnset;
else
    inhaleMaxBoundary=exhaleOnset;
end

% compare value to lims
if inhaleOnset<inhaleMinBoundary || inhaleOnset>inhaleMaxBoundary
    validityDecision=0;
    errorText='Invalid Inhale Value. It must take place after the preceeding exhale and before the next exhale.';
end

% check inhale pause
if isInhalePause
    
    % lims
    ipMinBoundary=inhaleOnset;
    ipMaxBoundary=exhaleOnset;
    
    % compare to lims
    if inhalePauseOnset<ipMinBoundary || inhalePauseOnset>ipMaxBoundary
        validityDecision=0;
        errorText='Invalid Inhale Pause Value. It must take place after the preceeding inhale and before the next exhale.';
    end
end

% check exhale
% lims

if isInhalePause
    exhaleMinBoundary=inhalePauseOnset;
else
    exhaleMinBoundary=inhaleOnset;
end

if UserData.thisBreath==UserData.nBreaths
    exhaleMaxBoundary=recordingLen;
else
    exhaleMaxBoundary=UserData.bmObj.inhaleOnsets(UserData.thisBreath+1);
end

% compare value to lims
if exhaleOnset<exhaleMinBoundary || exhaleOnset>exhaleMaxBoundary
    validityDecision=0;
    errorText='Invalid Exhale Value. It must take place after the preceeding inhale or inhale pause and before the next exhale pause or inhale.';
end

% check exhale pause
if isExhalePause
    
    % lims
    epMinBoundary=exhaleOnset;
    
    if UserData.thisBreath==UserData.nBreaths
        epMaxBoundary=recordingLen;
    else
        epMaxBoundary=UserData.bmObj.inhaleOnsets(UserData.thisBreath+1);
    end
    
    % compare to lims
    if exhalePauseOnset<epMinBoundary || exhalePauseOnset>epMaxBoundary
        validityDecision=0;
        errorText='Invalid Exhale Pause Value. It must take place after the preceeding exhale and before the next inhale.';
    end
end
end

% save all changes that have been made
function saveAllChangesCallback(varargin)

src=varargin{1};
S=varargin{3};
UserData=S.fh.UserData;

inhaleOnsets=round(UserData.breathEditMat(:,1)' * UserData.bmObj.srate);
inhalePauseOnsets=round(UserData.breathEditMat(:,2)' * UserData.bmObj.srate);
exhaleOnsets=round(UserData.breathEditMat(:,3)' * UserData.bmObj.srate);
exhalePauseOnsets=round(UserData.breathEditMat(:,4)' * UserData.bmObj.srate);

statuses=UserData.breathSelectMat(:,4)';
notes=UserData.breathSelectMat(:,5)';

newBM=UserData.bmObj;
newBM.inhaleOnsets=inhaleOnsets;
newBM.inhalePauseOnsets=inhalePauseOnsets;
newBM.exhaleOnsets=exhaleOnsets;
newBM.exhalePauseOnsets=exhalePauseOnsets;

newBM.notes=notes;
newBM.statuses=statuses;
newBM.featuresManuallyEdited=1;

answer = questdlg('Are you sure that you want to save all changes? This window will be closed and your edits will be saved into the output variable.', ...
	'Yes', ...
	'No');

if strcmp(answer,'Yes')
    UserData.newBM=newBM;
    set( S.fh, 'UserData', UserData);
    set( src, 'Tag', 'done');
end
end

