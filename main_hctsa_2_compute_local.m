%compute hctsa_2 using local resources
%31/8/23 created from main_hctsa_2_compute.m
%
% run this after save_perchannel_test.m

data_server = '/mnt/dshi0006_market/Massive/COSproject';
hctsa_dir = fullfile(data_server,'hctsa_space_subtractMean_removeLineNoise/');
%hctsa_mat = 'HCTSA_validate1_ch65.mat';

nCores = feature('numcores');
p = gcp('nocreate');
if isempty(p)
    parpool(nCores);
end

add_toolbox; %this is critical to run TS_Compute successfully

load('selectedCh_20230909','selectedCh');

for ich = 15:numel(selectedCh)
    tic;
    TS_Compute(true, [], [], [], [hctsa_dir sprintf('HCTSA_train_ch%d.mat', selectedCh(ich))]);
    toc

    tic;
    TS_Compute(true, [], [], [], [hctsa_dir sprintf('HCTSA_validate1_ch%d.mat', selectedCh(ich))]);
    toc
end