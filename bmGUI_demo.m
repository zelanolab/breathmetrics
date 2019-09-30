%% BreathMetrics GUI demo.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PLEASE READ THROUGH THIS BEFORE USING THE GUI
% If you encounter a problem that was not addressed in the text below,
% please email me (Torben Noto) at torben.noto@gmail.com with questions.
% I'd be happy to help you get this working.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The breathmetrics GUI is a powerful tool that lets you efficiently look
% through your data, manually adjust the automatic features, reject bad
% periods of data, and annotate breaths with your comments.

% It takes your breathmetrics object as its only input and returns the
% modified breathmetrics object as the output. Shown below.

% newBM=bmGui(bmObj);

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

% This GUI allows users to manually check and edit respiratory features.
% 
% Before explaining how to use it, I recommend that you use this GUI with
% the following workflow:
%
% SUGGESTED WORKFLOW
% 1. Select a breath
% 2. Edit the features of the breath
% 3. Repeat for as many breaths as you choose
% 4. Click "Save All Changes" and confirm.
% All of your edits will be saved to the the output variable of the bmGUI
% function.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% LAUNCHING THE GUI
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% bmGUI takes in a breathmetrics object as its only argument and returns
% another breathmetrics object with all of the modifications you've made to
% its features.
%
% This line of code launches the GUI:
%
% newBM=bmGui(bmObj);
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% THERE ARE TWO IMPORTANT THINGS YOU MUST KNOW BEFORE USING THE GUI
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 1. the breathmetrics object that you input to bmGUI must already have
%    features estimated.
%
%    This will not work:
%    bmObj = breathmetrics(respiratoryRecording, srate, dataType);   
%    newBM=bmGui(bmObj);
%
%    This will work:
%    bmObj = breathmetrics(respiratoryRecording, srate, dataType);   
%    bmObj.estimateAllFeatures();
%    newBM=bmGui(bmObj);
%
%
% 2. As explained later on, you must click SAVE ALL CHANGES after you've 
%    made your edits if you wish to keep any changes you've made. If you 
%    close the figure without making any changes, the function will return 
%    the original breathmetrics object.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SELECTING A BREATH
% * Using the interactive breath selection table
% * Using the breath navigation buttons
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% There are two ways that you can select a breath: by clicking the table,
% or by clicking the buttons that say "Previous Breath" and "Next Breath".
%
%
% SELECTING A BREATH WITH THE BREATH SELECTION TABLE
% 
% The table on the left displays all of the breaths that breathmetrics
% automatically extracted in the recording. The table displays the breath
% number (first breath in the recording is 1, second breath is 2, etc.),
% the onset and offset of the breath (in seconds), the status (default is
% valid), and an empty string to write a note about the breath.
% Clicking any cell on the table will plot the corresponding breath on the
% axes to the right. Clicking any column in the same row has the same
% effect of selecting the breath corresponding to that row. The index of 
% the breath you are currently editing is shown in the title of the plot.
%
%
% SELECTING A BREATH WITH THE NAVIGATION BUTTONS
%
% Clicking the buttons that say "Previous Breath" and "Next Breath" will
% navigate to the breath before or after the one you are currently editing.
% The index of the breath you are currently editing is shown in the title 
% of the plot.
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% EDITING A BREATH'S NOMINAL FEATURES
% * Adding a note
% * Rejecting a breath from analysis
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ADDING A NOTE TO A BREATH
%
% You can add a note to the breath by clicking the button that says 
% "Add Note To This Breath". After clicking this button, you will be 
% prompted to enter a note. You can write whatever you want in this field.
% This feature is intended to be helpful for keeping track of features that 
% you observe in the breathing that breathmetrics might not recognize. 
% For example, you can annotate breaths as 'sneeze' or 'double inhale', or
% you could write something like 'Condition 1' if you are running an
% experiment and want to have a clean list of each breath for each
% experimental condition.
%
%
% REJECTING A BREATH FROM ANALYSIS
%
% If you see that a breath doesn't look correct, click the button that says
% "Reject This Breath". When you save all of your features at the end,
% breathmetrics will recalculate all of the features in the data excluding
% any rejected breaths. This can be helpful if during an experiment, a 
% participant sneezed during a trial when they were supposed to inhale,
% rejecting this breath would exclude it from other analyses.
%
% As another example, if a participant took a spirometor off during the 
% recording, it would probably result in a 'breath' with an extremely long 
% exhale pause, and their breathing rate will be artifically slower because 
% of an increased period between inhale onsets. If you reject the breaths 
% before and after this period, breathmetrics will recompute their 
% breathing rate, (as well as all of the other features dependant on breath 
% onsets) and result in a much more accurate evaluation of the recording.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% EDITING A BREATH'S NUMERIC FEATURES
% * Adjusting the onset of each phase
% * Adding or removing a pause
% * Undo-ing any changes made to this breath
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ADJUSTING THE ONSET OF EACH PHASE
%
% If you see that the onset of a breath's inhale, exhale, or pause is 
% mislabeled, you can edit it one of two ways: 
%
% 1. By dragging its corresponding point to the correct position
% 2. By editing the text in the phase's corresponding field.
%
% Any changes you make using either method will automatically be saved. 
% If you make a mistake, you can click "Undo Changes To This Breath" and it 
% will revert back to its orignal values. 
%
%
% There are only two rules you must follow when using either method:
%
% 1. Onsets of each phase must fall within the boundaries of the recording.
%    In other words, an inhale cannot happen before sample 1 and an exhale
%    or exhale pause can't occur after the duration of the recording.
%
% 2. Phase onsets must procede in the correct order: Inhale, Inhale Pause
%    (optional), Exhale, Exhale Pause (optional). If you create an inhale
%    pause after an exhale, you will be notified that the change is invalid
%    and this edit will not be saved.
%
%
% ADJUSTING PHASE ONSETS USING DRAGGABLE POINTS
% 
% You can simply drag and drop each phase point to where you think it
% should be. The color of each point corresponds to the color of the text
% fields below. i.e. The text box that says exhale below the plot is 
% orange so the point on the plot corresponding to the exhale is also 
% orange. 
%
% You can also zoom in over the plot by hovering your mouse over the axis 
% and selecting the zoom icon. The axis will snap back to its original 
% values after moving the point.
%
%
% ADJUSTING PHASE ONSETS USING THE TEXT FIELDS
% 
% If you click the text box for a phase, edit the numbers there, and press
% return or click elsewhere on the plot, the corresponding respiratory
% phase will move to the new value that you entered.
%
%
% % CREATING OR REMOVING A RESPIRATORY PAUSE
%
% If you believe there is or is not a pause in the breath you are
% reviewing, you can add or remove it in one of two ways:
%
% 1. You can edit the text in the corresponding field (just like above).
%
% 2. You can click the add and remove buttons below the corresponding 
%    phase. If you create a pause in this way, you should drag the point to
%    the correct position.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% SAVING ALL OF THE CHANGES THAT YOU HAVE MADE
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% As noted before, make sure that you click save all changes, and confirm
% it after you've made all of the changes that you wish. If not, you will
% lose any changes you have made.
%
% All changes are written to the newBM output variable and the orignal
% breathmetrics object should be unaffected.
%