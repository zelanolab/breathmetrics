%% BreathMetrics GUI demo.

% The breathmetrics GUI is a powerful tool that lets you efficiently look
% through your data, manually adjust the automatic features, reject bad
% periods of data, and annotate breaths with your comments.

% It takes your breathmetrics object as its only input and returns the
% modified breathmetrics object as the output. Shown below.

% newBM=bmGui(bm);

%% Before you launch the GUI

% To use the GUI, you must first initialize a breathmetrics object and
% estimate all features, as shown here.

rootDir='';
respDataFileName='sample_data.mat';

% sample data contains 
respiratoryData = load(fullfile(rootDir,respDataFileName));

respiratoryRecording = respiratoryData.resp;
srate = respiratoryData.srate;
dataType = 'humanAirflow';

bmObj = breathmetrics(respiratoryRecording, srate, dataType);
bmObj.estimateAllFeatures();

%% How to Use the GUI
% *** READ THIS BEFORE YOU USE IT ***

% This tool has many powerful capabilities but using it might not be 
% intuitive. 
%
% If you stick to the following workflow you will be fine:
%
% 1. Select a breath by clicking either a cell in the table on the left or
%    by pressing the previous or next breath buttons.
%
% 2. If you want, adjust the points on the plot using one of two methods:
%    A) Drag the points on the plot to where you want then and click the 
%       button that reads 'Update Changes to Plot'. 
%       If you create or remove a pause using the create and remove pause
%       buttons, you also need to click 'Update Changes to Plot' to save 
%       these changes
%
%    B) Edit the text in the boxes below the plotting axis and click the
%       button that reads 'Update Changes to Text'.
%
% 3. *** Click the button that reads 'Save All Changes To This Breath'. ***
%    You must click one of the update buttons in step 2 before you do this 
%    to save any changes you've made.
%
% 4. Add a note, choose to reject this breath from analysis, or undo any
%    changes you've made to this breath using the buttons to the left of
%    the plotting axis. These automatically save.
%
% 5. When you have made all of the changes that you want, click 'SAVE ALL
%    CHANGES'. If you close the figure before doing this, none of your work
%    will be saved.


%% Launching the GUI
% This launches the GUI.

newBM=bmGui(bmObj);

%% That's all :) 
%  Sorry for yelling in cell 3. 
%  I'm just tryin to help.