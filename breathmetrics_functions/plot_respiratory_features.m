function [fig] = plot_respiratory_features( bm, annotate, size_data)
% Plots respiration as well as any respiratory features that have been
% estimated
% annotate is a cell of features you wish to plot. Options are:
% 'extrema', 'onsets','maxflow','volumes', and 'pauses'

if nargin < 3
    size_data = 36;
end

params = {};
param_labels = {};
i=1;

% plot all params that have been calculated
if ~isempty(bm.inhale_peaks)
    params{i}=bm.inhale_peaks;
    param_labels{i}='Inhale Peaks';
    i=i+1;
end

if ~isempty(bm.exhale_troughs)
    params{i}=bm.exhale_troughs;
    param_labels{i}='Exhale Troughs';
    i=i+1;
end

if ~isempty(bm.inhale_onsets)
    params{i}=bm.inhale_onsets;
    param_labels{i}='Inhale Onsets';
    i=i+1;
end

if ~isempty(bm.exhale_onsets)
    params{i}=bm.exhale_onsets;
    param_labels{i}='Exhale Onsets';
    i=i+1;
end

if ~ isempty(bm.inhale_pause_onsets)
    params{i}=bm.inhale_pause_onsets(bm.exhale_pause_onsets>0);
    param_labels{i} = 'Inhale Pauses';
    i=i+1;
end

if ~ isempty(bm.exhale_pause_onsets)
    params{i}=bm.exhale_pause_onsets(bm.exhale_pause_onsets>0);
    param_labels{i} = 'Exhale Pauses';
    i=i+1;
end

if nargin < 2
    annotate=[];
end

resp = bm.which_resp();
x_axis = bm.time;

fig=figure; 
hold all;

title('Estimated Respiratory Features');
r = plot(x_axis,resp,'k-');
handles = [r];
legend_text = {'Respiration'};

xlabel('Time (seconds)');
ylabel('Respiratory Flow (AU)');
if ~isempty(params)
    mycolors = parula(length(params));
    for param_ind=1:length(params)
        this_param = params{param_ind};
        %exclude nans for points where pauses don't happen or volumes can't
        %be calculated
        real_params = this_param(this_param>0);
        h=scatter(x_axis(real_params),resp(real_params),'MarkerEdgeColor',mycolors(param_ind,:),'MarkerFaceColor',mycolors(param_ind,:),'SizeData',size_data);
        handles = [handles, h(1)];
        legend_text{param_ind+1}=param_labels{param_ind};
    end
end

legend(handles,legend_text);

% placeholders for annotations
peak_annotations = {};
trough_annotations = {};
inhale_onset_annotations = {};
exhale_onset_annotations = {};
inhale_pause_annotations = {};
exhale_pause_annotations = {};

