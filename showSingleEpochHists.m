function ax = showSingleEpochHists(hctsaData, featureIdx, condNames, ax, nbins, showLabels)
% showSingleEpochHists(trainData, condNames, featureIdx, ax)

if nargin < 6
    showLabels = false;
end
if nargin < 5
    nbins = 10;
end
if nargin < 4
    ax = gca;
end
if nargin < 3
    condNames = {'awake','unconscious'};
end

condTrials = getCondTrials(hctsaData.TimeSeries, condNames);
binedges = linspace(0,1,nbins);
histogram(ax, hctsaData.TS_Normalised(condTrials==1, featureIdx), binedges); hold on;
histogram(ax, hctsaData.TS_Normalised(condTrials==2, featureIdx), binedges); hold off
xlim([0 1]);

if showLabels
    xlabel('TS_Normalised'); ylabel('#epochs');
    legend(condNames);
end