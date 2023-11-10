function [predicted_class, correctRate, correctRate_rand] = ValidateNMClassifier(DataMat, classifier, ...
    TimeSeries_validate, condnames)
% [predicted_class] = ValidateNMClassifier(DataMat, classifier)
% returns predicted classification to the given DataMat, using classifier,
% the output of TrainNMClassifier.m
%
% [predicted_class, correctRate] = ValidateNMClassifier(DataMat, classifier, TimeSeries_validate)
% also returns correct rate of the classifier


if nargin < 4
    condnames = {'condition1','condition2'};
end

% Calculate Euclidean distances to both class medians
distance_to_class1 = abs(DataMat - classifier.median_cond(1,:));
distance_to_class2 = abs(DataMat - classifier.median_cond(2,:));

% Assign the data point to the class with the closest median
predicted_class = nan(size(DataMat));
idx1=find(distance_to_class1 < distance_to_class2);
idx2=find(distance_to_class1 >= distance_to_class2);
predicted_class(idx1) = 1;
predicted_class(idx2) = 2;

% for computation of significance
predicted_class_rand = nan(size(DataMat));
randIdx = randperm(numel(distance_to_class1));
idx1_rand = randIdx(1:numel(idx1));
idx2_rand = randIdx(numel(idx1)+1:numel(randIdx));
predicted_class_rand(idx1_rand) = 1;
predicted_class_rand(idx2_rand) = 2;

    actual_class = nan(size(DataMat));
    for icond = 1:2
        idx = contains(TimeSeries_validate.Name, condnames{icond});
        actual_class(idx,:)=icond;
    end

    correct_class = (predicted_class == actual_class);
    correctRate = mean(correct_class,1);

    % chance_accuracy.m
    correct_class_rand = (predicted_class_rand == actual_class);
    correctRate_rand = mean(correct_class_rand);
