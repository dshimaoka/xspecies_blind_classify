function fig = showHCTSAbarcodes(TS_Normalised, TimeSeries, order_f, order_e, CodeString, refCodeStrings)
%fig = showHCTSAbarcodes(TS_Normalised, TimeSeries, validFeatures, CodeString, refCodeString, bestCodeString)

%cf. https://github.com/Prototype003/fly_blind_classify/blob/main/main_hctsa_matrix.m

condNames = {'awake','unconscious'};

[nEpochs,nFeatures] = size(TS_Normalised);

refOperation_idx = [];
for ss = 1:numel(refCodeStrings)
    refOperation_idx(ss) =  find(strcmp(CodeString, refCodeStrings{ss}));
end

%order feature
%[order_c] = clusterFeatures(TS_Normalised(:,validFeatures));
%order_f = validFeatures(order_c);

if isempty(order_f)
    order_f = 1:nFeatures;
end

refOperation_idx_f=[];
for ss = 1:numel(refCodeStrings)
    [~,refOperation_idx_f(ss)] = intersect(order_f, refOperation_idx(ss));
end

condTrials = getCondTrials(TimeSeries, condNames);
data_a = TS_Normalised(condTrials==1,order_f);
data_u = TS_Normalised(condTrials==2,order_f);

    %order epoch
if isempty(order_e)
    order_e{1} = clusterFeatures(data_a');
    order_e{2} = clusterFeatures(data_u');
end

fig = figure('position',[0 0 500 400]);
ax(1)=subplot(211);
imagesc(data_a(order_e{1},:));title('awake');
ax(2)=subplot(212);
imagesc(data_u(order_e{2},:));title('unconscious');
set(ax,'tickdir','out');

fig2=figure;
%linecolors = colormap(fig2,cool(numel(refCodeStrings)));
linecolors = [0 1 0; 1 0 0];

close(fig2);
for ss = 1:numel(refOperation_idx_f)
    %reflines(gcf, refOperation_idx_f(ss),[],linecolors(ss,:))
    refvarrow(ax(1),refOperation_idx_f(ss),linecolors(ss,:))
    refvarrow(ax(2),refOperation_idx_f(ss),linecolors(ss,:))
end

colormap(inferno);
linkcaxes(ax(:), [0 1]);
mcolorbar;