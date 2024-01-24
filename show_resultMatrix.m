

%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
rebuildMatrix = true;

species_train = 'macaque';%'human'; %
subject_train = 'George';%'376';%
species_validate = 'macaque';% 'human'; %
subject_validate = 'George';%'376';%

svm_type = 'lasso';

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

if rebuildMatrix
    ngIdx = detectNGidx_NMclassification(load_dir, species_train, subject_train, tgtChannels_train, ...
        species_validate, subject_validate, tgtChannels_validate);
    if ~isempty(ngIdx)
        disp(numel(ngIdx));
        error('Data is incomplete:');
    end

    result_nm = cell(numel(tgtChannels_train), numel(tgtChannels_validate));
    result_svm = cell(numel(tgtChannels_train), numel(tgtChannels_validate));
    for ii = 1:numel(tgtChannels_train)
        for jj = 1:numel(tgtChannels_validate)

            disp([num2str(ii) '_' num2str(jj)]);

            ch_train = tgtChannels_train(ii);
            ch_validate = tgtChannels_validate(jj);

            out_file = fullfile(load_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy.mat', ...
                species_train, subject_train, ch_train,...
                species_validate,subject_validate, ch_validate));
            data = load(out_file, 'classifier_cv',"p_fdr_consistency_th","p_consistency","p_fdr_accuracy_th",...
                "p_accuracy","consisetencies",'consistencies_random');
            data.nsig_accuracy =  sum(data.p_accuracy < repmat(data.p_fdr_accuracy_th, [1, size(data.p_accuracy, 2)]));
            data.nsig_consistency =  sum(data.p_consistency < repmat(data.p_fdr_consistency_th, [1, size(data.p_consistency, 2)]));
            data.best_accuracy = max(mean(data.classifier_cv.accuracy_validate,2));
            data.best_consistency = max(mean(data.consisetencies,3));
            result_nm{ii,jj} = data;

            if ~strcmp(svm_type, 'lasso')
                load(out_file, 'svm_cv');
                result_svm{ii,jj} = svm_cv;
            elseif strcmp(svm_type, 'lasso')
                load(out_file, 'svm_lasso_cv');
                result_svm{ii,jj} = svm_lasso_cv;
            end

            clear svm_lasso_cv data
        end
    end
    save(saveMatrixName, ...
        'result_nm', 'result_svm','species_train','subject_train','species_validate','subject_validate','-v7.3');
else
    load(saveMatrixName);
end


%% figures for neareset median
f1=figure; f2=figure;
statMat_nm = [];
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
    statMat_nm(:,:,im) = cellfun(@(x)(x.(thisMetric)), result_nm,'UniformOutput',true);

    figure(f1);
    subplot(2,2,im);
    imagesc(squeeze(statMat_nm(:,:,im)));
    set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
    vline([3 6 9]+.5,gca,'-');
    hline([3 6 9]+.5,gca,'-');
    title(thisMetric);
    colorbar;

    % compare within lobe v between lobes
    [withinlobe, betweenlobes] = extractLobes(squeeze(statMat_nm(:,:,im)), tgtChannels_train, channelsByLobe_train,...
        tgtChannels_validate, channelsByLobe_validate);
    figure(f2);
    subplot(2,2,im);
    violin({withinlobe',betweenlobes'},'xlabel',{'within','between'});
    [h,p] = ttest2(withinlobe, betweenlobes);
    title(sprintf('%s\np=%3f',thisMetric,p));
end
squareplots(f1);
screen2png(fullfile(load_dir,['resultMatrix_nm_' saveSuffix]),f1);
screen2png(fullfile(load_dir, ['resultMatrix_nm_violin_' saveSuffix]) ,f2);
%best accuracy - did not depend on training channel - dubious
%best consistency & nsig consistent - did depend on training channel -dubious
%nsig accuracy & nsig consistent - values too high


%% figures for svm
f1=figure; f2=figure;
statMat_svm = [];
for im = 1:2
    switch im
        case 1
            thisMetric = 'accuracy_train';
        case 2
            thisMetric = 'accuracy_validate';
    end
    statMat_svm(:,:,im) = cellfun(@(x)(mean(x.(thisMetric))), result_svm,'UniformOutput',true);

    figure(f1);
    subplot(2,2,im);
    imagesc(squeeze(statMat_svm(:,:,im)));
    set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
    vline([3 6 9]+.5,gca,'-');
    hline([3 6 9]+.5,gca,'-');
    title(thisMetric);
    colorbar;

    % compare within lobe v between lobes
    [withinlobe, betweenlobes] = extractLobes(squeeze(statMat_svm(:,:,im)), tgtChannels_train, channelsByLobe_train,...
        tgtChannels_validate, channelsByLobe_validate);
    figure(f2);
    subplot(2,2,im);
    violin({withinlobe',betweenlobes'},'xlabel',{'within','between'});
    [h,p] = ttest2(withinlobe, betweenlobes);
    title(sprintf('%s\np=%3f',thisMetric,p));
end
squareplots(f1);
screen2png(fullfile(load_dir, ['resultMatrix_svm_' saveSuffix]),f1);
screen2png(fullfile(load_dir, ['resultMatrix_svm_violin_' saveSuffix]) ,f2);


