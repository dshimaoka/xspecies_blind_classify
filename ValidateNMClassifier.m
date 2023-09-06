function [predicted_class, correctRate] = ValidateNMClassifier(DataMat, classifier, TimeSeries_validate)
% [predicted_class] = ValidateNMClassifier(DataMat, classifier)
% returns predicted classification to the given DataMat, using classifier,
% the output of TrainNMClassifier.m
%
% [predicted_class, correctRate] = ValidateNMClassifier(DataMat, classifier, TimeSeries_validate)
% also returns correct rate of the classifier

% Calculate Euclidean distances to both class medians
distance_to_class1 = abs(DataMat - classifier.median_cond(1,:));
distance_to_class2 = abs(DataMat - classifier.median_cond(2,:));


% Assign the data point to the class with the closest median
predicted_class = nan(size(DataMat));
idx1=find(distance_to_class1 < distance_to_class2);
idx2=find(distance_to_class1 >= distance_to_class2);
predicted_class(idx1) = 1;
predicted_class(idx2) = 2;

if nargin == 3
    condnames = {'condition1','condition2'};

    actual_class = nan(size(DataMat));
    for icond = 1:2
        idx = contains(TimeSeries_validate.Name, condnames{icond});
        actual_class(idx,:)=icond;
    end

    correct_class = (predicted_class == actual_class);
    correctRate = mean(correct_class,1);
end