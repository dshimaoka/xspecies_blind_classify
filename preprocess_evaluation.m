%% Description

%{

Data pre-processing for evaluation data
    multi-dosage flies (N=10)
    single-dosage flies (N=18)
    sleep flies (N=19)

Line noise removal

Based on preprocess.m (corresponding preprocess script for discovery and
pilot evaluation flies)

Note - extra preprocessing steps required for single-dosage and sleep flies
    Bipolar rereference (ch1 minus ch2, ch2 minus ch3), ch1 is most central

%}

%%

clear tmp

%% Common parameters

sample_rate = 1000;

params = struct();
params.Fs = sample_rate;
params.tapers = [5 9];
params.pad = 2;
params.removeFreq = [];

data = struct();

% For keeping track if the datasets have been rereferenced
%   0 = not rereferenced; 1 = rereferenced
%   Position 1 is for single-dosage set; position 2 is for sleep set
reref_flags = nan(2, 1);

%% Load data - Multi-dosage flies

% Multi-dosage flies
%   Note - dataset has 2 files
source_files = {'data/labelled_data_1_selected.mat', 'data/labelled_data_2_selected.mat'};
for f = 1 : length(source_files)
    tmp{f} = load(source_files{f});
    tmp_ordered{f} = tmp{f}.(['labelled_ordered_data_' num2str(f)]);
end
data.multidose = [tmp_ordered{:}]; % join parts together

%% Find which flies the pilot evaluation flies are

pilot_eval = load('data/labelled/labelled_data_01.mat');

ref = nan(numel(pilot_eval.labelled_ordered_data(1).data), length(pilot_eval.labelled_ordered_data));
for i = 1 : size(ref, 2)
    ref(:, i) = pilot_eval.labelled_ordered_data(i).data(:);
end

check = nan(size(ref, 1), length(data.multidose));
for i = 1 : size(check, 2)
    check(:, i) = data.multidose(i).data(:);
end

match = corr(ref, check);

% Fly 2 in pilot evaluation seems to match Fly 11 in the full set
%   Matches both wake and anaesthesia, iso A corresponds to iso 0.6
% Fly 1 in pilot evaluation matches Fly 12 in full set
%   Wake matches with wake
%   BUT iso A doesn't match with anything...?

%% Load data - Single-dosage flies

source_file = 'data/merge_table.mat';
tmp = load(source_file);
data.singledose = tmp.merge_table;
reref_flag(1) = 0;

%% Load data - Sleep flies

source_file = 'data/LFP_data.mat';
tmp = load(source_file);
data.sleep = tmp.LFP_data;
reref_flag(2) = 0;

%% Preprocess - bipolar rereference
% Note - assumes channel 1 is the most central channel
% Assumes LFP data is always (ch x time)

% Which datasets need to be processed
process_sets = {'singledose', 'sleep'};

% Field names corresponding to LFP to be processed for each dataset
data_fields = {'pre_visual_lfp', 'LFP'};

for dset = 1 : length(process_sets)
    if reref_flag(dset) == 0
        for chunk = 1 : length(data.(process_sets{dset}))
            data.(process_sets{dset})(chunk).(data_fields{dset}) = ...
                data.(process_sets{dset})(chunk).(data_fields{dset})(1:end-1, :) - ...
                data.(process_sets{dset})(chunk).(data_fields{dset})(2:end, :);
        end
        reref_flag(dset) = 1;
    end
end

data_original = data;

%% Inspect power spectra of some epoch
% Expecting line noise peak at 50Hz

% Visually apparent line noise in sleep data, row 3

row = 3;

