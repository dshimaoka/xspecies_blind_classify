function [data_d] = detrendAll(data)
% Inputs:
%   data = matrix (time x repeat-dimensions...)
%       repeat-dimensions can be any set of dimensions
%   params = struct; Chronux params
%
% Outputs:
%   data_c = matrix (time x repeat-dimensions...)
%       Cleaned data
%   data_fit = matrix (time x repeat-dimensions...)
%       Fitted line noise data (which was removed to obtain data_c

dims = size(data);
data_r = reshape(data, [dims(1) prod(dims(2:end))]);

% Detrend
data_d = detrend(data_r);

% Reshape to match original dimensions
data_d = reshape(data_d, dims);
end