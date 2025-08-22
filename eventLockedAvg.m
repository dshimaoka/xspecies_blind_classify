function [avgPeriEventV, winSamps, periEventV, sortedLabels, uniqueLabels] ...
    = eventLockedAvg(V, t, eventTimes, eventLabels, calcWin, doMedian)
% [avgPeriEventV, winSamps, periEventV, sortedLabels] ...
% = eventLockedAvg(V, t, eventTimes, eventLabels, calcWin)
%
% Inputs: 
%   V: nCells x nTimePoints
%   t: 1 x nTimePoints, the time points of each sample in V
%   eventTimes: 1 x nEvents, the time of each event.  (Nans are omitted in periEventV)
%   eventLabels: 1 x nEvents, the label of each event, e.g. the contrast
%       value or some text label. If this is a cell array, the "tuning curve"
%       will be plotted evenly spaced; if numeric array then these will be the
%       x-axis values of the tuning curve
%   window: 1 x 2, the start and end times relative to the event
%

% Outputs:
%   avgPeriEventV: nEventTypes x nCells x nTimePoints, average temporal
%       components across all events of each type
%   winSamps: labels for the time axis, relative to the event times
%   periEventV: nEvents x nCells x nTimePoints, the temporal components around
%       each event
%   sortedLabels: the labels of the rows of periEventV

if nargin < 6
    doMedian = false;
end

if isempty(eventLabels)
    eventLabels = ones(length(eventTimes),1);
end

t = t(:)'; % make row
eventTimes = eventTimes(:)';
[eventTimes, ii] = sort(eventTimes);
sortedLabels = eventLabels(ii);


nCells = size(V,1);

uniqueLabels = unique(eventLabels);
nConditions = length(uniqueLabels);

Fs = 1/median(diff(t));
winSamps = calcWin(1):1/Fs:calcWin(2);
periEventTimes = bsxfun(@plus, eventTimes', winSamps); % rows of absolute time points around each event

%% only use events whose time window is within the recording 
okEvents = intersect(find(periEventTimes(:,end)<=max(t)), find(periEventTimes(:,1)>=min(t)));
periEventTimes = periEventTimes(okEvents,:);
sortedLabels = sortedLabels(okEvents);

periEventV = zeros(nCells, length(okEvents), length(winSamps));
for s = 1:nCells
    periEventV(s,:,:) = interp1(t, V(s,:), periEventTimes);
end



avgPeriEventV = zeros(nConditions, nCells, length(winSamps));
for c = 1:nConditions
    if iscell(eventLabels)
        thisCondEvents = cellfun(@(x)strcmp(x,uniqueLabels(c)),sortedLabels);
    else
        thisCondEvents = sortedLabels==uniqueLabels(c);
    end
    if doMedian
        avgPeriEventV(c,:,:) = squeeze(nanmedian(periEventV(:,thisCondEvents,:),2));
    else
        avgPeriEventV(c,:,:) = squeeze(nanmean(periEventV(:,thisCondEvents,:),2));
    end
end




periEventV = permute(periEventV, [2 1 3]);
