function [powers, faxis] = getPower(data, params)
% Inputs:
%   data = matrix (time x repeat-dimensions...)
%       repeat-dimensions can be any set of dimensions
%   params = struct; Chronux params
%
% Outputs:
%   powers = matrix (frequencies x repeat-dimensions...)
%   faxis = vector of frequencies for power spectrum

dims = size(data);
data_r = reshape(data, [dims(1) prod(dims(2:end))]);

% Create storage matrix (figure out how many freqs)
[fpower, faxis] = mtspectrumc(data_r(:, 1), params);
powers = zeros(length(faxis), size(data_r, 2));

% Chronux multi-taper spectrum
for r = 1 : size(data_r, 2)
    [fpower, faxis] = mtspectrumc(data_r(:, r), params);
    powers(:, r) = fpower;
end

% Reshape to match original dimensions
powers = reshape(powers, [length(faxis) dims(2:end)]);
end
