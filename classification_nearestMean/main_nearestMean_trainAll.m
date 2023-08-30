%% Description

%{

Produce nearest mean classifier using all training data

%}

%% Settings

%class_type = 'nearestMean'; % nearest mean classification
class_type = 'nearestMedian'; % nearest median classification

source_prefix = 'HCTSA_train';

preprocess_string = '_subtractMean_removeLineNoise';

out_dir = ['results' preprocess_string '/'];
out_file = ['class_' class_type '_thresholds'];
source_dir = ['../hctsa_space' preprocess_string '/'];

addpath('../');
here = pwd;
cd('../'); add_toolbox; cd(here);

%% Load

% Get dimensions
tic;
tmp = load('../data/preprocessed/fly_data_removeLineNoise.mat');
nChannels = size(tmp.data.train, 2);
nEpochs = size(tmp.data.train, 3);
nFlies = size(tmp.data.train, 4);
nConditions = size(tmp.data.train, 5);
toc

tic;
tmp = load([source_dir source_prefix '_channel' num2str(1) '.mat']);
nFeatures = size(tmp.TS_DataMat, 2);
toc

%% Create classifier at each channel

% Results structure
% channels x features
%   Note - number of valid features can vary across channels
% Need to store - thresholds, directions

thresholds = NaN(nChannels, nFeatures);
directions = NaN(nChannels, nFeatures);

for ch = 1 : nChannels
    
    % Load HCTSA values for channel
    hctsa = load([source_dir source_prefix '_channel' num2str(ch) '.mat']);
    
    % Get valid features
    %valid_features = getValidFeatures(hctsa.TS_DataMat);
    valid_features = ones(1, size(hctsa.TS_DataMat, 2)); % do for all features
    feature_ids = find(valid_features);
    
    % Find rows corresponding to each class
    %   (assumes 2 classes only)
    %classes{1} = getIds({'condition1'}, hctsa.TimeSeries);
    %classes{2} = ~classes{1};
    class_labels = [1 0]; % 1 = wake; 0 = anest
    class1 = getIds({'condition1'}, hctsa.TimeSeries);
    class2 = ~class1;
    classes = {class1, class2};
    
    % For each feature, conduct cross-validation
    for f = feature_ids
        tic;
        disp(f);
        
        % Get means for each class
        centres = NaN(size(classes));
        for c = 1 : length(classes)
            class_rows = classes{c};
            if strcmp(class_type, 'nearestMean')
                centres(c) = mean(hctsa.TS_DataMat(class_rows, f), 1);
            elseif strcmp(class_type, 'nearestMedian')
                centres(c) = median(hctsa.TS_DataMat(class_rows, f), 1);
            end
        end
        
        % Get threshold and direction based on centres
        %   direction: 1 means class 1 centre >= class 2 centre
        %   direction: 0 means class 1 centre < class 2 centre
        direction = centres(1) >= centres(2);
        threshold = sum(centres(:)) / numel(centres(:));
        
        thresholds(ch, f) = threshold;
        directions(ch, f) = direction;
        
        toc
    end
    
end

%% Save

tic;
save([out_dir out_file], 'thresholds', 'directions');
toc