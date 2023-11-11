
preprocess_string = '_subtractMean_removeLineNoise';
data_server = '/mnt/dshi0006_market/Massive/COSproject';
out_dir = fullfile(data_server, ['hctsa_space' preprocess_string '/']);
channels = [10, 47, 128];

%% retrieve best features for fly analysis (Angus)
tmp=load(fullfile(out_dir, 'HCTSA_validate1_ch10'),'Operations');
bestFlyFeature(1)=getFeatureID(tmp.Operations, 'SP_Summaries_welch_rect.logarea_2_1');
bestFlyFeature(2)=getFeatureID(tmp.Operations, 'StatAvl250');

for jj = 1:numel(channels) %training channels
    fileName_train = ['HCTSA_train_ch' num2str(channels(jj))];
    trainData = load(fullfile(out_dir, fileName_train));
    classifier = TrainNMClassifier(trainData.TS_Normalised, trainData.TimeSeries);
    [~, correctRate_train] = ValidateNMClassifier(trainData.TS_Normalised, classifier, trainData.TimeSeries);

    for ii = 1:numel(channels) %validate channels

        fileName_validate = ['HCTSA_validate1_ch' num2str(channels(ii))];
        validateData = load(fullfile(out_dir, fileName_validate));

        [predicted, accuracy_validate(:,jj,ii)] = ValidateNMClassifier(validateData.TS_Normalised, classifier, validateData.TimeSeries);

        validFeatures(:,jj,ii) = logical(trainData.valid_features .* validateData.valid_features);

        ax(jj,ii) = subplot(numel(channels),numel(channels),ii+numel(channels)*(jj-1));
        plot(correctRate_train(validFeatures(:,jj,ii)), accuracy_validate(validFeatures(:,jj,ii),jj,ii),'.');
hold on
        plot(correctRate_train(bestFlyFeature(1)), accuracy_validate(bestFlyFeature(1)), 'ro');
        plot(correctRate_train(bestFlyFeature(2)), accuracy_validate(bestFlyFeature(2)), 'go');

axis equal padded;
        xlim([.5 1]);
        ylim([0 1]);
        line([.5 1],[.5 1],'color','k');
        set(gca,'tickdir','out');


        xlabel(['accuracy discovery data ch' num2str(channels(jj))]);
        ylabel(['accuracy validation data ch' num2str(channels(ii))]);
    end
end


 saveas(gcf,'NMclassifier_test.png');

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