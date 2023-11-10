%% Description

%{

Data pre-processing

Line noise removal

%}

%% Common parameters
species = 'macaque';
subject = 'George';

sample_rate = 1000;
%awake_file_t = fullfile(source_server, awake_dir, 'ECoGTime');
%load(awake_file_t); %ECoGTime
duration = 0.2; %[s]
frames = sample_rate * duration;

s_subtractMean = 1;
s_lineNoise = 1;

%% Path
addDirPrefs_COS;
dirPref = getpref('cosProject','dirPref');
save_dir = fullfile(dirPref.rootDir, 'preprocessed',species,subject);
load_dir = fullfile(dirPref.rootDir,'Neurotycho Data');

if exist(save_dir,'dir')
    mkdir(save_dir);
end

%% for spectral analysis
params = struct();
params.Fs = sample_rate;
params.tapers = [5 19]; %for monkey 
params.pad = 2;
params.removeFreq = [50];


%% load channels to process
load(fullfile(save_dir,['detectChannels_' subject]) ,'channel','tgtChannels','lobe');


for ich = 1:numel(tgtChannels)
    disp([num2str(ich), '/' num2str(numel(tgtChannels))]);

    thisCh = tgtChannels(ich);
    thisLobe = lobe(find(channel == thisCh));
    savedata_prefix = sprintf('%s_%s_ch%03d', species, subject, thisCh);
    data = getStats(species, subject);

    %% Load data
    data_tmp = cell(2,1);

    for icond = 1:2     %1: awake, %2: anesth

        source_dir = ['20120803PF_Anesthesia+and+Sleep_George_Toru+Yanagawa_mat_ECoG128' filesep 'Session' num2str(icond)];


        condition_file = fullfile(load_dir, source_dir, 'Condition');
        load(condition_file, 'ConditionIndex','ConditionTime','ConditionLabel');

        if icond == 1
            theseConditionIndex = [find(strcmp(ConditionLabel, 'AwakeEyesOpened-Start')) find(strcmp(ConditionLabel, 'AwakeEyesClosed-End'))];
        elseif icond == 2
            theseConditionIndex = [find(strcmp(ConditionLabel, 'Anesthetized-Start')) find(strcmp(ConditionLabel, 'Anesthetized-End'))];
        end
        theseTimeIdx = ConditionIndex(theseConditionIndex);

        chName = ['ECoG_ch' num2str(thisCh)];
        awake_file = fullfile(load_dir, source_dir, [chName '.mat']);
        tmp = load(awake_file); %ECoGData_chxx

        chDataName = ['ECoGData_ch' num2str(thisCh)];
        tmpdata=tmp.(chDataName);
        tmpdata = tmpdata(theseTimeIdx(1):theseTimeIdx(end));
        nTrials = floor(length(tmpdata)/frames);

        data_tmp{icond} = reshape(tmpdata(1:frames*nTrials), frames, nTrials);
    end

    %time x trial x condition
    data_raw = [];
    minTrials = min(size(data_tmp{1},2), size(data_tmp{2},2));
    data_tmp{1} = data_tmp{1}(:,randperm(size(data_tmp{1},2)));
    data_tmp{2} = data_tmp{2}(:,randperm(size(data_tmp{2},2)));
    data_raw(:,:,1) = data_tmp{1}(:,1:minTrials);
    data_raw(:,:,2) = data_tmp{2}(:,1:minTrials);

    [data_proc, preprocess_string, powers_before, powers_after , faxis_before, faxis_after] ...
        = preprocessOneCh(data_raw, params, s_subtractMean, s_lineNoise);
 
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


% %% Save
% 
% data = struct();
% data.train = data_t_proc;
% data.validate1 = data_v_proc;
% data.preprocess_params = params;
% data.preprocess_string = preprocess_string;
% 
% out_dir = '\\storage.erc.monash.edu.au\shares\MNHS-dshi0006\Massive\COSproject\preprocessed/';
% out_file = ['macaque_data' preprocess_string];
% mkdir(out_dir);
% tic;
% save([out_dir out_file], 'data', '-v7.3', '-nocompression');
% toc
% disp(['data saved: ' out_dir out_file]);
