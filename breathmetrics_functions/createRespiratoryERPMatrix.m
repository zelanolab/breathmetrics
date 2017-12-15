function [ERPMatrix] = createRespiratoryERPMatrix(data, events, ...
    preSamples, postSamples, verbose)

% pre and post must both be positive.

if nargin<5
    verbose=1;
end
iter=1;
for event = 1:length(events)
    EVENT_INDS = events(event)-preSamples:events(event) + postSamples;
    if ~ (any(EVENT_INDS<1) || any(EVENT_INDS>size(data,2)))
        ERPMatrix(iter,:) = data(1,EVENT_INDS);
        iter=iter+1;
    else
        if verbose
            fprintf('Event #%i (%i) is outside of ERP range \n', ...
                event, events(event));
        end
    end
end