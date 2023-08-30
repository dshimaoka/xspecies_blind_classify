function [ch_valid_features, ch_excluded, valid_perStage] = getValidFeatures_allChannels(data_set, preprocess_string)
%GETVALIDFEATURES_ALLCHANNELS
%   Gets valid features for all channels
%
% Inputs:
%   data_set = 'train' or 'validate1'
%   preprocess_string = string; preprocessing stream identifier
% Outputs:
%   ch_valid_features = matrix (channels x features)
%   ch_excluded = matrix (channels x 2); gives number of additional
%       features excluded at each stage
%   valid_perStage = logical matrix (channels x features x stages);
%       holds valid features IDs at each stage, independent from previous 
%       stages

disp(['Getting valid features for all channels in ' data_set]);

% TODO - get these from some initial file
nChannels = 15;
nFeatures = 7702; 

% Files are relative to this function file
source_dir = ['hctsa_space' preprocess_string];
[filepath, filename, ext] = fileparts(mfilename('fullpath'));
hctsa_prefix = fullfile(filepath, source_dir, ['HCTSA_' data_set]);

ch_valid_features = nan(nChannels, nFeatures);
ch_excluded = zeros(nChannels, 2); % 2 exclusion stages
valid_perStage = nan(nChannels, nFeatures, 2);

for ch = 1 : nChannels
    tic;
    hctsa = load([hctsa_prefix '_channel' num2str(ch) '.mat']);
    [valid_ids, nExclude, ids_per_stage] = getValidFeatures(hctsa.TS_DataMat);
    ch_valid_features(ch, :) = valid_ids; % store
    ch_excluded(ch, :) = nExclude;
    valid_perStage(ch, :, :) = ids_per_stage;
    fprintf('ch%d: ', ch);
    toc
end

end

