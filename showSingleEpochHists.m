function ax = showSingleEpochHists(hctsaData, featureIdx, condNames, ax, nbins, showLabels, hctsaType)
% showSingleEpochHists(trainData, condNames, featureIdx, ax)
if nargin<7
    hctsaType = 'TS_Normalised';
end
if nargin < 6 || isempty(showLabels)
    showLabels = false;
end
if nargin < 5 || isempty(nbins)
    nbins = 10;
end
if nargin < 4 || isempty(ax)
    ax = gca;
end
if nargin < 3
    condNames = {'awake','unconscious'};
end

condTrials = getCondTrials(hctsaData.TimeSeries, condNames);
binedges = linspace(0,1,nbins);
histodata = hctsaData.(hctsaType);
if strcmp(hctsaType, 'TS_DataMat')
    histodata = hctsa2rank(histodata);%convert to rank [0-1]
end
histogram(ax, histodata(condTrials==1, featureIdx), binedges); hold on;
histogram(ax, histodata(condTrials==2, featureIdx), binedges); hold off
xlim([0 1]);

if showLabels
    xlabel(hctsaType); ylabel('#epochs');
    legend(condNames);
end