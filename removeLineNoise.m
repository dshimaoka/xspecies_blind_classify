function [data_c, data_fit] = removeLineNoise(data, params)
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

data_c = zeros(size(data_r));
data_fit = zeros(size(data_r));

for r = 1 : size(data_r, 2)
    %[cl_data, datafit] = rmlinesmovingwinc(data_r(:, r), params.win, [], params, [], [], params.removeFreq);
    cl_data = rmlinesc(data_r(:, r), params, [], [], params.removeFreq);
    datafit = fitlinesc(data_r(:, r), params, [], [], params.removeFreq);
    data_c(:, r) = cl_data;
    data_fit(:, r) = datafit;
end

% Reshape to match original dimensions
data_c = reshape(data_c, dims);
data_fit = reshape(data_fit, dims);
end
