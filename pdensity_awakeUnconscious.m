function fig_rc = pdensity_awakeUnconscious(data_all, TimeSeries_all, CodeString, refCodeString, subjectNames, condNames, xscale)
%fig_rc = pdensity_awakeUnconscious(data_all, TimeSeries_all, CodeString, refCodeString, subjectNames, condNames)

nedges = 50;

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

fig_rc=figure('position',[0 0 900 400]);
data_each = [];
ax_rc = [];
for itv = 1:2
    
    for icond = 1:2
        theseEpochs = intersect(find(getCondTrials(TimeSeries_all,subjectNames(itv))==1), ...
            find(getCondTrials(TimeSeries_all,condNames(icond))==1));
        data_each{itv, icond} = data_all(theseEpochs,refOperation_idx);
          if strcmp(xscale, 'log')
              data_each{itv,icond} = log10(data_each{itv,icond});
          end
        edges = linspace(dataRange(1), dataRange(2), nedges);

        switch icond
            case 1
                color = [1 0 1]; %awake
            case 2
                color = [0 1 1]; %unconscious
        end
        ax_rc(itv)=subplot(1,2,itv);
        % h= raincloud_plot(data_each{itv,icond}, 'color',color,'alpha',.5); hold on
        histogram(data_each{itv,icond},'binEdges',edges, 'facecolor',color,'orientation','horizontal',...
            'Normalization','probability');
        hold on;
        ylabel(subjectNames{itv});
    end
end
xlabel(replace(refCodeString,'_','-'));
linkaxes(ax_rc);
set(ax_rc,'tickdir','out'); %set(ax_rc,'ytick',[]);

% ff= mergefigs([fig_rc(:)']);
% set(ff,'position',[0 0 1100 700]);
%close fig_rc