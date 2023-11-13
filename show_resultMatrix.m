

%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';

species_train = 'human';
subject_train = '376';
species_validate = 'macaque';%'human';
subject_validate = 'George';%'376';

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


result = cell(numel(tgtChannels_train), numel(tgtChannels_validate));
for ii = 1:numel(tgtChannels_train)
    for jj = 1:numel(tgtChannels_validate)

        disp([num2str(ii) '_' num2str(jj)]);

        ch_train = tgtChannels_train(ii);
        ch_validate = tgtChannels_validate(jj);

        out_file = fullfile(load_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy', ...
            species_train, subject_train, ch_train,...
            species_validate,subject_validate, ch_validate));
        data = load(out_file, 'classifier_cv',"p_fdr_consistency_th","p_consistency","p_fdr_accuracy_th",...
            "p_accuracy","consisetencies",'consistencies_random');
        data.nsig_accuracy =  sum(data.p_accuracy < repmat(data.p_fdr_accuracy_th, [1, size(data.p_accuracy, 2)]));
        data.nsig_consistency =  sum(data.p_consistency < repmat(data.p_fdr_consistency_th, [1, size(data.p_consistency, 2)]));
        data.best_accuracy = max(mean(data.classifier_cv.accuracy_validate,2));
        data.best_consistency = max(mean(data.consisetencies,3));
        result{ii,jj} = data;

    end
end


f1=figure; f2=figure;
for im = 1:4
    switch im
        case 1
            thisMetric = 'nsig_accuracy';
        case 2
            thisMetric = 'nsig_consistency';
        case 3
            thisMetric = 'best_accuracy';
        case 4
            thisMetric = 'best_consistency';
    end
    thisMatrix = cellfun(@(x)(x.(thisMetric)), result,'UniformOutput',true);
    
    figure(f1);
    subplot(2,2,im);
    imagesc(thisMatrix);
    set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
    vline([3 6 9]+.5,gca,'-');
    hline([3 6 9]+.5,gca,'-');
    title(thisMetric);
    colorbar;

    % compare within lobe v between lobes
    [withinlobe, betweenlobes] = extractLobes(thisMatrix, tgtChannels_train, channelsByLobe_train,...
         tgtChannels_validate, channelsByLobe_validate); 
    figure(f2);
    subplot(2,2,im);
    violin({withinlobe',betweenlobes'},'xlabel',{'within','between'});
    [h,p] = ttest2(withinlobe, betweenlobes);
    title(sprintf('%s\np=%3f',thisMetric,p));
end
squareplots(f1);
screen2png(['resultMatrix_train_' species_train '_'  subject_train '_validate_' species_validate '_'  subject_validate],f1);
screen2png(['resultMatrix_violin_train_' species_train '_' subject_train  '_validate_' species_validate '_'  subject_validate] ,f2);
%best accuracy - did not depend on training channel - dubious
%best consistency & nsig consistent - did depend on training channel -dubious
%nsig accuracy & nsig consistent - values too high

