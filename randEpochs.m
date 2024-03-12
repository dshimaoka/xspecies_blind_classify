function dividedEpochs = randEpochs(Data, condNames, nDraws, nEpochs, rngSeed)
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
%
%TODO: refactor based on https://au.mathworks.com/help/stats/cvpartition.html

if nargin< 5
    % Set the random number generator seed
    rngSeed = 100;%42;
end
rng(rngSeed); % You can use any integer value as the seed

if nargin < 4 || isempty(nEpochs)
    nEpochs = [10 100]; %#epochs for training and validation
end

idx_perm = cell(1,2);
for icond = 1:2 %awake / unconscious
    % idx = find(contains(Data.TimeSeries.Name, condNames{icond}))';
    % idx_perm{icond} = idx(randperm(numel(idx)));
    idx_perm{icond} = find(contains(Data.TimeSeries.Name, condNames{icond}))';
end
%epochs for training
nEpochs_percel(1,1) = nEpochs(1);
nEpochs_percel(2,1) = nEpochs(1);
%epochs for validation ... do not overlap epochs for training
nEpochs_percel(1,2) = nEpochs(2);
nEpochs_percel(2,2) = nEpochs(2);

dividedEpochs = cell(2,nDraws);  %1st row: epochs for training, 2nd row: epochs for validation
for ipercel = 1:nDraws    
    idx_percel_cond1 = randperm(numel(idx_perm{1}), sum(nEpochs_percel(1,:))); 
    idx_percel_cond2 = randperm(numel(idx_perm{2}), sum(nEpochs_percel(2,:)));

    %for training [awake unconscious]
    dividedEpochs{1,ipercel} = [idx_perm{1}(idx_percel_cond1(1:nEpochs_percel(1,1))) ...
        idx_perm{2}(idx_percel_cond2(1:nEpochs_percel(2,1)))];

    %for validation [awake unconscious]
    dividedEpochs{2,ipercel} =[idx_perm{1}(idx_percel_cond1(nEpochs_percel(1,1)+1:end)) ...
        idx_perm{2}(idx_percel_cond2(nEpochs_percel(2,1)+1:end))];
end
