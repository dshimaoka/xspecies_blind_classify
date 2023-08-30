function [] = main_hctsa_2_compute(hctsa_mat)
% Compute HCTSA features on initialised HCTSA matrices
%
% Inputs:
%   hctsa_mat = string; initialised HCTSA .mat file

data_server = '/fs03/fs11/Daisuke/tmpData/COSproject';
hctsa_dir = fullfile(data_server,'hctsa_space_subtractMean_removeLineNoise/');

nCores = feature('numcores');
parpool(nCores);

tic;
TS_Compute(true, [], [], [], [hctsa_dir hctsa_mat]);
toc

end