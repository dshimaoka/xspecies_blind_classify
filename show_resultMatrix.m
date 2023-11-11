

%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
species = 'macaque';%'human';
subject = 'George';%'376';
preprocessSuffix = '_subtractMean_removeLineNoise';
channel_dir = fullfile(dirPref.rootDir, 'preprocessed',species,subject);
load_dir = fullfile(dirPref.rootDir, ['results' preprocessSuffix]);

load(fullfile(channel_dir,['detectChannels_' subject]) );

result = cell(numel(tgtChannels));
for ii = 1:numel(tgtChannels)
    for jj = 1:numel(tgtChannels)

        disp([num2str(ii) '_' num2str(jj)]);

        ch_train = tgtChannels(ii);
        ch_validate = tgtChannels(jj);

        out_file = fullfile(load_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy', species, subject, ch_train,...
            species,subject, ch_validate));
        data = load(out_file, 'classifier_cv',"p_fdr_consistency","p_consistency","p_fdr_accuracy",...
            "p_accuracy","consisetencies",'consistencies_random');
        data.nsig_accuracy =  sum(data.p_accuracy < repmat(data.p_fdr_accuracy, [1, size(data.p_accuracy, 2)]));
        data.nsig_consistency =  sum(data.p_consistency < repmat(data.p_fdr_consistency, [1, size(data.p_consistency, 2)]));
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
    set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames,'ytick',[2 5 8 11],'YTickLabel',lobeNames)
    vline([3 6 9]+.5,gca,'-');
    hline([3 6 9]+.5,gca,'-');
    title(thisMetric);
    colorbar;

    % compare within lobe v between lobes
    [withinlobe, betweenlobes] = extractLobes(thisMatrix, tgtChannels, channelsByLobe);
    figure(f2);
    subplot(2,2,im);
    violin({withinlobe',betweenlobes'},'xlabel',{'within','between'});
    [h,p] = ttest2(withinlobe, betweenlobes);
    title(sprintf('%s\np=%3f',thisMetric,p));
end
squareplots(f1);
screen2png(['resultMatrix_' species '_'  subject],f1);
screen2png(['resultMatrix_violin_' species '_' subject] ,f2);
%best accuracy - did not depend on training channel - dubious
%best consistency & nsig consistent - did depend on training channel -dubious
%nsig accuracy & nsig consistent - values too high

