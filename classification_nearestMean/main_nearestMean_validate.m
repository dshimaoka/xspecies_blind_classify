%% Description

%{

Apply thresholds obtained from test dataset to validation dataset(s)

%}

%% Settings

%class_type = 'nearestMean'; % nearest mean classification
class_type = 'nearestMedian'; % nearest median classification

preprocess_string = '_subtractMean_removeLineNoise';

source_dir = ['../hctsa_space' preprocess_string '/'];
source_prefix = 'HCTSA_validate1';

out_dir = ['results' preprocess_string '/'];
out_file = ['class_' class_type '_validate1'];

thresh_dir = ['results' preprocess_string '/'];
thresh_file = ['class_' class_type '_thresholds'];

addpath('../');
here = pwd;
cd('../'); add_toolbox; cd(here);

%% Load thresholds

load([thresh_dir thresh_file]);

% Get dimensions
tic;
tmp = load([source_dir source_prefix '_channel1.mat']);
nRows = size(tmp.TS_DataMat, 1);
nFeatures = size(tmp.TS_DataMat, 2);
toc

%% Classify validation data

predictions = zeros(nRows, nFeatures, size(thresholds, 1));

for ch = 1 : size(thresholds, 1)
    
    % Load HCTSA values for channel
    hctsa = load([source_dir source_prefix '_channel' num2str(ch) '.mat']);
    
    % Get valid features
    %valid_features = getValidFeatures(hctsa.TS_DataMat);
    valid_features = ones(1, size(hctsa.TS_DataMat, 2)); % do for all features
    feature_ids = find(valid_features);
    
    for f = 1 : size(thresholds, 2)
        tic;
        disp(f);
        
        % Make predictions
        prediction = hctsa.TS_DataMat(:, f) >= thresholds(ch, f);
        if directions(ch, f) == 0
            % flip if class 1 centre < class 2 centre
            prediction = ~prediction;
        end
        
        % Store predictions
        predictions(:, f, ch) = prediction;
        
        toc
    end
end

%% Save

tic;
save([out_dir out_file], 'predictions');
toc