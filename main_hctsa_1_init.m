%% Description

%{

Extract time series features and append to "(species)_(subject)_(channel)"
Apply initialization and save as "(species)_(subject)_(channel)_hctsa"

Run this after preprocess_kirill.m

%}

%% Settings
addDirPrefs_COS;
preprocessSuffix = '_subtractMean_removeLineNoise';
dirPref = getpref('cosProject','dirPref');
species = 'macaque';%'human';
subject = 'George';%'376';
load_dir = fullfile(dirPref.rootDir, 'preprocessed',species,subject);
save_dir = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species,subject);
if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end

    
%% load channels to process
load(fullfile(load_dir,['detectChannels_' subject]) ,'tgtChannels');

for ich = 1:numel(tgtChannels)
    disp([num2str(ich), '/' num2str(numel(tgtChannels))]);

    thisCh = tgtChannels(ich);

    savedata_prefix = sprintf('%s_%s_ch%03d', species, subject, thisCh);
    loadName = fullfile(load_dir, [savedata_prefix preprocessSuffix '.mat']);
    hctsaName = fullfile(save_dir, [savedata_prefix '_hctsa.mat']);
    
    loaded = load(loadName);
    data = loaded.data;

    %% Setup for HCTSA - training set
    % Reformat into series x time matrix

    % Training dataset
    data_set = data.data_proc; % time x trials x conditions
    % Get labels for each time-series
    %   dimensions - (channels x trials x flies x conditions)
    dims = size(data_set);
    ids = cell(dims(2:end)); % details of each time-series
    for tr = 1 : dims(2)
        for c = 1 : dims(3)
            ids{tr, c} = ['subject:' data.subject ',channel:' num2str(thisCh) ',epoch:' num2str(tr) ',state:' data.state{c}...
                ',anesthetic:'  data.anesthetic  ',dose:' num2str(data.dose(c) ) ',lobe:' char(data.lobe) ',sex:' data.sex ',age:' num2str(data.age) ];
        end
    end

    % Reformat to (series x time)
    data_set = permute(data_set, [2 3 1]); % trials x conditions x time
    data_set = reshape(data_set, [prod(dims(2:end)) dims(1)]); % Collapse all dimensions other than time
    ids = reshape(ids, [prod(dims(2:end)) 1]); % Collapse labels also
    % Create hctsa matrix
    timeSeriesData = data_set;
    labels = ids; % keywords are already unique
    keywords = ids;
    save(loadName, 'timeSeriesData', 'labels', 'keywords','-append');
    tic;
    %TS_Init([out_dir 'train.mat'], [], [], [true, false, false], [out_dir 'HCTSA_train.mat']);
    TS_Init(loadName, 'hctsa', [false, false, false], hctsaName);
    toc
    disp('training set done');
end