%% Description

%{

Get chance accuracy distribution

%}

%% Settings

class_set = 'train';
class_set = 'validate1';

source_file = ['consis_nearestMean_' class_set '.mat'];
source_dir = 'results/';

out_dir = 'results/';
out_file = ['consis_random_' class_set '.mat'];

hctsa_prefix = '../hctsa_space/HCTSA_train';

%% Load

% consistencies
con = load([source_dir source_file]);

%% Chance distribution

dims = size(con.consistencies); % ch x features x flies x epochs

% Assumes equal number of epochs for each class
pool = (0:dims(4)) / dims(4);
consistencies_random = randsample(pool, numel(con.consistencies), true);
consistencies_random = reshape(consistencies_random, dims);

%% Save

save([out_dir out_file], 'consistencies_random');