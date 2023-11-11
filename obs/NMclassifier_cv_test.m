
preprocess_string = '_subtractMean_removeLineNoise';
data_server = '/mnt/dshi0006_market/Massive/COSproject';
out_dir = fullfile(data_server, ['hctsa_space' preprocess_string '/']);
channels = [10, 47, 128];

%% combine all trials
for ii = 1:numel(channels)
    fileName = ['HCTSA_tv_ch' num2str(channels(ii))];


    fileName_train = ['HCTSA_train_ch' num2str(channels(ii))];
    Data1 = load(fullfile(out_dir, fileName_train));
    fileName_validate = ['HCTSA_validate1_ch' num2str(channels(ii))];
    Data2 = load(fullfile(out_dir, fileName_validate));

    load(fullfile(out_dir, fileName_validate));

    TS_CalcTime = cat(1, Data1.TS_CalcTime, Data2.TS_CalcTime);
    TS_DataMat = cat(1, Data1.TS_DataMat, Data2.TS_DataMat);
    TS_Quality = cat(1, Data1.TS_Quality, Data2.TS_Quality);
    TS_Normalised = cat(1, Data1.TS_Normalised, Data2.TS_Normalised);
    TimeSeries = cat(1, Data1.TimeSeries, Data2.TimeSeries);
    valid_Features = Data1.valid_features.*Data2.valid_features;


    save(fullfile(out_dir, fileName), "TS_Normalised",'valid_Features','TimeSeries',"TS_Quality",...
        "TS_DataMat","TS_CalcTime","MasterOperations","Operations","fromDatabase","gitInfo");
end

%% retrieve best features for fly analysis (Angus)
tmp=load(fullfile(out_dir, 'HCTSA_validate1_ch10'),'Operations');
bestFlyFeature(1)=getFeatureID(tmp.Operations, 'SP_Summaries_welch_rect.logarea_2_1');
bestFlyFeature(2)=getFeatureID(tmp.Operations, 'StatAvl250');


%% define valid features, common across channels
validFeatures = [];
for jj = 1:numel(channels) %training channels
    fileName_train = ['HCTSA_tv_ch' num2str(channels(jj))];
    trainData = load(fullfile(out_dir, fileName_train));
    for ii = 1:numel(channels) %validate channels
        fileName_validate = ['HCTSA_tv_ch' num2str(channels(ii))];
        validateData = load(fullfile(out_dir, fileName_validate));
        validFeatures(:,jj,ii) = logical(trainData.valid_Features .* validateData.valid_Features);
    end
end
validFeatures_all = sum(sum(validFeatures,2),3) == 9;


%% compute classification accuracy w cross validation (within a channel)
trainFraction = 0.8; %[0-1]
ncv=50;
for jj = 1:numel(channels) %training channels
    fileName_train = ['HCTSA_tv_ch' num2str(channels(jj))];
    trainData = load(fullfile(out_dir, fileName_train));


    for ii = 1:numel(channels) %validate channels
        fileName_validate = ['HCTSA_tv_ch' num2str(channels(ii))];
        validateData = load(fullfile(out_dir, fileName_validate));

        nEpochs = size(trainData.TimeSeries,1);
        nTrainEpochs = round(nEpochs*trainFraction);
        for icv = 1:ncv
            rndEpochs = randperm(nEpochs);
            trainEpochs = rndEpochs(1:nTrainEpochs);
            validateEpochs= rndEpochs(nTrainEpochs+1:end);

            classifier = TrainNMClassifier(trainData.TS_Normalised(trainEpochs,:), trainData.TimeSeries(trainEpochs,:));
            [~, accuracy_train(:,jj,ii,icv)] = ValidateNMClassifier(trainData.TS_Normalised(trainEpochs,:), ...
                classifier, trainData.TimeSeries(trainEpochs,:));
            [~, accuracy_validate(:,jj,ii,icv)] = ValidateNMClassifier(validateData.TS_Normalised(validateEpochs,:), ...
                classifier, validateData.TimeSeries(validateEpochs,:));
        end
    end
end


maccuracy_train = mean(accuracy_train,4);
maccuracy_validate = mean(accuracy_validate,4);

for jj = 1:numel(channels) %training channels
    for ii = 1:numel(channels) %validation channels

        ax(jj,ii) = subplot(numel(channels),numel(channels),ii+numel(channels)*(jj-1));
        plot(maccuracy_train(validFeatures_all,jj,ii), maccuracy_validate(validFeatures_all, jj,ii),'.');
        hold on
        plot(maccuracy_train(bestFlyFeature(1), jj,ii), maccuracy_validate(bestFlyFeature(1), jj,ii), 'ro');
        plot(maccuracy_train(bestFlyFeature(2), jj,ii), maccuracy_validate(bestFlyFeature(2), jj,ii), 'go');

        axis equal padded;
        xlim([.5 1]);
        ylim([0 1]);
        line([.5 1],[.5 1],'color','k');
        set(gca,'tickdir','out');

        xlabel(['discovery ch' num2str(channels(jj))]);
        ylabel(['validation ch' num2str(channels(ii))]);
    end
end

saveas(gcf,'NMclassifier_cv_test.png');

%% get significant features
perf_type = 'nearestMedian';
data_set = 'validate1'; %'train'
[performances, performances_random, sig, ps, ps_fdr, sig_thresh, sig_thresh_fdr] = ...
    get_sig_features(perf_type, data_set, validFeatures, preprocess_string);


%% Nearest median classifier Demo
% % Example dataset with two features (X1 and X2)
% X = [1, 2; 2, 3; 3, 4; 6, 5; 7, 8; 8, 9];
%
% % Corresponding class labels (1 or 2)
% y = [1; 1; 1; 2; 2; 2];
%
% % Calculate the median for class 1
% median_class1 = median(X(y == 1, :));
%
% % Calculate the median for class 2
% median_class2 = median(X(y == 2, :));
%
% % New data point
% new_point = [4, 5];
%
% % Calculate Euclidean distances to both class medians
% distance_to_class1 = norm(new_point - median_class1);
% distance_to_class2 = norm(new_point - median_class2);
%
% % Assign the data point to the class with the closest median
% if distance_to_class1 < distance_to_class2
%     predicted_class = 1;
% else
%     predicted_class = 2;
% end
%
% disp(['Predicted class for the new point: ', num2str(predicted_class)]);