% compare classification accuracy between human and macaque using the same
% classifier trained with macaque data in NMclassification_selectCh.m

%% Settings
add_toolbox_COS;
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
htcsaType = 'TS_DataMat';

refCodeStrings = {'DN_rms', ... %13
    'MF_GP_hyperparameters_covSEiso_covNoise_1_200_resample.logh1'}; %6339
condNames = {'awake','unconscious'};

species_train = 'macaque';
subject_train = 'George';

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
                "p_accuracy","consisetencies",'consistencies_random','nsig_consistency','nsig_accuracy','sig_thresh_accuracy_fdr');

            mean_accuracy(:,vv) = mean(data.classifier_cv.accuracy_validate,2);
            p_accuracy(:,vv) = data.p_accuracy; %get_sig_features
            p_fdr_accuracy_th(vv) = data.p_fdr_accuracy_th; %get_sig_features
            validFeatures(:,vv) = data.classifier_cv.validFeatures;
            sig_thresh_accuracy_fdr(vv) = data.sig_thresh_accuracy_fdr;

            
            ch_string{vv} = [species_validate '-ch' num2str(ch_validate)];

            [~, best_accuracy_idx(vv)]=max(mean_accuracy(:,vv));
            bestOperation_c{vv} = replace(data.classifier_cv.operations.CodeString(best_accuracy_idx(vv)), '_','-');

            refOperation_idx = [];
            for ss = 1:numel(refCodeStrings)
                refOperation_idx(ss) =  find(strcmp(data.classifier_cv.operations.CodeString, refCodeStrings{ss}));
            end
      
            sigFeatures(:,JID,vv) = data.nsig_accuracy;

        end
        bestOperation{JID} = bestOperation_c{2};

        allValid =sum(validFeatures,2)==2;
        nSig_accuracy(JID,1) = sum(sigFeatures(allValid,JID,1));
        nSig_accuracy(JID,2) = sum(sigFeatures(allValid,JID,2));
        nSig_accuracy(JID,3) = sum(sigFeatures(allValid,JID,1).*sigFeatures(allValid,JID,2));
            
        mean_accuracy_all(JID,1,:) = mean_accuracy(:,1);
        mean_accuracy_all(JID,2,:) = mean_accuracy(:,2);
        validFeatures_all(JID,:,:) = validFeatures; %for Method, Parallel feature extraction
        
        % mean accuracy of significant features?
        %mean_accuracy_sig(JID,1,:) = 
     

        %% scatter plot accuracy
        figure('position',[0 0 1000 500]);
        subplot(121);
        plot(mean_accuracy(allValid,1), mean_accuracy(allValid,2),'.','Color',[.5 .5 .5]); hold on;
        nSig_accuracy_both = logical(sigFeatures(:,JID,1).*sigFeatures(:,JID,2));
        plot(mean_accuracy(nSig_accuracy_both,1), mean_accuracy(nSig_accuracy_both,2),'k.');
        plot(mean_accuracy(refOperation_idx(2),1), mean_accuracy(refOperation_idx(2),2),'ro')
        plot(mean_accuracy(refOperation_idx(1),1), mean_accuracy(refOperation_idx(1),2),'go')
        xlabel(ch_string{1}); ylabel(ch_string{2});
        squareplot;
        vline([sig_thresh_accuracy_fdr(1)], gca,'-','b'); vline(.5, gca,'-','k');
        hline([sig_thresh_accuracy_fdr(2)], gca,'-','b'); hline(.5, gca,'-','k');
        set(gca,'tickdir','out');
        axis padded;

        subplot(122);
        RowName = {'sig(Human)', 'nsig(Human)'};
        ColumnName = {'-','nsig(Macque)','sig(Macaque)'};
        Age = [sum(~sigFeatures(allValid,JID,1).*sigFeatures(allValid,JID,2)) sum(~sigFeatures(allValid,JID,1).*~sigFeatures(allValid,JID,2))];
        Height = [sum(sigFeatures(allValid,JID,1).*sigFeatures(allValid,JID,2)) sum(sigFeatures(allValid,JID,1).*~sigFeatures(allValid,JID,2))];
        T = table(RowName',Age',Height','VariableNames',ColumnName,'RowNames', RowName);
        %uit = uitable('Data', table2cell(T), 'ColumnName',T.Properties.VariableNames,...
        %    'Units', 'Normalized', 'Position',[0.5,0.1,0.3,0.3]);
        
        tableCell = [T.Properties.VariableNames; table2cell(T)];
        tableCell(cellfun(@isnumeric,tableCell)) = cellfun(@num2str, tableCell(cellfun(@isnumeric,tableCell)),'UniformOutput',false);
        tableChar = splitapply(@strjoin,pad(tableCell),[1;2;3]);
        set(gca,'position',[0.5,0.1,0.3,0.3], 'Visible','off')
        text(.2, .95, tableChar,'VerticalAlignment','Top','HorizontalAlignment','Left','FontName','Arial');

        savePaperFigure(gcf, fullfile(load_dir,['bestAccuracyHists_train_' ch_string{1} '_validate_' ch_string{2}]));
        close
end

%% save results
save(fullfile(load_dir, 'compareValidation.mat'),'validFeatures_all',"mean_accuracy_all",'sigFeatures','nSig_accuracy');

%% accuracy
figure('position',[0 0 600 800])
subplot(211);
plot(find(sigFeatures(refOperation_idx(1),:,1)), mean_accuracy_all(find(sigFeatures(refOperation_idx(1),:,1)),1,refOperation_idx(1)),'gs','MarkerSize',7, 'LineWidth',2)%monkey
hold on;
plot(find(sigFeatures(refOperation_idx(1),:,2)), mean_accuracy_all(find(sigFeatures(refOperation_idx(1),:,2)),2,refOperation_idx(1)),'go','MarkerSize',7, 'LineWidth',2)%human
plot(find(sigFeatures(refOperation_idx(2),:,1)), mean_accuracy_all(find(sigFeatures(refOperation_idx(2),:,1)),1,refOperation_idx(2)),'rs','MarkerSize',7, 'LineWidth',2)%monkey
plot(find(sigFeatures(refOperation_idx(2),:,2)), mean_accuracy_all(find(sigFeatures(refOperation_idx(2),:,2)),2,refOperation_idx(2)),'ro','MarkerSize',7, 'LineWidth',2)%human

plot(find(sigFeatures(refOperation_idx(1),:,1)==0), mean_accuracy_all(find(sigFeatures(refOperation_idx(1),:,1)==0),1,refOperation_idx(1)),'gs','MarkerSize',7, 'LineWidth',.5)%monkey
plot(find(sigFeatures(refOperation_idx(1),:,2)==0), mean_accuracy_all(find(sigFeatures(refOperation_idx(1),:,2)==0),2,refOperation_idx(1)),'go','MarkerSize',7, 'LineWidth',.5)%human
plot(find(sigFeatures(refOperation_idx(2),:,1)==0), mean_accuracy_all(find(sigFeatures(refOperation_idx(2),:,1)==0),1,refOperation_idx(2)),'rs','MarkerSize',7, 'LineWidth',.5)%monkey
plot(find(sigFeatures(refOperation_idx(2),:,2)==0), mean_accuracy_all(find(sigFeatures(refOperation_idx(2),:,2)==0),2,refOperation_idx(2)),'ro','MarkerSize',7, 'LineWidth',.5)%human
axis  padded square;
ylim([0.35 0.9]); 
vline([6.5 9.5]); hline(.5);
set(gca,'tickdir','out','xtick',[2 5 8 11],'XTickLabel',{'Occipital','Parietal','Temporal','Frontal'},'box','off');
xlim([3.5 12.5]);
ylabel('accuracy');
legend('macaque','human','location','southeast');

subplot(212);
plot(nSig_accuracy(:,1),'ks','MarkerSize',7, 'LineWidth',2); hold on;
plot(nSig_accuracy(:,2),'ko','MarkerSize',7, 'LineWidth',2); hold on;
plot(nSig_accuracy(:,3),'kx','MarkerSize',7, 'LineWidth',2); hold on;
axis padded square;
ylim([0 5500])
vline([6.5 9.5]);
set(gca,'tickdir','out','xtick',[2 5 8 11],'XTickLabel',{'Occipital','Parietal','Temporal','Frontal'},'box','off');
xlim([3.5 12.5]);
ylabel('#sig. features');
legend('macaque','human','both','location','southeast');

savePaperFigure(gcf,fullfile(load_dir,'nsig_accuracy'))

%% stats
mean(nSig_accuracy(4:12,3))
std(nSig_accuracy(4:12,3))

%% for fig2 explanation
mean_accuracy_all(12,:,refOperation_idx(1)) %RMS
mean_accuracy_all(12,:,refOperation_idx(2)) %MF

%% valid features for method
validFeatures_all_2D = reshape(permute(validFeatures_all, [2 1 3]), 7755,[]);
for ich = 1:size(validFeatures_all_2D,2)
    nValidFeatures(ich) = sum(validFeatures_all_2D(:,ich));
end
mean(nValidFeatures)
std(nValidFeatures)