%% histogram of SVM weights
for ii = 1:numel(tgtChannels_train)
    for jj = 1:numel(tgtChannels_validate)

        disp([num2str(ii) '_' num2str(jj)]);

        ch_train = tgtChannels_train(ii);
        ch_validate = tgtChannels_validate(jj);

        fig = figure('Visible','off');
        show_SVMclassifier_single(result_svm{ii,jj});%, [], p_weight, p_fdr_weight_th);
        set(gca,'yscale','log');
        axis tight padded;
       
        figname = fullfile(load_dir, sprintf('svmWeights_train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy.mat', ...
            species_train, subject_train, ch_train,...
            species_validate,subject_validate, ch_validate));
        screen2png(figname, fig);
        close ;
    end
end



%% svm v nm
f1=figure; f2=figure;
for im = 1
    thisMatrix = statMat_svm(:,:,2) - statMat_nm(:,:,3);

    figure(f1);
    subplot(2,2,im);
    imagesc(thisMatrix);
   caxis([-0.2 0.2]);
    set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
    vline([3 6 9]+.5,gca,'-');
    hline([3 6 9]+.5,gca,'-');
    title('improved accuracy svm - nm');
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
screen2png(fullfile(load_dir, ['resultMatrix_svm_nm_' saveSuffix]),f1);
screen2png(fullfile(load_dir, ['resultMatrix_svm_nm_violin_' saveSuffix]) ,f2);


%% common metrics between NM and SVM
nTopMetric = 50;

for ii = 1:numel(tgtChannels_train)
    for jj = 1:numel(tgtChannels_validate)

        %retrieve best performing metrics of NM classifier
        [a, idx] = sort(mean(result_nm{ii,jj}.classifier_cv.accuracy_train,2), 'descend');
        operationNames_nm{ii,jj} = result_nm{ii,jj}.classifier_cv.operations(idx(1:nTopMetric),:).Name;
        operationID_nm = result_nm{ii,jj}.classifier_cv.operations(idx(1:nTopMetric),:).ID;

        %retrieve top weights of SVM classifier
        [a, idx] = sort(abs(mean(result_svm{ii,jj}.weight,2)), 'descend');
        validOperations = result_svm{ii,jj}.operations(result_svm{ii,jj}.validFeatures,:);
        operationNames_svm{ii,jj} = validOperations(idx(1:nTopMetric),:).Name;
        operationID_svm = validOperations(idx(1:nTopMetric),:).ID;

        operationNames_nm_svm{ii,jj} = intersect(operationNames_nm{ii,jj}, operationNames_svm{ii,jj});

        nOperations_nm_svm(ii,jj) = numel(operationNames_nm_svm{ii,jj});
    end
end


%% common metrics between training channels
nOperations_bothCh_nm = [];
nOperations_bothCh_svm = [];
for ii1 = 1:numel(tgtChannels_train)
    for ii2 = 1:numel(tgtChannels_train)
        nOperations_bothCh_nm(ii1, ii2) =  numel(intersect(operationNames_nm{ii1,1}, operationNames_nm{ii2,1}));
        nOperations_bothCh_svm(ii1, ii2) =  numel(intersect(operationNames_svm{ii1,1}, operationNames_svm{ii2,1}));
    end
end

f= figure('position',[0 0 1800 700])
subplot(231);
imagesc(nOperations_nm_svm);
set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
vline([3 6 9]+.5,gca,'-');
hline([3 6 9]+.5,gca,'-');
squareplot;
mcolorbar;
title(['NM-SVM #overlapped operations out of top ' num2str(nTopMetric) ]);

subplot(232);
imagesc(nOperations_bothCh_nm);
title(['NM #overlapped operations out of top ' num2str(nTopMetric) ]);
set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
vline([3 6 9]+.5,gca,'-');
hline([3 6 9]+.5,gca,'-');
caxis([0 nTopMetric]);
squareplot;
mcolorbar;

subplot(233);
imagesc(nOperations_bothCh_svm);
title(['SVM #overlapped operations out of top ' num2str(nTopMetric) ]);
set(gca,'xtick',[2 5 8 11],'XTickLabel',lobeNames_train,'ytick',[2 5 8 11],'YTickLabel',lobeNames_validate)
vline([3 6 9]+.5,gca,'-');
hline([3 6 9]+.5,gca,'-');
caxis([0 nTopMetric]);
squareplot;
mcolorbar;


   [withinlobe, betweenlobes] = extractLobes(nOperations_nm_svm, tgtChannels_train, channelsByLobe_train,...
        tgtChannels_validate, channelsByLobe_validate);
    subplot(234);
    violin({withinlobe',betweenlobes'},'xlabel',{'within','between'});
    [h,p] = ttest2(withinlobe, betweenlobes);
    title(sprintf('%s\np=%3f','nOperations_n_svm',p));

   [withinlobe, betweenlobes] = extractLobes(nOperations_bothCh_nm, tgtChannels_train, channelsByLobe_train,...
        tgtChannels_train, channelsByLobe_train);
    subplot(235);
    violin({withinlobe',betweenlobes'},'xlabel',{'within','between'});
    [h,p] = ttest2(withinlobe, betweenlobes);
    title(sprintf('%s\np=%3f','nOperations_bothCh_nm',p));

   [withinlobe, betweenlobes] = extractLobes(nOperations_bothCh_svm, tgtChannels_train, channelsByLobe_train,...
        tgtChannels_train, channelsByLobe_train);
    subplot(236);
    violin({withinlobe',betweenlobes'},'xlabel',{'within','between'});
    [h,p] = ttest2(withinlobe, betweenlobes);
    title(sprintf('%s\np=%3f','nOperations_bothCh_svm',p));

screen2png(fullfile(load_dir, ['overlapOperations_svm_nm_' saveSuffix ]),f);
