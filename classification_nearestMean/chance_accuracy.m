%% Description

%{

Get chance accuracy distribution

%}

%% Settings

class_set = 'crossValidation';
%class_set = 'validate1_accuracy';

source_file = ['class_nearestMean_' class_set '.mat'];
source_dir = 'results/';

out_dir = 'results/';
out_file = ['class_random_' class_set '.mat'];

hctsa_prefix = '../hctsa_space/HCTSA_train';

%% Load

% Accuracies
acc = load([source_dir source_file]);

%% Chance distribution

% Correct labels
%   Note - from the classification script, class 1 has label 1 and class 2
%       has label 0, but order of correct labels here probably doesn't
%       matter
dims = size(acc.predictions); % channels x features x flies x conditions x epochs

if size(acc.predictions, 4) == 1
    % Dimension 4 corresponds to classes
    labels = zeros(dims(4), dims(5));
    labels(1, :) = 1;
    labels = repmat(labels, [1 1 dims(1:3)]);
    labels = permute(labels, [3 4 5 1 2]);
else
    % Use existing labels from file
    labels = acc.labels;
end

% Random predictions for all features, cross-validations
nPredictions = numel(acc.predictions);
classes = unique(acc.predictions);
predictions_random = randsample(classes, nPredictions, true);
predictions_random = reshape(predictions_random, size(acc.predictions));

% Check accuracy
correct = predictions_random == labels;
accuracies_random = sum(correct, 5); % across epochs
accuracies_random = sum(accuracies_random, 4) ./ (dims(4)*dims(5)); % accuracy across conditions
accuracies_random = mean(accuracies_random, 3); % averace across cross-validations

%% Save

save([out_dir out_file], 'accuracies_random');