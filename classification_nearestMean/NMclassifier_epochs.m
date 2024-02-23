function [classifier_result, fig] =  NMclassifier_epochs(trainData, validateData, nDraws, nEpochs, condNames, hctsaType) 
% classifier_result =  NMclassifier_cv(trainData, validateData, trainFraction, nDraws, labelToClassify) 

%INPUT
%trainData/validateData
% .Operations
% .TS_DataMat
% .TimeSeries
% .TS_Normalised

%OUTPUT: classifier_result:
% .threshold
% .direction
% .accuracy_train
% .accuracy_validate
% .accuracy_validate_rand

verbose = false;
visualize = false;

assert(isequal(trainData.Operations, validateData.Operations));

%created from NMclassifier_cv_test
% if nargin < 3 || isempty(trainFraction)
%     trainFraction = 0.8; %[0-1]
% end
if nargin < 3 || isempty(nDraws)
    nDraws=10; 
end
if nargin < 4 || isempty(nEpochs)
    nEpochs = [10 100]; %#epochs for training and validation
end
if nargin < 5 || isempty(condNames)
    condNames = {'awake','unconscious'};
end

if nargin < 6
    hctsaType = 'TS_Normalised';
end

%% define valid features, common across channels
%cf. main_hctsa_matrix.m
validFeatures = logical(getValidFeatures(trainData.TS_DataMat).* getValidFeatures(validateData.TS_DataMat));


%% compute classification accuracy w cross validation (within a channel)
classifier_result.operations = trainData.Operations;
%classifier_result.trainFraction = trainFraction;
classifier_result.validFeatures = validFeatures;

parcelledEpochs_train = randEpochs(trainData, condNames, nDraws, nEpochs);
if isequal(trainData.TimeSeries, validateData.TimeSeries)
    parcelledEpochs_validate = parcelledEpochs_train;
else
    parcelledEpochs_validate =randEpochs(validateData, condNames, nDraws);
end

for idraw = 1:nDraws

    if verbose
        disp([num2str(idraw) '/' num2str(nDraws)]);
    end

    %trainParcelIdx = setxor(1:nDraws, idraw);
    %validateParcelIdx = idraw;
    trainEpochs = [parcelledEpochs_train{1, idraw}];
    validateEpochs = [parcelledEpochs_validate{2, idraw}];

    data_c = trainData.(hctsaType);
    timeSeries_c = trainData.TimeSeries;
    classifier = TrainNMClassifier(data_c(trainEpochs,:), timeSeries_c(trainEpochs,:), condNames);
    [~, accuracy_train_c] = ValidateNMClassifier(data_c(trainEpochs,:), ...
        classifier, timeSeries_c(trainEpochs,:), condNames);

    data_c = validateData.(hctsaType);
    timeSeries_c = validateData.TimeSeries;
    [predicted, accuracy_validate_c, accuracy_validate_rand_c] = ValidateNMClassifier(data_c(validateEpochs,:), ...
        classifier,  timeSeries_c(validateEpochs,:), condNames);

    threshold(:,idraw) = classifier.threshold;
    direction(:,idraw) = classifier.direction;
    accuracy_train(:,idraw) = accuracy_train_c;
    accuracy_validate(:,idraw) = accuracy_validate_c;
    accuracy_validate_rand(:,idraw) = accuracy_validate_rand_c;
    %classifier_result.predicted(:,:,icv) = predicted;
end

classifier_result.threshold = threshold;
classifier_result.direction = direction;
classifier_result.accuracy_train = accuracy_train;
classifier_result.accuracy_validate = accuracy_validate;
classifier_result.accuracy_validate_rand = accuracy_validate_rand;

maccuracy_train = mean(accuracy_train,2);
maccuracy_validate = mean(accuracy_validate,2);

if nargout==2
    fig = figure;
    show_NMclassifier_single(classifier_result);%, [], p_accuracy, p_fdr_accuracy_th);
        
        % plot(maccuracy_train(validFeatures), maccuracy_validate(validFeatures),'.');
        % axis equal padded;
        % xlim([.5 1]);
        % ylim([0 1]);
        % line([.5 1],[.5 1],'color','k');
        % set(gca,'tickdir','out');
        % 
        % xlabel('discovery data');
        % ylabel('validate data');
        % saveas(gcf,'NMclassifier_cv_test.png');
end




%% get significant features
% perf_type = 'nearestMedian';
% data_set = 'validate1'; %'train'
% [performances, performances_random, sig, ps, ps_fdr, sig_thresh, sig_thresh_fdr] = ...
%     get_sig_features(perf_type, data_set, validFeatures, preprocess_string);

