function [erpmat] = create_erp_mat(data, events, pre_samples, post_samples)

% pre and post must both be positive.

%erp_mat = zeros(length(events),length(x_axis)); % cant do in case zeros
iter=1;
for event = 1:length(events)
    event_inds = events(event)-pre_samples:events(event)+post_samples;
    if ~ (any(event_inds<1) || any(event_inds>size(data,2)))
        erpmat(iter,:) = data(1,event_inds);
        iter=iter+1;
    else
        disp(sprintf('Event #%i (%i) is outside of ERP range', event, events(event)));
    end
end