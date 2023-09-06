function classifier =  TrainNMClassifier(DataMat_train, TimeSeries)

condnames = {'condition1','condition2'};
%[dims, macaque, channel, condition, epoch] = decodeTimeSeries(TimeSeries);


classifier = [];
for icond = 1:2
    idx = contains(TimeSeries.Name, condnames{icond});
    classifier.median_cond(icond,:) = median(DataMat_train(idx,:),1);
end