function [ERPMatrix,trialEvents,rejectedEvents,trialEventInds,rejectedEventInds] = createRespiratoryERPMatrix(resp, eventArray, ...
    preSamples, postSamples, appendNaNs, verbose)
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
% appendNaNs : 0 (default) or 1 : if the full window for an event can't be
%              calculated, nan's are inserted where values are missing.
% verbose : 0 or 1 (default) : displays each step of this function
if nargin<5
    appendNaNs=0;
end
if nargin<6
    verbose=1;
end
% keep track of which trials were used for data and which ones could not be
% used to compute ERPs
trialEvents=[];
rejectedEvents=[];
trialEventInds=[];
rejectedEventInds=[];
ERPiter=1;

for thisEvent = 1:length(eventArray)
    if ~isnan(eventArray(thisEvent))
        eventWindow = eventArray(thisEvent)-preSamples:eventArray(thisEvent) + postSamples;
        
        if appendNaNs == 0
            % reject events where the whole window can't be calculated
            if ~ (any(eventWindow<1) || any(eventWindow>size(resp,2)))
                trialEvents=[trialEvents,eventArray(thisEvent)];
                trialEventInds = [trialEventInds,thisEvent];
                ERPMatrix(ERPiter,:) = resp(1,eventWindow);
                ERPiter=ERPiter+1;
            else
                rejectedEvents=[rejectedEvents,eventArray(thisEvent)];
                rejectedEventInds = [rejectedEventInds,thisEvent];
                if verbose
                    fprintf('Event #%i (%i) is outside of ERP range \n', ...
                        thisEvent, eventArray(thisEvent));
                end
            end
            
        % appending nans
        else
            thisEventERP = zeros(1,preSamples+postSamples+1);
            thisEventERP(:)=nan;
            validInds = ~((eventWindow<1) | any(eventWindow>size(resp,2)));
            thisEventERP(1,validInds)=resp(1,eventWindow(validInds));
            
            if all(isnan(thisEventERP))
                rejectedEvents=[rejectedEvents,eventArray(thisEvent)];
                rejectedEventInds = [rejectedEventInds,thisEvent];
                if verbose
                    fprintf('Event #%i (%i) is outside of ERP range \n', ...
                        thisEvent, eventArray(thisEvent));
                end
            else
                trialEvents=[trialEvents,eventArray(thisEvent)];
                trialEventInds=[trialEventInds,thisEvent];
                ERPMatrix(ERPiter,:)=thisEventERP;
                ERPiter=ERPiter+1;
            end
            
        end
        
    else
        rejectedEvents = [rejectedEvents,eventArray(thisEvent)];
        rejectedEventInds = [rejectedEventInds,thisEvent];
        if verbose
            fprintf('Event #%i (%i) is outside of ERP range \n', ...
                thisEvent, eventArray(thisEvent));
        end
    end
        
end

if ~exist('ERPMatrix','var')
    if verbose
        disp('No valid events were found. Returning empty array');
    end
    ERPMatrix = [];
end