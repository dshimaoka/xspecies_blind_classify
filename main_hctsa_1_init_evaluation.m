%% Description

%{

Extract time series features from fly data using hctsa for multidose,
singledose, and sleep evaluation data

%}

%% Settings

out_dir = 'hctsa_space_subtractMean_removeLineNoise/';

%% Load

source_dir = 'data/preprocessed/';
source_file = 'flyEvaluation_data_subtractMean_removeLineNoise';

loaded = load([source_dir source_file]);
data = loaded.data;

%% Multidose

datasets = {'multidose', 'singledose', 'sleep'};

for dset = length(datasets)-2 : -1 : 1
    
    timeSeriesData = data.(datasets{dset}).data;
    labels = data.(datasets{dset}).labels;
    keywords = data.(datasets{dset}).keywords;
    
    save([out_dir datasets{dset} '.mat'], 'timeSeriesData', 'labels', 'keywords');
    tic;
    TS_Init([out_dir datasets{dset} '.mat'], [], [], [false, true, false], [out_dir 'HCTSA_' datasets{dset} '.mat']);
    toc
    
    disp([datasets{dset} 'done']);
    
end