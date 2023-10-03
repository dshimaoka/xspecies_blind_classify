
%awake
%load('/mnt/dshi0006_market/Massive/COSproject/Kirill Iowa Intracranial Data/369-130_SPECIALevents_DBT1.mat')

%unconscious
load('/mnt/dshi0006_market/Massive/COSproject/Kirill Iowa Intracranial Data/369-135_SPECIALevents_DBT1.mat')



%theseTrials = (FIDX.evnt == 0 | FIDX.evnt==2);
theseTimes = FIDX.time;%(theseTrials);
eventLabels = FIDX.evnt;

%thisCh = 1;
%dataName = sprintf('LFPx_RZ2_chn%03d',thisCh)
time_ori = LFPx_RZ2_chn048.t;
fs = LFPx_RZ2_chn048.fs;
data = LFPx_RZ2_chn048.dat;

%t = linspace(time_ori(1), time_ori(end), numel(data)); %wild guess! ... NG
t = time_ori(1):1e-3:time_ori(1)+1e-3*(numel(data)-1);

calcWin = [0 1.4]; %[s]
doMedian = 0;
 [avgPeriEventV, winSamps, periEventV, sortedLabels, uniqueLabels] ...
    = eventLockedAvg(data', t, theseTimes, eventLabels, calcWin, doMedian);
%plot(winSamps, squeeze(avgPeriEventV));

standard = squeeze(periEventV(sortedLabels==0|sortedLabels==2,:));
deviant = squeeze(periEventV(sortedLabels==1|sortedLabels==3,:));
silence = squeeze(periEventV(sortedLabels==7,:));

%result of find_lgd_trial_indices
%standard = squeeze(periEventV(ls,:));
%deviant = squeeze(periEventV(ld,:));
plot(winSamps, -mean(standard),'color',[0 1 1]);hold on;
plot(winSamps, -mean(deviant),'color','k');