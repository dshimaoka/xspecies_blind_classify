% created from preprocess_kirill.m 22/8/25

%% Description

%{

Data pre-processing

Line noise removal

%}

addpath(genpath('~/Documents/git/chronux_2_11'));

%% Common parameters
species = 'human';
subject = '369';

sample_rate = 1000;
duration = 0.2; %[s]
frames = sample_rate * duration;
calcWin = [1.4 - duration 1.4]; %[s]

s_subtractMean = 1;
s_lineNoise = 1;

%% Path
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
save_dir = fullfile(dirPref.rootDir, 'preprocessed',species,subject);
load_dir = fullfile(dirPref.rawDir, 'Kirill Iowa Intracranial Data/Stage 2');

if ~exist(save_dir,'dir')
    mkdir(save_dir);
end

%% parameters for spectral analysis
params = struct();
params.Fs = sample_rate;
params.tapers = [5 9];
params.pad = 2;
params.removeFreq = [];

%% load channels to process
% load(fullfile(save_dir,['detectChannels_' subject]) ,'channel','tgtChannels','lobe');
channel = 1:256; %FIXME
tgtChannels = 1; %FIXME
lobe = {'dummylobe'}; %FIXME

for ich = 1:numel(tgtChannels)
    disp([num2str(ich), '/' num2str(numel(tgtChannels))]);

    thisCh = tgtChannels(ich);
    thisLobe = lobe(find(channel == thisCh));
    savedata_prefix = sprintf('%s_%s_ch%03d', species, subject, thisCh);
    data = getStats(species, subject);


    %% Load data
    data_tmp = cell(2,1);
    original_file = cell(2,1);
    for icond = 1:2     %1: awake, %2: anesth

        %% load raw data
        load_file = [subject '-' data.expIDs{icond} '_SPECIALevents_DBT1.mat'];
        original_file{icond} = load_file;
        fileName = fullfile(load_dir, load_file);

        [dat, t, eventTimes, eventLabels] = loadOneChannel(fileName, thisCh,'LFPx');

        save(fullfile(save_dir, [load_file(1:end-4) '_icond' num2str(icond) '.mat']), 'dat','t','eventLabels','eventTimes');
        
        buttonPressCh = 1;
        [dat_btn, t_btn] = loadOneChannel(fileName, buttonPressCh,'Inpt');

        th = median(dat_btn)*0.5;
        dat_btn = single(dat_btn>th);

        %% select data without sensory stimulation
        theseEvents = find(eventLabels < 4);
        [~, winSamps, dat_event, sortedLabels, uniqueLabels] ...
            = eventLockedAvg(dat', t, eventTimes(theseEvents), eventLabels(theseEvents), calcWin, 0);

        %% select data without button press
        [~, winSamps, dat_btn_event, sortedLabels_btn] ...
            = eventLockedAvg(dat_btn', t_btn, eventTimes(theseEvents), eventLabels(theseEvents), calcWin, 0);

        noBtn = find(squeeze(mean(dat_btn_event,3))==0);

        data_tmp{icond} = squeeze(dat_event(noBtn,:)'); %time x trial

    end

    %time x trial x condition
    data_raw = [];
    minTrials = min(size(data_tmp{1},2), size(data_tmp{2},2));
    data_tmp{1} = data_tmp{1}(:,randperm(size(data_tmp{1},2)));
    data_tmp{2} = data_tmp{2}(:,randperm(size(data_tmp{2},2)));
    data_raw(:,:,1) = data_tmp{1}(:,1:minTrials);
    data_raw(:,:,2) = data_tmp{2}(:,1:minTrials);

    for icond = 1:2
        [data_proc(:,:,icond), preprocess_string, powers_before(:,:,icond), powers_after(:,:,icond) , faxis_before, faxis_after] ...
            = preprocessOneCh(data_raw(:,:,icond), params, s_subtractMean, s_lineNoise);
    end

    %% Plot and check power spectra for each fly
    figure;

    ax(1)=subplot(211);hold on;
    plot(faxis_before, squeeze(mean(log(powers_before(:, :, 1)),2)), 'r'); % wake
    plot(faxis_before, squeeze(mean(log(powers_before(:, :, 2)),2)), 'k'); % anest
    title('before preprocessing');

    ax(2)=subplot(212);hold on;
    plot(faxis_after, squeeze(mean(log(powers_after(:, :, 1)),2)), 'r'); % wake
    plot(faxis_after, squeeze(mean(log(powers_after(:, :, 2)),2)), 'k'); % anest
    title('after preprocessing');

    xlim([1 120]);
    linkaxes(ax(:));


    xlabel('Hz');
    ylabel('log(power)');
    legend('awake', 'anesthetized');
    screen2png(fullfile(save_dir, [savedata_prefix, '_powerspectra']));
    close;

    % %% Plot power spectra to help find validation trial with line noise
    %
    % % 50Hz line noise seems to be more apparent for channel 15
    % % There seems to be another peak for channel 14 (not at 50Hz)?
    %
    % ch = 15;
    % tr = 1;
    %
    % figure;
    % for ep = 1 : size(powers_v_proc, 4)
    %     subplot(6, 10, ep);
    %     plot(faxis_v, log(powers_v_proc(:, ch, tr, ep)));
    %
    %     xlim([40 60]);
    %     xlim([0 100]);
    %     title(num2str(ep));
    % end

    %% Save

    data.data_raw = data_raw;
    data.data_proc = data_proc;
    data.preprocess_params = params;
    data.preprocess_string = preprocess_string;
    data.channel = thisCh;
    data.lobe = thisLobe;

    out_file = [savedata_prefix preprocess_string];
    tic;
    save(fullfile(save_dir, out_file), 'data', '-v7.3', '-nocompression');
    toc
    disp(['data saved: ' fullfile(save_dir, out_file)]);
end
