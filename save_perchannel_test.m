%run this file after main_hctsa_1_init.m

suffix = 'validate1'; %
saveDir = '/mnt/dshi0006_market/Massive/COSproject/hctsa_space_subtractMean_removeLineNoise/';

nTotCh = 128;
thisMacaque = 2;
load('selectedCh_20230909','selectedCh');

for ich = 15:numel(selectedCh)
    thisCh = selectedCh(ich);
    load(fullfile(saveDir,['HCTSA_' suffix '.mat']));

    idx = thisCh:128:size(TS_DataMat,1);
    saveName = sprintf('HCTSA_%s_ch%d.mat',suffix,thisCh);

    TimeSeries = TimeSeries(idx,:);
    TS_CalcTime = TS_CalcTime(idx,:);
    TS_DataMat = TS_DataMat(idx,:);
    TS_Quality = TS_Quality(idx,:);

    save(fullfile(saveDir,saveName),'TS_Quality','TS_DataMat','TS_CalcTime','TimeSeries',...
        'MasterOperations','Operations',"fromDatabase",'gitInfo');
end
