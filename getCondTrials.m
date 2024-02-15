function condTrials = getCondTrials(TimeSeries, condNames)
%condTrials = getCondTrials(TimeSeries, condNames)

if nargin < 2
condNames = {'awake','unconscious'};
end
condTrials = nan(size(TimeSeries,1),1);
for icond =1:numel(condNames)
    condTrials(find(contains(TimeSeries.Name, condNames{icond}))) = icond;
end