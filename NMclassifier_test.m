%% Nearest median classifier Demo

% Example dataset with two features (X1 and X2)
X = [1, 2; 2, 3; 3, 4; 6, 5; 7, 8; 8, 9];

% Corresponding class labels (1 or 2)
y = [1; 1; 1; 2; 2; 2];

% Calculate the median for class 1
median_class1 = median(X(y == 1, :));

% Calculate the median for class 2
median_class2 = median(X(y == 2, :));

% New data point
new_point = [4, 5];

% Calculate Euclidean distances to both class medians
distance_to_class1 = norm(new_point - median_class1);
distance_to_class2 = norm(new_point - median_class2);

% Assign the data point to the class with the closest median
if distance_to_class1 < distance_to_class2
    predicted_class = 1;
else
    predicted_class = 2;
end

disp(['Predicted class for the new point: ', num2str(predicted_class)]);


%% THIS IS WHAT I WANT TO DO
trainData = load('/mnt/dshi0006_market/Massive/COSproject/hctsa_space_subtractMean_removeLineNoise/HCTSA_train_ch10.mat');
validateData = load('/mnt/dshi0006_market/Massive/COSproject/hctsa_space_subtractMean_removeLineNoise/HCTSA_validate1_ch10.mat');
classifier = TrainNMClassifier(trainData.TS_DataMat, trainData.TimeSeries);
[~, correctRate_train] = ValidateNMClassifier(trainData.TS_DataMat, classifier, trainData.TimeSeries);
[predicted, correctRate_validate] = ValidateNMClassifier(validateData.TS_DataMat, classifier, validateData.TimeSeries);

plot(correctRate_train, correctRate_validate,'.');
axis equal tight padded;
set(gca,'tickdir','out');

xlabel('classification performance discovery data');
ylabel('classification performance validation data');

saveas(gcf,'NMclassifier_test.png');