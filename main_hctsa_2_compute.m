function [] = main_hctsa_2_compute(hctsa_mat)
% Compute HCTSA features on initialised HCTSA matrices
%
% Inputs:
%   hctsa_mat = string; initialised HCTSA .mat file

hctsa_dir = 'hctsa_space_subtractMean_removeLineNoise/';

nCores = feature('numcores');
parpool(nCores);

tic;
TS_Compute(true, [], [], [], [hctsa_dir hctsa_mat]);
toc

end