%% Description

%{

Conduct nearest mean classification on HCTSA features

%}

%% Settings

%class_type = 'nearestMean'; % nearest mean classification
class_type = 'nearestMedian'; % nearest median classification

source_prefix = 'HCTSA_train';

preprocess_string = '_subtractMean_removeLineNoise';

out_dir = ['results' preprocess_string '/'];
out_file = ['class_' class_type '_crossValidation'];
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

%% Cross-validation at each channel

% Results structure
% channels x features x cross validations x epochs
%   Note - number of valid features can vary across channels
% Need to store - thresholds, directions, predictions, accuracy

thresholds = NaN(nChannels, nFeatures, nFlies);
directions = NaN(nChannels, nFeatures, nFlies);
predictions = NaN(nChannels, nFeatures, nFlies, nConditions, nEpochs);
accuracies = NaN(nChannels, nFeatures, nFlies);

nCores = feature('numcores');
parpool(nCores);

parfor ch = 1 : nChannels
    
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
    
    ch_thresholds = NaN(nFeatures, nFlies);
    ch_directions = NaN(nFeatures, nFlies);
    ch_predictions = NaN(nFeatures, nFlies, nConditions, nEpochs);
    ch_accuracies = NaN(nFeatures, nFlies);
    
    % For each feature, conduct cross-validation
    for f = feature_ids
        tic;
        disp(f);
        for cv = 1 : nFlies
            
            % Leave out one fly for testing
            test_set = getIds({['fly' num2str(cv)]}, hctsa.TimeSeries);
            train_set = ~test_set;
            
            % Get means for each class
            centres = NaN(size(classes));
            for c = 1 : length(classes)
                class_rows = train_set & classes{c};
                if strcmp(class_type, 'nearestMean')
                    centres(c) = nanmean(hctsa.TS_DataMat(class_rows, f), 1);
                elseif strcmp(class_type, 'nearestMedian')
                    centres(c) = nanmedian(hctsa.TS_DataMat(class_rows, f), 1);
                end
            end
            
            if any(isnan(centres))
                x=1;
            end
            
            % Get threshold and direction based on centres
            %   direction: 1 means class 1 centre >= class 2 centre
            %   direction: 0 means class 1 centre < class 2 centre
            direction = centres(1) >= centres(2);
            threshold = sum(centres(:)) / numel(centres(:));
            
            % Classify test set
            correct_total = 0;
            guesses_total = 0;
            for c = 1 : length(classes)
                class_rows = test_set & classes{c};
                
                % Make predictions
                prediction = hctsa.TS_DataMat(class_rows, f) >= threshold;
                if direction == 0
                    % flip if class 1 centre < class 2 centre
                    prediction = ~prediction;
                end
                
                % Check accuracy of predictions
                correct = prediction == class_labels(c);
                correct_total = correct_total + sum(correct);
                guesses_total = guesses_total + length(correct);
                
                % Store predictions
                ch_predictions(f, cv, c, :) = prediction;
            end
            
            % Store results (within parfor)
            ch_thresholds(f, cv) = threshold;
            ch_directions(f, cv) = direction;
            ch_accuracies(f, cv) = correct_total / guesses_total;
            
        end
        toc
    end
    
    % Store results (outside parfor)
    thresholds(ch, :, :) = ch_thresholds;
    directions(ch, :, :) = ch_directions;
    accuracies(ch, :, :) = ch_accuracies;
    predictions(ch, :, :, :, :) = ch_predictions;
    
end

%% Save

tic;
save([out_dir out_file], 'thresholds', 'directions', 'accuracies', 'predictions');
toc