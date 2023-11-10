thisCh = 48;


for istate = 1:2
    switch istate
        case 1
            %awake
            fname = '/mnt/dshi0006_market/Massive/COSproject/Kirill Iowa Intracranial Data/369-130_SPECIALevents_DBT1.mat';

        case 2
            %unconscious
            fname = '/mnt/dshi0006_market/Massive/COSproject/Kirill Iowa Intracranial Data/369-135_SPECIALevents_DBT1.mat';
    end

    load(fname)



    %theseTrials = (FIDX.evnt == 0 | FIDX.evnt==2);
    theseTimes = FIDX.time;%(theseTrials);
    eventLabels = FIDX.evnt;

    dataName = sprintf('LFPx_RZ2_chn%03d',thisCh);
    
    channelStruct = eval(dataName);

    time_ori = channelStruct.t;
    dat = channelStruct.dat;

    %t = linspace(time_ori(1), time_ori(end), numel(data)); %wild guess! ... NG
    t = time_ori(1):1e-3:time_ori(1)+1e-3*(numel(dat)-1);

    calcWin = [0 1.4]; %[s]
    doMedian = 0;
    [avgPeriEventV, winSamps, periEventV, sortedLabels, uniqueLabels] ...
        = eventLockedAvg(dat', t, theseTimes, eventLabels, calcWin, doMedian);
    %plot(winSamps, squeeze(avgPeriEventV));

    silence = squeeze(periEventV(sortedLabels==7,:));

    subplot(2,1,istate);
    imagesc(silence_awake);caxis([-100 100]);colorbar;
    title(fname);
end