[powers, faxis] = getPower(data.sleep(row).LFP', params);

figure;
plot(faxis, mean(log(powers), 2));
xlim([0 100]);

%% Separate out epochs and channels
% Meanwhile, might as well make the format ready for HCTSA's TS_Init()

epoch_length = 2250; % 2.25s @ 1000Hz, based on discovery fly data format

process_sets = {'multidose', 'singledose', 'sleep'};
data_fields = {'data', 'pre_visual_lfp', 'LFP'};
flyID_fields = {'fly_ID', 'fly_number', 'fly_num'};
condition_fields = {'TrialType', 'trial_type', 'status'};

% If there are multiple chunks with the same info
multi_segments = [1 0 0];

data_split = struct();
for dset = 1 : length(process_sets)
    
    data_split.(process_sets{dset}).data = {};
    data_split.(process_sets{dset}).labels = {};
    data_split.(process_sets{dset}).keywords = {};
    
    for chunk = 1 : length(data.(process_sets{dset}))
        
        % Chunk fly ID
        flyID = data.(process_sets{dset})(chunk).(flyID_fields{dset});
        
        % Chunk condition
        condition = data.(process_sets{dset})(chunk).(condition_fields{dset});
        if dset == 2
            % note - singledose has cell arrays (of size 1) containing the
            % string, instead of directly storing the string...
            condition = condition{1};
        end
        condition = strrep(condition, ' ', '_'); % replace spaces with underscore
        
        % Chunk number
        segment = nan;
        if multi_segments(dset) == 1
            segment = data.(process_sets{dset})(chunk).chunk_number;
        end
        
        % Chunk data
        chunk_data = data.(process_sets{dset})(chunk).(data_fields{dset}); % should be channels x time
        
        % Find number of epochs which can be extracted from the chunk
        nEpochs = floor(size(chunk_data, 2) / epoch_length);
        
        % Separate out epochs (output - cell array (epochs x channels)
        chunk_data = chunk_data(:, 1:nEpochs*epoch_length);
        chunk_data = mat2cell(chunk_data, ones(1, size(chunk_data, 1)), ones(1, nEpochs)*epoch_length);
        
        % Generate labels for chunk
        chunk_labels = cell(size(chunk_data));
        chunk_keywords = cell(size(chunk_data));
        for ch = 1 : size(chunk_data, 1)
            for epoch = 1 : size(chunk_data, 2)
                label = [...
                    'fly' num2str(flyID) ...
                    ',channel' num2str(ch) ...
                    ',epoch' num2str(epoch) ...
                    ',condition' condition];
                if multi_segments(dset) == 1
                    label = [label ',segment' num2str(segment)];
                end
                chunk_labels{ch, epoch} = label;
                chunk_keywords{ch, epoch} = label;
            end
        end
        
        % Combine epoch and channel dimensions
        chunk_data = chunk_data(:);
        chunk_labels = chunk_labels(:);
        chunk_keywords = chunk_keywords(:);
        
        % Store
        data_split.(process_sets{dset}).data = cat(1, data_split.(process_sets{dset}).data, chunk_data);
        data_split.(process_sets{dset}).labels = cat(1, data_split.(process_sets{dset}).labels, chunk_labels);
        data_split.(process_sets{dset}).keywords = cat(1, data_split.(process_sets{dset}).keywords, chunk_keywords);
        
    end
    
    % Tranpose dimensions (from ch x time) to (time x ch)
    data_split.(process_sets{dset}).data = cellfun(@(x) permute(x, [2 1]),...
        data_split.(process_sets{dset}).data, 'UniformOutput', false);
    
end

data = data_split;

%% Inspect power spectra of some epoch
% Expecting line noise peak at 50Hz

% Visually apparent line noise in sleep data, row 500

row = 500;

[powers, faxis] = getPower(data_split.sleep.data{row}, params);

figure;
plot(faxis, mean(log(powers), 2));
xlim([0 100]);

%% Preprocessing

preprocess_string = ''; % To keep track of preprocessing

%% Subtract mean from each epoch

process_sets = {'multidose', 'singledose', 'sleep'};

s_subtractMean = 1;

if s_subtractMean == 1
    
    for dset = 1 : length(process_sets)
        for epoch = 1 : length(data.(process_sets{dset}).data)
            data.(process_sets{dset}).data{epoch} = data.(process_sets{dset}).data{epoch} - mean(data.(process_sets{dset}).data{epoch});
        end
    end
    
    preprocess_string = [preprocess_string '_subtractMean'];
end

%% Remove line noise

process_sets = {'multidose', 'singledose', 'sleep'};

s_lineNoise = 1;

if s_lineNoise == 1
    
    for dset = 1 : length(process_sets)
        tic
        for epoch = 1 : length(data.(process_sets{dset}).data)
            [data.(process_sets{dset}).data{epoch}, ~] = removeLineNoise(data.(process_sets{dset}).data{epoch}, params);
        end
        toc;
    end
    
    preprocess_string = [preprocess_string '_removeLineNoise'];
end

%% Inspect power spectra of some epoch
% Expecting line noise from previous to be removed

% Visually apparent line noise (before removal) in sleep data, row 500

row = 500;

[powers, faxis] = getPower(data.sleep.data{row}, params);

figure;
plot(faxis, mean(log(powers), 2));
xlim([0 100]);

%% Save

data.preprocess_params = params;
data.preprocess_string = preprocess_string;

out_dir = 'data/preprocessed/';
out_file = ['flyEvaluation_data' preprocess_string];
tic;
save([out_dir out_file], 'data', '-v7.3', '-nocompression');
toc
disp(['data saved: ' out_dir out_file]);
