
%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
species = 'human';
subject = '376';
preprocessSuffix = '_subtractMean_removeLineNoise';
load_dir = fullfile(dirPref.rootDir, 'preprocessed',species,subject);
hctsa_dir = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species,subject);

save_dir = fullfile(dirPref.rootDir, ['results' preprocessSuffix]);
mkdir(save_dir);

%% load channels to process
load(fullfile(load_dir,['detectChannels_' subject]) ,'tgtChannels');

for ii = 1:numel(tgtChannels)
    for jj = 1:numel(tgtChannels)

        disp([num2str(ii) '_' num2str(jj)]);
        
        ch_train = tgtChannels(ii);
        ch_validate = tgtChannels(jj);

        file_string_train = fullfile(hctsa_dir,  sprintf('%s_%s_ch%03d_hctsa', species, subject, ch_train));
        trainData = matfile(file_string_train, 'Writable', false);

        file_string_validate = fullfile(hctsa_dir,  sprintf('%s_%s_ch%03d_hctsa', species, subject, ch_validate));
        validateData = matfile(file_string_validate, 'Writable', false);

        out_file = fullfile(save_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy', species, subject, ch_train,...
            species,subject, ch_validate));

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

        clear trainData validateData
    end
end
