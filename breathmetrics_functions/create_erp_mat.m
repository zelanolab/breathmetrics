function [erpmat] = create_erp_mat(data, events, pre_samples, post_samples, verbose)

% pre and post must both be positive.

if nargin<5
    verbose=1;
end
iter=1;
for event = 1:length(events)
    event_inds = events(event)-pre_samples:events(event)+post_samples;
    if ~ (any(event_inds<1) || any(event_inds>size(data,2)))
        erpmat(iter,:) = data(1,event_inds);
        iter=iter+1;
    else
        if verbose
            disp(sprintf('Event #%i (%i) is outside of ERP range', event, events(event)));
        end
    end
end