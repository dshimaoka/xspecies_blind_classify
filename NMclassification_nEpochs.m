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
species_train ='macaque';
subject_train = 'George';
species_validate = 'human';%'macaque';%
subject_validate = '376';%'George';%
q = 0.01;
refCodeStrings = {'DN_rms', ... %13
    'MF_GP_hyperparameters_covSEiso_covNoise_1_200_resample.logh1'}; %6339

%% number of epochs
nEpochs_t = round(logspace(0 ,2, 8)); %#epochs for training
nEpochs_v = 50; %#epochs for validation
nDraws = 10; %times to compute accuracy

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
for JID = 12%1:maxJID

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

        CodeString = validateData.Operations.CodeString;

        %% train nearest-median classifier w cross-validation
        accuracy = nan(numel(nEpochs_t), 2, size(validateData.Operations,1), nDraws);
        for it = 1:numel(nEpochs_t)
            nEpochs_tv = [nEpochs_t(it) nEpochs_v]; %[#epochs for training, #epochs for validation] (per condition)
            [classifier_train] =  NMclassifier_epochs(trainData, trainData, nDraws, nEpochs_tv, [], htcsaType);
            [classifier_validate] =  NMclassifier_epochs(trainData, validateData, nDraws, nEpochs_tv, [], htcsaType);

            accuracy(it, 1,:,:) = classifier_train.accuracy_validate;
            accuracy(it, 2,:,:) = classifier_validate.accuracy_validate;
        end
    
        %% visualize
        refOperation_idx = [];
        for ss = 1:numel(refCodeStrings)
            refOperation_idx(ss) =  find(strcmp(CodeString, refCodeStrings{ss}));

            ax(ss) = subplot(1,numel(refCodeStrings),ss);
            accuracy_c = squeeze(accuracy(:,:,refOperation_idx(ss),:));
            maccuracy = squeeze(mean(accuracy_c, 3));
            sdaccuracy = squeeze(std(accuracy_c, [], 3));
            errorbar(2*nEpochs_t, squeeze(maccuracy(:,1)), squeeze(sdaccuracy(:,1)));hold on;
            errorbar(2*nEpochs_t, squeeze(maccuracy(:,2)), squeeze(sdaccuracy(:,2)));
            xlabel(replace(refCodeStrings{ss},'_','-'));
            set(ax(ss),'XScale','log','xtick',2*nEpochs_t)
            axis padded

            if ss == 1
                legend('monkey','human');
                ylabel('classification accuracy');
            end
        end
        linkaxes(ax);

        screen2png([out_file '_nEpochs']);

        %save('test','accuracy');
        clear validateData trainData 'classifier_train' 'classifier_validate' "p_fdr_consistency_th" "p_consistency" "p_fdr_accuracy_th"...
            "p_accuracy" "consisetencies" 'consistencies_random' 'nsig_consistency' "nsig_accuracy"

    catch err
        errorID = [errorID; JID];
        err
    end
end

disp('error ID:')
disp(errorID);
