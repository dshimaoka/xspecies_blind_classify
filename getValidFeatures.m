function [ids_valid, nExclude, ids_per_stage] = getValidFeatures(TS_DataMat)
%GETVALIDFEATURES
%
% Exclusion criteria
%   Exclude any feature which has at least 1 NaN value across time series
%   Exclude any feature which has constant values across time series
%
% Inputs:
%   TS_DataMat = HCTSA data matrix (time series x features)
% Outputs:
%   ids_valid = logical vector; 1s indicate valid feature IDs and 0s
%       indicate feature IDs to exclude
%   nExclude = vector (1 x stages); each number indicates number of
%       additional features removed at each exclusion criterion
%   ids_per_stage = logical matrix (channels x features x stages);
%       holds valid features IDs at each stage, independent from previous 
%       stages

% Get feature IDs with NaN
ids_nan = isnan(TS_DataMat);
ids_nan = any(ids_nan, 1);
nExclude(1) = sum(ids_nan);

% Get feature IDs with constant value
ids_const = diff(TS_DataMat, [], 1);
ids_const(isnan(ids_const)) = 0; % treat nans as diff == 0
ids_const = all(~ids_const, 1);
nExclude(2) = sum(~ids_nan & ids_const);

ids_invalid = ids_nan | ids_const;

ids_valid = ~ids_invalid;

ids_per_stage = cat(3, ~ids_nan, ~ids_const);

end