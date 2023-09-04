
saveDir = '/mnt/dshi0006_market/Massive/COSproject/hctsa_space_subtractMean_removeLineNoise/';
load(fullfile(saveDir,'HCTSA_train.mat')

nTotCh = 128;
thisCh = 10;
idx = thisCh:128:52736;
saveName = sprintf('HCTSA_train_ch%d.mat',thisCh);

TimeSeries = TimeSeries(idx,:);
TS_CalcTime = TS_CalcTime(idx,:);
TS_DataMat = TS_DataMat(idx,:);
TS_Quality = TS_Quality(idx,:);

save(fullfile(saveDir,saveName),'TS_Quality','TS_DataMat','TS_CalcTime','TimeSeries',...
    'MasterOperations','Operations',"fromDatabase",'gitInfo');

idx_sub = 1:3;
TimeSeries = TimeSeries(idx_sub,:);
TS_CalcTime = TS_CalcTime(idx_sub,:);
TS_DataMat = TS_DataMat(idx_sub,:);
TS_Quality = TS_Quality(idx_sub,:);
saveName_sub = sprintf('HCTSA_train_ch%d_sub.mat',thisCh);

save(fullfile(saveDir,saveName_sub),'TS_Quality','TS_DataMat','TS_CalcTime','TimeSeries',...
    'MasterOperations','Operations',"fromDatabase",'gitInfo');


