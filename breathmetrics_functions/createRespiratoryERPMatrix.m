function [ERPMatrix,trialEvents,rejectedEvents] = createRespiratoryERPMatrix(data, events, ...
    preSamples, postSamples, verbose)

% pre and post must both be positive.

if nargin<5
    verbose=1;
end
% keep track of which trials were used for data and which ones could not be
% used to compute ERPs
trialEvents=[];
rejectedEvents=[];
iter=1;
for event = 1:length(events)
    EVENT_INDS = events(event)-preSamples:events(event) + postSamples;
    if ~ (any(EVENT_INDS<1) || any(EVENT_INDS>size(data,2)))
        trialEvents=[trialEvents,events(event)];
        ERPMatrix(iter,:) = data(1,EVENT_INDS);
        iter=iter+1;
    else
        rejectedEvents=[rejectedEvents,events(event)];
        if verbose
            fprintf('Event #%i (%i) is outside of ERP range \n', ...
                event, events(event));
        end
    end
end

if ~exist('ERPMatrix','var')
    if verbose
        disp('No valid events were found. Returning empty array');
    end
    ERPMatrix = zeros(1,length(-preSamples:postSamples));
    ERPMatrix(:)=nan;
end