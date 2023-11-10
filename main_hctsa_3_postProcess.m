%% Description

%{

Exclude any feature which has at least 1 NaN value across time series
Exclude any feature which has a constant value across time series

Exclusion is done per channel

% run this after main_hctsa_2
% this script was created from main_hctsa_3_perChannel and
main_hctsa_matrix
%}

%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
species = 'human';
subject = '376';
preprocessSuffix = '_subtractMean_removeLineNoise';
load_dir = fullfile(dirPref.rootDir, 'preprocessed',species,subject);
save_dir = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species,subject);

%% load channels to process
load(fullfile(load_dir,['detectChannels_' subject]) ,'tgtChannels');

%% Re-add special values to TS_DataMat
% Note HCTSA replaces special values with 0
%   https://hctsa-users.gitbook.io/hctsa-manual/setup/hctsa_structure#quality-labels

for ch = tgtChannels
    tic;
    %ch_string = ['ch' num2str(ch)];
    %file_string = [load_dir file_prefix '_' ch_string file_suffix];
     file_string = fullfile(save_dir,  sprintf('%s_%s_ch%03d_hctsa', species, subject, ch));

    hctsa = matfile(file_string, 'Writable', true);
    TS_DataMat = hctsa.TS_DataMat;
    TS_Quality = hctsa.TS_Quality;
    
    % "Fatal" errors - treat as NaN
    TS_DataMat(TS_Quality == 1) = NaN;
    % Special value NaN
    TS_DataMat(TS_Quality == 2) = NaN;
    % Special value Inf
    TS_DataMat(TS_Quality == 3) = Inf;
    % Special value -Inf
    TS_DataMat(TS_Quality == 4) = -Inf;
    % Special value complex
    TS_DataMat(TS_Quality == 5) = NaN;
    % Special value empty
    TS_DataMat(TS_Quality == 6) = NaN;
    
    
    % % Check for other cases
    % if any(TS_Quality(:) > 4)
    %     tmp = unique(TS_Quality(:));
    %     disp([file_string ' TS_Quality ' num2str(tmp)]);
    % end
    
    hctsa.TS_DataMat = TS_DataMat;
    hctsa.TS_Quality = TS_Quality;


    %%  below from main_hctsa_matrix.m
    hctsa.valid_features = getValidFeatures(hctsa.TS_DataMat);

    TS_Normalised = BF_NormalizeMatrix(hctsa.TS_DataMat, 'mixedSigmoid');
    hctsa.TS_Normalised = TS_Normalised;

    toc
end