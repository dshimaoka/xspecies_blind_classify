function [classifier_result] =  SVMclassifier_cv(trainData, validateData, ncv, condNames, regularization) 
% classifier_result =  NMclassifier_cv(trainData, validateData, trainFraction, ncv, labelToClassify) 
% 
% train classifier using fitclinear for each cross-validation partitions
% validate using predict
%
%INPUT
%trainData/validateData
% .Operations
% .TS_DataMat
% .TimeSeries
% .TS_Normalised

%OUTPUT: classifier_result:
% .weight
% .operations
% .accuracy_train
% .accuracy_validate
% .accuracy_validate_rand


verbose = false;

assert(isequal(trainData.Operations, validateData.Operations));

%created from NMclassifier_cv_test
% if nargin < 3 || isempty(trainFraction)
%     trainFraction = 0.8; %[0-1]
% end
if nargin < 3 || isempty(ncv)
    ncv=10; 
end
if nargin < 4 || isempty(condNames)
    condNames = {'awake','unconscious'};
end
if nargin < 5
    classifier_result.regularization = 'ridge';
else
    classifier_result.regularization = regularization;
end

%% define valid features, common across channels
%cf. main_hctsa_matrix.m
validFeatures = logical(getValidFeatures(trainData.TS_DataMat).* getValidFeatures(validateData.TS_DataMat));


%% compute classification accuracy w cross validation (within a channel)
classifier_result.operations = trainData.Operations;
%classifier_result.trainFraction = trainFraction;
classifier_result.validFeatures = validFeatures;

parcelledEpochs_train = parcellateEpochs(trainData, condNames, ncv);
if isequal(trainData.TimeSeries, validateData.TimeSeries)
    parcelledEpochs_validate = parcelledEpochs_train;
else
    parcelledEpochs_validate = parcellateEpochs(validateData, condNames, ncv);
end

for icv = 1:ncv

    if verbose
        disp([num2str(icv) '/' num2str(ncv)]);
    end

    trainParcelIdx = setxor(1:ncv, icv);
    validateParcelIdx = icv;
    trainEpochs = [parcelledEpochs_train{trainParcelIdx}];
    validateEpochs = [parcelledEpochs_validate{validateParcelIdx}];

    X_train= trainData.TS_Normalised(trainEpochs,validFeatures)';
    Y_train = contains(trainData.TimeSeries(trainEpochs,:).Name, condNames{1})';
    classifier = fitclinear(X_train, Y_train, 'ObservationsIn','columns','Regularization',classifier_result.regularization);
    accuracy_train_c = 1 - loss(classifier, X_train, Y_train, 'ObservationsIn','columns');
    % classifier = TrainNMClassifier(data_c(trainEpochs,:), timeSeries_c(trainEpochs,:), condNames);
    % [~, accuracy_train_c] = ValidateNMClassifier(data_c(trainEpochs,:), ...
    %     classifier, timeSeries_c(trainEpochs,:), condNames);

    X_validate = validateData.TS_Normalised(validateEpochs,validFeatures)';
    Y_validate = contains(validateData.TimeSeries(validateEpochs,:).Name, condNames{1})';
    predicted = predict(classifier, X_validate, 'ObservationsIn','columns')';
    accuracy_validate_c = 1 - loss(classifier, X_validate, Y_validate, 'ObservationsIn','columns');
    predicted_rand = predicted(randperm(numel(predicted)));
    correct_class_rand = (predicted_rand == Y_validate)';
    accuracy_validate_rand_c = mean(correct_class_rand);

    
    % data_c = validateData.TS_Normalised(validateEpochs,:)';
    % timeSeries_c = validateData.TimeSeries;
    % [predicted, accuracy_validate_c, accuracy_validate_rand_c] = ValidateNMClassifier(data_c(validateEpochs,:), ...
    %     classifier,  timeSeries_c(validateEpochs,:), condNames);
    
    weight(:,icv) = classifier.Beta;
    %threshold(:,icv) = classifier.threshold;
    %direction(:,icv) = classifier.direction;
    accuracy_train(icv) = accuracy_train_c;
    accuracy_validate(icv) = accuracy_validate_c;
    accuracy_validate_rand(icv) = accuracy_validate_rand_c;
    %classifier_result.predicted(:,:,icv) = predicted;
end

classifier_result.weight = weight;
%classifier_result.threshold = threshold;
%classifier_result.direction = direction;
classifier_result.accuracy_train = accuracy_train;
classifier_result.accuracy_validate = accuracy_validate;
classifier_result.accuracy_validate_rand = accuracy_validate_rand;


%% get significant weights
p_weight = nan(1,size(classifier_result.weight,1));
for iop = 1:size(classifier_result.weight,1)
    p_weight(iop) = signrank(classifier_result.weight(iop,:));
end
classifier_result.p_weight = p_weight;

%TODO: p_fdr_weight_th

%% get stats
% maccuracy_validate = mean(classifier_result.accuracy_validate);
% maccuracy_rand = mean(classifier_result.accuracy_validate_rand)';
% [nsig_accuracy, p_accuracy, p_fdr_accuracy_th] = get_sig_features(maccuracy, maccuracy_rand, classifier_cv.validFeatures);


if nargout==2
    fig = figure;
    show_SVMclassifier_single(classifier_result);%, [], p_weight, p_fdr_weight_th);
end


