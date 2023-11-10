%compute hctsa_2 on "(species)_(subject)_(channel)_hctsa" using local resources
%
% run this after main_hctsa_1_init.m

%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
species = 'macaque';%'human';
subject = 'George';%'376';
preprocessSuffix = '_subtractMean_removeLineNoise';
load_dir = fullfile(dirPref.rootDir, 'preprocessed',species,subject);
save_dir = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species,subject);

%data_server = '/mnt/dshi0006_market/Massive/COSproject';
%hctsa_dir = fullfile(data_server,'hctsa_space_subtractMean_removeLineNoise/');
%hctsa_mat = 'HCTSA_validate1_ch65.mat';

%% load channels to process
load(fullfile(load_dir,['detectChannels_' subject]) ,'tgtChannels');
%load('selectedCh_20230909','selectedCh');


%% prepare parallel computation
nCores = feature('numcores');
p = gcp('nocreate');
if isempty(p)
    parpool(nCores);
end
add_toolbox; %this is critical to run TS_Compute successfully

%human: 3h per channel (200ms x 400 trials)
for ich = 1:numel(tgtChannels)
    disp([num2str(ich), '/' num2str(numel(tgtChannels))]);
    thisCh = tgtChannels(ich);

     savedata_prefix = sprintf('%s_%s_ch%03d', species, subject, thisCh);
    hctsaName = fullfile(save_dir, [savedata_prefix '_hctsa.mat']);

    tic;
    TS_Compute(true, [], [], [], hctsaName);
    t = toc
end
