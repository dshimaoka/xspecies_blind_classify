%
% train nearest median classifier & evaluate with the same or other channels and obtain consistency metric
%
% run after main_hctsa_3_postProcess.m(?)
%
% created from awake_unconscious_human_stats.m

if isempty(getenv('COMPUTERNAME'))
    [~,narrays] = getArray('script_NMclassification.sh');
else
    narrays = 1;
end

%% draw slurm ID for parallel computation specifying ROI position
pen = getPen;

%% Settings
add_toolbox;
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';

species_train = 'human';
subject_train = '376';
species_validate = 'macaque';%'human';
subject_validate = 'George';%'376';


load_dir_train = fullfile(dirPref.rootDir, 'preprocessed',species_train,subject_train);
hctsa_dir_train = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species_train,subject_train);
load_dir_validate = fullfile(dirPref.rootDir, 'preprocessed',species_validate,subject_validate);
hctsa_dir_validate = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species_validate,subject_validate);

save_dir = fullfile(dirPref.rootDir, ['results' preprocessSuffix]);
if ~exist(save_dir, 'dir')
    mkdir(save_dir);
end

%% load channels to process
load(fullfile(load_dir_train,['detectChannels_' subject_train]) ,'tgtChannels');
tgtChannels_train = tgtChannels;
load(fullfile(load_dir_validate,['detectChannels_' subject_validate]) ,'tgtChannels');
tgtChannels_validate = tgtChannels;
clear  tgtChannels;

tgtIdx = 1:numel(tgtChannels_train)*numel(tgtChannels_validate);
maxJID = numel(pen:narrays:numel(tgtIdx));

errorID = [];
for JID = 1:maxJID

    chIdx_total = tgtIdx(pen + (JID-1)*narrays);
    [ii,jj] = ind2sub([numel(tgtChannels_train) numel(tgtChannels_validate)], chIdx_total);
    disp([num2str(JID) '/' num2str(maxJID)]);

    try

        ch_train = tgtChannels_train(ii);
        file_string_train = fullfile(hctsa_dir_train,  sprintf('%s_%s_ch%03d_hctsa', species_train, subject_train, ch_train));
        %trainData = matfile(file_string_train, 'Writable', false);
        trainData = load([file_string_train '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');


        ch_validate = tgtChannels_validate(jj);
        file_string_validate = fullfile(hctsa_dir_validate,  sprintf('%s_%s_ch%03d_hctsa', species_validate, subject_validate, ch_validate));
        %validateData = matfile(file_string_validate, 'Writable', false);
        validateData = load([file_string_validate '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

        out_file = fullfile(save_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy', ...
            species_train, subject_train, ch_train,...
            species_validate,subject_validate, ch_validate));

        %% nearest-median classification w cross-validation
        classifier_cv =  NMclassifier_cv(trainData, validateData);

        %% getConsistency
        [consisetencies, consistencies_random] = getConsistency(trainData.TS_DataMat, trainData.TimeSeries, {'awake','unconscious'});

        %% stats
        accuracy = mean(classifier_cv.accuracy_validate,2)';
        accuracy_rand = mean(classifier_cv.accuracy_validate_rand,2)';
        [nsig_accuracy, p_accuracy, p_fdr_accuracy] = get_sig_features(accuracy, accuracy_rand, classifier_cv.validFeatures);

        consistency = mean(consisetencies, 3);
        consistency_rand = mean(consistencies_random,3);
        [nsig_consistency,p_consistency,p_fdr_consistency] = get_sig_features(consistency, consistency_rand, classifier_cv.validFeatures);

        save(out_file, 'classifier_cv',"p_fdr_consistency","p_consistency","p_fdr_accuracy",...
            "p_accuracy","consisetencies",'consistencies_random','nsig_consistency',"nsig_accuracy");

        clear validateData

    catch err
        errorID = [errorID; JID];
    end
end

disp('error ID:')
disp(errorID);
