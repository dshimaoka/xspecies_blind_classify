function classifier =  TrainNMClassifier(DataMat_train, TimeSeries, condNames)
%  classifier =  TrainNMClassifier(DataMat_train, TimeSeries, condNames)
%
% OUTPUT:
% classifier.median_cond
% classifier.threshold
% classifier.direction

if nargin < 3
    condNames = {'condition1','condition2'};
end
%[dims, macaque, channel, condition, epoch] = decodeTimeSeries(TimeSeries);


classifier = [];
for icond = 1:2
    idx = contains(TimeSeries.Name, condNames{icond});
    classifier.median_cond(icond,:) = median(DataMat_train(idx,:),1);
end

classifier.threshold = mean(classifier.median_cond,1) ; %main_nearestMean_crossValidation.m

%   direction: 1 means class 1 centre >= class 2 centre
%   direction: 0 means class 1 centre < class 2 centre
classifier.direction = classifier.median_cond(1,:) >= classifier.median_cond(2,:); %main_nearestMean_crossValidation.m

