%
% train nearest median classifier & evaluate with the same or other channels and obtain consistency metric
% this script uses parfor in NMclassifier_cv.m
%
% run after main_hctsa_3_postProcess.m(?)
%
% created from awake_unconscious_human_stats.m

if isempty(getenv('COMPUTERNAME'))
    [~,narrays] = getArray('script_NMclassification.sh');
    %addDirPrefs_COS;  DO NOT ADD THIS IN A BATCH JOB
else
    narrays = 1;
end

%% draw slurm ID for parallel computation specifying ROI position
pen = getPen;

%% Settings
add_toolbox_COS;
dirPref = getpref('cosProject','dirPref');
htcsaType = 'TS_DataMat';
preprocessSuffix = '_subtractMean_removeLineNoise';
svm = true;%false;
ncv = 10;
species_train ='macaque';
subject_train = 'George';
species_validate = 'macaque';%'human';%
subject_validate = 'George';%'376';%
q = 0.01;
refCodeStrings = {'DN_rms', ... %13
    'MF_GP_hyperparameters_covSEiso_covNoise_1_200_resample.logh1'}; %6339

condNames = {'awake','unconscious'};
subjectNames = {['subject:' subject_train], ['subject:' subject_validate]};

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

tgtIdx  = 1:numel(tgtChannels_train);
%tgtIdx  = 1:numel(tgtChannels_train)*numel(tgtChannels_validate);
% tgtIdx = detectNGidx_NMclassification(save_dir, species_train, subject_train, tgtChannels_train, ...
%      species_validate, subject_validate, tgtChannels_validate);

maxJID = numel(pen:narrays:numel(tgtIdx));

errorID = [];
for JID = 1:maxJID

    %chIdx_total = tgtIdx(pen + (JID-1)*narrays);
    %[ii,jj] = ind2sub([numel(tgtChannels_train) numel(tgtChannels_validate)], chIdx_total);
    disp([num2str(JID) '/' num2str(maxJID)]);

    try

        ch_train = tgtChannels_train(JID);
        ch_validate = tgtChannels_validate(JID);
        out_file = fullfile(save_dir, sprintf('%s_train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy', ...
            htcsaType, species_train, subject_train, ch_train, species_validate,subject_validate, ch_validate));

        file_string_train = fullfile(hctsa_dir_train,  sprintf('%s_%s_ch%03d_hctsa', species_train, subject_train, ch_train));
        trainData = load([file_string_train '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

        file_string_validate = fullfile(hctsa_dir_validate,  sprintf('%s_%s_ch%03d_hctsa', species_validate, subject_validate, ch_validate));
        validateData = load([file_string_validate '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

        %% train nearest-median classifier w cross-validation
        [classifier_cv, fig] =  NMclassifier_cv(trainData, validateData, ncv, [], htcsaType);
        set(fig,'Position',[0 0 1000 500]);
        screen2png(out_file, fig);
        close(fig);

        %% show HTCSA barcode
        validFeatures = find(classifier_cv.validFeatures);


        order_f = validFeatures(clusterFeatures(trainData.(htcsaType)(:,validFeatures)));
        
        % fig = showHCTSAbarcodes(trainData.TS_Normalised, trainData.TimeSeries, order_f, [], ...
        %     classifier_cv.operations.CodeString, refCodeStrings);
        % fig2 = showHCTSAbarcodes(validateData.TS_Normalised, validateData.TimeSeries, order_f, [], ...
        %     classifier_cv.operations.CodeString, refCodeStrings);
        % ff= mergefigs([fig fig2]);colormap(ff,"inferno");
        % screen2png([out_file '_HCTSA_barcode.png'],ff);
        % close all
 
        data_all = [trainData.(htcsaType); validateData.(htcsaType) ];
        if strcmp(htcsaType, 'TS_DataMat')
            data_all = hctsa2rank(data_all);
        end
        TimeSeries_all = [trainData.TimeSeries; validateData.TimeSeries];

        subjectEpochs{1} = find(getCondTrials(TimeSeries_all,subjectNames(1))==1);
        subjectEpochs{2} = find(getCondTrials(TimeSeries_all,subjectNames(2))==1);
        order_e_all = clusterFeatures(data_all(:,validFeatures)');
       for itv = 1:2
            for icond = 1:2
                theseEpochs = intersect(subjectEpochs{itv}, find(getCondTrials(TimeSeries_all,condNames(icond))==1));
                [~, order_e{itv,icond}] = sort(order_e_all(theseEpochs));
            end
        end

        fig = showHCTSAbarcodes(data_all(subjectEpochs{1},:),TimeSeries_all(subjectEpochs{1},:), order_f, order_e(1,:), ...
            classifier_cv.operations.CodeString, refCodeStrings);
        fig2 = showHCTSAbarcodes(data_all(subjectEpochs{2},:),TimeSeries_all(subjectEpochs{2},:),  order_f, order_e(2,:), ...
            classifier_cv.operations.CodeString, refCodeStrings);
        ff= mergefigs([fig fig2]);colormap(ff,"inferno");
        screen2png([out_file '_HCTSA_barcode.png'],ff);
        close all

        %% raincloud plots for selected features
         ff_rc = raincloud_awakeUnconscious(data_all, TimeSeries_all, classifier_cv.operations.CodeString, ...
             refCodeStrings, subjectNames);
         pause(0.5);
         screen2png([out_file '_rc.png'],ff_rc);

      %% getConsistency
        [consisetencies, consistencies_random] = getConsistency(trainData.TS_DataMat, trainData.TimeSeries, condNames);

        %% stats
        accuracy = mean(classifier_cv.accuracy_validate,2)';
        accuracy_rand = mean(classifier_cv.accuracy_validate_rand,2)';
        [nsig_accuracy, p_accuracy, p_fdr_accuracy_th] = get_sig_features(accuracy, accuracy_rand, ...
            classifier_cv.validFeatures,q);

        consistency = mean(consisetencies, 3);
        consistency_rand = mean(consistencies_random,3);
        [nsig_consistency,p_consistency,p_fdr_consistency_th] = get_sig_features(consistency, ...
            consistency_rand, classifier_cv.validFeatures,q);

        save(out_file, 'classifier_cv',"p_fdr_consistency_th","p_consistency","p_fdr_accuracy_th",...
            "p_accuracy","consisetencies",'consistencies_random','nsig_consistency',"nsig_accuracy",'q');

        clear validateData trainData 'classifier_cv' "p_fdr_consistency_th" "p_consistency" "p_fdr_accuracy_th"...
            "p_accuracy" "consisetencies" 'consistencies_random' 'nsig_consistency' "nsig_accuracy"

    catch err
        errorID = [errorID; JID];
        err
    end
end

disp('error ID:')
disp(errorID);

