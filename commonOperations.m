%% Settings
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
preprocessSuffix = '_subtractMean_removeLineNoise';
rebuildMatrix = true;

species_train =  'macaque'; %
subject_train = 'George';%
species_validate = 'macaque';%
subject_validate = 'George';%

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
saveMatrixName = fullfile(load_dir, saveSuffix);

load(saveMatrixName, 'result_nm','result_svm');

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

    end
end


tgtChannelID = 10:12;
for icl = 1:2
    switch icl
        case 1
            thisCl = 'nm';
        case 2
            thisCl = 'svm';
    end
    operationNames = eval(['operationNames_' thisCl]);

    intersect_c = [];union_c = [];
    for ii1 = 1:numel(tgtChannelID)
        for ii2 = 1:numel(tgtChannelID)
            intersectOperations = intersect(operationNames{tgtChannelID(ii1),1}, operationNames{tgtChannelID(ii2),1});
            unionOperations = union(operationNames{tgtChannelID(ii1),1}, operationNames{tgtChannelID(ii2),1});
            if ii1==1 && ii2==1
                intersect_c = intersectOperations;
            else
                intersect_c = intersect(intersect_c, intersectOperations);
            end
            union_c = [union_c; unionOperations];
            nintersect(ii1,ii2)=numel(intersectOperations);
            nunion(ii1,ii2)=numel(unionOperations);
        end
    end

    intersect_all = intersect_c;
    union_all = unique(union_c);
    nintersect_all = numel(intersect_all);
    nunion_all = numel(union_all);

    mysets = arrayfun(@(x)(['ch' num2str(x)]), tgtChannels_train(tgtChannelID), 'UniformOutput', false);
    mylabels = {'','','',num2str(nintersect(1,2)), num2str(nintersect(1,3)), num2str(nintersect(2,3)), num2str(nintersect_all)};
    venn(3, 'sets',mysets,'labels',mylabels);
    text(0,0,[species_train '-' thisCl ' union: ' num2str(nunion_all)]);
    screen2png([species_train '-' thisCl],gcf);
    save(['commonOperations _' species_train '_' thisCl], 'intersect_all','union_all');
    close
end


%% common operations between species
for icl = 1:2
    switch icl
        case 1
            thisCl = 'nm';
        case 2
            thisCl = 'svm';
    end
    load(['commonOperations _human_' thisCl], 'intersect_all','union_all');
    i{1}=intersect_all;
    u{1}=union_all;
    load(['commonOperations _macaque_' thisCl], 'intersect_all','union_all');
    i{2}=intersect_all;
    u{2}=union_all;

    intersect_species{icl}=intersect(i{1},i{2});
    union_species{icl}=intersect(u{1},u{2});
end
