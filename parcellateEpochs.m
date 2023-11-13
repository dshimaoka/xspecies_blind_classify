function dividedEpochs = parcellateEpochs(Data, condNames, ncv, equalEpochsBetConds)
%dividedEpochs = parcellateEpochs(trainData, condNames, ncv)
%
% dont assume equal number of epochs between conditions
% if equalEpochsBetConds(default), each parcel has equal number of epochs from cond1
% and 2. This means some epochs are discarded when #epochs are not equal
% betwen two conditions
%
% INPUT:
% Data:
% .Operations
% .TS_DataMat
% .TimeSeries

if nargin<4
    equalEpochsBetConds= true;
end

idx_perm = cell(1,2);
for icond = 1:2
    idx = find(contains(Data.TimeSeries.Name, condNames{icond}))';
    idx_perm{icond} = idx(randperm(numel(idx)));
end
nEpochs_percel(1) =floor(numel(idx_perm{1})/ncv);
nEpochs_percel(2) =floor(numel(idx_perm{2})/ncv);

if equalEpochsBetConds
    nEpochs_parcel(2)=nEpochs_percel(1);
end

dividedEpochs = cell(1,ncv);
for ipercel = 1:ncv
    if ipercel < ncv
        idx_percel_cond1 = (ipercel-1)*nEpochs_percel(1) + (1:nEpochs_percel(1));
        idx_percel_cond2 = (ipercel-1)*nEpochs_percel(2) + (1:nEpochs_percel(2));
    elseif ipercel == ncv
        idx_percel_cond1 = (ipercel-1)*nEpochs_percel(1) + 1:numel(idx_perm{1});
        idx_percel_cond2 = (ipercel-1)*nEpochs_percel(2) + 1:numel(idx_perm{2});
    end
    dividedEpochs{ipercel} = [idx_perm{1}(idx_percel_cond1) idx_perm{2}(idx_percel_cond2)];
end