
add_toolbox;

%
thisCh=10;
saveDir = '/mnt/dshi0006_market/Massive/COSproject/hctsa_space_subtractMean_removeLineNoise/';
saveName = sprintf('HCTSA_train_ch%d_sub.mat',thisCh);
thisData = fullfile(saveDir,saveName);
load(thisData,'TS_CalcTime','Operations')

ID_ng_ori = find(TS_InspectQuality('summary'));%run on sample data - 2172 NG operations
ID_ng_macaque = find(TS_InspectQuality('summary',thisData)); %run on macaque data - 999NG operations
%TS_InspectQuality('master',thisData);

%ID_ng=find(isnan(TS_CalcTime(1,:)));
%ID_ng_master = unique(Operations.MasterID(ID_ng));

ID_ng = intersect(ID_ng_macaque, ID_ng_ori); %457NG operations

codeString_ng = Operations.CodeString(ID_ng);
keywords_ng = Operations.Keywords(ID_ng);
keywords_all = Operations.Keywords;

thisOperation = find(contains(codeString_ng, 'NL_TISEAN_d2_ac_10_001.meanh2'));

[ts_ind, dataCell, codeEval] = TS_WhichProblemTS(ID_ng(thisOperation(1)), thisData); close all;

ngfunc = str2func(['@(x_z)' codeEval]);
ngfunc(dataCell{1}{1})

