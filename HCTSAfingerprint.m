%% compute hctsa avearge across within epoch
%% then compute correlation between conditions

%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
hctsaType = 'TS_Normalised'; %'TS_DataMat';

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
dataString = [];
mhctsa = [];
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

        condTrials{vv} = getCondTrials(validateData{vv}.TimeSeries, condNames);
        for icond = 1:2
            mhctsa(JID,vv,icond,:) =  mean(validateData{vv}.(hctsaType)(condTrials{vv}==icond,:));
            dataString{JID,vv,icond} = [species_validate '-' condNames{icond} '-ch' num2str(ch_validate)];
        end
    end

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
end

mhctsa_all = reshape(mhctsa,[size(mhctsa,1)*size(mhctsa,2)*size(mhctsa,3),size(mhctsa,4)]);
dataString_all = reshape(dataString, [size(mhctsa,1)*size(mhctsa,2)*size(mhctsa,3),1]);
allValid = ~isnan(sum(mhctsa_all,1));
corr_p=corr(mhctsa_all(:,allValid)','Type','Pearson');
corr_s=corr(mhctsa_all(:,allValid)','Type','Spearman');

ax(1)=subplot(121);
imagesc(corr_p);set(gca,'xtick',1:size(corr_p),'xticklabel',dataString_all,'ytick',1:size(corr_p),'yticklabel',dataString_all)
vline([12.5 24.5 36.5],[],'-'); hline([12.5 24.5 36.5],[],'-')
title("Pearson");
ax(2)=subplot(122);
imagesc(corr_s);set(gca,'xtick',1:size(corr_p),'xticklabel',dataString_all,'ytick',1:size(corr_p),'yticklabel',dataString_all)
vline([12.5 24.5 36.5],[],'-'); hline([12.5 24.5 36.5],[],'-')
title("Spearman")
squareplots;
clim([0 1]);
linkcaxes(ax(:));
colormap(inferno);

mcolorbar(ax(2));

savePaperFigure(gcf,'HCTSAfingerprint');


%% selected channels
% tgtChIdx = 12;
% icond=1;
% idx_selected = find(contains(dataString_all, [condNames{icond} '-ch' num2str(tgtChannels_validate(tgtChIdx))]));
% corr_p_selected = corr_p(idx_selected, idx_selected);

% across species - within unconscious 
corr_select = corr_s(37:48, 25:36);
black = mean(corr_select(:));
black_one = corr_select(12,12)

%  across species - within conscious 
corr_select = corr_s(13:24,1:12);
blue = mean(corr_select(:));
blue_one = corr_select(12,12)

% across species -across conscious vs unconscious  
corr_select = [corr_s(25:36,13:24) corr_s(37:48,1:12)];
red = mean(corr_select(:));
red_one = mean([corr_select(12,12) corr_select(12,24)])

% within species - across conscious vs unconscious 
corr_select = [corr_s(25:36,1:12) corr_s(37:48,13:24)];
green = mean(corr_select(:));
green_one = mean([corr_select(12,12) corr_select(12,24)])


