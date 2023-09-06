%compute hctsa_2 using local resources
%31/8/23 created from main_hctsa_2_compute.m

data_server = '/mnt/dshi0006_market/Massive/COSproject';
hctsa_dir = fullfile(data_server,'hctsa_space_subtractMean_removeLineNoise/');
hctsa_mat = 'HCTSA_validate1_ch10.mat';

nCores = feature('numcores');
p = gcp('nocreate');
if isempty(p)
    parpool(nCores);
end

add_toolbox;

tic;
TS_Compute(true, [], [], [], [hctsa_dir hctsa_mat]);
toc