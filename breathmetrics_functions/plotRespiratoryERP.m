function [fig] = plotRespiratoryERP(ERPMatrix, xAxis, simpleOrResampled)
% plots an erp of respiratory data
% erpmat : events x respiratory amplitude matrix of data
% x_axis : time points corresponding to amplitudes in erpmat
% simple_or_resampled : 'simple' if erpmat and x_axis are in real time
% 'resampled' if data is in reference to breathing rate

if strcmp(simpleOrResampled,'simple')
    TITLE_TEXT = 'Respiratory ERP';
    XLABEL_TEXT = 'Time (ms)';
    
elseif strcmp(simpleOrResampled,'resampled')
    TITLE_TEXT = 'Resampled respiratory ERP before and after events';
    XLABEL_TEXT = 'Percent of average respiratory cycle';
    
else
    raise('Method not recognized. Use simple or resampled.');
    
end

fig = figure;
hold all;
title(TITLE_TEXT)
plot(xAxis, ERPMatrix', 'b');
plot(xAxis, mean(ERPMatrix), 'LineWidth', 5, 'Color', 'k');
xlabel(XLABEL_TEXT)
ylabel('Airflow');

end