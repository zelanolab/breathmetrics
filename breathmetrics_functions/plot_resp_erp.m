function [fig] = plot_resp_erp(erpmat, x_axis, simple_or_resampled)
% plots an erp of respiratory data
% erpmat : events x respiratory amplitude matrix of data
% x_axis : time points corresponding to amplitudes in erpmat
% simple_or_resampled : 'simple' if erpmat and x_axis are in real time
% 'resampled' if data is in reference to breathing rate

if strcmp(simple_or_resampled,'simple')
    title_text = 'Respiratory ERP before and after events';
    xlabel_text = 'Time (ms)';
elseif strcmp(simple_or_resampled,'resampled')
    title_text = 'Resampled respiratory ERP before and after events';
    xlabel_text = 'Percent of average respiratory cycle';
else
    raise('Method not recognized. Use simple or resampled.')
end

fig = figure;
hold all;
title(title_text)
plot(x_axis,erpmat','b');
plot(x_axis,mean(erpmat),'LineWidth',5,'Color','k');
xlabel(xlabel_text)
end