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
%nEpochs_t = round(logspace(0 ,2, 7)); %#epochs for training
%nEpochs_t = round(logspace(0 ,log10(400), 9)); %#epochs for training
nEpochs_t = round(logspace(0 ,log10(258), 9)); %#epochs for training
nEpochs_v = 50; %#epochs for validation
nDraws = 100; %times to compute accuracy %10 50

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

        validateStats = load(out_file, "p_accuracy",'p_fdr_accuracy_th');
        
        out_file_t = fullfile(save_dir, sprintf('%s_train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy', ...
            htcsaType, species_train, subject_train, ch_train, species_train,subject_train, ch_train));
        trainStats = load(out_file, "p_accuracy",'p_fdr_accuracy_th');
        sigFeatures = find((trainStats.p_accuracy < trainStats.p_fdr_accuracy_th).* (validateStats.p_accuracy < validateStats.p_fdr_accuracy_th));


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

            accuracy(it, 1, :, :) = classifier_train.accuracy_validate;
            accuracy(it, 2, :, :) = classifier_validate.accuracy_validate;
        end
    
        %% visualize example features
        lcolors = [0 1 0; 1 0 0];
        figure('position',[0 0 800 900]);
        for itv = 1:2
            refOperation_idx = [];
            for ss = 1:numel(refCodeStrings)
                refOperation_idx(ss) =  find(strcmp(CodeString, refCodeStrings{ss}));
                accuracy_c = squeeze(accuracy(:,itv,refOperation_idx(ss),:));
                maccuracy = squeeze(mean(accuracy_c, 2));
                sdaccuracy = squeeze(std(accuracy_c, [], 2));
                
                ax(itv,1) = subplot(3,2, itv);
                plot(2*nEpochs_t, squeeze(maccuracy),'-o','color',lcolors(ss,:));hold on;
                set(ax(itv,1),'XScale','log','xtick',2*nEpochs_t)
                axis padded

               
                %t test for mean
                pf_ori = zeros(numel(nEpochs_t)-1,1);
                groups = cell(1,numel(nEpochs_t)-1);
                for ix = 1:numel(nEpochs_t)-1
                   %[~,pf_ori(ix)] = vartest2(accuracy_c(ix,:), accuracy_c(end,:)); %F-test for variance
                    %pf_ori(ix) = ranksum(accuracy_c(ix,:), accuracy_c(end,:)); %mann-whitney U test for equality of population medians. weak 
                    [~, pf_ori(ix)] = ttest2(accuracy_c(ix,:), accuracy_c(end,:),'Vartype','unequal');
                    groups{ix} = [2*nEpochs_t(ix) 2*nEpochs_t(end)];
                end
                pf_corrected = pf_ori*(numel(nEpochs_t)-1);
                noshow = pf_corrected>0.05;
                groups(noshow) = [];
                pf_corrected(noshow) = [];

                hstar = sigstar(groups, pf_corrected);
                set(hstar,'color',lcolors(ss,:));

                 ax(itv,2) = subplot(3,2, itv+2);
                plot(2*nEpochs_t, squeeze(sdaccuracy),'-o','color',lcolors(ss,:));hold on;
                set(ax(itv,2),'XScale','log','xtick',2*nEpochs_t)
                axis padded

                % f test for variance
                pf_ori = zeros(numel(nEpochs_t)-1,1);
                groups = cell(1,numel(nEpochs_t)-1);
                for ix = 1:numel(nEpochs_t)-1
                   [~,pf_ori(ix)] = vartest2(accuracy_c(ix,:), accuracy_c(end,:)); %F-test for variance
                    %pf_ori(ix) = ranksum(accuracy_c(ix,:), accuracy_c(end,:)); %mann-whitney U test for equality of population medians. weak 
                    groups{ix} = [2*nEpochs_t(ix) 2*nEpochs_t(end)];
                end
                pf_corrected = pf_ori*(numel(nEpochs_t)-1);
                noshow = pf_corrected>0.05;
                groups(noshow) = [];
                pf_corrected(noshow) = [];
                hstar = sigstar(groups, pf_corrected);
                set(hstar,'color',lcolors(ss,:));


                ax(itv,3)=subplot(3,2,itv+4);
                errorbar(2*nEpochs_t, squeeze(maccuracy), squeeze(sdaccuracy),'color',lcolors(ss,:));hold on;
                set(ax(itv,3),'XScale','log','xtick',2*nEpochs_t)
                axis padded
                if ss == 2 && itv == 1
                    %legend(replace(refCodeStrings,'_','-'), 'location','northoutside');
                    ylabel('classification accuracy');
                end
            end
        end
        linkaxes(ax(:,1));
        linkaxes(ax(:,2));
        linkaxes(ax(:,3));
        set(ax,'tickdir','out', 'box','off');

        addpath(genpath('~/Documents/git/export_fig'));
        savePaperFigure(gcf,[out_file '_nEpochs']);


        %% visualize all significant features
        for itv = 1:2
            p_var = zeros(numel(nEpochs_t)-1, 7755);
            p_mean = zeros(numel(nEpochs_t)-1, 7755);
            for ix = 1:numel(nEpochs_t)-1
                [~, p_var(ix,:)] = vartest2(squeeze(accuracy(ix,itv,:,:))',  squeeze(accuracy(end,itv,:,:))');
                [~, p_mean(ix,:)] = ttest2(squeeze(accuracy(ix,itv,:,:))',  squeeze(accuracy(end,itv,:,:))','Vartype','unequal');
            end
            p_var = p_var*(numel(nEpochs_t)-1);
            p_mean = p_mean * (numel(nEpochs_t)-1);

            minEpoch_var = [];           minEpoch_var = [];
            for ifeature = 1:size(p_var,2)
                var_temp = find(p_var(:,ifeature)<0.05, 1, 'last' );
                if ~isempty(var_temp)
                    minEpoch_var(ifeature)  = nEpochs_t(var_temp+1);
                else
                    minEpoch_var(ifeature)  = nan; %did not coverge
                end

                var_mean = find(p_mean(:,ifeature)<0.05, 1, 'last' );
                if ~isempty(var_mean)
                    minEpoch_mean(ifeature)  = nEpochs_t(var_mean+1);
                else
                    minEpoch_mean(ifeature)  = nan; %did not coverge
                end
            end

            mean_nEpochs_var(itv) = nanmean(minEpoch_var(sigFeatures));
            sd_nEpochs_var(itv) = nanstd(minEpoch_var(sigFeatures));
            nFeatures_nonconverge_var(itv) = sum(isnan(minEpoch_var(sigFeatures)));

            mean_nEpochs_mean(itv) = nanmean(minEpoch_mean(sigFeatures));
            sd_nEpochs_mean(itv) = nanstd(minEpoch_mean(sigFeatures));
            nFeatures_nonconverge_mean(itv) = sum(isnan(minEpoch_mean(sigFeatures)));
        end

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

save('NMclassification_nEpochs','mean_nEpochs_var','sd_nEpochs_var',"nFeatures_nonconverge_var",...
    'mean_nEpochs_mean','sd_nEpochs_mean',"nFeatures_nonconverge_mean",'JID');
