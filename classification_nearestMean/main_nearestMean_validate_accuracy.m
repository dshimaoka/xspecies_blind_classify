%% Description

%{

Apply thresholds obtained from test dataset to validation dataset(s)

%}

%% Settings

val_set = 'validate1';

%class_type = 'nearestMean'; % nearest mean classification
class_type = 'nearestMedian'; % nearest median classification

preprocess_string = '_subtractMean_removeLineNoise';

source_dir = ['../hctsa_space' preprocess_string '/'];
source_prefix = ['HCTSA_' val_set];

pred_dir = ['results' preprocess_string '/'];
pred_file = ['class_' class_type '_' val_set];

out_dir = ['results' preprocess_string '/'];
out_file = ['class_' class_type '_' val_set '_accuracy.mat'];

addpath('../');
here = pwd;
cd('../'); add_toolbox; cd(here);

%% Load predictions

load([pred_dir pred_file]);

%% Load labelled data and dimensions

% Get data dimensions
data_dir = '../data/preprocessed/';
data_file = 'fly_data_removeLineNoise.mat';
data_ref = load([data_dir data_file]);

% Get labels
label_dir = '../data/labelled/';
label_file = 'labelled_data_01.mat';
data_labels = load([label_dir label_file]);

%% Get labels

% Convert string labels wake/anesthesia to binary 1/0
labels = {data_labels.labelled_shuffled_data.TrialType};
labels = cellfun(@(x) strcmp(x, 'Wake'), labels);

% Repeat labels as required to match divided epochs
nEpochs = size(data_ref.data.(val_set), 3);
labels = repmat(labels, [nEpochs 1]); % assumes labels is (1 x N)
labels = labels(:);

% Repeat labels for each feature and channel
%   (time-series x features x channels)
labels = repmat(labels, [1 size(predictions, 2) size(predictions, 3)]);

%% Check accuracy

correct = predictions == labels;
accuracies = squeeze(sum(correct, 1) ./ size(correct, 1))'; % (channels x features)

% Format to save dims as training CV set
%   predictions - (ch x f x cv x cond x epoch)
%   labels - (ch x f x cv x cond x epoch)
%   accuracies - (ch x f x cv)
predictions = permute(predictions, [3 2 4 5 1]);
labels = permute(labels, [3 2 4 5 1]);

%% Save

save([out_dir out_file], 'predictions', 'labels', 'accuracies');
