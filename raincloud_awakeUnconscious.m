function ff = raincloud_awakeUnconscious(data_all, TimeSeries_all, CodeString, refCodeStrings, subjectNames, condNames)

if nargin < 6
    condNames = {'awake','unconscious'};
end

refOperation_idx = [];
for ss = 1:numel(refCodeStrings)
    refOperation_idx(ss) =  find(strcmp(CodeString, refCodeStrings{ss}));
end

for ss = 1:numel(refCodeStrings)
    fig_rc(ss)=figure;
    data_each = [];
    ax_rc = [];
    for itv = 1:2
        for icond = 1:2
            theseEpochs = intersect(find(getCondTrials(TimeSeries_all,subjectNames(itv))==1), ...
                find(getCondTrials(TimeSeries_all,condNames(icond))==1));
            data_each{itv, icond} = data_all(theseEpochs,refOperation_idx(ss));

            switch icond
                case 1
                    color = [1 0 1]; %awake
                case 2
                    color = [0 1 1]; %unconscious
            end
            ax_rc(itv)=subplot(2,1,itv);
            h= raincloud_plot(data_each{itv,icond}, 'color',color,'alpha',.5); hold on
            ylabel(subjectNames{itv});
        end
    end
    xlabel(replace(refCodeStrings{ss},'_','-'));
    linkaxes(ax_rc);
    set(ax_rc,'tickdir','out'); set(ax_rc,'ytick',[]);
end
ff= mergefigs([fig_rc(:)']);
set(ff,'position',[0 0 1100 700]);
%close fig_rc