function [hctsa] = hctsa_load(hctsa_set, ch, preprocess_string)
%HCTSA_LOAD
% Loads HCTSA files for a given channel
%
% Inputs:
%   hctsa_set = string; train/validate1/validate2
%   ch = scalar; which channel to load for
%   preprocess_string = string; preprocessing stream identifier
%
% Outputs:
%   hctsa = struct containing all hctsa variables from hctsa file

% Paths relative project home directory
source_dir = ['hctsa_space' preprocess_string];

[filepath, filename, ext] = fileparts(mfilename('fullpath'));

data_prefix = fullfile(filepath, source_dir, ['HCTSA_' hctsa_set]);
hctsa = load([data_prefix '_channel' num2str(ch) '.mat']);

% Replace keywords if required
if strcmp(hctsa_set, 'validate1') || strcmp(hctsa_set, 'validate2')
    % Load new keywords
    keywords = load(fullfile(filepath, source_dir, [hctsa_set, '_labels.mat']));
    % Replace existing keywords
    hctsa.TimeSeries.Keywords(:) = keywords.keywords;
end

end