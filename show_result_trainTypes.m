%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
rebuildMatrix = false;
svm_type = 'ridge';%'lasso';

for tt = 1:3
    switch tt
        case 1
            species_train = 'human'; %
            subject_train = '376';%
            species_validate = 'human'; %
            subject_validate ='376';%
        case 2
            species_train = 'macaque';%'human'; %
            subject_train = 'George';%'376';%
            species_validate =  'macaque';%'human'; %
            subject_validate = 'George';%'376';%
        case 3
            species_train = 'macaque';%'human'; %
            subject_train = 'George';%'376';%
            species_validate = 'human'; %
            subject_validate ='376';%
    end

    channel_dir_train = fullfile(dirPref.rootDir, 'preprocessed',species_train, subject_train);
    load(fullfile(channel_dir_train,['detectChannels_' subject_train]) , 'tgtChannels','channelsByLobe','lobeNames');
    tgtChannels_train= tgtChannels;
    channelsByLobe_train = channelsByLobe;
    lobeNames_train = lobeNames;
    channel_dir_validate = fullfile(dirPref.rootDir, 'preprocessed',species_validate, subject_validate);
    load(fullfile(channel_dir_validate,['detectChannels_' subject_validate]), 'tgtChannels' ,'channelsByLobe','lobeNames');
    tgtChannels_validate= tgtChannels;
    channelsByLobe_validate = channelsByLobe;
    lobeNames_validate = lobeNames;
    clear tgtChannels channelsByLobe lobeNames

    load_dir = fullfile(dirPref.rootDir, ['results' preprocessSuffix]);
    saveSuffix = ['train_' species_train '_'  subject_train '_validate_' species_validate '_'  subject_validate];
    if strcmp(svm_type, 'lasso')
        saveSuffix = ['lasso_' saveSuffix];
    end
    saveMatrixName = fullfile(load_dir, saveSuffix);


    load([saveMatrixName '_accuracy'],'nm_accuracy_eachLobe','svm_accuracy_eachLobe');


    for ll = 1:4
        nm_m(ll,tt) = mean(nm_accuracy_eachLobe{ll});
        nm_ste(ll,tt) = ste(nm_accuracy_eachLobe{ll});

        svm_m(ll,tt) = mean(svm_accuracy_eachLobe{ll});
        svm_ste(ll,tt) = ste(svm_accuracy_eachLobe{ll});
    end
end

subplot(1,2,1);
errorbar(nm_m, nm_ste,'linewidth',2);
set(gca,'xtick',1:4,'XTickLabel',lobeNames_validate,'TickDir','out');
ylim([0.65 0.9])
xlim([.7 4.3]);
legend('human','macaque','xspecies','Location','northwest');
title('NM');

subplot(1,2,2);
errorbar(svm_m, svm_ste,'linewidth',2);
set(gca,'xtick',1:4,'XTickLabel',lobeNames_validate,'TickDir','out');
ylim([0.65 0.9])
xlim([.7 4.3]);
legend('human','macaque','xspecies','Location','northwest');
title('SVM');
screen2png('result_trainTypes.png')
