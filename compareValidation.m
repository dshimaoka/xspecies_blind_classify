%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
htcsaType = 'TS_DataMat';

refCodeStrings = {'DN_rms', ... %13
    'MF_GP_hyperparameters_covSEiso_covNoise_1_200_resample.logh1'}; %6339
condNames = {'awake','unconscious'};

species_train = 'macaque';%'human'; %
subject_train = 'George';%'376';%

load_dir = fullfile(dirPref.rootDir, ['results' preprocessSuffix]);

channel_dir_train = fullfile(dirPref.rootDir, 'preprocessed','macaque', 'George');
load(fullfile(channel_dir_train,['detectChannels_' 'George']) , 'tgtChannels','channelsByLobe','lobeNames');
tgtChannels_train= tgtChannels;
channelsByLobe_train = channelsByLobe;
lobeNames_train = lobeNames;

channel_dir_validate = fullfile(dirPref.rootDir, 'preprocessed','human', '376');
load(fullfile(channel_dir_validate,['detectChannels_' '376']) , 'tgtChannels','channelsByLobe','lobeNames');
tgtChannels_validate= tgtChannels;
channelsByLobe_validate = channelsByLobe;
lobeNames_validate = lobeNames;


errorID = [];
for JID = 1:numel(tgtChannels_train)
    disp(JID);
    mean_accuracy = [];
    p_accuracy = [];
    validatedata = cell(1,2);
    ch_train = tgtChannels_train(JID);
        for vv = 1:2
            switch vv
                case 1
                    species_validate = species_train;
                    subject_validate = subject_train;
                    ch_validate = tgtChannels_train(JID);
                case 2
                    species_validate =  'human'; 
                    subject_validate = '376';
                    ch_validate = tgtChannels_validate(JID);
            end

            %% HCTSA
            hctsa_dir_train = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species_train,subject_train);
            file_string_train = fullfile(hctsa_dir_train,  sprintf('%s_%s_ch%03d_hctsa', species_train, subject_train, ch_train));
            trainData = load([file_string_train '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

            hctsa_dir_validate = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species_validate,subject_validate);
            file_string_validate = fullfile(hctsa_dir_validate,  sprintf('%s_%s_ch%03d_hctsa', species_validate, subject_validate, ch_validate));
            validateData{vv} = load([file_string_validate '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

            %% NM classifier result
            out_file = fullfile(load_dir, sprintf('%s_train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy.mat', ...
                htcsaType, species_train, subject_train, ch_train,...
                species_validate,subject_validate, ch_validate));
            data = load(out_file, 'classifier_cv',"p_fdr_consistency_th","p_consistency","p_fdr_accuracy_th",...
                "p_accuracy","consisetencies",'consistencies_random','nsig_consistency','nsig_accuracy');

            mean_accuracy(:,vv) = mean(data.classifier_cv.accuracy_validate,2);
            p_accuracy(:,vv) = data.p_accuracy;
            validFeatures(:,vv) = data.classifier_cv.validFeatures;

            ch_string{vv} = [species_validate '-ch' num2str(ch_validate)];

            [~, best_accuracy_idx(vv)]=max(mean_accuracy(:,vv));
            bestOperation_c{vv} = replace(data.classifier_cv.operations.CodeString(best_accuracy_idx(vv)), '_','-');

            refOperation_idx = [];
            for ss = 1:numel(refCodeStrings)
                refOperation_idx(ss) =  find(strcmp(data.classifier_cv.operations.CodeString, refCodeStrings{ss}));
            end
      
            nSig_accuracy_tmp(:,vv) = data.nsig_accuracy;

        end
        bestOperation{JID} = bestOperation_c{2};

        allValid =sum(validFeatures,2)==2;
        nSig_accuracy(JID,1) = sum(nSig_accuracy_tmp(allValid,1));
        nSig_accuracy(JID,2) = sum(nSig_accuracy_tmp(allValid,2));
        nSig_accuracy(JID,3) = sum(nSig_accuracy_tmp(allValid,1).*nSig_accuracy_tmp(allValid,2));
            
        mean_accuracy_all(JID,1,:) = mean_accuracy(:,1);
        mean_accuracy_all(JID,2,:) = mean_accuracy(:,2);
        
        % % %% HCTSA barcodes
        % figure('position',[0 0 1000 400]);
        % ax(1)=subplot(221);
        % imagesc(validateData{1}.TS_Normalised(condTrials{1}==1,allValid))
        % title('macaque awake');
        % 
        % ax(2)=subplot(222);
        % imagesc(validateData{2}.TS_Normalised(condTrials{2}==1,allValid))
        % title('human awake');
        % 
        % ax(3)=subplot(223);
        % imagesc(validateData{1}.TS_Normalised(condTrials{1}==2,allValid))
        % title('macaque unconscious');
        % 
        % ax(4)=subplot(224);
        % imagesc(validateData{2}.TS_Normalised(condTrials{2}==2,allValid))
        % title('human unconscious');
        % linkcaxes(ax,[0 1]);
        % set(ax,'tickdir','out');
        % [~,refOperation_idx_adj]=intersect(find(allValid), refOperation_idx);
        % reflines(gcf, refOperation_idx_adj,[],'g')
        % [~,best_accuracy_idx_adj]=intersect(find(allValid), best_accuracy_idx(2));
        % reflines(gcf, best_accuracy_idx_adj,[],'r')
        % mcolorbar(gca,.5);
        % savePaperFigure(gcf, fullfile(load_dir,['HCTSA_barcode_train_' ch_string{1} '_validate_' ch_string{2}]));

        %% scatter plot accuracy
        figure('position',[0 0 2000 1000]);
        ax(1)=subplot(231);
        plot(mean_accuracy(allValid,1), mean_accuracy(allValid,2),'.','Color',[.5 .5 .5]); hold on;
        nSig_accuracy_both = logical(nSig_accuracy_tmp(:,1).*nSig_accuracy_tmp(:,2));
        plot(mean_accuracy(nSig_accuracy_both,1), mean_accuracy(nSig_accuracy_both,2),'k.');
        plot(mean_accuracy(refOperation_idx(2),1), mean_accuracy(refOperation_idx(2),2),'ro')
        plot(mean_accuracy(refOperation_idx(1),1), mean_accuracy(refOperation_idx(1),2),'go')

        xlabel(ch_string{1}); ylabel(ch_string{2});
        squareplot;
        axis padded

        ax(2)=subplot(232);    showSingleEpochHists(validateData{1}, refOperation_idx(2), condNames,[],[],[],htcsaType);ylabel(ch_string{1});title(refCodeStrings{2},'color','r');
        ax(5)=subplot(235);    showSingleEpochHists(validateData{2}, refOperation_idx(2), condNames,[],[],[],htcsaType);ylabel(ch_string{2});
        ax(3)=subplot(233);    showSingleEpochHists(validateData{1}, refOperation_idx(1), condNames,[],[],[],htcsaType);title(replace(refCodeStrings{1},'_','-'),'color','g')
        ax(6)=subplot(236);    showSingleEpochHists(validateData{2}, refOperation_idx(1), condNames,[],[],[],htcsaType);legend(condNames);
        linkaxes([ax(2) ax(3)],'y');
        linkaxes([ax(5) ax(6)],'y');
        set(ax(:),'tickdir','out');

        savePaperFigure(gcf, fullfile(load_dir,['bestAccuracyHists_train_' ch_string{1} '_validate_' ch_string{2}]));
        close
end


%% accuracy
plot(mean_accuracy_all(:,1,refOperation_idx(1)),'go','MarkerSize',5)%monkey
hold on;
plot(mean_accuracy_all(:,2,refOperation_idx(1)),'gx','MarkerSize',5)%human
plot(mean_accuracy_all(:,1,refOperation_idx(2)),'ro','MarkerSize',5)%monkey
plot(mean_accuracy_all(:,2,refOperation_idx(2)),'rx','MarkerSize',5)%human
axis  padded square;
ylim([0.45 0.9])
    vline([3.5 6.5 9.5])
set(gca,'tickdir','out','xtick',[2 5 8 11],'XTickLabel',{'Occipital','Parietal','Temporal','Frontal'});
ylabel('#sig. features');title('accuracy');
legend('macaque','human','location','southwest');

addpath(genpath('~/Documents/git/export_fig'));
savePaperFigure(gcf, 'compareValidation_accuracy');


%% summary plot for each lobe
figure;
plot(nSig_accuracy,'o','MarkerSize',5)
axis padded square;
    vline([3.5 6.5 9.5])
set(gca,'tickdir','out','xtick',[2 5 8 11],'XTickLabel',{'Occipital','Parietal','Temporal','Frontal'});
ylabel('#sig. features');title('accuracy');
legend('macaque','human','both','location','southwest');


savePaperFigure(gcf,'nsig_summary')