function [nChannels, nFlies, nConditions, nEpochs] = getDimensions(source_prefix)
%GETDIMENSIONS
%   Gets dimensions for the given dataset
%
% Inputs:
%   source_prefix = 'train'; 'validate1', 'validate2'
% Outputs:
%   nChannels
%   nFlies
%   nConditions
%   nEpochs

source_prefix = ['HCTSA_' source_prefix];

if strcmp(source_prefix, 'HCTSA_train')
    tic;
    tmp = load('../data/preprocessed/fly_data_removeLineNoise.mat');
    nChannels = size(tmp.data.train, 2);
    nEpochs = size(tmp.data.train, 3);
    nFlies = size(tmp.data.train, 4);
    nConditions = size(tmp.data.train, 5);
    toc
elseif strcmp(source_prefix, 'HCTSA_validate1')
    % Assumes equal dimensions for all flies, etc.
    tic;
    tmp = load('../data/labelled/labelled_data_01.mat');
    nChannels = size(tmp.labelled_shuffled_data(1).data, 1);
    nFlies = numel(unique([tmp.labelled_shuffled_data.fly_ID]));
    nConditions = numel(unique({tmp.labelled_shuffled_data.TrialType})); % should be 2
    nChunks = numel(unique([tmp.labelled_shuffled_data.chunk_number]));
    tLength = size(tmp.labelled_shuffled_data(1).data, 2);
    tmp = load('../data/preprocessed/fly_data_removeLineNoise.mat');
    nEpochs = nChunks * floor(tLength/size(tmp.data.validate1, 1));
    toc
elseif strcmp(source_prefix, 'HCTSA_validate2')
    % Need to figure out dimensions based on labelled datafile
end

end

