function [ERPMatrix,trialEvents,rejectedEvents] = createRespiratoryERPMatrix(resp, eventArray, ...
    preSamples, postSamples, verbose)
% Calculates an ERP matrix (events x time) for given events in respiratory 
% data. Returns events used for ERP as well as events where a full ERP 
% could not be calculated.

% PARAMETERS
% resp : respiratory recording (1xN vector)
% eventArray : indices of events to be used as onsets for the
%              ERP
% preSamples : number of samples before each event in eventArray to include
%              in ERP calculation (must be positive).
% postSamples : number of samples after each event in eventArray to include
%              in ERP calculation.
% verbose : 0 or 1 (default) : displays each step of this function

if nargin<5
    verbose=1;
end
% keep track of which trials were used for data and which ones could not be
% used to compute ERPs
trialEvents=[];
rejectedEvents=[];
iter=1;
for event = 1:length(eventArray)
    EVENT_INDS = eventArray(event)-preSamples:eventArray(event) + postSamples;
    if ~ (any(EVENT_INDS<1) || any(EVENT_INDS>size(resp,2)))
        trialEvents=[trialEvents,eventArray(event)];
        ERPMatrix(iter,:) = resp(1,EVENT_INDS);
        iter=iter+1;
    else
        rejectedEvents=[rejectedEvents,eventArray(event)];
        if verbose
            fprintf('Event #%i (%i) is outside of ERP range \n', ...
                event, eventArray(event));
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