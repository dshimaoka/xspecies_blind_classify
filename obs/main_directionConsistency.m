%% Description

%{

Quantify consistency of direction of effect of anesthesia, per fly

%}

%% Settings

preprocess_string = '_subtractMean_removeLineNoise';

source_dir = ['../hctsa_space' preprocess_string '/'];
source_prefix = 'validate1'; % train; validate1

out_dir = ['results' preprocess_string '/'];
out_file = ['consis_nearestMedian_' source_prefix];

thresh_dir = ['results' preprocess_string '/'];
thresh_file = 'class_nearestMedian_thresholds';

addpath('../');
here = pwd;
cd('../'); add_toolbox; cd(here);

%% Keywords for validation datasets

if strcmp(source_prefix, 'validate1')
    kw = load([source_dir 'validate1_labels.mat']);
end

%% Load thresholds

load([thresh_dir thresh_file]);

% Get hctsa dimensions
tic;
tmp = load([source_dir 'HCTSA_' source_prefix '_channel1.mat']);
nRows = size(tmp.TS_DataMat, 1);
nFeatures = size(tmp.TS_DataMat, 2);
toc

% Get data dimensions
[nChannels, nFlies, nConditions, nEpochs] = getDimensions(source_prefix);

%% Effect direction consistency at each fly, channel

% Storage
consistencies = nan(nChannels, nFeatures, nFlies, nEpochs);

for ch = 1 : nChannels
    tic;
    
    % Load HCTSA values for channel
    hctsa = load([source_dir 'HCTSA_' source_prefix '_channel' num2str(ch) '.mat']);
    if exist('kw', 'var')
        hctsa.TimeSeries.Keywords = kw.keywords;
    end
    
    % Get valid features
    %valid_features = getValidFeatures(hctsa.TS_DataMat);
    valid_features = ones(1, size(hctsa.TS_DataMat, 2)); % do for all features
    feature_ids = find(valid_features);
    
    % Find rows corresponding to each class
    %   (assumes 2 classes only)
    class_labels = [1 0]; % 1 = wake; 0 = anest
    class1 = getIds({'condition1'}, hctsa.TimeSeries);
    class2 = ~class1;
    classes = {class1, class2};
    
    for fly = 1 : nFlies
        
        % Find rows corresponding to the fly
        fly_rows = getIds({['fly' num2str(fly)]}, hctsa.TimeSeries);
        
        % Get rows for each class
        rows = cell(size(classes));
        values = cell(size(classes));
        for class = 1 : length(classes)
            rows{class} = classes{class} & fly_rows;
        end
        
        for f = feature_ids
            
            % Get values for each class
            values = cell(size(classes));
            for class = 1 : length(classes)
                values{class} = hctsa.TS_DataMat(rows{class}, f);
            end
            
            % Get direction of effect (from training data???)
            direction = directions(ch, f);
            
            % Flip epoch values to always test class1 > class2
            if direction == 0
                values = cellfun(@(x) x*-1, values, 'UniformOutput', false);
            end
            
            for epoch = 1 : length(values{1})
                
                % Find proportion of class2 epochs which are in the same
                % direction as the trained direction
                greater = values{1}(epoch) > values{2};
                
                consistencies(ch, f, fly, epoch) = sum(greater) / numel(greater);
                
            end
            
        end
    end
    toc
end

%% Save

tic;
save([out_dir out_file], 'consistencies');
toc