function ngIdx = detectNGidx_NMclassification(save_dir, species_train, subject_train, tgtChannels_train, ...
    species_validate, subject_validate, tgtChannels_validate)
%ngIdx = detectNGidx_NMclassification(species_train, subject_train, tgtChannels_train, ...
%    species_validate, subject_validate, tgtChannels_validate)

%hctsa_dir_train = fullfile(rootDir, ['hctsa' preprocessSuffix],species_train,subject_train);
%hctsa_dir_validate = fullfile(rootDir, ['hctsa' preprocessSuffix],species_validate,subject_validate);

%tgtIdx = 1:numel(tgtChannels_train)*numel(tgtChannels_validate);

ngIdx = [];
for thisChIdx = 1:numel(tgtChannels_train)*numel(tgtChannels_validate)

    [ii,jj] = ind2sub([numel(tgtChannels_train) numel(tgtChannels_validate)],  thisChIdx);

    ch_train = tgtChannels_train(ii);
    % file_string_train = fullfile(hctsa_dir_train,  sprintf('%s_%s_ch%03d_hctsa', species_train, subject_train, ch_train));
    % trainData = matfile(file_string_train, 'Writable', false);
    % %trainData = load([file_string_train '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

    ch_validate = tgtChannels_validate(jj);
    % file_string_validate = fullfile(hctsa_dir_validate,  sprintf('%s_%s_ch%03d_hctsa', species_validate, subject_validate, ch_validate));
    % validateData = matfile(file_string_validate, 'Writable', false);
    %validateData = load([file_string_validate '.mat'], 'Operations', 'TS_DataMat', 'TimeSeries', 'TS_Normalised');

    %clear trainData validateData

    out_file = fullfile(save_dir, sprintf('train_%s_%s_ch%03d_validate_%s_%s_ch%03d_accuracy.mat', ...
        species_train, subject_train, ch_train,...
        species_validate,subject_validate, ch_validate));

    %test = matfile(out_file, 'Writable', false); %USELESS
    if exist(out_file, 'file')==0
        ngIdx = [ngIdx thisChIdx];
        disp(out_file);
        continue;
    end
    try
        load(out_file, 'classifier_cv')
    catch err
        ngIdx = [ngIdx thisChIdx];
        disp(out_file);
    end
end
disp([num2str(numel(ngIdx)) ' NGs' ]);