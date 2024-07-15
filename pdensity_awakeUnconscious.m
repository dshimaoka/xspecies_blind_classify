function fig_rc = pdensity_awakeUnconscious(data_all, TimeSeries_all, CodeString, refCodeString, subjectNames, condNames, xscale, nedges)
%fig_rc = pdensity_awakeUnconscious(data_all, TimeSeries_all, CodeString, refCodeString, subjectNames, condNames)

if nargin<8
    nedges = 25;
end
if nargin < 7
    xscale = 'linear';
end

if nargin < 6
    condNames = {'awake','unconscious'};
end

refOperation_idx =  find(strcmp(CodeString, refCodeString));

dataRange = prctile(data_all(:,refOperation_idx),[1 99]);%[0 100]);
if strcmp(xscale, 'log')
    dataRange = log10(dataRange);
end

lcolors = [];
for icond = 1:2
    switch icond
        case 1
            lcolors(icond,:) = [1 0 1]; %awake
        case 2
            lcolors(icond,:) = [0 1 1]; %unconscious
    end
end

fig_rc=figure('position',[0 0 900 400]);
data_each = []; median_each = [];
ax_rc = [];
for itv = 1:2
    for icond = 1:2
        theseEpochs = intersect(find(getCondTrials(TimeSeries_all,subjectNames(itv))==1), ...
            find(getCondTrials(TimeSeries_all,condNames(icond))==1));
        data_each{itv, icond} = data_all(theseEpochs,refOperation_idx);
        median_each(itv,icond) = median(data_each{itv, icond});
          if strcmp(xscale, 'log')
              data_each{itv,icond} = log10(data_each{itv,icond});
              median_each(itv,icond) = log10(median_each(itv,icond));
          end
        edges = linspace(dataRange(1), dataRange(2), nedges);

        ax_rc(itv)=subplot(1,2,itv);
        % h= raincloud_plot(data_each{itv,icond}, 'color',color,'alpha',.5); hold on
        histogram(data_each{itv,icond},'binEdges',edges, 'facecolor',lcolors(icond,:),'orientation','horizontal',...
            'Normalization','probability');
        hold on;
        ylabel(subjectNames{itv});
    end
    axis square;
end
xlabel(replace(refCodeString,'_','-'));
linkaxes(ax_rc);
for itv = 1:2
    hline(median_each(1,1), ax_rc(itv),'-',lcolors(1,:));     hline(median_each(2,1), ax_rc(itv),':',lcolors(1,:));

    hline(median_each(1,2), ax_rc(itv),'-',lcolors(2,:));    hline(median_each(2,2), ax_rc(itv),':',lcolors(2,:));

    hline(mean(median_each(1,:)), ax_rc(itv),'-', [0 0 0]);  hline(mean(median_each(2,:)), ax_rc(itv),':', [0 0 0]); 
end
set(ax_rc,'tickdir','out'); %set(ax_rc,'ytick',[]);


% ff= mergefigs([fig_rc(:)']);
% set(ff,'position',[0 0 1100 700]);
%close fig_rc