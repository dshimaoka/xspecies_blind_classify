function [order] = clusterFeatures(data)
%CLUSTERFEATURES
%   Clusters features based on correlation distance (correlation across
%   time-series
%
% Inputs:
%   data = TS_DataMat matrix (time-series x features)
% Outputs:
%   order = ordering of features based on correlation-distance clustering

% Similarity measure - aboslute correlation across rows
%data(isinf(data)) = NaN; % Remove Infs for correlation
% Note - Spearman pairwise can take a long time
fCorr = (corr(data, 'Type', 'Spearman'));
%fCorr = abs(fCorr + fCorr.') / 2; % because corr output isn't symmetric for whatever reason

% Correlation distance
distances = 1 - fCorr;

% Cluster tree
tree = linkage(squareform(distances), 'average'); % note - distances must be pdist vector (treats matrix as data instead of distances)

% Sorted features
f = figure('visible', 'off'); % we want the order, not the actual plot
[h, T, order] = dendrogram(tree, 0);
close(f);

end