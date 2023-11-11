%% Description

%{

Get new labels from labelled data

%}

%%

val_set = 'validate1';
preprocess_string = '_subtractMean_removeLineNoise';

%% Load labelled data and dimensions

% Get data dimensions
data_dir = 'data/preprocessed/';
data_file = 'fly_data_removeLineNoise.mat';
data_ref = load([data_dir data_file]);

% Get labels
label_dir = 'data/labelled/';
label_file = 'labelled_data_01.mat';
data_labels = load([label_dir label_file]);

%% Get dimensions

nEpochs = size(data_ref.data.(val_set), 3);

nSegments = length(data_labels.labelled_shuffled_data);
nChannels = size(data_labels.labelled_shuffled_data(1).data, 1);
nFlies = numel(unique([data_labels.labelled_shuffled_data.fly_ID]));
nConditions = numel(unique({data_labels.labelled_shuffled_data.TrialType})); % should be 2

%% Get label csv for each segment

%'fly1,channel1,epoch1,condition1

keywords = cell(1, nSegments); % we will use rows for repeating labels for epochs

for s = 1 : nSegments
    f = data_labels.labelled_shuffled_data(s).fly_ID;
    c = ~strcmp('Wake', data_labels.labelled_shuffled_data(s).TrialType)+1; % 1 if wake, 2 if anesthesia
    keywords{s} = ['fly' num2str(f) ',condition' (num2str(c))]; % ignore channel, as there is one channel per file
end

% Repeat labels as required to match number of divided epochs
keywords = repmat(keywords, [nEpochs 1]);

% Add epoch labels
for e = 1 : nEpochs
    keywords(e, :) = cellfun(@(x) [x ',epoch' num2str(e)], keywords(e, :), 'UniformOutput', false);
end

keywords = keywords(:);

%% Save

save(['hctsa_space' preprocess_string '/validate1_labels.mat'], 'keywords');