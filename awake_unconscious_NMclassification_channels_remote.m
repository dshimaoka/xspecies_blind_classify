%
% train nearest median classifier & evaluate with the same or other channels and obtain consistency metric
% this script uses parfor in NMclassifier_cv.m
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
add_toolbox_COS;
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
doTrain = true;%false;
ncv = 10;
species_train = 'macaque';
subject_train = 'George';
species_validate = 'macaque';%
subject_validate = 'George';%

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

tgtIdx  = 1:numel(tgtChannels_train)*numel(tgtChannels_validate);
% tgtIdx = detectNGidx_NMclassification(save_dir, species_train, subject_train, tgtChannels_train, ...
%      species_validate, subject_validate, tgtChannels_validate);

maxJID = numel(pen:narrays:numel(tgtIdx));

errorID = [];
for JID = 1:maxJID

    chIdx_total = tgtIdx(pen + (JID-1)*narrays);
    [ii,jj] = ind2sub([numel(tgtChannels_train) numel(tgtChannels_validate)], chIdx_total);
    disp([num2str(JID) '/' num2str(maxJID)]);

    try

        ch_train = tgtChannels_train(ii);
        ch_validate = tgtChannels_validate(jj);
        out_file = fullfile(save_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy', ...
            species_train, subject_train, ch_train,...
            species_validate,subject_validate, ch_validate));
      
        if doTrain
        file_string_train = fullfile(hctsa_dir_train,  sprintf('%s_%s_ch%03d_hctsa', species_train, subject_train, ch_train));
        trainData = load([file_string_train '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

        file_string_validate = fullfile(hctsa_dir_validate,  sprintf('%s_%s_ch%03d_hctsa', species_validate, subject_validate, ch_validate));
        validateData = load([file_string_validate '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

        %% nearest-median classification w cross-validation
        [classifier_cv, fig] =  NMclassifier_cv(trainData, validateData, ncv);
        set(fig,'Position',[0 0 1000 500]);
        screen2png(out_file, fig);
        close(fig);

        %% getConsistency
        [consisetencies, consistencies_random] = getConsistency(trainData.TS_DataMat, trainData.TimeSeries, {'awake','unconscious'});

        %% stats
        accuracy = mean(classifier_cv.accuracy_validate,2)';
        accuracy_rand = mean(classifier_cv.accuracy_validate_rand,2)';
        [nsig_accuracy, p_accuracy, p_fdr_accuracy_th] = get_sig_features(accuracy, accuracy_rand, classifier_cv.validFeatures);

        consistency = mean(consisetencies, 3);
        consistency_rand = mean(consistencies_random,3);
        [nsig_consistency,p_consistency,p_fdr_consistency_th] = get_sig_features(consistency, consistency_rand, classifier_cv.validFeatures);
        

        save(out_file, 'classifier_cv',"p_fdr_consistency_th","p_consistency","p_fdr_accuracy_th",...
            "p_accuracy","consisetencies",'consistencies_random','nsig_consistency',"nsig_accuracy");
        else
            load(out_file);
            p_fdr_consistency_th = p_fdr_consistency;
            p_fdr_accuracy_th = p_fdr_accuracy;
            save(out_file, 'classifier_cv',"p_fdr_consistency_th","p_consistency","p_fdr_accuracy_th",...
            "p_accuracy","consisetencies",'consistencies_random','nsig_consistency',"nsig_accuracy");
        end

        
        clear validateData trainData 'classifier_cv' "p_fdr_consistency_th" "p_consistency" "p_fdr_accuracy_th"...
            "p_accuracy" "consisetencies" 'consistencies_random' 'nsig_consistency' "nsig_accuracy"

    catch err
        errorID = [errorID; JID];
        err
    end
end

disp('error ID:')
disp(errorID);
