function [data_proc, preprocess_string, powers_before, powers_after , faxis_before, faxis_after] ...
    = preprocessOneCh(data_raw,  params, s_subtractMean,  s_lineNoise)

%% Preprocessing

    preprocess_string = ''; % To keep track of preprocessing pipeline

    % Processed versions of the data structure
    %data_proc = data_t;
    %data_v_proc = data_v;
    data_proc = data_raw;

    %% Subtract mean from each epoch


    if s_subtractMean == 1
        tic;
        dims = size(data_proc);
        data_mean = mean(data_proc, 1);
        data_mean = repmat(data_mean, [dims(1) ones(1, length(dims)-1)]);
        data_proc = data_proc - data_mean;
        toc

        preprocess_string = [preprocess_string '_subtractMean'];
    end


    %% Remove line noise
    % Do extra processing
    if s_lineNoise == 1
        disp('removing line noise');
        tic;
        [data_proc, data_t_fit] = removeLineNoise(data_proc, params); % ~10 seconds (tapers = [3 5])
        toc
        disp('...done')
        preprocess_string = [preprocess_string '_removeLineNoise'];
    end

    %% Plot and check power spectra before/after line noise removal
    % Get power spectra
    disp('computing power spectra');
    tic;
    [powers_before, faxis_before] = getPower(data_raw, params);
    toc

    tic;
    [powers_after, faxis_after] = getPower(data_proc, params);
    toc
    disp('...done');
