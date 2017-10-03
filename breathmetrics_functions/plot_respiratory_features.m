function [fig] = plot_respiratory_features( bm, annotate)
% Plots respiration as well as any respiratory features that have been
% estimated

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

if sum(bm.respiratory_pause_onsets)>0
    params{i}=bm.respiratory_pause_onsets(bm.respiratory_pause_onsets>0);
    param_labels{i} = 'Respiratory Pauses';
    i=i+1;
end

if nargin < 2
    annotate=0;
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
ylabel('Respiratory Amplitude (AU)');
if ~isempty(params)
    mycolors = parula(length(params));
    for param_ind=1:length(params)
        this_param = params{param_ind};
        h=scatter(x_axis(this_param),resp(this_param),'MarkerEdgeColor',mycolors(param_ind,:),'MarkerFaceColor',mycolors(param_ind,:));
        handles = [handles, h(1)];
        legend_text{param_ind+1}=param_labels{param_ind};
    end
end

legend(handles,legend_text);


if annotate==1
    if ~isempty(bm.inhale_volumes)
        for i=1:length(bm.inhale_volumes)
            text(x_axis(bm.inhale_peaks(i)),resp(bm.inhale_peaks(i)),sprintf('Peak: %i Volume: %i', i, round(bm.inhale_volumes(i))))
        end
        for e=1:length(bm.exhale_volumes)
            text(x_axis(bm.exhale_troughs(e)),resp(bm.exhale_troughs(e)),sprintf('Trough: %i Volume: %i', e, round(bm.exhale_volumes(e))))
        end
    end
end

if annotate==2
    if ~isempty(bm.inhale_peaks)
        for i=1:length(bm.inhale_peaks)
            text(x_axis(bm.inhale_peaks(i)),resp(bm.inhale_peaks(i)),sprintf('Peak: %i Max Flow: %i', i, round(bm.inhale_peaks(i))))
        end
        for e=1:length(bm.exhale_volumes)
            text(x_axis(bm.exhale_troughs(e)),resp(bm.exhale_troughs(e)),sprintf('Trough: %i Max Flow: %i', e, round(bm.exhale_troughs(e))))
        end
    end
end