if ~isempty(annotate)
    % annotate information about peaks if they have been calculated
    if sum(strcmp(annotate,'extrema'))>0 || sum(strcmp(annotate,'volumes'))>0 || sum(strcmp(annotate,'maxflow'))>0
        if ~isempty(bm.inhale_peaks) && ~isempty(bm.exhale_troughs)
            for i=1:length(bm.inhale_peaks)
                peak_annotations{i} = sprintf('Peak at %.1f\n',bm.time(bm.inhale_peaks(i)));
            end
            for e=1:length(bm.exhale_volumes)
                trough_annotations{e} = sprintf('Trough at %.1f\n',bm.time(bm.exhale_troughs(e)));
            end
        else
            disp('Breath extrema have not been calculated.')
        end
    end
    % annotate information about airflow if it have been calculated
    if sum(strcmp(annotate,'maxflow'))>0
        if ~isempty(bm.inhale_peaks) && ~isempty(bm.exhale_troughs)
            for i=1:length(bm.inhale_peaks)
                peak_annotations{i} = sprintf('%s%s\n',peak_annotations{i},sprintf(' Max Flow: %.2g',bm.peak_inspiratory_flows(i)));
            end
            for e=1:length(bm.exhale_troughs)
                trough_annotations{e} = sprintf('%s%s\n',trough_annotations{e},sprintf(' Max Flow: %.2g',bm.trough_expiratory_flows(e)));
            end
        else
            disp('Max flow at breath extrema have not been calculated.')
        end
    end

    % annotate information about breath volumes if they have been calculated
    if sum(strcmp(annotate,'volumes'))>0
        if ~isempty(bm.inhale_volumes) && ~isempty(bm.exhale_volumes)
            for i=1:length(bm.inhale_volumes)
                peak_annotations{i} = sprintf('%s%s', peak_annotations{i},sprintf(' Volume: %.3g', bm.inhale_volumes(i)));
            end
            for e=1:length(bm.exhale_volumes)
                trough_annotations{e} = sprintf('%s%s', trough_annotations{e},sprintf(' Volume: %.3g', bm.exhale_volumes(e)));
            end
        else
            disp('Breath volumes have not been calculated.')
        end
    end
    
    if sum(strcmp(annotate,'onsets'))>0
        if ~isempty(bm.inhale_onsets) && ~isempty(bm.exhale_onsets)
            for i=1:length(bm.inhale_onsets)
                inhale_onset_annotations{i} = sprintf('Inhale at %.1f',bm.time(bm.inhale_onsets(i)));
            end
            for e=1:length(bm.exhale_onsets)
                exhale_onset_annotations{e} = sprintf('Exhale at %.1f',bm.time(bm.exhale_onsets(e)));
            end
        else
            disp('Breath onsets have not been calculated.')
        end
    end
    
    if sum(strcmp(annotate,'pauses'))>0
        if ~isempty(bm.inhale_pause_onsets) && ~isempty(bm.exhale_pause_onsets)
            % remove nan's for breaths where there was no pause
            real_inhale_pause_onsets = bm.inhale_pause_onsets(bm.inhale_pause_onsets>0);
            real_exhale_pause_onsets = bm.exhale_pause_onsets(bm.exhale_pause_onsets>0);
            
            if ~isempty(real_inhale_pause_onsets)
                for i=1:length(real_inhale_pause_onsets)
                    inhale_pause_annotations{i} = sprintf('Inhale pause at %.1f', bm.time(real_inhale_pause_onsets(i)));
                end
            else
                disp('No inhale pauses detected');
            end
            if ~isempty(real_exhale_pause_onsets)
                for e=1:length(real_exhale_pause_onsets)
                    exhale_pause_annotations{e} = sprintf('Exhale pause at %.1f', bm.time(real_exhale_pause_onsets(e)));
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
if ~isempty(peak_annotations) && ~isempty(trough_annotations)
    for i=1:length(bm.inhale_peaks)
        text(x_axis(bm.inhale_peaks(i)),resp(bm.inhale_peaks(i)),peak_annotations{i});
    end
    for e=1:length(bm.exhale_troughs)
        text(x_axis(bm.exhale_troughs(e)),resp(bm.exhale_troughs(e)),trough_annotations{e});
    end
end

if ~isempty(inhale_onset_annotations) && ~isempty(exhale_onset_annotations)
    for i=1:length(bm.inhale_onsets)
        text(x_axis(bm.inhale_onsets(i)),resp(bm.inhale_onsets(i)),inhale_onset_annotations{i});
    end
    for e=1:length(bm.exhale_onsets)
        text(x_axis(bm.exhale_onsets(e)),resp(bm.exhale_onsets(e)),exhale_onset_annotations{e});
    end
end

if ~isempty(inhale_pause_annotations)
    for i=1:length(real_inhale_pause_onsets)
        text(x_axis(real_inhale_pause_onsets(i)),resp(real_inhale_pause_onsets(i)),inhale_pause_annotations{i});
    end
end

if ~isempty(exhale_pause_annotations)
    for e=1:length(real_exhale_pause_onsets)
        text(x_axis(real_inhale_pause_onsets(e)),resp(real_exhale_pause_onsets(e)),exhale_pause_annotations{e});
    end
end


