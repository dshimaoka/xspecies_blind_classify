%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
rebuildMatrix = false;
svm_type = 'ridge';%'lasso';
refCodeString = 'DN_rms';
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

bestOperation = cell(numel(tgtChannels_train),numel(tgtChannels_validate));
mhctsa_m = zeros(numel(tgtChannels_train), 7755);
mhctsa_h = zeros(numel(tgtChannels_validate), 7755);

%for figure: ii=12, jj=11
for ii = 12;%1:numel(tgtChannels_train)
    for jj = 11;%1:numel(tgtChannels_validate)
        ch_train = tgtChannels_train(ii);

        disp([ii jj]);

        mean_accuracy = [];
        p_accuracy = [];
        validatedata = cell(1,2);
        for vv = 1:2
            switch vv
                case 1
                    species_validate = species_train;
                    subject_validate = subject_train;
                    ch_validate = ch_train;
                case 2
                    species_validate =  'human'; 
                    subject_validate = '376';
                    ch_validate = tgtChannels_validate(jj);
            end

            %% HCTSA
            hctsa_dir_train = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species_train,subject_train);
            file_string_train = fullfile(hctsa_dir_train,  sprintf('%s_%s_ch%03d_hctsa', species_train, subject_train, ch_train));
            trainData = load([file_string_train '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

            hctsa_dir_validate = fullfile(dirPref.rootDir, ['hctsa' preprocessSuffix],species_validate,subject_validate);
            file_string_validate = fullfile(hctsa_dir_validate,  sprintf('%s_%s_ch%03d_hctsa', species_validate, subject_validate, ch_validate));
            validateData{vv} = load([file_string_validate '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');


            %% channel matching ... only use awake condition
            condTrials{vv} = getCondTrials(validateData{vv}.TimeSeries, condNames);
            if vv == 1 %macaque
                mhctsa_m(ii,:) =  mean(validateData{vv}.TS_Normalised(condTrials{vv}==1,:));
            elseif vv == 2 %human
                mhctsa_h(jj,:) =  mean(validateData{vv}.TS_Normalised(condTrials{vv}==1,:));
            end

            %% NM classifier result
            %ncv = 10;
            %[classifier_cv, fig] =  NMclassifier_cv(trainData, validateData, ncv);

            %load result of awake_unconscious_NMclassification_channels.m
            out_file = fullfile(load_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy.mat', ...
                species_train, subject_train, ch_train,...
                species_validate,subject_validate, ch_validate));
            data = load(out_file, 'classifier_cv',"p_fdr_consistency_th","p_consistency","p_fdr_accuracy_th",...
                "p_accuracy","consisetencies",'consistencies_random','nsig_consistency','nsig_accuracy');

            mean_accuracy(:,vv) = mean(data.classifier_cv.accuracy_validate,2);
            p_accuracy(:,vv) = data.p_accuracy;
            validFeatures(:,vv) = data.classifier_cv.validFeatures;

            ch_string{vv} = [species_validate '-ch' num2str(ch_validate)];

            [~, best_accuracy_idx(vv)]=max(mean_accuracy(:,vv));
            bestOperation_c{vv} = replace(data.classifier_cv.operations.CodeString(best_accuracy_idx(vv)), '_','-');

            refOperation_idx =  find(strcmp(data.classifier_cv.operations.CodeString, refCodeString));

            consistencies{vv}= squeeze(data.consisetencies)';

            nSig_accuracy_tmp(:,vv) = data.nsig_accuracy;
            nSig_consistency_tmp(:,vv) = data.nsig_consistency;
        end
        bestOperation{ii,jj} = bestOperation_c{2};

        allValid =sum(validFeatures,2)==2;
        % allSig = (p_accuracy(:,1)<pth)&(p_accuracy(:,2)<pth);
        nSig_accuracy(ii,jj,1) = sum(nSig_accuracy_tmp(allValid,1));
        nSig_accuracy(ii,jj,2) = sum(nSig_accuracy_tmp(allValid,2));
        nSig_accuracy(ii,jj,3) = sum(nSig_accuracy_tmp(allValid,1).*nSig_accuracy_tmp(allValid,2));
        nSig_consistency(ii,jj,1) = sum(nSig_consistency_tmp(allValid,1));
        nSig_consistency(ii,jj,2) = sum(nSig_consistency_tmp(allValid,2));
        nSig_consistency(ii,jj,3) = sum(nSig_consistency_tmp(allValid,1).*nSig_accuracy_tmp(allValid,2));
       
        mean_accuracy_all(ii,jj,1,:) = mean_accuracy(:,1);
        mean_accuracy_all(ii,jj,2,:) = mean_accuracy(:,2);
        
        % %% HCTSA barcodes
        figure('position',[0 0 1000 400]);
        ax(1)=subplot(221);
        imagesc(validateData{1}.TS_Normalised(condTrials{1}==1,allValid))
        title('macaque awake');

        ax(2)=subplot(222);
        imagesc(validateData{2}.TS_Normalised(condTrials{2}==1,allValid))
        title('human awake');

        ax(3)=subplot(223);
        imagesc(validateData{1}.TS_Normalised(condTrials{1}==2,allValid))
        title('macaque unconscious');

        ax(4)=subplot(224);
        imagesc(validateData{2}.TS_Normalised(condTrials{2}==2,allValid))
        title('human unconscious');
        linkcaxes(ax,[0 1]);
        set(ax,'tickdir','out');
        [~,refOperation_idx_adj]=intersect(find(allValid), refOperation_idx);
        reflines(gcf, refOperation_idx_adj,[],'g')
        [~,best_accuracy_idx_adj]=intersect(find(allValid), best_accuracy_idx(2));
        reflines(gcf, best_accuracy_idx_adj,[],'r')
        mcolorbar(gca,.5);
        savePaperFigure(gcf, fullfile(load_dir,['HCTSA_barcode_train_' ch_string{1} '_validate_' ch_string{2}]));
 
        % %% consistency barcode
        % figure('position',[0 0 1000 400]);
        % ax(1)=subplot(221);
        % imagesc(consistencies{1}(:,allValid))
        % title('macaque');
        % 
        % ax(2)=subplot(222);
        % imagesc(consistencies{2}(:,allValid))
        % title('human');
        % 
        % linkcaxes(ax,[0 1]);
        % set(ax,'tickdir','out');
        % [~,refOperation_idx_adj]=intersect(find(allValid), refOperation_idx);
        % reflines(gcf, refOperation_idx_adj,[],'g')
        % [~,best_accuracy_idx_adj]=intersect(find(allValid), best_accuracy_idx(2));
        % reflines(gcf, best_accuracy_idx_adj,[],'r')
        % mcolorbar(gca,.5);
        % savePaperFigure(gcf, fullfile(load_dir,['consistencies_train_' ch_string{1} '_validate_' ch_string{2}]));
        % 
        % %% scatter plot accuracy
        % figure('position',[0 0 2000 1000]);
        % ax(1)=subplot(231);
        % plot(mean_accuracy(allValid,1), mean_accuracy(allValid,2),'.','Color',[.5 .5 .5]); hold on;
        % nSig_accuracy_both = logical(nSig_accuracy_tmp(:,1).*nSig_accuracy_tmp(:,2));
        % plot(mean_accuracy(nSig_accuracy_both,1), mean_accuracy(nSig_accuracy_both,2),'k.');
        % plot(mean_accuracy(best_accuracy_idx(2),1), mean_accuracy(best_accuracy_idx(2),2),'ro')
        % plot(mean_accuracy(refOperation_idx,1), mean_accuracy(refOperation_idx,2),'go')
        % 
        % xlabel(ch_string{1}); ylabel(ch_string{2});
        % squareplot;
        % axis padded
        % 
        % ax(2)=subplot(232);    showSingleEpochHists(validateData{1}, best_accuracy_idx(2));ylabel(ch_string{1});title(bestOperation_c{2},'color','r');
        % ax(5)=subplot(235);    showSingleEpochHists(validateData{2}, best_accuracy_idx(2));ylabel(ch_string{2});
        % ax(3)=subplot(233);    showSingleEpochHists(validateData{1}, refOperation_idx);title(replace(refCodeString,'_','-'),'color','g')
        % ax(6)=subplot(236);    showSingleEpochHists(validateData{2}, refOperation_idx);legend(condNames);
        % linkaxes([ax(2) ax(3)],'y');
        % linkaxes([ax(5) ax(6)],'y');
        % set(ax(:),'tickdir','out');
        % 
        %  savePaperFigure(gcf, fullfile(load_dir,['bestAccuracyHists_train_' ch_string{1} '_validate_' ch_string{2}]));
        %  close

    end
end

%% pie chart
allOperations = [bestOperation{:}];
opNames = unique(allOperations);
for iop = 1:numel(opNames)
    opNumbers(iop) = sum(strcmp(allOperations, opNames{iop}));
end
pie(opNumbers, opNames);
screen2png('compareValidation_pie.png');


%% channel matching
allValid = intersect(find(~isnan(sum(mhctsa_h,1))), find(~isnan(sum(mhctsa_m,1))));
corr_mh = corr(mhctsa_h(:,allValid)', mhctsa_m(:,allValid)');

%% compute best channel in each lobe
validateChIdx = [];
trainChIdx = [];
for ll = 1:4
    [theseCh_train, theseIdx_train] = intersect(tgtChannels_train, channelsByLobe_train{ll});
    [theseCh_validate, theseIdx_validate] = intersect(tgtChannels_validate, channelsByLobe_validate{ll});
    for ii = 1:numel(theseIdx_validate)
        validateChIdx(theseIdx_validate(ii)) = theseIdx_validate(ii);
        [~, bestIdx]  = max(corr_mh(theseIdx_validate(ii),theseIdx_train));
        trainChIdx(theseIdx_validate(ii)) = theseIdx_train(bestIdx);
    end
end

save(fullfile(load_dir,'compareValidation'),'corr_mh','mhctsa_h','mhctsa_m','allValid',...
    'trainChIdx','validateChIdx','lobeNames_train','lobeNames_validate','nSig_consistency','nSig_accuracy');


imagesc(corr_mh)
vline([3 6 9]+.5,gca,'-');
hline([3 6 9]+.5,gca,'-');
ylabel('human (validate)');xlabel('macaque (train)');
set(gca,'tickDir','out','xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
axis equal tight;
hold on;
plot(trainChIdx, validateChIdx, 'r*');
title(sprintf('Correlation of HCTSA under awake\n(*: highest correlation across macaque channels)'));
caxis([.5 1]);
mcolorbar(gca,.5);

savePaperFigure(gcf, 'compareValidation');

%% mean hctsa across trials
figure('position',[ 0 0 1000 200]);
ax2(1)=subplot(121);
imagesc(mhctsa_m(:,allValid));
hline([3 6 9]+.5,gca,'-');
set(ax(1),'ytick',[]);

ax2(2)=subplot(122);
imagesc(mhctsa_h(:,allValid));
hline([3 6 9]+.5,gca,'-');
set(ax2(2),'ytick',[]);
linkcaxes(ax2(:));
caxis([0 1]);
mcolorbar;

savePaperFigure(gcf, 'compareValidation_hctsa');

%% accuracy
mean_accuracy_summary = [];
for ich = 1:12
    mean_accuracy_summary(ich,:,:) = mean_accuracy_all(trainChIdx(ich), validateChIdx(ich),:,:);
end

subplot(121)
plot(mean_accuracy_summary(:,1,refOperation_idx),'go','MarkerSize',5)%monkey
hold on;
plot(mean_accuracy_summary(:,2,refOperation_idx),'gx','MarkerSize',5)%human
plot(mean_accuracy_summary(:,1,best_accuracy_idx(2)),'ro','MarkerSize',5)%monkey
plot(mean_accuracy_summary(:,2,best_accuracy_idx(2)),'rx','MarkerSize',5)%human
axis  padded square;
ylim([0.45 0.9])
    vline([3.5 6.5 9.5])
set(gca,'tickdir','out','xtick',[2 5 8 11],'XTickLabel',{'Occipital','Parietal','Temporal','Frontal'});
ylabel('#sig. features');title('accuracy');
legend('macaque','human','location','southwest');

savePaperFigure(gcf, 'compareValidation_accuracy');


%% summary plot for each lobe
nSig_accuracy_summary = [];
nSig_consistency_summary = [];
for ich = 1:12
    nSig_accuary_summary(ich,:) = nSig_accuracy(trainChIdx(ich), validateChIdx(ich),:);
    nSig_consistency_summary(ich,:) = nSig_consistency(trainChIdx(ich), validateChIdx(ich),:);
end

subplot(121)
plot(nSig_accuary_summary,'o','MarkerSize',5)
axis padded square;
    vline([3.5 6.5 9.5])
set(gca,'tickdir','out','xtick',[2 5 8 11],'XTickLabel',{'Occipital','Parietal','Temporal','Frontal'});
ylabel('#sig. features');title('accuracy');
legend('macaque','human','both','location','southwest');

subplot(122)
plot(nSig_consistency_summary,'o','MarkerSize',5)
axis padded square;
    vline([3.5 6.5 9.5])
set(gca,'tickdir','out','xtick',[2 5 8 11],'XTickLabel',{'Occipital','Parietal','Temporal','Frontal'});
ylabel('#sig. features');title('consistency');
legend('macaque','human','both','location','southwest');

addpath(genpath('~/Documents/git/export_fig'));
savePaperFigure(gcf,'nsig_summary')