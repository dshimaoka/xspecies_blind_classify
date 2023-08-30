%% Description

%{

% Plot feature matrix for given dataset

%}

%% Settings

preprocess_string = '_subtractMean_removeLineNoise';
source_prefix = 'sleep';

source_dir = ['hctsa_space' preprocess_string '/'];
source_file = ['HCTSA_' source_prefix '_channel6.mat']; % HCTSA_train.mat; HCTSA_validate1.mat;

%% Load

tic;
hctsa = load([source_dir source_file]);
toc

% Note - even with mixedSigmoid, feature 976 (870th valid feature) scales
%   to NaNs and 0s
hctsa.TS_Normalised = BF_NormalizeMatrix(hctsa.TS_DataMat, 'mixedSigmoid');

%% Visualise

% Which set of time series to visualise for
keywords = {'fly1'};
keywords = {}; % everything

% Get corresponding rows
match = getIds(keywords, hctsa.TimeSeries);

% Get valid feature columns
valid_features = true(size(hctsa.TS_DataMat, 2), 1); % everything
valid_features = getValidFeatures(hctsa.TS_DataMat);

valid_cols = hctsa.TS_DataMat(find(match), find(valid_features));

% Sort features by similarity across time series
tic;
fOrder = clusterFeatures(valid_cols);
toc

% Sort rows by similarity across features
tic;
rOrder = clusterFeatures(valid_cols');
toc

% Normalise (note - nan values can occur during normalisation - so cluster
% first!
tic;
vis_rows = hctsa.TS_Normalised(:, valid_features);
toc

%%
figure;
imagesc(vis_rows(rOrder, fOrder));
title([source_file(1:end-4) ' ' strjoin(keywords, ',')], 'Interpreter', 'none');

%%

tmp = BF_NormalizeMatrix(hctsa.TS_DataMat(:, 976), 'robustSigmoid');

%% Manually add axis ticks to delineate groups
% Find a good way of doing this programmatically?

xlabel('feature');

% 13 flies x 8 epochs x 2 conditions
yticks((1 : 8 : 13*8*2));
ystrings = cell(size(yticks));
conds = {'W', 'A'};
y = 1;
for c = 1 : 2
    for f = 1 : 13
        ystrings{y} = ['F' num2str(f) ' ' conds{c}];
        y = y + 1;
    end
end
yticklabels(ystrings);

set(gca, 'TickDir', 'out');

%% Other details

c = colorbar;
ylabel(c, 'norm. value');

colormap inferno

set(gcf, 'Color', 'w');

%% Plot wake-anesthesia consistency matrix

% Get data dimensions
[nChannels, nFlies, nConditions, nEpochs] = getDimensions(source_prefix);

% Get rows corresponding to each condition
class1 = getIds({'condition1'}, hctsa.TimeSeries);
classes = {class1, ~class1}; % two conditions only

%diff_mat = nan(nEpochs*nEpochs*nFlies, size(hctsa.TS_DataMat, 2));
diff_mat = [];

for fly = 1 : nFlies
    % Find rows corresponding to the fly
    fly_rows = getIds({['fly' num2str(fly)]}, hctsa.TimeSeries);
    
    % Get rows for each class for this fly
    rows = cell(size(classes));
    for class = 1 : length(classes)
        rows{class} = find(classes{class} & fly_rows);
    end
    
    % Subtract anest from wake for every pair of epochs
    %vals = nan(nEpochs*nEpochs, 1);
    vals = [];
    for epoch1 = 1 : nEpochs
        epoch_vals = nan(nEpochs, length(find(valid_features)));
        for epoch2 = 1 : nEpochs
            epoch_vals(epoch2, :) = hctsa.TS_Normalised(rows{1}(epoch1), valid_features) - hctsa.TS_Normalised(rows{2}(epoch2), valid_features);
        end
%         if any(isnan(epoch_vals(:)))
%             keyboard;
%         end
        vals = cat(1, vals, epoch_vals);
    end
    diff_mat = cat(1, diff_mat, vals);
end

% Replace nans for that one feature which gets nans after scaling
nan_features = any(isnan(diff_mat), 1);
diff_mat(:, nan_features) = [];

% Sort features by similarity across rows
tic;
fOrder_diff = clusterFeatures(diff_mat);
toc

%% Plot figure

% Can use feature order from raw values
% Only works if there's only one feature in nan_features
fOrder_removed = fOrder;
fOrder_removed(nan_features) = [];
fOrder_removed(fOrder_removed > find(nan_features)) = fOrder_removed(fOrder_removed > find(nan_features)) - 1;

figure;
imagesc(diff_mat(:, fOrder_removed));
title([source_file(1:end-4) ' ' strjoin(keywords, ',')], 'Interpreter', 'none');
colorbar;

%% Figure details

yticks((1 : nEpochs*nEpochs : nEpochs*nEpochs*nFlies));
ystrings = cell(nFlies, 1);
for fly = 1 : nFlies
    ystrings{fly} = ['F' num2str(fly)];
end
yticklabels(ystrings);
set(gca, 'TickDir', 'out');

neg = viridis(256);
pos = inferno(256);
negPos_map = cat(1, flipud(neg(1:128, :)), pos(129:end, :));
negPos_map = flipud(cbrewer('div', 'RdBu', 100));
colormap(negPos_map);